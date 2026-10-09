# Custom .iso (Sử dụng Cubic)

## 1. Mục tiêu:

- Tạo ra một tệp Live ISO tùy biến hoàn chỉnh đóng gói toàn bộ công cụ phát triển, driver và thư viện chuyên dụng.

- Chỉ cần cắm USB vào bất kỳ máy tính nào, cắm nguồn là có thể:

    - Tự động boot vào thẳng màn hình Desktop không cần mật khẩu.

    - Mở trực tiếp terminal có sẵn ROS 2 Rolling, Gazebo Sim, RQt.

    - Biên dịch ngay lập tức các dự án C++/Qt dùng Snap7 và Qwt mà không cần cài thêm bất kỳ gói nào.

## 2. Quy trình

### 2.1. Quy trình chung

- Khảo sát & đóng gói offline repo (apt-repo.tar.gz): Trích xuất toàn bộ cấu hình APT, danh sách gói cài đặt (installed_packages.txt) và khóa GPG từ máy nguồn đang chạy ổn định.

- Chuẩn bị công cụ Cubic: Cài đặt Cubic trên máy Host, nạp ISO Ubuntu 24.04 Desktop chuẩn.

- Tái tạo cấu hình hệ thống, tạo user tự động đăng nhập, vá lỗi nhân/boot, cài đặt ROS 2 Rolling, biên dịch Qwt 6.3.0 và Snap7 từ nguồn.

- Tự động hóa kiểm tra (Precheck & Self-healing): Thiết lập script chẩn đoán tự động phân loại [PASS], [WARN], [FAIL] để rà soát 100% trước khi bấm Generate.

- Đóng gói và ghi USB: Chọn thuật toán nén tối ưu và xuất ISO hoàn chỉnh.

### 2.2. Các bước chi tiết

#### a) TRÍCH XUẤT CẤU HÌNH & TẠO apt-repos.tar.gz TỪ MÁY NGUỒN

- Sao lưu danh sách gói đã cài

```bash
# Xuất toàn bộ danh sách gói kèm kiến trúc và phiên bản
dpkg --get-selections > installed_packages.txt
dpkg-query -W -f='${binary:Package}\t${Version}\t${Status}\n' > bao_cao_da_cai.txt

```
- Đóng gói toàn bộ cấu hình khi phần mềm và khóa ký

```bash
# Gom nguồn APT, keyrings và trusted keys vào một file nén duy nhất
tar -czvf apt-repos.tar.gz \
    /etc/apt/sources.list \
    /etc/apt/sources.list.d/ \
    /etc/apt/trusted.gpg \
    /etc/apt/trusted.gpg.d/ \
    /usr/share/keyrings/
```

* Note:
- Tác dụng của file này: Đảm bảo khi vào môi trường chroot Cubic, nếu gặp lỗi không tìm thấy repo ROS 2 hoặc PPA bên thứ ba, bạn có thể bung file này ra để khôi phục cấu hình tương đương máy nguồn.

#### b) CÀI ĐẶT VÀ KHỞI TẠO CUBIC TRÊN MÁY HOST
```bash
sudo apt-add-repository universe -y
sudo apt-add-repository ppa:cubic-wizard/release -y
sudo apt update
sudo apt install -y cubic
```

- Khởi tạo dự án
    - Mở Cubic qua terminal (cubic) hoặc menu ứng dụng.

    - Chọn thư mục làm việc (Working directory, ví dụ: /home/user/cubic_workspace).

    - Chọn file ISO gốc: ubuntu-24.04-desktop-amd64.iso.

    - Nhấn Next để Cubic giải nén SquashFS và tự động mở ra một Terminal chroot với quyền root@cubic:~#.

#### c) THIẾT LẬP VÀ CÀI ĐẶT TRONG CHROOT CỦA CUBIC

- Tạo 1 script để cài đặt và thiết lập: 

