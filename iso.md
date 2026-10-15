# Custom .iso (Sử dụng Cubic dựa trên file Hướng dẫn cài đặt môi trường)

## 1. Quy trình

### 1.1. Các bước chi tiết

#### a) CÀI ĐẶT VÀ KHỞI TẠO CUBIC TRÊN MÁY HOST
```bash
sudo apt-add-repository universe -y
sudo apt-add-repository ppa:cubic-wizard/release -y
sudo apt update
sudo apt install -y cubic
```

#### b) Các bước: 

- Chuẩn bị file script để kiểm tra môi trường

- Khởi tạo dự án
    - Mở Cubic qua terminal (cubic) hoặc menu ứng dụng.

    - Chọn thư mục làm việc (Working directory, ví dụ: /home/user/cubic_workspace).

    - Chọn file ISO gốc: ubuntu-24.04-desktop-amd64.iso.

    - Nhấn Next để Cubic giải nén SquashFS và tự động mở ra một Terminal chroot với quyền root@cubic:~#.

- Tại Terminal (Script lấy QT, Snap 7, QWT từ máy hiện tại để đưa vào custome-root, đồng thời chuẩn bị script cài các gói còn lại trong cubic):
```bash 
cd ~/Downloads
chmod +x prepare-cubic-env-host.sh check_env_iso.sh
sudo ./prepare-cubic-env-host.sh
```

- Chuyển riêng nguồn ROS 2 sang HTTP. APT vẫn phải xác minh chữ ký GPG của repository; không tắt xác minh bảo mật hay dùng trusted=yes:

```bash
grep -Rns 'packages.ros.org/ros2/ubuntu' \
    /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null

grep -rl 'https://packages.ros.org/ros2/ubuntu' \
    /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null |
while IFS= read -r file; do
    sed -i \
        's#https://packages.ros.org/ros2/ubuntu#http://packages.ros.org/ros2/ubuntu#g' \
        "$file"
done

apt-get update
```
- Kiểm tra lại ROS 2

```bash 
apt-cache policy ros-rolling-desktop

apt-cache policy ros-dev-tools
```

- Cài những gói được liệt kê trong check_env.sh, bao gồm build tools, QT5/OpenGL, Git, SSH Server, Wireshark, FFmpeg, Terminal, Ros 2 Rolling,.....
```bash 
bash /root/install-dev-env.sh
```
- Kiểm tra: 
```bash
bash /usr/local/bin/check_env.sh
```

- Tại terminal cubic:
```bash 
echo "===== QT 6.7.2 ====="
/opt/Qt/6.7.2/gcc_64/bin/qmake -query QT_VERSION

echo
echo "===== ROS 2 ROLLING ====="
bash --noprofile --norc -c '
source /opt/ros/rolling/setup.bash
echo "ros2: $(command -v ros2)"
ros2 --help >/dev/null && echo "ROS 2 CLI hoạt động bình thường"
echo "colcon: $(command -v colcon)"
'

echo
echo "===== SNAP7 VÀ QWT ====="
ldconfig -p | grep -E 'libsnap7|libqwt' || true
```

- Dọn dẹp lại:
```bash
apt-get clean
rm -rf /var/lib/apt/lists/*
```

- Kiểm tra môi trường:
```bash
bash /usr/local/bin/check_env.sh
```

- Thiết lập Locale mặc định:
```bash
update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en

export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
unset LC_ALL

locale
```
```bash 
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en
```
- Thêm autostart (Ví dụ Firefox)

Script auto start Firefox:
```bash 
install -d -m 755 /usr/local/bin /etc/xdg/autostart

cat > /usr/local/bin/firefox-autostart.sh <<'SCRIPT'
#!/bin/sh

# Chờ desktop và dịch vụ Snap khởi tạo
sleep 10

# Ưu tiên lệnh firefox trong PATH
if command -v firefox >/dev/null 2>&1; then
    exec firefox --new-window about:blank
elif [ -x /snap/bin/firefox ]; then
    exec /snap/bin/firefox --new-window about:blank
else
    logger -t firefox-autostart "Không tìm thấy Firefox"
    exit 1
fi
SCRIPT

chmod 755 /usr/local/bin/firefox-autostart.sh
```

Thiết lập tự khởi động:

```bash 
cat > /etc/xdg/autostart/firefox-autostart.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Firefox
Comment=Automatically launch Firefox at desktop login
Exec=/usr/local/bin/firefox-autostart.sh
Terminal=false
X-GNOME-Autostart-enabled=true
DESKTOP

chmod 644 /etc/xdg/autostart/firefox-autostart.desktop
```
- Đồng bộ Database trong Project Cubic ( Run trong terminal ubuntu)
```bash
set -Eeuo pipefail

PROJECT="$HOME/ubuntu-iso-build/cubic-project"
BASE_STATUS="$PROJECT/custom-root/var/lib/dpkg/status"
LIVE_STATUS="$PROJECT/custom-live/var/lib/dpkg/status"


if [[ ! -f "$BASE_STATUS" ]]; then
    echo "LỖI: Không tìm thấy $BASE_STATUS"
    exit 1
fi

if [[ ! -f "$LIVE_STATUS" ]]; then
    echo "LỖI: Không tìm thấy $LIVE_STATUS"
    echo "Chưa sửa gì. Cần xác định lại thư mục nguồn lớp Live."
    exit 1
fi

BASE_COUNT=$(sudo grep -c '^Package:' "$BASE_STATUS" || true)
LIVE_COUNT=$(sudo grep -c '^Package:' "$LIVE_STATUS" || true)

printf 'custom-root: %s package records\n' "$BASE_COUNT"
printf 'custom-live: %s package records\n' "$LIVE_COUNT"

if (( BASE_COUNT <= LIVE_COUNT )); then
    echo "LỖI: Database không khớp với tình trạng dự kiến; dừng để tránh sửa nhầm."
    exit 1
fi

BACKUP="$HOME/cubic-live-dpkg-status-$(date +%Y%m%d-%H%M%S).bak"
sudo cp -a "$LIVE_STATUS" "$BACKUP"
echo "Đã sao lưu: $BACKUP"

sudo install -o root -g root -m 0644 "$BASE_STATUS" "$LIVE_STATUS"

sudo grep -c '^Package:' "$LIVE_STATUS"
sudo grep -A2 -B1 '^Package: ros-rolling-desktop$' "$LIVE_STATUS" || true
sudo grep -A2 -B1 '^Package: build-essential$' "$LIVE_STATUS" || true
```

- Chọn Next trong Cubic, sau đó chọn kernal, gzip rồi Generate