#include "AuthService.h"
#include "LoginWindow.h"

#include <QApplication>
#include <QDateTime>
#include <QMessageBox>

#include <cstdio>

// Kiểm thử tự động không cần giao diện: ./run.sh test
static int runSelfTest(AuthService &auth)
{
    int failures = 0;
    auto check = [&failures](bool ok, const char *what) {
        std::printf("[%s] %s\n", ok ? " OK " : "FAIL", what);
        if (!ok)
            ++failures;
    };

    AuthService::User u;
    QString err;

    check(auth.login("admin", "admin123", &u, &err) == AuthService::LoginResult::Ok,
          "login admin/admin123 succeeds");
    check(u.username == "admin", "returned username is 'admin'");
    check(auth.login("ADMIN", "admin123", &u, &err) == AuthService::LoginResult::Ok,
          "username is case-insensitive");
    check(auth.login("admin", "wrong", &u, &err) == AuthService::LoginResult::InvalidCredentials,
          "wrong password is rejected");
    check(auth.login("nobody", "admin123", &u, &err) == AuthService::LoginResult::InvalidCredentials,
          "unknown user is rejected");
    check(auth.login("admin' OR '1'='1", "x", &u, &err) == AuthService::LoginResult::InvalidCredentials,
          "SQL injection attempt is rejected");

    const QString name = QStringLiteral("selftest_%1").arg(QDateTime::currentMSecsSinceEpoch());
    check(auth.registerUser(name, "short", "", &err) == AuthService::RegisterResult::InvalidInput,
          "short password is rejected");
    check(auth.registerUser(name, "longenough1", "Self Test", &err) == AuthService::RegisterResult::Ok,
          "register new user");
    check(auth.registerUser(name.toUpper(), "longenough1", "", &err)
              == AuthService::RegisterResult::UsernameTaken,
          "duplicate username (any case) is rejected");
    check(auth.login(name, "longenough1", &u, &err) == AuthService::LoginResult::Ok,
          "login with the new account");

    std::printf("%s (%d failure%s)\n", failures ? "SELFTEST FAILED" : "SELFTEST PASSED",
                failures, failures == 1 ? "" : "s");
    return failures ? 1 : 0;
}

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    QApplication::setApplicationName("qt_login_demo");

    AuthService auth;
    QString err;
    if (!auth.connectToDatabase(30, &err)) {
        const QString msg = QObject::tr("Cannot connect to the database:\n%1").arg(err);
        std::fprintf(stderr, "%s\n", qPrintable(msg));
        if (QApplication::arguments().contains("--selftest") == false)
            QMessageBox::critical(nullptr, QObject::tr("Database error"), msg);
        return 2;
    }

    if (QApplication::arguments().contains("--selftest"))
        return runSelfTest(auth);

    LoginWindow w(&auth);
    w.show();
    return app.exec();
}
