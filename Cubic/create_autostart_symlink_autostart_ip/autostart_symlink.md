# Hướng dẫn từng bước: đóng gói ASRRDD vào Ubuntu ISO bằng Cubic

## 1. Mục tiêu và phạm vi


```text
/home/<user>/
├── asrrdd/
│   ├── asrrdd
│   ├── run.sh
│   ├── .deployinfo
│   ├── lib/
│   ├── plugins/
│   ├── qml/
│   ├── ros/
│   ├── protocol/
│   └── settings/
│       └── appconfig.ini -> /home/<user>/Desktop/appconfig.ini
└── Desktop/
    └── appconfig.ini            
```

GNOME Autostart gọi launcher để mở `~/asrrdd/run.sh`. File cấu hình trong ứng dụng là symlink nên nội dung chỉnh sửa trên Desktop được ứng dụng sử dụng ngay.

**Phạm vi:** các bước dưới đây cấu hình autostart cho Ubuntu đã cài lên ổ cứng. Ubuntu Live là môi trường riêng; muốn tự chạy ứng dụng cả trong Live cần cấu hình và kiểm thử riêng cho tài khoản Live.

## 2. Khai báo biến đường dẫn

Thực hiện trên **máy Ubuntu nguồn**, bên ngoài terminal chroot của Cubic.

### Khai báo 2 biến trong terminal:

```bash
# Thay bằng đường dẫn đến custom root thực tế
ROOT="custom-root"

# Thư mục runtime ASRRDD đã build, không phải source code
APP_SRC="/asrrdd-2.1.0-20261021-e49338d9"
```

**Kiểm tra đường dẫn và những file bắt buộc:**

```bash
test -f "$ROOT/etc/os-release" || { echo "Sai ROOT: không phải custom-root"; exit 1; }
test -x "$APP_SRC/asrrdd" || { echo "Không tìm thấy executable asrrdd"; exit 1; }
test -x "$APP_SRC/run.sh" || { echo "Không tìm thấy run.sh"; exit 1; }
test -f "$APP_SRC/.deployinfo" || { echo "Không tìm thấy .deployinfo"; exit 1; }
test -f "$APP_SRC/settings/appconfig.ini" || { echo "Không tìm thấy settings/appconfig.ini"; exit 1; }
echo "Đường dẫn hợp lệ"
```

`run.sh` trong gói này nạp `.deployinfo` để thiết lập môi trường và kiểm tra thư viện; phải giữ file này cùng các thư mục runtime.

## 3. Sao chép runtime vào staging của ISO

Dùng `/etc/skel/asrrdd` làm staging trong filesystem Cubic. First-boot service sẽ đưa runtime vào home của user sau khi Ubuntu được cài đặt.

```bash
# Biến ROOT và APP_SRC đã khai báo ở bước 2

STAGE="$ROOT/etc/skel/asrrdd"
sudo mkdir -p "$STAGE"
sudo cp -a "$APP_SRC/." "$STAGE/"
```

Bảo đảm file cấu hình trong staging là file thật, không phải symlink trỏ về máy nguồn:

```bash
sudo rm -f "$STAGE/settings/appconfig.ini"
sudo cp -L "$APP_SRC/settings/appconfig.ini" "$STAGE/settings/appconfig.ini"
```

Cấp quyền thực thi và kiểm tra:

```bash
sudo chmod 755 "$STAGE/asrrdd" "$STAGE/run.sh"
sudo test -f "$STAGE/.deployinfo" && echo "OK: .deployinfo"
sudo test -f "$STAGE/settings/appconfig.ini" && echo "OK: appconfig.ini"
```

Chỉ sao chép runtime đã build, không cần đưa source code vào ISO.

## 4. Cài font Roboto Condensed

Nếu `run.sh` kiểm tra `/usr/share/fonts/RobotoCondensed-Regular.ttf`, phải đặt font ở chính đường dẫn đó trong filesystem đích. Không tạo symlink hệ thống về home của một người dùng cụ thể vì tài khoản chưa biết trước.

```bash
FONT_SRC="$APP_SRC/fonts/RobotoCondensed-Regular.ttf"
test -f "$FONT_SRC" || { echo "Không tìm thấy font: $FONT_SRC"; exit 1; }
sudo install -D -m 644 "$FONT_SRC" \
    "$ROOT/usr/share/fonts/RobotoCondensed-Regular.ttf"
```

Nếu `.deployinfo` chỉ định một `FONT_FILE` khác, hãy đặt font đúng vị trí mà ứng dụng thực sự yêu cầu.