```bash
cat << 'EOF' > /install_all.sh
#!/bin/bash
set -e

# 1. TẠO USER VÀ THIẾT LẬP AUTO-LOGIN
useradd -m -s /bin/bash testuser
echo "testuser:1" | chpasswd
echo "testuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/testuser
chmod 0440 /etc/sudoers.d/testuser

mkdir -p /etc/gdm3
cat << 'GDM' > /etc/gdm3/custom.conf
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=testuser
WaylandEnable=false
GDM

# 2. CẤU HÌNH LOCALE VÀ BIẾN MÔI TRƯỜNG HỆ THỐNG
locale-gen en_US.UTF-8
update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

cat << 'ENV' >> /etc/environment
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
QT_QPA_PLATFORM=xcb
LIBGL_ALWAYS_SOFTWARE=0
ENV

# 3. CÀI ĐẶT CÔNG CỤ BUILD, NỀN TẢNG QT VÀ THƯ VIỆN ĐỒ HỌA
apt-get update
apt-get install -y \
    build-essential cmake ninja-build git curl wget tar bzip2 p7zip-full \
    libxcb-xinerama0 libxcb-cursor0 libxcb-icccm4 libxcb-image0 \
    libxcb-keysyms1 libxcb-randr0 libxcb-render-util0 libxcb-shape0 \
    libxcb-sync1 libxcb-xfixes0 libxcb-xkb1 libxkbcommon-x11-0 \
    libgl1 libegl1 libglx-dev libgl1-mesa-dev \
    libqt5gui5 qt5-qpa-platform-plugin-xcb \
    qt6-base-dev qt6-base-dev-tools libqt6svg6-dev \
    python3-pip python3-colcon-common-extensions terminator

# 4. CÀI ĐẶT ROS 2 ROLLING & GAZEBO SIM
curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu noble main" > /etc/apt/sources.list.d/ros2.list

apt-get update
apt-get install -y \
    ros-rolling-desktop \
    ros-rolling-rqt \
    ros-rolling-rqt-common-plugins \
    ros-rolling-ros-gz \
    ros-rolling-ros-gz-bridge \
    ros-rolling-ros-gz-sim

echo 'source /opt/ros/rolling/setup.bash' >> /home/testuser/.bashrc
chown -R testuser:testuser /home/testuser

# 5. BIÊN DỊCH VÀ CÀI ĐẶT SNAP7
cd /tmp
curl -L "https://downloads.sourceforge.net/project/snap7/1.4.2/snap7-full-1.4.2.7z" -o snap7.7z
7z x -y snap7.7z > /dev/null
cd snap7-full-1.4.2/build/unix
make -f x86_64_linux.mk install
cp ../bin/x86_64-linux/libsnap7.so /usr/local/lib/libsnap7.so
cp ../bin/x86_64-linux/libsnap7.so /usr/lib/libsnap7.so
cp ../../release/Wrappers/c-cpp/snap7.h /usr/include/
chmod 755 /usr/local/lib/libsnap7.so
pip install --break-system-packages python-snap7 2>/dev/null || true
ldconfig
rm -rf /tmp/snap7*

# 6. BIÊN DỊCH VÀ CÀI ĐẶT QWT 6.3.0 CHO QT6
cd /tmp
wget -q -O qwt-6.3.0.tar.bz2 "https://sourceforge.net/projects/qwt/files/qwt/6.3.0/qwt-6.3.0.tar.bz2/download"
tar -xjf qwt-6.3.0.tar.bz2
cd qwt-6.3.0
sed -i '1s/^/QT += svg\n/' qwt.pro
sed -i 's/^QWT_CONFIG.*+=.*QwtSvg/# &/' qwtconfig.pri
qmake6
make -j$(nproc)
make install
echo "/usr/local/qwt-6.3.0/lib" > /etc/ld.so.conf.d/qwt.conf
ldconfig
rm -rf /tmp/qwt*

# 7. TẠO LAUNCHER VÀ CẤU HÌNH PATH
cat << 'LAUNCHER' > /usr/share/applications/qtcreator.desktop
[Desktop Entry]
Type=Application
Exec=bash -i -c "source /opt/ros/rolling/setup.bash && qtcreator" %F
Name=Qt Creator
GenericName=C++/Qt IDE for ROS 2
Icon=QtProject-qtcreator
StartupWMClass=qtcreator
Terminal=false
Categories=Development;IDE;Qt;
LAUNCHER
chmod +x /usr/share/applications/qtcreator.desktop
update-desktop-database /usr/share/applications 2>/dev/null || true

echo 'export PATH=$PATH:/usr/lib/qt6/bin' > /etc/profile.d/qt_path.sh
chmod +x /etc/profile.d/qt_path.sh

echo "=== QUÁ TRÌNH CÀI ĐẶT ĐÃ HOÀN TẤT THÀNH CÔNG ==="
EOF
```

