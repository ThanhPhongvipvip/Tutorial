# Custom Ubuntu ISO - Live Selector + Subiquity Autoinstall

**Mục tiêu:** Chọn app trong Live Ubuntu 24.04. Khi cài Ubuntu (Automated installation), chỉ apps được chọn vào ổ cứng và tự khởi động.

**Phương pháp:** Live Zenity Selector + Subiquity Late Commands + Local HTTP Server

---

## Kiến trúc

```
Boot ISO → Try Ubuntu → Menu chọn app → Lưu selection
  → HTTP server khởi động (127.0.0.1:8765) serve autoinstall.yaml
  → Install Ubuntu → Automated installation
  → User nhập URL + tạo account
  → Subiquity chạy Late Commands
  → Deploy apps + dependencies
  → Reboot → Apps tự chạy
```

---

## 1. Cài đặt công cụ

```bash
sudo apt-get update
sudo apt-get install -y cubic jq file apt-rdepends dpkg-dev
```

| Công cụ | Chức năng |
|:---|:---|
| cubic | Mở/edit custom-root Cubic, cài packages, config OS, generate ISO |
| jq | Parse + tạo metadata.json, lấy app info (name, executable, requires) |
| file| Xác định file là ELF executable trong build folder |
| apt-rdepends | Tìm dependency tree (includes gián tiếp) của packages |
| dpkg-dev | Cung cấp `dpkg-scanpackages` tạo Packages.gz cho kho .deb offline |

---

## 2. Cấu hình: `~/app-iso.conf`

**Mục đích:** Định nghĩa biến môi trường dùng chung cho tất cả scripts.

**Ý nghĩa:**
- `ROOT` = Path custom-root Cubic (nơi cài tools, scripts, apps vào ISO)
- `STAGING` = Folder tạm để staging apps + .deb trước copy vào ISO
- `APP_BUILD_DIRS` = Danh sách thư mục build của apps
- `EXTRA_APT_PACKAGES` = Packages bổ sung (nếu cần)

```bash
ROOT="/home/phongvt/test/cub/custom-root"
STAGING="$HOME/iso-apps-staging"

APP_BUILD_DIRS=(
    "/home/phongvt/god/build"
    "/home/phongvt/cat/build"
)

EXTRA_APT_PACKAGES=()
```

---

## 3. Script chuẩn bị: `prepare-all-apps.sh`

**Mục đích:** Duyệt từng app, scan dependencies, tải .deb về local, chuẩn bị cấu trúc staging.

Tác dụng chi tiết:
1. Kiểm tra từng folder trong `APP_BUILD_DIRS` có đúng 1 ELF executable
2. Copy vào staging: `$STAGING/apps/$id/` 
3. Scan dependencies:
   - `ldd` → system libraries cần
   - `dpkg-query` → package cung cấp library
   - `apt-rdepends` → dependency gián tiếp (chain)
4. Tải .deb offline: `$STAGING/deb-cache/*.deb`
5. Tạo metadata: File json chứa app info (id, name, requires)
6. Tạo run.sh wrapper: Script chạy app + set LD_LIBRARY_PATH

Output:
- `$STAGING/apps/god/` (app + lib nếu bundle Qt, etc)
- `$STAGING/apps/cat/` (app)
- `$STAGING/deb-cache/*.deb` (tất cả dependencies)
- `$STAGING/deb-cache/Packages.gz` (index kho offline)

**Chạy:**
```bash
chmod +x ~/prepare-all-apps.sh
source ~/app-iso.conf
sudo apt-get update
~/prepare-all-apps.sh
```

---

## 4. Copy vào Cubic

```bash
source ~/app-iso.conf

sudo mkdir -p "$ROOT/opt/iso-apps"
sudo cp -a "$STAGING/apps" "$ROOT/opt/iso-apps/"
sudo cp -a "$STAGING/deb-cache" "$ROOT/opt/iso-apps/"
sudo chown -R root:root "$ROOT/opt/iso-apps"
```

---

## 5. Live Selector Script + HTTP Server

File: `$ROOT/usr/local/bin/live-app-selector.sh`

