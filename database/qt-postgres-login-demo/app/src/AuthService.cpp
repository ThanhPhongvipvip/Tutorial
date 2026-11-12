#include "AuthService.h"

#include <QDebug>
#include <QProcessEnvironment>
#include <QRegularExpression>
#include <QSqlError>
#include <QSqlQuery>
#include <QThread>

const QString AuthService::kConnectionName = QStringLiteral("login_demo");

namespace {
QString env(const char *name, const QString &fallback)
{
    const auto e = QProcessEnvironment::systemEnvironment();
    return e.value(QString::fromLatin1(name), fallback);
}
} // namespace

AuthService::AuthService()
{
    m_db = QSqlDatabase::addDatabase(QStringLiteral("QPSQL"), kConnectionName);
    m_db.setHostName(env("DB_HOST", QStringLiteral("localhost")));
    m_db.setPort(env("DB_PORT", QStringLiteral("5432")).toInt());
    m_db.setDatabaseName(env("DB_NAME", QStringLiteral("appdb")));
    m_db.setUserName(env("DB_USER", QStringLiteral("login_app")));
    m_db.setPassword(env("DB_PASSWORD", QString()));
    m_db.setConnectOptions(QStringLiteral("connect_timeout=3"));
}

AuthService::~AuthService()
{
    if (m_db.isOpen())
        m_db.close();
    m_db = QSqlDatabase();
    QSqlDatabase::removeDatabase(kConnectionName);
}

bool AuthService::connectToDatabase(int timeoutSec, QString *error)
{
    if (!QSqlDatabase::isDriverAvailable(QStringLiteral("QPSQL"))) {
        if (error)
            *error = QStringLiteral("Qt PostgreSQL driver (QPSQL) is not installed.");
        return false;
    }

    QString lastError;
    for (int attempt = 0; attempt < qMax(1, timeoutSec); ++attempt) {
        if (m_db.open())
            return true;
        lastError = m_db.lastError().text();
        qInfo().noquote() << "Waiting for database..." << lastError.simplified();
        QThread::sleep(1);
    }
    if (error)
        *error = lastError;
    return false;
}

bool AuthService::isValidUsername(const QString &username)
{
    static const QRegularExpression re(QStringLiteral("^[A-Za-z0-9_.-]{3,50}$"));
    return re.match(username).hasMatch();
}

AuthService::LoginResult AuthService::login(const QString &username, const QString &password,
                                            User *user, QString *error)
{
    // So khớp mật khẩu ngay trong DB: crypt(plain, stored_hash) dùng lại salt trong hash.
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral(
        "SELECT id, username, coalesce(full_name, ''), last_login_at "
        "FROM app_users "
        "WHERE lower(username) = lower(:u) "
        "  AND password_hash = crypt(:p, password_hash)"));
    q.bindValue(QStringLiteral(":u"), username);
    q.bindValue(QStringLiteral(":p"), password);

    if (!q.exec()) {
        if (error)
            *error = q.lastError().text();
        return LoginResult::Error;
    }
    if (!q.next())
        return LoginResult::InvalidCredentials; // cùng một kết quả cho "sai user" và "sai mật khẩu"

    User u;
    u.id = q.value(0).toLongLong();
    u.username = q.value(1).toString();
    u.fullName = q.value(2).toString();
    u.lastLogin = q.value(3).toDateTime();

    QSqlQuery upd(m_db);
    upd.prepare(QStringLiteral("UPDATE app_users SET last_login_at = now() WHERE id = :id"));
    upd.bindValue(QStringLiteral(":id"), u.id);
    if (!upd.exec())
        qWarning().noquote() << "Could not update last_login_at:" << upd.lastError().text();

    if (user)
        *user = u;
    return LoginResult::Ok;
}

AuthService::RegisterResult AuthService::registerUser(const QString &username,
                                                      const QString &password,
                                                      const QString &fullName, QString *error)
{
    if (!isValidUsername(username) || password.size() < kMinPasswordLength)
        return RegisterResult::InvalidInput;

    QSqlQuery q(m_db);
    q.prepare(QStringLiteral(
        "INSERT INTO app_users (username, password_hash, full_name) "
        "VALUES (:u, crypt(:p, gen_salt('bf', 10)), nullif(:n, ''))"));
    q.bindValue(QStringLiteral(":u"), username);
    q.bindValue(QStringLiteral(":p"), password);
    q.bindValue(QStringLiteral(":n"), fullName.trimmed());

    if (q.exec())
        return RegisterResult::Ok;

    const QSqlError e = q.lastError();
    // SQLSTATE 23505 = unique_violation
    if (e.nativeErrorCode() == QLatin1String("23505"))
        return RegisterResult::UsernameTaken;
    if (error)
        *error = e.text();
    return RegisterResult::Error;
}
