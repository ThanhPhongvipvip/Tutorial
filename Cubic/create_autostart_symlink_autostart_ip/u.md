# Custom Ubuntu ISO - Live Selector + Subiquity Late Commands

**Môi trường:** Ubuntu Desktop 24.04 amd64, Cubic

**Lưu ý:** Ubuntu 24.04 dùng **Subiquity** (không phải Ubiquity cũ). Preseed `success_command` không còn hoạt động. Dùng Subiquity `late-commands` thay thế. Để tránh kẹt `configuring apt`, deploy script **chỉ dùng `dpkg -i` trực tiếp**, không gọi `apt-get` với network.

---

## Kiến trúc

```
Boot ISO → Try Ubuntu → Menu chọn app → Lưu selection → HTTP server localhost:8765
  → Install Ubuntu → Automated Installation → URL: http://127.0.0.1:8765/autoinstall.yaml
  → Subiquity late-commands → dpkg -i từ /opt/iso-apps/deb-cache → copy apps vào /target/opt
  → Reboot → Apps tự chạy
```

**Điểm khác biệt so với cách cũ:**
- Apps + libs bundled (Qt, etc.) nằm trong `/opt/iso-apps` của ISO filesystem
- Dependencies cài bằng `dpkg -i` trực tiếp từ local cache — **không cần network, không kẹt apt**
- `autoinstall.yaml` có `apt.fallback: offline-install` và `apt.geoip: false` để tắt hẳn apt network

---

## BƯỚC 1: Cấu hình

### 1.1. Cài công cụ

```bash
sudo apt-get update
sudo apt-get install -y cubic jq file apt-rdepends dpkg-dev
```

### 1.2. `~/app-iso.conf`

```bash
ROOT="/home/phongvt/test/cub/custom-root"
STAGING="$HOME/iso-apps-staging"

APP_BUILD_DIRS=(
    "/home/phongvt/test/app/god/build"
    "/home/phongvt/test/app/cat/build"
)

EXTRA_APT_PACKAGES=()
```

---

## BƯỚC 2: Script chuẩn bị apps — `~/prepare-all-apps.sh`

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

source "${1:-$HOME/app-iso.conf}"
: "${ROOT:?ROOT not set}" "${STAGING:?STAGING not set}"

ROOT="$(realpath -e "$ROOT")"
mkdir -p "$STAGING/apps" "$STAGING/deb-cache"
STAGING="$(realpath -e "$STAGING")"

echo "ROOT: $ROOT"
echo "STAGING: $STAGING"

make_id() {
    python3 -c "
import re, sys, unicodedata as u
s = u.normalize('NFKD', sys.argv[1]).encode('ascii','ignore').decode()
print(re.sub(r'[^A-Za-z0-9]+', '-', s).strip('-').lower())
" "$1"
}

# Bundle non-apt libs vào appdir/lib/, trả ra apt packages qua stdout
bundle_libs_and_get_pkgs() {
    local bin="$1" appdir="$2"
    mkdir -p "$appdir/lib"

    while IFS= read -r lib; do
        [[ -z "$lib" ]] && continue
        [[ "$lib" == "$appdir"/* ]] && continue
        [[ "$lib" == *vdso* || "$lib" == */ld-linux* || "$lib" == */ld-*.so* ]] && continue

        pkg="$(dpkg-query -S "$lib" 2>/dev/null | head -n1 | cut -d: -f1 || true)"
        if [[ -n "$pkg" ]]; then
            echo "APT:$pkg"
        else
            [[ -f "$lib" ]] && echo "BUNDLE:$lib"
        fi
    done < <(ldd "$bin" 2>&1 | awk '/=>/ && $3~/^\// {print $3}')
}

