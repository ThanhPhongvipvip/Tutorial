#include "LoginWindow.h"

#include "RegisterDialog.h"
#include "WelcomeWindow.h"

#include <QFormLayout>
#include <QLabel>
#include <QLineEdit>
#include <QPushButton>
#include <QVBoxLayout>

LoginWindow::LoginWindow(AuthService *auth, QWidget *parent)
    : QWidget(parent), m_auth(auth)
{
    setWindowTitle(tr("Qt + PostgreSQL Login"));

    auto *title = new QLabel(tr("<h2>Sign in</h2>"));
    title->setAlignment(Qt::AlignCenter);

    m_username = new QLineEdit;
    m_username->setPlaceholderText(tr("Username"));
    m_password = new QLineEdit;
    m_password->setPlaceholderText(tr("Password"));
    m_password->setEchoMode(QLineEdit::Password);

    m_status = new QLabel;
    m_status->setAlignment(Qt::AlignCenter);
    m_status->setWordWrap(true);

    m_loginButton = new QPushButton(tr("Login"));
    m_loginButton->setDefault(true);
    auto *registerButton = new QPushButton(tr("Create account"));
    registerButton->setFlat(true);

    auto *hint = new QLabel(tr("<small>Demo accounts: <b>admin / admin123</b>, "
                               "<b>demo / demo123</b></small>"));
    hint->setAlignment(Qt::AlignCenter);

    auto *form = new QFormLayout;
    form->addRow(tr("Username"), m_username);
    form->addRow(tr("Password"), m_password);

    auto *layout = new QVBoxLayout(this);
    layout->setContentsMargins(24, 20, 24, 20);
    layout->setSpacing(10);
    layout->addWidget(title);
    layout->addLayout(form);
    layout->addWidget(m_status);
    layout->addWidget(m_loginButton);
    layout->addWidget(registerButton);
    layout->addWidget(hint);

    connect(m_loginButton, &QPushButton::clicked, this, &LoginWindow::attemptLogin);
    connect(m_password, &QLineEdit::returnPressed, this, &LoginWindow::attemptLogin);
    connect(m_username, &QLineEdit::returnPressed, m_password,
            qOverload<>(&QWidget::setFocus));
    connect(registerButton, &QPushButton::clicked, this, &LoginWindow::openRegister);

    setMinimumWidth(360);
    m_username->setFocus();
}

void LoginWindow::attemptLogin()
{
    const QString user = m_username->text().trimmed();
    const QString pass = m_password->text();

    m_status->setStyleSheet(QStringLiteral("color: #c0392b;"));
    if (user.isEmpty() || pass.isEmpty()) {
        m_status->setText(tr("Please enter username and password."));
        return;
    }

    AuthService::User u;
    QString err;
    switch (m_auth->login(user, pass, &u, &err)) {
    case AuthService::LoginResult::Ok:
        m_status->clear();
        m_password->clear();
        delete m_welcome;
        m_welcome = new WelcomeWindow(u);
        m_welcome->setAttribute(Qt::WA_DeleteOnClose, false);
        connect(m_welcome, &WelcomeWindow::loggedOut, this, &LoginWindow::onLoggedOut);
        m_welcome->show();
        hide();
        break;
    case AuthService::LoginResult::InvalidCredentials:
        m_status->setText(tr("Invalid username or password."));
        m_password->clear();
        m_password->setFocus();
        break;
    case AuthService::LoginResult::Error:
        m_status->setText(tr("Database error: %1").arg(err));
        break;
    }
}

void LoginWindow::openRegister()
{
    RegisterDialog dlg(m_auth, this);
    if (dlg.exec() == QDialog::Accepted) {
        m_username->setText(dlg.username());
        m_password->clear();
        m_password->setFocus();
        m_status->setStyleSheet(QStringLiteral("color: #27ae60;"));
        m_status->setText(tr("Account created. You can sign in now."));
    }
}

void LoginWindow::onLoggedOut()
{
    if (m_welcome)
        m_welcome->hide();
    show();
    m_password->setFocus();
}
