#include "WelcomeWindow.h"

#include <QLabel>
#include <QLocale>
#include <QPushButton>
#include <QVBoxLayout>

WelcomeWindow::WelcomeWindow(const AuthService::User &user, QWidget *parent)
    : QWidget(parent)
{
    setWindowTitle(tr("Welcome"));

    const QString name = user.fullName.isEmpty() ? user.username : user.fullName;
    auto *hello = new QLabel(tr("<h2>Hello, %1!</h2>").arg(name.toHtmlEscaped()));
    hello->setAlignment(Qt::AlignCenter);

    const QString last = user.lastLogin.isNull()
        ? tr("This is your first login.")
        : tr("Last login: %1").arg(QLocale().toString(user.lastLogin.toLocalTime(),
                                                       QLocale::ShortFormat));
    auto *info = new QLabel(tr("You are signed in as <b>%1</b> (id %2).<br>%3")
                                .arg(user.username.toHtmlEscaped())
                                .arg(user.id)
                                .arg(last));
    info->setAlignment(Qt::AlignCenter);

    auto *logout = new QPushButton(tr("Log out"));
    connect(logout, &QPushButton::clicked, this, &WelcomeWindow::loggedOut);

    auto *layout = new QVBoxLayout(this);
    layout->setContentsMargins(32, 24, 32, 24);
    layout->addWidget(hello);
    layout->addWidget(info);
    layout->addSpacing(8);
    layout->addWidget(logout);

    setMinimumWidth(360);
}