## 5. Tạo first-boot script cho home và symlink

Tạo script trong hệ thống đích của Cubic:

```bash
sudo mkdir -p "$ROOT/usr/local/sbin"
sudo tee "$ROOT/usr/local/sbin/eldis-home-appconfig-link.sh" >/dev/null <<'FIRSTBOOT_SCRIPT'
#!/usr/bin/env bash
set -Eeuo pipefail
exec >>/var/log/eldis-home-appconfig-link.log 2>&1
echo "===== ASRRDD HOME SETUP: $(date) ====="

# Không thay đổi phiên Live; chỉ xử lý Ubuntu đã cài vào ổ đĩa.
if grep -qw 'boot=casper' /proc/cmdline || [[ -d /run/casper ]]; then
    echo "Live session detected; skip."
    exit 0
fi

if [[ -f /var/lib/eldis-home-appconfig-link.done ]]; then
    echo "Already configured; skip."
    systemctl disable eldis-home-appconfig-link.service >/dev/null 2>&1 || true
    exit 0
fi

STAGE="/etc/skel/asrrdd"
USER_LINE="$(awk -F: '$3 >= 1000 && $3 < 60000 && $6 ~ /^\/home\/[^/]+$/ && $7 !~ /(nologin|false)$/ {print; exit}' /etc/passwd)"
if [[ -z "$USER_LINE" ]]; then
    echo "ERROR: No normal desktop user with home under /home found."
    exit 1
fi

IFS=: read -r USERNAME _ USER_ID GROUP_ID _ HOME_DIR _ <<< "$USER_LINE"
APP_HOME="$HOME_DIR/asrrdd"

# Installer đôi khi đã chép /etc/skel vào home; nếu chưa thì chép tại đây.
if [[ ! -x "$APP_HOME/asrrdd" || ! -x "$APP_HOME/run.sh" ]]; then
    if [[ -x "$STAGE/asrrdd" && -x "$STAGE/run.sh" ]]; then
        if [[ -e "$APP_HOME" ]]; then
            echo "ERROR: $APP_HOME exists but is not a complete app; refusing to overwrite."
            exit 1
        fi
        cp -a "$STAGE" "$APP_HOME"
    else
        echo "ERROR: Runtime missing in both $APP_HOME and $STAGE."
        exit 1
    fi
fi

chown -R "$USER_ID:$GROUP_ID" "$APP_HOME"
chmod 755 "$APP_HOME/asrrdd" "$APP_HOME/run.sh"

# XDG Desktop path; fallback to ~/Desktop if xdg-user-dir is unavailable.
DESKTOP=""
if command -v xdg-user-dir >/dev/null 2>&1; then
    DESKTOP="$(runuser -u "$USERNAME" -- env HOME="$HOME_DIR" xdg-user-dir DESKTOP 2>/dev/null || true)"
fi
if [[ -z "$DESKTOP" || "$DESKTOP" != "$HOME_DIR"/* ]]; then
    DESKTOP="$HOME_DIR/Desktop"
fi
mkdir -p "$DESKTOP"
chown "$USER_ID:$GROUP_ID" "$DESKTOP"

CFG="$APP_HOME/settings/appconfig.ini"
DESKTOP_CFG="$DESKTOP/appconfig.ini"
STAGE_CFG="$STAGE/settings/appconfig.ini"

# Determine a valid source config, including recovery from a broken old symlink.
CFG_SOURCE=""
if [[ -L "$CFG" ]]; then
    CFG_SOURCE="$(readlink -e "$CFG" 2>/dev/null || true)"
    if [[ -z "$CFG_SOURCE" && -f "$STAGE_CFG" ]]; then
        CFG_SOURCE="$STAGE_CFG"
    fi
elif [[ -f "$CFG" ]]; then
    CFG_SOURCE="$CFG"
fi

# Create the real Desktop config only when the user does not already have one.
if [[ ! -e "$DESKTOP_CFG" && ! -L "$DESKTOP_CFG" ]]; then
    if [[ -z "$CFG_SOURCE" || ! -f "$CFG_SOURCE" ]]; then
        echo "ERROR: No valid appconfig.ini source."
        exit 1
    fi
    install -o "$USER_ID" -g "$GROUP_ID" -m 664 "$CFG_SOURCE" "$DESKTOP_CFG"
fi

if [[ -L "$DESKTOP_CFG" || ! -f "$DESKTOP_CFG" ]]; then
    echo "ERROR: Desktop appconfig.ini must be a regular file: $DESKTOP_CFG"
    exit 1
fi

# The Desktop file is the editable source of truth. Preserve the factory copy once.
if [[ -L "$CFG" ]]; then
    CURRENT_TARGET="$(readlink -f "$CFG" 2>/dev/null || true)"
    if [[ "$CURRENT_TARGET" != "$DESKTOP_CFG" ]]; then
        rm -f "$CFG"
    fi
elif [[ -f "$CFG" ]]; then
    BACKUP="$CFG.factory-original"
    if [[ ! -e "$BACKUP" ]]; then
        mv "$CFG" "$BACKUP"
    else
        rm -f "$CFG"
    fi
else
    echo "ERROR: $CFG is neither a regular file nor a symlink."
    exit 1
fi

ln -sfn "$DESKTOP_CFG" "$CFG"
chown -h "$USER_ID:$GROUP_ID" "$CFG"
chown "$USER_ID:$GROUP_ID" "$DESKTOP_CFG"
chmod u+rw "$DESKTOP_CFG"

# Update the known SMap path if that key exists.
if grep -qE '^[[:space:]]*DirDatabaseSMap=' "$DESKTOP_CFG"; then
    sed -i -E "s|^[[:space:]]*DirDatabaseSMap=.*|DirDatabaseSMap=\"$APP_HOME/smap\"|" "$DESKTOP_CFG"
    chown "$USER_ID:$GROUP_ID" "$DESKTOP_CFG"
fi

# One primary desktop user is assumed. Remove staging to avoid a second full copy.
rm -rf "$STAGE"
mkdir -p /var/lib
touch /var/lib/eldis-home-appconfig-link.done
systemctl disable eldis-home-appconfig-link.service >/dev/null 2>&1 || true

echo "SUCCESS: APP_HOME=$APP_HOME"
echo "SUCCESS: Desktop config=$DESKTOP_CFG"
echo "SUCCESS: symlink=$(readlink "$CFG")"
ls -l "$CFG"
FIRSTBOOT_SCRIPT

sudo chmod 755 "$ROOT/usr/local/sbin/eldis-home-appconfig-link.sh"
```

