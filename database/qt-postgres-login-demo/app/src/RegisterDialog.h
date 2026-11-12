#pragma once

#include "AuthService.h"

#include <QDialog>

class QLineEdit;
class QLabel;

class RegisterDialog : public QDialog
{
    Q_OBJECT
public:
    explicit RegisterDialog(AuthService *auth, QWidget *parent = nullptr);

    QString username() const;

private slots:
    void submit();

private:
    AuthService *m_auth;
    QLineEdit *m_username;
    QLineEdit *m_fullName;
    QLineEdit *m_password;
    QLineEdit *m_confirm;
    QLabel *m_status;
};
