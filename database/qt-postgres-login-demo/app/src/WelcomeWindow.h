#pragma once

#include "AuthService.h"

#include <QWidget>

class WelcomeWindow : public QWidget
{
    Q_OBJECT
public:
    explicit WelcomeWindow(const AuthService::User &user, QWidget *parent = nullptr);

signals:
    void loggedOut();
};
