# HƯỚNG DẪN TẠO CUSTOM UBUNTU ISO: FIRST BOOT APP SELECTOR

## 1. Mục tiêu
Xây dựng Custom Ubuntu ISO bằng Cubic với khả năng đóng gói nhiều ứng dụng và cho phép người dùng lựa chọn ứng dụng cần cài đặt offline ngay sau lần đăng nhập GNOME đầu tiên.

## 2. Yêu cầu môi trường
*   **Host & Target:** Khuyến nghị dùng chung phiên bản Ubuntu (VD: Ubuntu 24.04 amd64).
*   **Cài đặt công cụ trên Host:**
    ```bash
    sudo apt-get update
    sudo apt-get install -y cubic jq file apt-rdepends
    ```

---

## 3. Quy trình thực hiện trên Host

### Bước 1: Khai báo cấu hình
Tạo file `app-iso.conf` để khai báo đường dẫn. Đây là file duy nhất cần sửa khi thêm/bớt ứng dụng.

```bash
nano "$HOME/app-iso.conf"
```

**Nội dung:**
```bash
# =====================================================
# CUSTOM UBUNTU ISO CONFIGURATION
# =====================================================

# Cubic custom-root
ROOT="/path/to/cubic-project/custom-root"

# Staging directory trên Host
STAGING="$HOME/iso-apps-staging"

# =====================================================
# APPLICATION BUILD DIRECTORIES
# =====================================================
APP_BUILD_DIRS=(
    "/path/to/DogApp/build"
    "/path/to/CatApp/build"
    "/path/to/RobotControl/build"
)

# Optional Extra Dependencies (nếu ldd không tự phát hiện được)
EXTRA_APT_PACKAGES=()
```

### Bước 2: Tạo Script chuẩn bị ứng dụng
Script này sẽ tự động đọc thư mục build, tạo metadata, run script và tải .deb offline.

```bash
nano "$HOME/prepare-all-apps.sh"
```

