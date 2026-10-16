# Custom .iso (Sử dụng Cubic dựa trên file Hướng dẫn cài đặt môi trường)

## 0. Quy ước

| Tên | Giá trị |
|---|---|
| Thư mục project Cubic | `~/ubuntu-iso-build/cubic-project` (cố định trong `prepare-cubic-env-host.sh`) |
| custom-root | `~/ubuntu-iso-build/cubic-project/custom-root` |
| custom-live | `~/ubuntu-iso-build/cubic-project/custom-live` |
| Thư mục chứa các script | `~/Downloads` |
| Checker | `~/Downloads/check_env.sh`, được chép vào ISO thành `/usr/local/bin/check_env.sh` |

Mỗi bước đều ghi rõ nơi chạy:
- **[HOST]**: terminal Ubuntu bình thường trên máy build, chạy bằng user thường (dùng `sudo` khi cần).
- **[CUBIC]**: terminal chroot của Cubic (`root@cubic:~#`).

## 1. Quy trình

### 1.1. Các bước chi tiết

#### a) [HOST] Cài đặt Cubic
```bash
sudo apt-add-repository universe -y
sudo apt-add-repository ppa:cubic-wizard/release -y
sudo apt update
sudo apt install -y cubic
```

#### b) Các bước

- **[HOST]** Chuẩn bị script trong `~/Downloads`:
    - `prepare-cubic-env-host.sh`
    - `check_env.sh`: script prepare sẽ chép file này vào `custom-root/usr/local/bin/check_env.sh`.
    - `deploy-nvidia-firstboot-iso.sh`

- Khởi tạo dự án:
    - Mở Cubic qua terminal (`cubic`) hoặc menu ứng dụng.

    - Chọn thư mục làm việc (Working directory) **bắt buộc** là `~/ubuntu-iso-build/cubic-project`, vì `prepare-cubic-env-host.sh` dùng cố định đường dẫn này.

    - Chọn file ISO gốc: `ubuntu-24.04-desktop-amd64.iso`.

    - Nhấn Next để Cubic giải nén SquashFS và tự động mở ra một Terminal chroot với quyền `root@cubic:~#`. **Để nguyên cửa sổ Cubic này.**

- **[HOST]** Chạy script prepare (lấy Qt 6.7.2, Snap7, QWT từ máy hiện tại đưa vào custom-root, thêm nguồn ROS 2, chép checker và tạo `/root/install-dev-env.sh` để cài các gói còn lại trong Cubic):
```bash
cd ~/Downloads
chmod +x prepare-cubic-env-host.sh check_env.sh
sudo ./prepare-cubic-env-host.sh
```

- **[CUBIC]** Chuyển riêng nguồn ROS 2 sang HTTP. APT vẫn phải xác minh chữ ký GPG của repository; không tắt xác minh bảo mật hay dùng `trusted=yes`:

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

- **[CUBIC]** Kiểm tra lại ROS 2:

```bash
apt-cache policy ros-rolling-desktop
apt-cache policy ros-dev-tools
```

- **[CUBIC]** Cài những gói được kiểm tra trong `check_env.sh`, bao gồm build tools, Qt5/OpenGL, Git, SSH Server, Wireshark, FFmpeg, Terminal, ROS 2 Rolling,... Script này cũng tạo locale `en_US.UTF-8`, cấu hình `ldconfig` cho Snap7/QWT và dọn cache apt khi xong:
```bash
bash /root/install-dev-env.sh
```

- **[CUBIC]** Kiểm tra nhanh Qt, ROS 2, Snap7, QWT:
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

- **[CUBIC]** Thiết lập Locale mặc định (tạo locale trước, sau đó mới đặt mặc định):
```bash
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en

export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
unset LC_ALL

locale
```

- **[CUBIC]** Thêm autostart (Ví dụ Firefox)

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

- **[CUBIC]** Dọn dẹp (nếu đã chạy thêm `apt-get update`/cài gói sau `install-dev-env.sh`) và kiểm tra môi trường lần cuối:
```bash
apt-get clean
rm -rf /var/lib/apt/lists/*

bash /usr/local/bin/check_env.sh
```

- **[HOST]** Đồng bộ dpkg database từ custom-root sang custom-live:
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

> Nên chạy khối trên trong một shell con (`bash`) hoặc lưu thành file script, vì `set -e` và `exit` sẽ đóng terminal hiện tại khi gặp lỗi.

- **[HOST]** Thêm script và dịch vụ NVIDIA first-boot vào custom-root (mặc định script dùng đúng custom-root ở mục 0; chỉ cần truyền đường dẫn nếu project nằm chỗ khác):
```bash
cd ~/Downloads
chmod +x deploy-nvidia-firstboot-iso.sh
sudo ./deploy-nvidia-firstboot-iso.sh "$HOME/ubuntu-iso-build/cubic-project/custom-root"
```
Script sẽ thêm một dịch vụ systemd vào hệ thống Ubuntu bên trong ISO. Khi Ubuntu được cài lên máy đích và khởi động lần đầu, dịch vụ sẽ kiểm tra GPU NVIDIA, dùng `ubuntu-drivers install` để chọn driver phù hợp nếu phát hiện GPU, rồi ghi nhận kết quả để không chạy lại.

- **[HOST]** (Khuyến nghị) Điều chỉnh để Ubuntu khởi động nhanh hơn: dịch vụ mặc định chạy quá trình cài driver trực tiếp trong giai đoạn khởi động. Nếu Internet chậm, màn hình đăng nhập có thể xuất hiện muộn. Ghi đè unit để tác vụ cài driver chạy nền:

```bash
sudo tee "$HOME/ubuntu-iso-build/cubic-project/custom-root/etc/systemd/system/nvidia-firstboot.service" >/dev/null <<'EOF'
[Unit]
Description=Schedule NVIDIA first boot driver installation
ConditionKernelCommandLine=!boot=casper
ConditionPathExists=!/var/lib/nvidia-firstboot/done
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/bin/systemd-run --no-block --collect --unit=nvidia-firstboot-worker.service --property=Type=oneshot --property=Wants=network-online.target --property=After=network-online.target --property=TimeoutStartSec=45min /usr/local/sbin/nvidia-firstboot-install
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo chmod 0644 "$HOME/ubuntu-iso-build/cubic-project/custom-root/etc/systemd/system/nvidia-firstboot.service"
```

- **[CUBIC]** Chọn Next, sau đó chọn kernel, nén gzip rồi Generate.

#### c) Kiểm tra trên máy đích

Sau khi cài Ubuntu và khởi động lần đầu, kiểm tra log NVIDIA:
```bash
sudo cat /var/log/nvidia-firstboot.log
```

Kiểm tra kết quả:
```bash
sudo cat /var/lib/nvidia-firstboot/result
```

Nếu phát hiện NVIDIA và cài thành công:
```text
nvidia-driver-install-command-succeeded
```

Nếu không có GPU NVIDIA:
```text
no-nvidia
```

Sau khi cài xong driver NVIDIA, reboot rồi kiểm tra:
```bash
nvidia-smi
```

#### <span style="color:red">Note: (Nvidia chưa test)</span>
