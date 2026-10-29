# Hướng dẫn tạo Custom Ubuntu ISO với Cubic

Tài liệu này hướng dẫn chi tiết cách tạo một file ISO Ubuntu tùy chỉnh có sẵn môi trường phát triển (Qt, ROS 2, Snap7, Qwt) và tự động cài đặt NVIDIA driver khi khởi động lần đầu trên máy đích.

## Yêu cầu ban đầu

- Máy host chạy Ubuntu (24.04 hoặc tương tự)
- File ISO Ubuntu gốc (ví dụ: `ubuntu-24.04-desktop-amd64.iso`)
- Đã cài đặt và cấu hình sẵn trên máy host:
  - Qt 6.x (thường ở `/opt/Qt/` hoặc `~/Qt/`)
  - Snap7 SDK
  - Qwt library
  - ROS 2 Rolling
- Kết nối internet để tải các gói

---

##  Bước 1: Cài đặt Cubic trên máy host

Cubic là công cụ tạo custom Ubuntu ISO với giao diện đồ họa.

```bash
sudo apt-add-repository universe -y
sudo apt-add-repository ppa:cubic-wizard/release -y
sudo apt update
sudo apt install -y cubic
```

**Giải thích:**
- `universe`: kho phần mềm cộng đồng của Ubuntu
- `ppa:cubic-wizard/release`: repository chính thức của Cubic
- `cubic`: công cụ tạo ISO tùy chỉnh

---

## Bước 2: Khai báo biến đường dẫn

Trong terminal, khai báo biến đường dẫn đến custom-root:

```bash
# Thay bằng đường dẫn đến custom root thực tế
ROOT="/custom-root"
```

**Lưu ý**: Đường dẫn này sẽ được sử dụng trong tất cả các bước sau. Có thể thêm vào `~/.bashrc` để không phải khai báo lại:

```bash
echo 'export ROOT="/custom-root"' >> ~/.bashrc
source ~/.bashrc
```

---

##  Bước 3: Tạo dự án Cubic

### 3.1. Mở Cubic

Chạy lệnh hoặc tìm trong menu ứng dụng:

```bash
cubic
```

### 3.2. Tạo project mới

1. **Chọn thư mục làm việc** (Working directory):  
   Ví dụ: `/home/user/ubuntu-iso-build`

2. **Chọn file ISO gốc**:  
   Ví dụ: `ubuntu-24.04-desktop-amd64.iso`

3. **Nhấn Next** để Cubic:
   - Giải nén ISO
   - Mount filesystem
   - Mở terminal chroot với quyền root (`root@cubic:~#`)

**Lưu ý:** Thư mục `custom-root` sẽ được tạo tự động trong thư mục làm việc. Đây là nơi chứa toàn bộ filesystem của ISO tùy chỉnh.

---

## Bước 4: Chạy script chuẩn bị trên máy host

**QUAN TRỌNG:** Chạy script này ở terminal của **máy host** (không phải trong Cubic terminal).

Script sẽ tự động:
- Phát hiện `custom-root` đang được Cubic sử dụng (hoặc dùng biến $ROOT)
- Sao chép Qt, Snap7, Qwt từ máy host vào custom-root
- Cấu hình ROS 2 repository
- Tạo script `install-dev-env.sh` bên trong custom-root

```bash
sudo -E bash prepare-host.sh "$ROOT"
```

**Giải thích:**
- `sudo -E`: Giữ biến môi trường $ROOT
- `"$ROOT"`: Truyền đường dẫn custom-root

**Kết quả:** Script sẽ hiển thị thông tin đã chuẩn bị (Qt version, Snap7, Qwt, ROS).

---

##  Bước 5: Cài đặt môi trường trong Cubic Terminal

Quay lại **Cubic Terminal** (terminal màu đen với dòng nhắc `root@cubic:~#`).

### 5.1. Sửa lỗi SSL với ROS 2 repository

**VẤN ĐỀ:** Cubic có thể gặp lỗi chứng chỉ SSL khi kết nối HTTPS đến ROS 2 repository:
```
Certificate verification failed: The certificate is NOT trusted
```

**GIẢI PHÁP:** Đổi từ HTTPS sang HTTP. Chạy lệnh sau **trong Cubic Terminal**:

```bash
# Đổi HTTPS sang HTTP cho ROS 2 repository
sed -i 's|https://packages.ros.org/ros2/ubuntu|http://packages.ros.org/ros2/ubuntu|g' \
    /etc/apt/sources.list.d/ros2.list

# Cập nhật lại
apt-get update
```

**Kiểm tra kết quả:**

```bash
apt-cache policy ros-rolling-desktop
apt-cache policy ros-dev-tools
```