**Nội dung:**
```bash
#!/usr/bin/env bash
set -Eeuo pipefail

CONFIG_FILE="${1:-$HOME/app-iso.conf}"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Config file not found: $CONFIG_FILE"
    exit 1
fi
source "$CONFIG_FILE"

: "${ROOT:?ROOT is not configured}"
: "${STAGING:?STAGING is not configured}"

for cmd in jq file ldd dpkg-query dpkg-deb apt-get apt-cache apt-rdepends realpath python3; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "ERROR: Missing $cmd"; exit 1; }
done

ROOT="$(realpath -e "$ROOT")"
STAGING="$(realpath -m "$STAGING")"
mkdir -p "$STAGING"

APP_STAGE="$STAGING/apps"
DEB_CACHE="$STAGING/.deb-cache"
rm -rf "$APP_STAGE" "$DEB_CACHE"
mkdir -p "$APP_STAGE" "$DEB_CACHE"

make_id() {
    python3 - "$1" <<'PY'
import re, sys, unicodedata
name = unicodedata.normalize("NFKD", sys.argv[1]).encode("ascii", "ignore").decode()
name = re.sub(r"[^A-Za-z0-9]+", "-", name).strip("-").lower()
print(name)
PY
}

make_display_name() {
    python3 - "$1" <<'PY'
import re, sys
name = re.sub(r"[_-]+", " ", sys.argv[1])
name = re.sub(r"\s+", " ", name).strip()
print(name)
PY
}

project_name_from_path() {
    local path="$1" leaf lower
    while true; do
        leaf="$(basename "$path")"
        lower="${leaf,,}"
        case "$lower" in
            build|release|debug|bin|out|dist|cmake-build-*|build-*)
                [[ "$(dirname "$path")" != "$path" ]] || break
                path="$(dirname "$path")"
                ;;
            *) break ;;
        esac
    done
    basename "$path"
}

packages_for_binary() {
    local binary="$1" ldd_output library owner_line package
    local -A found=()
    ldd_output="$(ldd "$binary" 2>&1 || true)"
    if grep -qE "not a dynamic executable|statically linked" <<< "$ldd_output"; then return 0; fi
    while IFS= read -r library; do
        [[ -n "$library" ]] || continue
        owner_line="$(dpkg-query -S "$library" 2>/dev/null | head -n1 || true)"
        if [[ "$owner_line" =~ ^([^:]+)(:[^:]+)?:[[:space:]] ]]; then
            package="${BASH_REMATCH[1]}"
            found["$package"]=1
        fi
    done < <(awk '/=>/ && $3 ~ /^\// {print $3; next} /^[[:space:]]*\// {print $1}' <<< "$ldd_output")
    if ((${#found[@]})); then printf '%s\n' "${!found[@]}" | sort -u; fi
}

dependency_closure() {
    local roots=("$@") package candidate
    ((${#roots[@]})) || return 0
    while IFS= read -r package; do
        [[ -n "$package" ]] || continue
        candidate="$(apt-cache policy "$package" 2>/dev/null | awk '/Candidate:/ {print $2; exit}')"
        if [[ -n "$candidate" && "$candidate" != "(none)" ]]; then printf '%s\n' "$package"; fi
    done < <(apt-rdepends --follow=Depends,PreDepends "${roots[@]}" 2>/dev/null | awk 'NF && $0 !~ /^[[:space:]]/ && $1 !~ /^(Reading|Building)/ {print $1}' | sort -u)
}

declare -A SEEN_IDS=()
declare -A ALL_DEBS_PACKAGES=()
APP_COUNT=0

for BUILD_DIR_INPUT in "${APP_BUILD_DIRS[@]}"; do
    BUILD_DIR="$(realpath -e "$BUILD_DIR_INPUT")"
    RAW_NAME="$(project_name_from_path "$BUILD_DIR")"
    APP_NAME="$(make_display_name "$RAW_NAME")"
    APP_ID="$(make_id "$RAW_NAME")"

    SEEN_IDS["$APP_ID"]=1
    APP_DIR="$APP_STAGE/$APP_ID"
    mkdir -p "$APP_DIR"

    cp -a "$BUILD_DIR"/. "$APP_DIR"/
    find "$APP_DIR" -type d \( -name .git -o -name CMakeFiles -o -name .qt \) -prune -exec rm -rf {} +
    find "$APP_DIR" -type f \( -name CMakeCache.txt -o -name cmake_install.cmake -o -name Makefile -o -name '*.o' -o -name '*.obj' -o -name .qmake.stash \) -delete

    mapfile -d '' -t EXEC_CANDIDATES < <(
        while IFS= read -r -d '' executable; do
            description="$(file -b "$executable" 2>/dev/null || true)"
            if [[ "$description" == ELF* && "$description" == *executable* ]]; then
                printf '%s\0' "$executable"
            fi
        done < <(find "$APP_DIR" -type f -executable -print0)
    )

    EXEC_REL="${EXEC_CANDIDATES[0]#"$APP_DIR"/}"
    EXEC_PATH="$APP_DIR/$EXEC_REL"

    mapfile -t ROOT_PACKAGES < <(packages_for_binary "$EXEC_PATH")
    for extra in "${EXTRA_APT_PACKAGES[@]}"; do [[ -n "$extra" ]] && ROOT_PACKAGES+=("$extra"); done
    
    APP_PACKAGES=()
    if ((${#ROOT_PACKAGES[@]})); then
        mapfile -t ROOT_PACKAGES < <(printf '%s\n' "${ROOT_PACKAGES[@]}" | sort -u)
        mapfile -t APP_PACKAGES < <(dependency_closure "${ROOT_PACKAGES[@]}")
    fi

    REQUIRES_JSON='[]'
    if ((${#APP_PACKAGES[@]})); then
        REQUIRES_JSON="$(printf '%s\n' "${APP_PACKAGES[@]}" | jq -R . | jq -s .)"
        for package in "${APP_PACKAGES[@]}"; do ALL_DEBS_PACKAGES["$package"]=1; done
    fi

    jq -n --arg id "$APP_ID" --arg name "$APP_NAME" --arg description "$APP_NAME application" --arg executable "$EXEC_REL" --argjson requires "$REQUIRES_JSON" '{id: $id, name: $name, version: "1.0.0", description: $description, executable: $executable, requires: $requires}' > "$APP_DIR/metadata.json"

    EXEC_QUOTED="$(printf '%q' "$EXEC_REL")"
    {
        cat <<'RUNHEAD'
#!/usr/bin/env bash
set -euo pipefail
APP_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RUNHEAD
        printf 'EXEC_REL=%s\n' "$EXEC_QUOTED"
        cat <<'RUNTAIL'
cd "$APP_ROOT"
if [[ -r /etc/profile.d/cubic-dev-environment.sh ]]; then
    set +u; source /etc/profile.d/cubic-dev-environment.sh; set -u
fi
for directory in lib lib64; do
    if [[ -d "$APP_ROOT/$directory" ]]; then export LD_LIBRARY_PATH="$APP_ROOT/$directory${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"; fi
done
if [[ -d "$APP_ROOT/plugins" ]]; then
    export QT_PLUGIN_PATH="$APP_ROOT/plugins${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
    if [[ -d "$APP_ROOT/plugins/platforms" ]]; then export QT_QPA_PLATFORM_PLUGIN_PATH="$APP_ROOT/plugins/platforms"; fi
fi
if [[ -d "$APP_ROOT/qml" ]]; then export QML2_IMPORT_PATH="$APP_ROOT/qml${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"; fi
exec "$APP_ROOT/$EXEC_REL" "$@"
RUNTAIL
    } > "$APP_DIR/run.sh"

    chmod 755 "$APP_DIR/run.sh" "$EXEC_PATH"
    chmod -R a+rX "$APP_DIR"
    ((APP_COUNT += 1))
done

if ((${#ALL_DEBS_PACKAGES[@]})); then
    mapfile -t DOWNLOAD_PACKAGES < <(printf '%s\n' "${!ALL_DEBS_PACKAGES[@]}" | sort -u)
    sudo apt-get install -y --download-only --reinstall --no-install-recommends -o "Dir::Cache::archives=$DEB_CACHE/" "${DOWNLOAD_PACKAGES[@]}"
    sudo chown -R "$(id -u):$(id -g)" "$DEB_CACHE"
fi
```
Cấp quyền và chạy:
```bash
chmod +x "$HOME/prepare-all-apps.sh"
source "$HOME/app-iso.conf"
sudo apt-get update
"$HOME/prepare-all-apps.sh"
```

