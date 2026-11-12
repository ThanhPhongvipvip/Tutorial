#pragma once

#include "AuthService.h"

#include <QWidget>

class QLineEdit;
class QLabel;
class QPushButton;
class WelcomeWindow;

class LoginWindow : public QWidget
{
    Q_OBJECT
public:
    explicit LoginWindow(AuthService *auth, QWidget *parent = nullptr);

private slots:
    void attemptLogin();
    void openRegister();
    void onLoggedOut();

private:
    AuthService *m_auth;
    QLineEdit *m_username;
    QLineEdit *m_password;
    QLabel *m_status;
    QPushButton *m_loginButton;
    WelcomeWindow *m_welcome = nullptr;
};
