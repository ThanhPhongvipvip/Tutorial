#include "RegisterDialog.h"

#include <QDialogButtonBox>
#include <QFormLayout>
#include <QLabel>
#include <QLineEdit>
#include <QPushButton>
#include <QVBoxLayout>

RegisterDialog::RegisterDialog(AuthService *auth, QWidget *parent)
    : QDialog(parent), m_auth(auth)
{
    setWindowTitle(tr("Create account"));
    setModal(true);

    m_username = new QLineEdit;
    m_username->setPlaceholderText(tr("3-50 chars: letters, digits, _ . -"));
    m_fullName = new QLineEdit;
    m_fullName->setPlaceholderText(tr("Optional"));
    m_password = new QLineEdit;
    m_password->setEchoMode(QLineEdit::Password);
    m_password->setPlaceholderText(tr("At least %1 characters").arg(AuthService::kMinPasswordLength));
    m_confirm = new QLineEdit;
    m_confirm->setEchoMode(QLineEdit::Password);

    m_status = new QLabel;
    m_status->setWordWrap(true);
    m_status->setStyleSheet(QStringLiteral("color: #c0392b;"));

    auto *form = new QFormLayout;
    form->addRow(tr("Username"), m_username);
    form->addRow(tr("Full name"), m_fullName);
    form->addRow(tr("Password"), m_password);
    form->addRow(tr("Confirm"), m_confirm);

    auto *buttons = new QDialogButtonBox(QDialogButtonBox::Ok | QDialogButtonBox::Cancel);
    buttons->button(QDialogButtonBox::Ok)->setText(tr("Register"));
    connect(buttons, &QDialogButtonBox::accepted, this, &RegisterDialog::submit);
    connect(buttons, &QDialogButtonBox::rejected, this, &QDialog::reject);

    auto *layout = new QVBoxLayout(this);
    layout->addLayout(form);
    layout->addWidget(m_status);
    layout->addWidget(buttons);

    setMinimumWidth(380);
}

QString RegisterDialog::username() const
{
    return m_username->text().trimmed();
}

void RegisterDialog::submit()
{
    const QString user = username();
    const QString pass = m_password->text();

    if (!AuthService::isValidUsername(user)) {
        m_status->setText(tr("Username must be 3-50 characters: letters, digits, _ . -"));
        return;
    }
    if (pass.size() < AuthService::kMinPasswordLength) {
        m_status->setText(tr("Password must have at least %1 characters.")
                              .arg(AuthService::kMinPasswordLength));
        return;
    }
    if (pass != m_confirm->text()) {
        m_status->setText(tr("Passwords do not match."));
        return;
    }

    QString err;
    switch (m_auth->registerUser(user, pass, m_fullName->text(), &err)) {
    case AuthService::RegisterResult::Ok:
        accept();
        break;
    case AuthService::RegisterResult::UsernameTaken:
        m_status->setText(tr("This username is already taken."));
        break;
    case AuthService::RegisterResult::InvalidInput:
        m_status->setText(tr("Invalid input."));
        break;
    case AuthService::RegisterResult::Error:
        m_status->setText(tr("Database error: %1").arg(err));
        break;
    }
}