Script thực hiện các việc: tìm tài khoản thông thường; bảo đảm `~/asrrdd` tồn tại; tạo file thật `~/Desktop/appconfig.ini` nếu chưa có; giữ file Desktop hiện có; chuyển file cấu hình trong ứng dụng thành symlink; cập nhật `DirDatabaseSMap` nếu khóa đó có trong file; sau thành công thì vô hiệu hóa service.

**Giới hạn:** script xử lý tài khoản desktop thông thường đầu tiên trong `/etc/passwd`, phù hợp máy đích có một tài khoản chính. Nếu nhiều tài khoản đều cần ứng dụng riêng, cần sửa script để lặp qua từng người dùng.

## 6. Tạo service systemd

```bash
sudo tee "$ROOT/etc/systemd/system/eldis-home-appconfig-link.service" >/dev/null <<'UNIT'
[Unit]
Description=Provision ASRRDD in user home and link appconfig.ini to Desktop
After=local-fs.target
Before=display-manager.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/eldis-home-appconfig-link.sh

[Install]
WantedBy=multi-user.target
UNIT

sudo mkdir -p "$ROOT/etc/systemd/system/multi-user.target.wants"
sudo ln -sfn ../eldis-home-appconfig-link.service \
    "$ROOT/etc/systemd/system/multi-user.target.wants/eldis-home-appconfig-link.service"
```

Không chạy `systemctl enable` trên máy nguồn. Ta đang chuẩn bị filesystem của Cubic; symlink trong `multi-user.target.wants` đã bật unit trong hệ thống đích.

## 7. Tạo launcher Autostart

```bash
sudo mkdir -p "$ROOT/usr/local/bin"
sudo tee "$ROOT/usr/local/bin/asrrdd-autostart.sh" >/dev/null <<'ASRRDD_LAUNCHER'
#!/usr/bin/env bash
set -Eeuo pipefail

LOG="${XDG_CACHE_HOME:-$HOME/.cache}/asrrdd-autostart.log"
mkdir -p "$(dirname "$LOG")"
exec >>"$LOG" 2>&1

echo "===== ASRRDD AUTOSTART: $(date) ====="
echo "USER=$(id -un)"
echo "HOME=$HOME"
echo "DISPLAY=${DISPLAY:-}"
echo "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-}"

APP_HOME="$HOME/asrrdd"
if [[ ! -x "$APP_HOME/run.sh" ]]; then
    echo "ERROR: $APP_HOME/run.sh missing or not executable; first-boot may not have completed."
    exit 1
fi

cd "$APP_HOME"
exec "$APP_HOME/run.sh"
ASRRDD_LAUNCHER

sudo chmod 755 "$ROOT/usr/local/bin/asrrdd-autostart.sh"
```