- Cấp quyền để toàn bộ hệ thống tự động hoàn tất
```bash
chmod +x /install_all.sh
/install_all.sh
```

- Xóa script để không lưu lại file tạm thời trong bản ISO
```bash
rm -f /install_all.sh
```

- Kiểm tra Snap7, Qwt 6.3.0, ROS 2 Rolling trong cache Idconfig cũng như hệ thống tệp:

```bash
cat << 'EOF' > /quick_ldconfig_check.sh
#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

pass() { echo -e "  [${GREEN}PASS${NC}] $1"; }
fail() { echo -e "  [${RED}FAIL${NC}] $1"; }

echo "=========================================================="
echo "       KIỂM TRA LIÊN KẾT ĐỘNG (LDCONFIG & LIBS)           "
echo "=========================================================="

# 1. KIỂM TRA SNAP7
echo -e "\n▶ 1. Kiểm tra Snap7:"
SNAP7_CACHE=$(ldconfig -p | grep "libsnap7.so")
if [ -n "$SNAP7_CACHE" ]; then
    pass "Snap7 có trong ldconfig: $SNAP7_CACHE"
else
    fail "Snap7 KHÔNG có trong ldconfig cache!"
fi

if [ -f "/usr/local/lib/libsnap7.so" ]; then
    pass "File tồn tại tại chuẩn FHS: /usr/local/lib/libsnap7.so"
else
    fail "Thiếu file /usr/local/lib/libsnap7.so"
fi

# 2. KIỂM TRA QWT 6.3.0
echo -e "\n▶ 2. Kiểm tra Qwt 6.3.0 (Qt6):"
QWT_CACHE=$(ldconfig -p | grep "libqwt.so")
if [ -n "$QWT_CACHE" ]; then
    pass "Qwt có trong ldconfig: $QWT_CACHE"
else
    fail "Qwt KHÔNG có trong ldconfig cache!"
fi

if [ -f "/etc/ld.so.conf.d/qwt.conf" ]; then
    pass "Cấu hình linker tồn tại: /etc/ld.so.conf.d/qwt.conf ($(cat /etc/ld.so.conf.d/qwt.conf))"
else
    fail "Thiếu file /etc/ld.so.conf.d/qwt.conf"
fi

if [ -f "/usr/local/qwt-6.3.0/lib/libqwt.so" ]; then
    pass "File thư viện tồn tại: /usr/local/qwt-6.3.0/lib/libqwt.so"
else
    fail "Thiếu thư viện /usr/local/qwt-6.3.0/lib/libqwt.so"
fi

# 3. KIỂM TRA ROS 2 ROLLING
echo -e "\n▶ 3. Kiểm tra ROS 2 Rolling:"
ROS_CACHE=$(ldconfig -p | grep "rclcpp")
if [ -n "$ROS_CACHE" ]; then
    pass "Thư viện cốt lõi ROS 2 (librclcpp.so) đã nhận diện trong ldconfig"
else
    fail "ROS 2 chưa được nạp vào ldconfig cache (Cần source môi trường hoặc kiểm tra /opt/ros/rolling/lib)"
fi

if [ -f "/opt/ros/rolling/setup.bash" ]; then
    pass "Tệp môi trường tồn tại: /opt/ros/rolling/setup.bash"
else
    fail "Không tìm thấy thư mục cài đặt /opt/ros/rolling"
fi

echo -e "\n=========================================================="
EOF

chmod +x /quick_ldconfig_check.sh
/quick_ldconfig_check.sh
```