### Bước 3: Đưa ứng dụng vào Cubic custom-root
```bash
source "$HOME/app-iso.conf"
sudo rm -rf "$ROOT/opt/iso-apps"
sudo mkdir -p "$ROOT/opt/iso-apps"
sudo cp -a "$STAGING/apps"/. "$ROOT/opt/iso-apps/"
sudo cp -a "$STAGING/.deb-cache" "$ROOT/opt/iso-apps/"
sudo chown -R root:root "$ROOT/opt/iso-apps"
sudo chmod -R a+rX "$ROOT/opt/iso-apps"
```

---

## 4. Cấu hình First Boot Scripts (ghi trực tiếp vào Cubic custom-root)

### 4.1. `app-selector-gui.sh` (Zenity GUI cho Desktop User)
```bash
sudo install -d "$ROOT/usr/local/bin"
sudo tee "$ROOT/usr/local/bin/app-selector-gui.sh" >/dev/null <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

APPS_DIR="/opt/iso-apps"
DONE_FILE="/var/lib/app-installer/done"
USER_STATE_DIR="$HOME/.cache/app-installer"
SELECTION_FILE="$USER_STATE_DIR/selection.conf"

if grep -qw 'boot=casper' /proc/cmdline 2>/dev/null || [[ -d /run/casper ]] || [[ -d /rofs ]]; then exit 0; fi
if [[ -f "$DONE_FILE" ]]; then exit 0; fi

declare -a APP_LIST=()
while IFS= read -r -d '' metadata; do
    app_id="$(basename "$(dirname "$metadata")")"
    [[ "$app_id" == .* ]] && continue
    display_name="$(jq -r '.name' "$metadata")"
    version="$(jq -r '.version // ""' "$metadata")"
    description="$(jq -r '.description // ""' "$metadata")"
    APP_LIST+=(FALSE "$app_id" "$display_name" "$version" "$description")
done < <(find "$APPS_DIR" -mindepth 2 -maxdepth 2 -type f -name metadata.json -print0 | sort -z)

if ! selected="$(zenity --list --title="Application Installation" --text="Select applications to install." --checklist --column="Install" --column="ID" --column="Application" --column="Version" --column="Description" --print-column=2 --hide-column=2 --separator="|" --width=900 --height=520 "${APP_LIST[@]} ")"; then exit 0; fi

if [[ -z "$selected" ]]; then exit 0; fi

install -d -m 0700 "$USER_STATE_DIR"
printf '%s\n' "$selected" | tr '|' '\n' | awk 'NF' > "$SELECTION_FILE"
chmod 0600 "$SELECTION_FILE"

if pkexec /usr/local/sbin/install-selected-apps.sh "$SELECTION_FILE"; then
    LOG_DIR="$USER_STATE_DIR/logs"
    mkdir -p "$LOG_DIR"
    while IFS= read -r app_id; do
        [[ -n "$app_id" ]] || continue
        if [[ -x "/opt/$app_id/run.sh" ]]; then
            nohup "/opt/$app_id/run.sh" >> "$LOG_DIR/$app_id.log" 2>&1 </dev/null &
        fi
    done < "$SELECTION_FILE"
    zenity --info --text="Installation complete. Selected apps have been launched and added to Autostart." 2>/dev/null || true
else
    zenity --error --text="Installation failed. Check /var/log/app-installer.log" 2>/dev/null || true
fi
EOF
sudo chmod 755 "$ROOT/usr/local/bin/app-selector-gui.sh"
```

