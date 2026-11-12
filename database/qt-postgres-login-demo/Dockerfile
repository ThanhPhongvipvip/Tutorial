# Build ứng dụng Qt trong container => máy người dùng KHÔNG cần cài Qt/CMake/trình biên dịch.

############################ Giai đoạn build ############################
FROM ubuntu:24.04 AS build
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential cmake ninja-build qt6-base-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY app/ .
RUN cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build \
    && strip build/qt_login_demo

############################ Giai đoạn chạy ############################
FROM ubuntu:24.04 AS runtime
ENV DEBIAN_FRONTEND=noninteractive
# libqt6sql6-psql: driver QPSQL; qt6-qpa-plugins: plugin nền tảng (xcb, offscreen).
RUN apt-get update && apt-get install -y --no-install-recommends \
        libqt6widgets6 libqt6sql6 libqt6sql6-psql qt6-qpa-plugins \
        libxcb-cursor0 libxkbcommon-x11-0 libxcb-icccm4 libxcb-image0 \
        libxcb-keysyms1 libxcb-render-util0 libxcb-shape0 libxcb-xinerama0 \
        libgl1 libegl1 fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /src/build/qt_login_demo /usr/local/bin/qt_login_demo

# Container chạy bằng uid của máy host (không phải root) nên HOME/XDG phải ghi được.
ENV HOME=/tmp \
    XDG_RUNTIME_DIR=/tmp/runtime \
    QT_X11_NO_MITSHM=1 \
    LIBGL_ALWAYS_SOFTWARE=1
RUN mkdir -p /tmp/runtime && chmod 700 /tmp/runtime

ENTRYPOINT ["qt_login_demo"]
