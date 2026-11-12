#pragma once

#include <QDateTime>
#include <QSqlDatabase>
#include <QString>

// Lớp truy cập dữ liệu: toàn bộ SQL của ứng dụng nằm ở đây.
// Mọi tham số đều đi qua bind value (prepared statement) => chống SQL injection.
class AuthService
{
public:
    struct User {
        qint64 id = 0;
        QString username;
        QString fullName;
        QDateTime lastLogin; // lần đăng nhập TRƯỚC (null nếu đây là lần đầu)
    };

    enum class LoginResult { Ok, InvalidCredentials, Error };
    enum class RegisterResult { Ok, InvalidInput, UsernameTaken, Error };

    // Đọc cấu hình từ biến môi trường DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD.
    AuthService();
    ~AuthService();

    // Kết nối, thử lại tối đa `timeoutSec` giây (DB có thể đang khởi động).
    bool connectToDatabase(int timeoutSec, QString *error);

    LoginResult login(const QString &username, const QString &password,
                      User *user, QString *error);

    RegisterResult registerUser(const QString &username, const QString &password,
                                const QString &fullName, QString *error);

    static bool isValidUsername(const QString &username);
    static constexpr int kMinPasswordLength = 8;

private:
    QSqlDatabase m_db;
    static const QString kConnectionName;
};