dependency_closure() {
    [[ $# -eq 0 ]] && return 0
    apt-rdepends --follow=Depends,PreDepends "$@" 2>/dev/null \
    | awk '$1 !~ /^(Reading|Building|Depends|PreDepends)/ { print $1 }' \
    | sort -u \
    | while IFS= read -r pkg; do
        cand="$(apt-cache policy "$pkg" 2>/dev/null | awk '/Candidate:/{print $2}')"
        [[ -n "$cand" && "$cand" != "(none)" ]] && echo "$pkg" || true
    done
}

declare -A ALL_PKGS=()
APP_COUNT=0

for dir in "${APP_BUILD_DIRS[@]}"; do
    echo "====================================="
    [[ -d "$dir" ]] || { echo "ERROR: Not found: $dir"; exit 1; }
    dir="$(realpath -e "$dir")"

    name="$(basename "$dir")"
    [[ "$name" =~ ^(build|bin|out|dist|release|debug)$ ]] && name="$(basename "$(dirname "$dir")")"

    id="$(make_id "$name")"
    [[ -z "$id" ]] && { echo "ERROR: Invalid name: $name"; exit 1; }
    echo "App: $name  (ID: $id)"

    appdir="$STAGING/apps/$id"
    rm -rf "$appdir"
    mkdir -p "$appdir"
    cp -a "$dir"/. "$appdir"/

    find "$appdir" -type d \( -name CMakeFiles -o -name .git \) -exec rm -rf {} + 2>/dev/null || true
    find "$appdir" -type f \( -name '*.o' -o -name '*.obj' -o -name CMakeCache.txt -o -name cmake_install.cmake \) -delete 2>/dev/null || true

    mapfile -t exes < <(find "$appdir" -type f -executable \( ! -name '*.sh' \) -exec file {} + | awk -F: '/ELF.*executable/{print $1}')
    if [[ ${#exes[@]} -ne 1 ]]; then
        echo "ERROR: Need exactly 1 ELF in $id, found ${#exes[@]}:"
        printf '  %s\n' "${exes[@]:-<none>}"
        exit 1
    fi
    exe="${exes[0]}"
    exe_rel="${exe#"$appdir"/}"
    echo "Executable: $exe_rel"

    echo "Analyzing dependencies..."
    declare -a root_pkgs=()
    declare -a to_bundle=()

    while IFS= read -r line; do
        if [[ "$line" == APT:* ]]; then
            root_pkgs+=("${line#APT:}")
        elif [[ "$line" == BUNDLE:* ]]; then
            to_bundle+=("${line#BUNDLE:}")
        fi
    done < <(bundle_libs_and_get_pkgs "$exe" "$appdir")

    for lib in "${to_bundle[@]+"${to_bundle[@]}"}"; do
        dest="$appdir/lib/$(basename "$lib")"
        [[ -f "$dest" ]] && continue
        cp -L "$lib" "$dest"
        echo "  bundled: $(basename "$lib")"
    done

    if [[ "${#EXTRA_APT_PACKAGES[@]}" -gt 0 ]]; then
        root_pkgs+=("${EXTRA_APT_PACKAGES[@]}")
    fi

    mapfile -t all_pkgs < <(
        [[ ${#root_pkgs[@]} -gt 0 ]] && dependency_closure "${root_pkgs[@]}" || true
    )
    for p in "${all_pkgs[@]+"${all_pkgs[@]}"}"; do ALL_PKGS["$p"]=1; done

    bundled_count="$(find "$appdir/lib" -type f -name '*.so*' 2>/dev/null | wc -l)"
    echo "Bundled libs: $bundled_count  |  APT deps: ${#all_pkgs[@]}"

    jq -n \
        --arg id "$id" \
        --arg name "$name" \
        --arg exe "$exe_rel" \
        --argjson req "$(printf '%s\n' "${all_pkgs[@]+"${all_pkgs[@]}"}" | jq -Rs 'split("\n")|map(select(length>0))')" \
        '{id:$id, name:$name, version:"1.0.0", description:$name, executable:$exe, requires:$req}' \
        > "$appdir/metadata.json"

    cat > "$appdir/run.sh" <<RUNEOF
#!/bin/bash
set -e
APP_ROOT="\$(cd "\$(dirname "\$0")" && pwd)"
[[ -r /etc/profile.d/cubic-dev-environment.sh ]] && source /etc/profile.d/cubic-dev-environment.sh 2>/dev/null || true
export LD_LIBRARY_PATH="\$APP_ROOT/lib\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="\$APP_ROOT/plugins\${QT_PLUGIN_PATH:+:\$QT_PLUGIN_PATH}"
export QML2_IMPORT_PATH="\$APP_ROOT/qml\${QML2_IMPORT_PATH:+:\$QML2_IMPORT_PATH}"
exec "\$APP_ROOT/$exe_rel" "\$@"
RUNEOF
    chmod 755 "$appdir/run.sh" "$exe"
    APP_COUNT=$(( APP_COUNT + 1 ))
    echo " $name done"
done

echo "====================================="
echo "Total apps prepared: $APP_COUNT"

mapfile -t pkgs < <(printf '%s\n' ${ALL_PKGS[@]+"${!ALL_PKGS[@]}"} | sort -u)
if [[ ${#pkgs[@]} -gt 0 ]]; then
    echo "Downloading ${#pkgs[@]} APT packages..."
    sudo apt-get install -y --download-only --reinstall --no-install-recommends \
        -o "Dir::Cache::archives=$STAGING/deb-cache/" "${pkgs[@]}"
    sudo chown -R "$(id -u):$(id -g)" "$STAGING/deb-cache"
    rm -rf "$STAGING/deb-cache/partial" "$STAGING/deb-cache/lock"
    ( cd "$STAGING/deb-cache" && dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz )
    echo ".deb files: $(find "$STAGING/deb-cache" -maxdepth 1 -name '*.deb' | wc -l)"
else
    echo "No APT packages to download."
fi

echo "====================================="
echo " Staging complete: $STAGING"
```

Chạy:
```bash
chmod +x ~/prepare-all-apps.sh
source ~/app-iso.conf
sudo apt-get update
~/prepare-all-apps.sh
```

---

## BƯỚC 3: Copy vào Cubic custom-root

```bash
source ~/app-iso.conf

sudo mkdir -p "$ROOT/opt/iso-apps"
sudo cp -a "$STAGING/apps"     "$ROOT/opt/iso-apps/"
sudo cp -a "$STAGING/deb-cache" "$ROOT/opt/iso-apps/"
sudo chown -R root:root "$ROOT/opt/iso-apps"

# Verify
find "$ROOT/opt/iso-apps/apps" -maxdepth 1 -type d
ls "$ROOT/opt/iso-apps/deb-cache" | wc -l
```

---

## BƯỚC 4: Live Selector — `$ROOT/usr/local/bin/live-app-selector.sh`

```bash
source ~/app-iso.conf
sudo tee "$ROOT/usr/local/bin/live-app-selector.sh" >/dev/null <<'EOF'
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

# Sinh autoinstall.yaml với cấu hình offline đầy đủ
mkdir -p /var/tmp/autoinstall
cat > /var/tmp/autoinstall/autoinstall.yaml <<'YAML'
#cloud-config
autoinstall:
  version: 1
  apt:
    preserve_sources_list: false
    geoip: false
    fallback: offline-install
  interactive-sections: ['*']
  late-commands:
    - /bin/bash /opt/iso-apps/deploy-selected-apps.sh
  error-commands:
    - cp -a /var/log/installer /target/var/log/installer-failure/ 2>/dev/null || true
YAML

# HTTP server phục vụ YAML cho Subiquity
python3 -m http.server 8765 \
    --bind 127.0.0.1 \
    --directory /var/tmp/autoinstall \
    > /var/tmp/autoinstall/http.log 2>&1 &
echo $! > /var/tmp/autoinstall/http.pid

# Đợi server sẵn sàng
for i in {1..20}; do
    python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8765/autoinstall.yaml',timeout=1)" 2>/dev/null && break
    sleep 0.5
done

zenity --info --width=600 --title="Selection Saved" \
    --text="Selection saved.\n\nTo install Ubuntu:\n1. Open 'Install Ubuntu'\n2. Choose 'Automated Installation'\n3. Enter URL: http://127.0.0.1:8765/autoinstall.yaml" \
    2>/dev/null || true
EOF
sudo chmod 755 "$ROOT/usr/local/bin/live-app-selector.sh"
```

---

## BƯỚC 5: Live Autostart

```bash
source ~/app-iso.conf
sudo tee "$ROOT/etc/xdg/autostart/live-app-selector.desktop" >/dev/null <<'EOF'
[Desktop Entry]
Type=Application
Name=App Selector
Exec=/usr/local/bin/live-app-selector.sh
Terminal=false
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=8
NoDisplay=true
OnlyShowIn=GNOME;Unity;
EOF
sudo chmod 644 "$ROOT/etc/xdg/autostart/live-app-selector.desktop"
```

---

## BƯỚC 6: Deploy Script — `$ROOT/opt/iso-apps/deploy-selected-apps.sh`

```bash
source ~/app-iso.conf
sudo tee "$ROOT/opt/iso-apps/deploy-selected-apps.sh" >/dev/null <<'EOF'
#!/usr/bin/env bash
set -e

TARGET="/target"
APPS_SRC="/opt/iso-apps/apps"
DEB_SRC="/opt/iso-apps/deb-cache"
SELECTION="/var/tmp/app-selection.conf"
LOG="$TARGET/var/log/app-deploy.log"

mkdir -p "$TARGET/var/log"
exec > >(tee -a "$LOG") 2>&1

log() { echo "[$(date '+%F %T')] $*"; }
log "=== Deploy started ==="

[[ -f "$SELECTION" ]] || { log "No selection — skip"; exit 0; }
[[ -d "$TARGET/etc" ]] || { log "ERROR: target not mounted"; exit 1; }

mapfile -t apps < <(grep -v '^$' "$SELECTION")
[[ ${#apps[@]} -eq 0 ]] && { log "No apps selected"; exit 0; }
log "Selected: ${apps[*]}"

# Tìm user
user_line="$(awk -F: '$3>=1000 && $3<60000 && $6~/^\/home\// && $7!~/(nologin|false)$/{print;exit}' "$TARGET/etc/passwd")"
[[ -z "$user_line" ]] && { log "ERROR: no user"; exit 1; }
IFS=: read -r uname _ uid gid _ uhome _ <<< "$user_line"
log "User: $uname ($uid:$gid)"

# Cài dependencies bằng dpkg -i trực tiếp (không cần network)
if [[ -d "$DEB_SRC" ]] && ls "$DEB_SRC"/*.deb &>/dev/null; then
    log "Installing .deb packages..."
    # Mount bind deb-cache vào target
    mkdir -p "$TARGET/mnt/debs"
    mount --bind "$DEB_SRC" "$TARGET/mnt/debs"

    # dpkg -i toàn bộ, bỏ qua lỗi (--force-depends để xử lý thứ tự)
    chroot "$TARGET" bash -c '
        dpkg -i --force-depends /mnt/debs/*.deb 2>&1 || true
        dpkg --configure -a 2>&1 || true
    '
    umount "$TARGET/mnt/debs"
    log "Packages installed"
fi

# Deploy từng app được chọn
for app in "${apps[@]}"; do
    [[ -z "$app" ]] && continue
    src="$APPS_SRC/$app"
    [[ -d "$src" ]] || { log "WARNING: $src not found"; continue; }

    log "Deploying: $app"
    cp -a "$src" "$TARGET/opt/$app"
    chown -R root:root "$TARGET/opt/$app"
    chmod 755 "$TARGET/opt/$app/run.sh"

    name="$(jq -r .name "$src/metadata.json")"

    # Desktop launcher
    cat > "$TARGET/usr/share/applications/$app.desktop" <<DESK
[Desktop Entry]
Version=1.0
Type=Application
Name=$name
Exec=/opt/$app/run.sh
Terminal=false
Categories=Utility;
DESK

    # Autostart
    mkdir -p "$TARGET$uhome/.config/autostart"
    cat > "$TARGET$uhome/.config/autostart/$app.desktop" <<DESK
[Desktop Entry]
Version=1.0
Type=Application
Name=$name
Exec=/opt/$app/run.sh
Terminal=false
X-GNOME-Autostart-enabled=true
NoDisplay=true
DESK
    chown "$uid:$gid" "$TARGET$uhome/.config/autostart/$app.desktop"
    log " $app deployed"
done

log "=== Deploy complete ==="
EOF
sudo chmod 755 "$ROOT/opt/iso-apps/deploy-selected-apps.sh"
```

---

## BƯỚC 7: Cài tools trong Cubic

Mở Cubic terminal:
```bash
apt-get update
apt-get install -y zenity jq
apt-get clean
rm -rf /var/lib/apt/lists/*
```

---

## BƯỚC 8: Generate ISO

Trong Cubic: **Next → Generate**

---

## BƯỚC 9: Test QEMU

```bash
qemu-img create -f qcow2 ~/ubuntu-test.qcow2 80G

qemu-system-x86_64 \
    -enable-kvm -m 8192 -smp 4 -cpu host \
    -drive file=~/ubuntu-test.qcow2,format=qcow2 \
    -cdrom ~/ubuntu-custom.iso \
    -boot order=d \
    -vga virtio \
    -nic none
```

**Quy trình:**
1. Boot → **Try Ubuntu**
2. Sau 8s, menu tự hiện → Chọn apps → OK
3. **Install Ubuntu** → **Automated Installation**
4. URL: `http://127.0.0.1:8765/autoinstall.yaml`
5. Cài như bình thường (disk, user, timezone...)
6. Subiquity chạy late-commands → deploy apps
7. Reboot → Login → Apps tự chạy

**Verify sau cài:**
```bash
ls /opt/                              # Chỉ có apps được chọn
cat /var/log/app-deploy.log           # Log deploy
ls ~/.config/autostart/               # Autostart files
```