Kết quả đúng sẽ hiển thị:
```
ros-rolling-desktop:
  Installed: (none)
  Candidate: 0.13.0-1noble.xxxxxxxx.xxxxxx
  Version table:
     0.13.0-1noble... 500
        500 http://packages.ros.org/ros2/ubuntu noble/main amd64 Packages
```

Nếu vẫn lỗi, kiểm tra kết nối internet trong Cubic hoặc thử repository mirror khác.

### 5.2. Cài đặt các gói và môi trường

**QUAN TRỌNG:** Chạy các lệnh sau **TRONG CUBIC TERMINAL** (root@cubic:~#)

```bash
# Chạy script cài đặt chính
bash /root/install-dev-env.sh
```

**Sau khi script chạy xong, KIỂM TRA VÀ SỬA LẠI các gói bị thiếu:**

```bash
# Đảm bảo các meta-packages được cài
apt-get install -y --no-install-recommends \
    build-essential \
    ubuntu-desktop-minimal

# Đảm bảo các gói thiết yếu được đánh dấu là manual (không bị auto-remove)
apt-mark manual \
    build-essential gcc g++ make cmake ninja-build \
    git openssh-server net-tools wireshark ffmpeg terminator fonts-roboto \
    libboost-dev \
    libglu1-mesa-dev freeglut3-dev mesa-common-dev libglfw3-dev \
    libgl1-mesa-dev libglew-dev libftgl-dev \
    libfontconfig1-dev libfreetype-dev \
    libx11-dev libx11-xcb-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev \
    libxcb1-dev libxcb-cursor-dev libxcb-glx0-dev libxcb-keysyms1-dev \
    libxcb-image0-dev libxcb-shm0-dev libxcb-icccm4-dev libxcb-sync-dev \
    libxcb-xfixes0-dev libxcb-shape0-dev libxcb-randr0-dev \
    libxcb-render-util0-dev libxcb-util-dev libxcb-xinerama0-dev \
    libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev \
    libxcb-cursor0 libglx-dev \
    zlib1g-dev graphviz doxygen gettext \
    qtscript5-dev libqt5svg5-dev qttools5-dev-tools qttools5-dev \
    libqt5opengl5-dev qtmultimedia5-dev libqt5multimedia5-plugins \
    libqt5serialport5 libqt5serialport5-dev \
    qtpositioning5-dev libgps-dev libqt5positioning5 libqt5positioning5-plugins \
    libclang-dev libgdal-dev libgoogle-glog-dev libglm-dev libcups2-dev \
    librtlsdr-dev libsoundtouch-dev libasound2-dev \
    ros-rolling-desktop ros-dev-tools python3-colcon-common-extensions

# Cập nhật lại ldconfig
ldconfig
```

**Giải thích:**
- `apt-mark manual` ngăn apt tự động xóa các gói này khi dọn dẹp
- Điều này đảm bảo tất cả gói dev được giữ lại trong ISO

**Quá trình cài đặt có thể mất 10-30 phút** tùy tốc độ internet.

### 5.3. Kiểm tra môi trường đã cài

```bash
bash /usr/local/bin/check_env.sh
```

Script này sẽ kiểm tra:
- ✔ Build tools
- ✔ Qt 6.x
- ✔ ROS 2 Rolling
- ✔ Snap7 và Qwt libraries
- ✔ Các công cụ khác

### 5.4. Kiểm tra thủ công (tuỳ chọn)

Nếu muốn kiểm tra từng thành phần:

```bash
# Kiểm tra Qt
qmake6 --version

# Kiểm tra ROS 2
source /opt/ros/rolling/setup.bash
ros2 --version
colcon version

# Kiểm tra thư viện
ldconfig -p | grep -E 'libsnap7|libqwt'
```

### 5.5. Dọn dẹp (QUAN TRỌNG)

**CHÚ Ý:** Chỉ dọn cache, KHÔNG XÓA /var/lib/apt/lists/* vì sẽ làm mất thông tin gói

```bash
# Chỉ xóa cache download
apt-get clean

# KHÔNG chạy lệnh này:
# rm -rf /var/lib/apt/lists/*  ← Lệnh này làm mất metadata gói!
```

**Giải thích:** 
- `/var/lib/apt/lists/*` chứa metadata của các gói đã cài
- Xóa nó sẽ khiến dpkg không biết gói nào đã cài, dẫn đến check_env.sh báo FAIL
- Chỉ nên xóa `/var/cache/apt/archives/*` (apt-get clean đã làm điều này)

### 5.6. Cấu hình Locale

```bash
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en
```

### 5.7. Disable Wayland (QUAN TRỌNG cho Qt)

**Wayland có thể gây vấn đề với ứng dụng Qt.** Disable Wayland để sử dụng X11:

```bash
# Tạo hoặc cập nhật cấu hình GDM3
if [ ! -f /etc/gdm3/custom.conf ]; then
    mkdir -p /etc/gdm3
    cat > /etc/gdm3/custom.conf <<'GDMCONF'
[daemon]
WaylandEnable=false

[security]

[xdmcp]

[chooser]

[debug]
GDMCONF
else
    # Thêm WaylandEnable=false vào section [daemon]
    if ! grep -q "^\[daemon\]" /etc/gdm3/custom.conf; then
        echo -e "\n[daemon]\nWaylandEnable=false" >> /etc/gdm3/custom.conf
    elif ! grep -q "^WaylandEnable=false" /etc/gdm3/custom.conf; then
        sed -i '/^\[daemon\]/a WaylandEnable=false' /etc/gdm3/custom.conf
    fi
fi

chmod 644 /etc/gdm3/custom.conf

echo "Wayland đã được disable. Hệ thống sẽ sử dụng X11."
```
---
## Bước 6: Cấu hình Wayland (QUAN TRỌNG)

**QUAN TRỌNG:** Chạy ở terminal **máy host**, không phải Cubic terminal.

Script này tạo dịch vụ systemd tự động phát hiện và cài đặt NVIDIA driver khi boot lần đầu trên máy đích.

```bash
sudo -E bash deploy-nvidia.sh "$ROOT"
```

**Dịch vụ sẽ:**
1. Chạy ở lần boot đầu tiên sau khi cài Ubuntu
2. Phát hiện GPU NVIDIA (nếu có)
3. Tự động chạy `ubuntu-drivers install`
4. Ghi log vào `/var/log/nvidia-firstboot.log`
5. Đánh dấu hoàn thành để không chạy lại

**Lưu ý:** Dịch vụ này đã được cấu hình chạy ở chế độ nền (background) để không làm chậm quá trình khởi động desktop.

---
## Bước 8: Tự đăng nhập

Cấu hình tự động đăng nhập và sudo không cần mật khẩu:

```bash 
sudo -E bash apply-c-passwordless-login.sh "$ROOT"
```
## Bước 9: Kiểm tra trong Cubic Terminal (tuỳ chọn)

Sau khi cài môi trường xong, có thể kiểm tra nhanh:

```bash
bash /usr/local/bin/check_env.sh
```

**Lưu ý:** Trong Cubic, nhiều package sẽ không hiển thị đầy đủ. Kiểm tra đầy đủ sau khi cài Ubuntu lên ổ cứng.

---
 
## Bước 10: Generate file ISO

1. Đóng Cubic Terminal

2. Trong cửa sổ Cubic, nhấn **Next**

3. Chọn cấu hình:
   - **Kernel:** Giữ mặc định (kernel mới nhất)
   - **Compression:** Chọn **gzip** (cân bằng tốc độ và kích thước)

4. Nhấn **Generate** để tạo ISO


File ISO sẽ được lưu trong thư mục project

## Bước 11: Kiểm tra ISO trên máy đích

### 9.1. Cài đặt Ubuntu từ ISO

- Ghi ISO ra USB hoặc chạy trên máy ảo
- Cài đặt Ubuntu bình thường
- Khởi động lại

### 9.2. Kiểm tra NVIDIA driver (nếu có GPU NVIDIA)

Sau khi boot lần đầu, kiểm tra log:

```bash
sudo cat /var/log/nvidia-firstboot.log
```

Kiểm tra kết quả:

```bash
sudo cat /var/lib/nvidia-firstboot/result
```

**Các kết quả có thể:**
- `nvidia-driver-install-command-succeeded` - Đã cài driver thành công
- `no-nvidia` - Không phát hiện GPU NVIDIA

**Nếu cài driver thành công, reboot rồi kiểm tra:**

```bash
nvidia-smi
```

### 9.3. Kiểm tra môi trường phát triển

**LƯU Ý:** Trong Live ISO, nhiều package sẽ không hiển thị trong dpkg nhưng vẫn hoạt động bình thường. Kiểm tra đầy đủ sau khi cài Ubuntu lên ổ cứng.

```bash
bash /usr/local/bin/check_env.sh
```

Hoặc kiểm tra từng thành phần:

```bash
# Qt
qmake6 --version

# ROS 2
source /opt/ros/rolling/setup.bash
ros2 --version

# Snap7 và Qwt
ldconfig -p | grep -E 'libsnap7|libqwt'
```

---

##  Ghi chú

- NVIDIA chưa được test đầy đủ - kiểm tra kỹ trên môi trường thực

---

## Tài liệu tham khảo

- [Cubic Documentation](https://github.com/PJ-Singh-001/Cubic)