### 4.2. `install-selected-apps.sh` (Installer chạy bằng quyền Root qua pkexec)
```bash
sudo install -d "$ROOT/usr/local/sbin"
sudo tee "$ROOT/usr/local/sbin/install-selected-apps.sh" >/dev/null <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

LOG_FILE="/var/log/app-installer.log"
STATE_DIR="/var/lib/app-installer"
DONE_FILE="$STATE_DIR/done"
ISO_APPS="/opt/iso-apps"
DEB_CACHE="$ISO_APPS/.deb-cache"
SELECTION_FILE="${1:-}"

install -d -o root -g root -m 0755 "$STATE_DIR" "$STATE_DIR/installed"
exec >> "$LOG_FILE" 2>&1

USER_LINE="$(getent passwd "$PKEXEC_UID" || true)"
IFS=: read -r USERNAME _ USER_ID GROUP_ID _ HOME_DIR _ <<< "$USER_LINE"

declare -a SELECTED_APPS=()
while IFS= read -r app_id || [[ -n "$app_id" ]]; do
    [[ -n "$app_id" ]] || continue
    SELECTED_APPS+=("$app_id")
done < "$SELECTION_FILE"

declare -A NEEDED_PACKAGES=()
for app_id in "${SELECTED_APPS[@]}"; do
    while IFS= read -r package; do
        [[ -n "$package" ]] && NEEDED_PACKAGES["$package"]=1
    done < <(jq -r '.requires[]?' "$ISO_APPS/$app_id/metadata.json")
done

if ((${#NEEDED_PACKAGES[@]})); then
    declare -a SELECTED_DEBS=()
    while IFS= read -r -d '' deb; do
        package="$(dpkg-deb -f "$deb" Package 2>/dev/null || true)"
        [[ -n "${NEEDED_PACKAGES[$package]+x}" ]] && SELECTED_DEBS+=("$deb")
    done < <(find "$DEB_CACHE" -maxdepth 1 -type f -name '*.deb' -print0)
    
    if ((${#SELECTED_DEBS[@]})); then
        DEBIAN_FRONTEND=noninteractive apt-get --yes --no-download --no-install-recommends install "${SELECTED_DEBS[@]}"
    fi
fi

for app_id in "${SELECTED_APPS[@]}"; do
    src="$ISO_APPS/$app_id"
    target="/opt/$app_id"
    mv "$src" "$target"
    chown -R root:root "$target"
    
    display_name="$(jq -r '.name' "$target/metadata.json")"
    exec_rel="$(jq -r '.executable' "$target/metadata.json")"
    
    cat > "/usr/share/applications/${app_id}.desktop" <<DESKTOP
[Desktop Entry]
Version=1.0
Type=Application
Name=$display_name
Exec=/opt/$app_id/run.sh
Terminal=false
Categories=Utility;
StartupNotify=true
DESKTOP
    chmod 644 "/usr/share/applications/${app_id}.desktop"

    USER_AUTOSTART_DIR="$HOME_DIR/.config/autostart"
    install -d -o "$USER_ID" -g "$GROUP_ID" -m 0755 "$USER_AUTOSTART_DIR"
    cat > "$USER_AUTOSTART_DIR/${app_id}.desktop" <<AUTOSTART
[Desktop Entry]
Version=1.0
Type=Application
Name=$display_name
Exec=/opt/$app_id/run.sh
Terminal=false
X-GNOME-Autostart-enabled=true
NoDisplay=true
AUTOSTART
    chown "$USER_ID:$GROUP_ID" "$USER_AUTOSTART_DIR/${app_id}.desktop"
    chmod 644 "$USER_AUTOSTART_DIR/${app_id}.desktop"
done

touch "$DONE_FILE"
rm -rf "$ISO_APPS"
exit 0
EOF
sudo chmod 755 "$ROOT/usr/local/sbin/install-selected-apps.sh"
```