Mục đích: Chạy trong Live session, hiện Zenity menu chọn apps, lưu selection, khởi động HTTP server.

Tác dụng chi tiết:
1. Build checklist: Đọc `metadata.json` từng app → Zenity list (id, name, description)
2. User chọn apps: Lưu IDs vào `/var/tmp/app-selection.conf`
3. Tạo autoinstall.yaml:
4. Start HTTP server: Python3 serve `/var/tmp/autoinstall/` port 8765
5. Test server: Kiểm tra kết nối trước khi thông báo user

Output:
- `/var/tmp/app-selection.conf` = Danh sách apps chọn (1 ID mỗi dòng)
- `/var/tmp/autoinstall/autoinstall.yaml` = YAML config
- HTTP server port 8765 

```bash
sudo nano "$ROOT/usr/local/bin/live-app-selector.sh"
```

```bash
#!/usr/bin/env bash
set -e

SELECTION_FILE="/var/tmp/app-selection.conf"
APPS_DIR="/opt/iso-apps/apps"

[[ -f "$SELECTION_FILE" ]] && exit 0
[[ -d "$APPS_DIR" ]] || { zenity --error --text="Apps not found: $APPS_DIR" 2>/dev/null; exit 1; }

rows=()
while IFS= read -r -d '' meta; do
    id="$(basename "$(dirname "$meta")")"
    jq -e ".id==\"$id\"" "$meta" &>/dev/null || continue
    name="$(jq -r .name "$meta")"
    desc="$(jq -r '.description//""' "$meta")"
    rows+=(FALSE "$id" "$name" "$desc")
done < <(find "$APPS_DIR" -name metadata.json -print0 | sort -z)

[[ ${#rows[@]} -eq 0 ]] && { zenity --error --text="No apps found" 2>/dev/null; exit 1; }

selection="$(zenity --list --checklist \
    --title="Select Applications" \
    --text="Choose applications to install.\nOnly selected apps will be on your disk." \
    --column="" --column="ID" --column="Name" --column="Description" \
    --print-column=2 --hide-column=2 --separator=$'\n' \
    --width=800 --height=500 \
    "${rows[@]}" 2>/dev/null)" || exit 0

echo "$selection" > "$SELECTION_FILE"
chmod 644 "$SELECTION_FILE"

mkdir -p /var/tmp/autoinstall
cat > /var/tmp/autoinstall/autoinstall.yaml <<'YAML'
#cloud-config
autoinstall:
  version: 1
  interactive-sections:
    - identity
  apt:
    disable_components: []
    geoip: false
    preserve_sources_list: false
  packages: []
  refresh-installer:
    update: no
  late-commands:
    - /bin/bash /opt/iso-apps/deploy-selected-apps.sh
    - curtin in-target -- rm -f /etc/xdg/autostart/live-app-selector.desktop
  error-commands:
    - cp -a /var/log/installer /target/var/log/installer-failure/ 2>/dev/null || true
YAML

python3 -m http.server 8765 \
    --bind 127.0.0.1 \
    --directory /var/tmp/autoinstall \
    > /var/tmp/autoinstall/http.log 2>&1 &
echo $! > /var/tmp/autoinstall/http.pid

for i in {1..20}; do
    python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8765/autoinstall.yaml',timeout=1)" 2>/dev/null && break
    sleep 0.5
done

zenity --info --width=600 --title="Selection Saved" \
    --text="Selection saved.\n\nTo install Ubuntu:\n1. Open 'Install Ubuntu'\n2. Choose 'Automated Installation'\n3. Enter URL: http://127.0.0.1:8765/autoinstall.yaml\n\nYou will be asked to create your username and password during installation." \
    2>/dev/null || true
```

Cấp quyền:
```bash
sudo chmod 755 "$ROOT/usr/local/bin/live-app-selector.sh"
```

---

## 6. Live Autostart

**File:** `$ROOT/etc/xdg/autostart/live-app-selector.desktop`

**Mục đích:** Trigger `live-app-selector.sh` tự độngsau khi GNOME Desktop boot trong Live.

