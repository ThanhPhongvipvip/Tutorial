cmake_minimum_required(VERSION 3.16)
project(qt_login_demo VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Widgets Sql)

add_executable(qt_login_demo
    src/main.cpp
    src/AuthService.cpp
    src/AuthService.h
    src/LoginWindow.cpp
    src/LoginWindow.h
    src/RegisterDialog.cpp
    src/RegisterDialog.h
    src/WelcomeWindow.cpp
    src/WelcomeWindow.h
)

target_link_libraries(qt_login_demo PRIVATE Qt6::Widgets Qt6::Sql)