### 4.3. Desktop Entry để kích hoạt App Selector tự động
```bash
sudo install -d "$ROOT/etc/xdg/autostart"
sudo tee "$ROOT/etc/xdg/autostart/app-selector.desktop" >/dev/null <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=First Boot App Selector
Exec=/usr/local/bin/app-selector-gui.sh
Terminal=false
X-GNOME-Autostart-enabled=true
NoDisplay=true
EOF
sudo chmod 644 "$ROOT/etc/xdg/autostart/app-selector.desktop"
```

---

## 5. Cài đặt Dependencies trong Cubic
Mở Terminal bên trong giao diện **Cubic** và chạy:
```bash
apt-get update
apt-get install -y zenity jq pkexec
apt-get clean
rm -rf /var/lib/apt/lists/*
```


---

## 6. Tóm tắt quy trình (Cheatsheet)
Khi bạn cần thêm ứng dụng mới hoặc build lại, chỉ cần làm theo luồng sau:
1. Sửa `APP_BUILD_DIRS` trong `~/app-iso.conf`.
2. Chạy: `~/prepare-all-apps.sh`
3. Chạy lệnh copy vào Cubic:
   ```bash
   sudo rm -rf "$ROOT/opt/iso-apps" && sudo mkdir -p "$ROOT/opt/iso-apps"
   sudo cp -a "$STAGING/apps"/. "$ROOT/opt/iso-apps/"
   sudo cp -a "$STAGING/.deb-cache" "$ROOT/opt/iso-apps/"
   sudo chown -R root:root "$ROOT/opt/iso-apps" && sudo chmod -R a+rX "$ROOT/opt/iso-apps"
   ```
4. Mở Cubic, `apt-get install -y zenity jq pkexec` (nếu chưa có).
5. Bấm **Generate ISO**.