**Options:**
- `X-GNOME-Autostart-Delay=8` = Chờ 8s (để desktop UI stabil)
- `NoDisplay=true` = Ẩn khỏi Applications menu
- `OnlyShowIn=GNOME;Unity;` = Chỉ trigger trong GNOME/Unity

```bash
sudo tee "$ROOT/etc/xdg/autostart/live-app-selector.desktop" >/dev/null <<'EOF'
[Desktop Entry]
Type=Application
Name=Live App Selector
Exec=/usr/local/bin/live-app-selector.sh
Terminal=false
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=8
NoDisplay=true
OnlyShowIn=GNOME;Unity;
EOF
```

---

## 7. Deploy Script

File: `$ROOT/opt/iso-apps/deploy-selected-apps.sh`

Mục đích: Chạy tự động trong Late Commands (sau Subiquity cài base system). Cài dependencies, copy apps, tạo launchers + autostart.

Tác dụng chi tiết:
1. Lấy danh sách apps từ `/var/tmp/app-selection.conf`
2. Dùng `/etc/passwd` để tìm user được tạo 
3. Thu thập dependencies: Đọc metadata.json → lấy `.requires[]` packages
4. Cài offline: Mount deb-cache → `dpkg -i` từng package (NO network)
5. Deploy apps: Copy từ Live → `/target/opt/app-id/`
6. Tạo launchers: 
   - `/usr/share/applications/$app.desktop` (system-wide)
   - `~/.config/autostart/$app.desktop` (user autostart)

Input:
- `/var/tmp/app-selection.conf` = Apps chọn
- `/opt/iso-apps/apps/` = Source apps (readonly)
- `/opt/iso-apps/deb-cache/` = .deb files

**Output:**
- `/target/opt/god/`, `/target/opt/cat/` = Apps deployed
- Desktop entries, autostart entries
- `/target/var/log/app-deploy.log` = Chi tiết log

```bash
sudo nano "$ROOT/opt/iso-apps/deploy-selected-apps.sh"
```

```bash
#!/usr/bin/env bash
set -e

SELECTION_FILE="/var/tmp/app-selection.conf"
TARGET="/target"
APPS_SOURCE="/opt/iso-apps/apps"
DEB_SOURCE="/opt/iso-apps/deb-cache"
LOG="$TARGET/var/log/app-deploy.log"

mkdir -p "$TARGET/var/log"
exec > >(tee -a "$LOG") 2>&1

echo "=== $(date) ==="
echo "Deploy started"

[[ -f "$SELECTION_FILE" ]] || { echo "ERROR: No selection file"; exit 1; }
[[ -d "$TARGET/etc" ]] || { echo "ERROR: Target not mounted"; exit 1; }

mapfile -t apps < "$SELECTION_FILE"
[[ ${#apps[@]} -eq 0 ]] && { echo "No apps selected"; exit 0; }

echo "Selected apps: ${apps[*]}"

user_line="$(awk -F: '$3>=1000 && $3<60000 && $6~/^\/home\//{print;exit}' "$TARGET/etc/passwd")"
[[ -z "$user_line" ]] && { echo "ERROR: No user found"; exit 1; }

IFS=: read -r uname _ uid gid _ uhome _ <<< "$user_line"
echo "Target user: $uname ($uid:$gid) home=$uhome"

declare -A all_pkgs=()
for app in "${apps[@]}"; do
    [[ -z "$app" ]] && continue
    meta="$APPS_SOURCE/$app/metadata.json"
    [[ -f "$meta" ]] || { echo "WARNING: $app metadata not found"; continue; }
    
    while IFS= read -r pkg; do
        [[ -n "$pkg" ]] && all_pkgs["$pkg"]=1
    done < <(jq -r '.requires[]?' "$meta")
done

if [[ ${#all_pkgs[@]} -gt 0 ]]; then
    echo "Installing ${#all_pkgs[@]} packages..."
    
    mkdir -p "$TARGET/mnt/debs"
    mount --bind "$DEB_SOURCE" "$TARGET/mnt/debs" || { echo "ERROR: Cannot mount"; exit 1; }
    
    mapfile -t debs < <(find "$TARGET/mnt/debs" -name '*.deb' 2>/dev/null)
    
    if [[ ${#debs[@]} -gt 0 ]]; then
        echo "Found ${#debs[@]} .deb files"
        for deb in "${debs[@]}"; do
            deb_in_target="${deb#$TARGET}"
            chroot "$TARGET" dpkg -i "$deb_in_target" 2>/dev/null || true
        done
        chroot "$TARGET" apt-get install -f -y 2>/dev/null || true
        echo "Packages installed"
    fi
    
    umount "$TARGET/mnt/debs"
fi

for app in "${apps[@]}"; do
    [[ -z "$app" ]] && continue
    
    src="$APPS_SOURCE/$app"
    dst="$TARGET/opt/$app"
    [[ -d "$src" ]] || { echo "WARNING: $app not found"; continue; }
    
    echo "Deploying: $app"
    
    cp -a "$src" "$dst"
    chown -R root:root "$dst"
    chmod 755 "$dst/run.sh"
    
    name="$(jq -r .name "$src/metadata.json" 2>/dev/null || echo "$app")"
    
    cat > "$TARGET/usr/share/applications/$app.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$name
Exec=/opt/$app/run.sh
Terminal=false
Categories=Utility;
EOF
    
    mkdir -p "$TARGET$uhome/.config/autostart"
    cat > "$TARGET$uhome/.config/autostart/$app.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$name
Exec=/opt/$app/run.sh
Terminal=false
X-GNOME-Autostart-enabled=true
NoDisplay=true
EOF
    chown -R $uid:$gid "$TARGET$uhome/.config"
    
    echo "  → /opt/$app"
    echo "  → /usr/share/applications/$app.desktop"
    echo "  → ~/.config/autostart/$app.desktop"
done

echo "=== $(date) ==="
echo "Deploy complete"
```