- Xóa Script kiểm tra tạm:
```bash
rm -f /quick_ldconfig_check.sh
```

- Dọn dẹp & Đóng gói ISO

    - Dọn dẹp cache và cập nhật initramfs trong chroot
```bash
# 1. Dừng các tiến trình ngầm còn chạy
killall -9 gz gz-sim ruby parameter_bridge 2>/dev/null || true

# 2. Xóa các file tạm thời
rm -rf /tmp/* /tmp/.* /var/tmp/* /var/tmp/.* 2>/dev/null || true
rm -rf ~/.gz ~/.ignition /root/.gz /root/.ignition /home/testuser/.gz /home/testuser/.ignition
rm -rf ~/.ros/log /root/.ros/log /home/testuser/.ros/log
apt-get clean
rm -rf /var/lib/apt/lists/*

# 3. Cập nhật lại initramfs lần cuối
update-initramfs -u
```
- Đóng gói ISO
    - Nhấn nút Next ở góc trên bên phải để đóng terminal chroot.

    - Trang Packages: Giữ nguyên mặc định, bấm Next.

    - Trang Kernels: Chọn nhân phiên bản generic mới nhất (ví dụ: vmlinuz-6.8.0-*-generic), bấm Next.

    - Trang Generate:

        - Volume ID: Đặt tên nhận diện ISO (ví dụ: UBUNTU_ROS2_ROLLING).

        - Compression: Chọn thuật toán gzip (cân bằng tốt giữa tốc độ nén và dung lượng) hoặc zstd (tốc độ giải nén siêu tốc khi boot). Tránh dùng xz để không làm chậm máy build.

        - Nhấn nút Generate ở góc trên cùng bên phải.

## 4. Nguyên nhân lỗi & Giải pháp

| Hiện tượng lỗi                                       | Nguyên nhân kỹ thuật                                                                           | Giải pháp                                                                                                 |
|------------------------------------------------------|------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| Boot USB bị dừng 5-15p                               | Dịch vụ casper-md5check.service mặc định quét toàn bộ block USB để kiểm tra MD5                | Khóa dịch vụ: systemctl mask casper-md5check.service                                                      |
| VS Code / Chromium văng ngay lập tức (Crash SIGTRAP) | Ubuntu 24.04 kích hoạt cấm unprivileged user namespaces qua AppArmor đối với các app Electron. | Khai báo: echo "kernel.apparmor_restrict_unprivileged_userns = 0" > /etc/sysctl.d/20-apparmor-userns.conf |
|Ứng dụng Qt (rqt, RViz2) báo thiếu xcb plugin|Thiếu gói kết nối libqxcb.so hoặc thư viện phụ thuộc của X11/XCB.|Cài đặt qt5-qpa-platform-plugin-xcb, các gói libxcb-* và thêm QT_QPA_PLATFORM=xcb vào /etc/environment.|
|Gặp lỗi GPG error khi chạy apt update|Các kho thứ 3 (Cloudflare, VS Code, Zerotier) thiếu public key trong keyring chroot.|Bung file sao lưu apt-repos.tar.gz hoặc cài lại khóa GPG tương ứng vào /usr/share/keyrings/.|
|Node ROS 2 crash chuỗi UTF-8 khi chạy|Môi trường chroot thiếu mã locale mặc định en_US.UTF-8.|Chạy locale-gen en_US.UTF-8 và xuất biến môi trường LANG / LC_ALL vào /etc/environment.|