Tạo mục autostart GNOME:

```bash
sudo mkdir -p "$ROOT/etc/xdg/autostart"
sudo tee "$ROOT/etc/xdg/autostart/asrrdd.desktop" >/dev/null <<'DESKTOP_ENTRY'
[Desktop Entry]
Version=1.0
Type=Application
Name=ASRRDD
Comment=Start ASRRDD after desktop login
Exec=/usr/local/bin/asrrdd-autostart.sh
Terminal=false
X-GNOME-Autostart-enabled=true
DESKTOP_ENTRY
```

Launcher gọi `$HOME/asrrdd/run.sh`. GNOME chạy nó sau khi người dùng đăng nhập desktop.

## 8. Kiểm tra trước khi tạo ISO

```bash
sudo bash -n "$ROOT/usr/local/sbin/eldis-home-appconfig-link.sh"
sudo bash -n "$ROOT/usr/local/bin/asrrdd-autostart.sh"

test -x "$ROOT/etc/skel/asrrdd/asrrdd" && echo "OK: staged executable"
test -x "$ROOT/etc/skel/asrrdd/run.sh" && echo "OK: run.sh"
test -f "$ROOT/etc/skel/asrrdd/.deployinfo" && echo "OK: .deployinfo"
test -f "$ROOT/etc/skel/asrrdd/settings/appconfig.ini" && echo "OK: appconfig.ini"
test -f "$ROOT/etc/systemd/system/eldis-home-appconfig-link.service" && echo "OK: service"
test -f "$ROOT/etc/xdg/autostart/asrrdd.desktop" && echo "OK: autostart"
```

## 10. Tạo ISO mới bằng Cubic

1. Giữ nguyên dự án Cubic đã chỉnh đúng `custom-root`.
2. Quay lại giao diện Cubic và nhấn `Next`.
3. Giữ/chọn kernel và mức nén phù hợp với dự án.
4. Nhấn `Generate` để tạo ISO mới.
5. Ghi lại đường dẫn ISO mới để không nhầm với ISO cũ.

ISO đã tạo trước đó không tự nhận các thay đổi mới trong `custom-root`.

## 11. Test sau khi cài Ubuntu lên ổ cứng

Dùng ISO mới cài Ubuntu lên ổ cứng ảo hoặc ổ cứng rời. Sau khi cài xong, khởi động từ ổ đĩa đã cài, rồi đăng nhập desktop.

Kiểm tra file, symlink và log:

```bash
ls -l "$HOME/asrrdd/run.sh"
ls -l "$HOME/asrrdd/settings/appconfig.ini"
readlink -e "$HOME/asrrdd/settings/appconfig.ini"
ls -l "$(xdg-user-dir DESKTOP)/appconfig.ini"
cat "$HOME/.cache/asrrdd-autostart.log"
sudo cat /var/log/eldis-home-appconfig-link.log
sudo journalctl -u eldis-home-appconfig-link.service -b --no-pager
```

`readlink -e` phải trả về file `appconfig.ini` trên Desktop. Thử chỉnh file Desktop rồi so sánh qua đường dẫn của ứng dụng:

```bash
nano "$(xdg-user-dir DESKTOP)/appconfig.ini"
cmp "$(xdg-user-dir DESKTOP)/appconfig.ini" "$HOME/asrrdd/settings/appconfig.ini"
```

Nếu `cmp` không in ra gì và exit code là 0, hai đường dẫn trỏ tới cùng nội dung. Nếu app không tự mở, đọc `~/.cache/asrrdd-autostart.log`; lỗi thiếu font, thư viện, ROS hoặc SMap phải được xử lý riêng.

## 12. Sơ đồ luồng cuối cùng

```text
Ubuntu đã cài khởi động
        |
        v
eldis-home-appconfig-link.service
  - tìm user
  - bảo đảm ~/asrrdd tồn tại
  - tạo ~/Desktop/appconfig.ini nếu chưa có
  - đổi settings/appconfig.ini thành symlink
  - cập nhật DirDatabaseSMap nếu có
  - tự disable sau khi thành công
        |
        v
GNOME đăng nhập desktop
        |
        v
/etc/xdg/autostart/asrrdd.desktop
        |
        v
/usr/local/bin/asrrdd-autostart.sh
        |
        v
~/asrrdd/run.sh
```