Cấp quyền:
```bash
sudo chmod 755 "$ROOT/opt/iso-apps/deploy-selected-apps.sh"
```

---

## Giải thích Autoinstall YAML

Tạo bởi: `live-app-selector.sh`, serve qua HTTP

Ý nghĩa:
```yaml
autoinstall:
  version: 1

  interactive-sections:
    - identity             # User tạo account, phần khác tự động
  
  apt:
    geoip: false           # KHÔNG geolocation (offline)
    preserve_sources_list: false
  
  packages: []             # **KHÔNG cài package nào**
                          
  
  refresh-installer:
    update: no             # **KHÔNG update** 
  
  late-commands:           # Chạy SAU cài base
    - /bin/bash /opt/iso-apps/deploy-selected-apps.sh
    - curtin in-target -- rm -f /etc/xdg/autostart/live-app-selector.desktop
```

**Tại sao:**
- `packages: []` + `update: no` = Tránh installer kẹt ở `configuring apt`
- `interactive-sections: [identity]` = User tạo account

---

## 8. Cài tools trong Cubic Terminal

Mở Cubic → chọn project → Terminal:

```bash
apt-get update
apt-get install -y zenity jq python3

# Xóa services cũ nếu có
rm -f /etc/systemd/system/c-auto-static-ip.service
rm -f /etc/systemd/system/nvidia-firstboot.service

apt-get clean
```

---

## 9. Generate ISO

Cubic:
1. Exit terminal
2. Next → Next
3. Generate ISO

---

---

## Tóm tắt Scripts

| Script | Chạy khi | Mục đích | Input | Output |
|:---|:---|:---|:---|:---|
| prepare-all-apps.sh| Before ISO | Scan, tải .deb | `APP_BUILD_DIRS` | `$STAGING/apps/`, `deb-cache/` |
| live-app-selector.sh | Live boot | Menu + HTTP server | metadata.json | `/var/tmp/app-selection.conf`, port 8765 |
| live-app-selector.desktop | Live autostart | Trigger script | — | Script run |
| deploy-selected-apps.sh | Late Commands | Cài + deploy + launchers | selection file, ISO apps | `/opt/` apps, desktop entries |


