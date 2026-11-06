#!/usr/bin/env bash
set -Eeuo pipefail
umask 022

# Prepare a Cubic custom-root using detected SDK versions and paths.
# Run on the host Ubuntu as: sudo -E bash prepare-cubic-env.sh "$ROOT"
# Or let it auto-detect if ROOT not provided

log()  { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
die()  { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

[[ ${EUID:-$(id -u)} -eq 0 ]] || die "Chạy bằng sudo: sudo -E bash $0 \"\$ROOT\""
CALLER="${SUDO_USER:-}"
[[ -n "$CALLER" && "$CALLER" != root ]] || die 'Hãy chạy bằng sudo từ tài khoản Ubuntu thường.'
CALLER_HOME="$(getent passwd "$CALLER" | cut -d: -f6)"
[[ -d "$CALLER_HOME" ]] || die "Không xác định được HOME của tài khoản $CALLER."

# --------------------------- Cubic root detection ---------------------------
normalise_root() {
  local p="$1"
  [[ -n "$p" ]] || return 1
  p="$(readlink -m -- "$p")"
  if [[ -d "$p/etc" && -d "$p/usr" ]]; then
    printf '%s\n' "$p"; return 0
  fi
  if [[ -d "$p/custom-root/etc" && -d "$p/custom-root/usr" ]]; then
    printf '%s\n' "$p/custom-root"; return 0
  fi
  return 1
}

ROOT=""
ARG_ROOT="${1:-${CUBIC_ROOT:-}}"
if [[ -n "$ARG_ROOT" ]]; then
  ROOT="$(normalise_root "$ARG_ROOT" || true)"
  [[ -n "$ROOT" ]] || die "Đường dẫn không phải custom-root/project Cubic hợp lệ: $ARG_ROOT"
else
  # Cubic's console/nspawn processes usually expose the active custom-root path.
  declare -A ACTIVE=()
  while IFS= read -r line; do
    while IFS= read -r p; do
      [[ -n "$p" ]] || continue
      r="$(normalise_root "$p" 2>/dev/null || true)"
      [[ -n "$r" ]] && ACTIVE["$r"]=1
    done < <(grep -oE '/[^[:space:]]*/custom-root' <<<"$line" || true)
  done < <(ps -eww -o args= 2>/dev/null || true)
  if ((${#ACTIVE[@]} == 1)); then
    for ROOT in "${!ACTIVE[@]}"; do :; done
    log "Phát hiện custom-root đang được Cubic sử dụng: $ROOT"
  elif ((${#ACTIVE[@]} > 1)); then
    printf 'Phát hiện nhiều custom-root đang hoạt động:\n' >&2
    printf '  %s\n' "${!ACTIVE[@]}" >&2
    die 'Đóng các phiên Cubic không dùng hoặc truyền đường dẫn mong muốn làm đối số đầu tiên.'
  else
    declare -A CANDIDATES=()
    # Check common conventional paths first
    for p in \
      "$CALLER_HOME/ubuntu-iso-build/custom-root" \
      "$CALLER_HOME/ubuntu-iso-build/cubic-project/custom-root" \
      "$CALLER_HOME/cubic/custom-root" \
      "$CALLER_HOME/Cubic/custom-root"; do
      r="$(normalise_root "$p" 2>/dev/null || true)"
      [[ -n "$r" ]] && CANDIDATES["$r"]=1
    done
    # Search only for Cubic's named root, with bounded depth to avoid walking all data.
    while IFS= read -r p; do
      r="$(normalise_root "$p" 2>/dev/null || true)"
      [[ -n "$r" ]] && CANDIDATES["$r"]=1
    done < <(find "$CALLER_HOME" -mindepth 2 -maxdepth 7 -type d -name custom-root \
             -not -path '*/.cache/*' -not -path '*/.local/share/Trash/*' -print 2>/dev/null || true)
    if ((${#CANDIDATES[@]} == 1)); then
      for ROOT in "${!CANDIDATES[@]}"; do :; done
    elif ((${#CANDIDATES[@]} == 0)); then
      die "Không tìm thấy custom-root. Mở Cubic hoặc truyền đường dẫn, ví dụ: sudo bash $0 '$CALLER_HOME/ubuntu-iso-build/custom-root'"
    else
      printf 'Tìm thấy nhiều custom-root; không tự chọn để tránh sửa nhầm:\n' >&2
      printf '  %s\n' "${!CANDIDATES[@]}" >&2
      die "Chạy lại với một đường dẫn rõ ràng: sudo bash $0 '/đường/dẫn/custom-root'"
    fi
  fi
fi

[[ -d "$ROOT/etc" && -d "$ROOT/usr" ]] || die "custom-root không hợp lệ: $ROOT"
# Do not mutate the rootfs while Cubic has it mounted in an active nspawn terminal.
if ps -eww -o args= 2>/dev/null | grep -F 'systemd-nspawn' | grep -F -- "$ROOT" >/dev/null; then
  die "Cubic đang sử dụng rootfs này trong systemd-nspawn. Đóng Cubic/Terminal Cubic hoàn toàn rồi chạy lại."
fi
[[ -f "$ROOT/etc/os-release" ]] || die "Không tìm thấy $ROOT/etc/os-release; đây có thể không phải rootfs Ubuntu."
# Do not use a root inside this custom-root as an SDK source.
case "$CALLER_HOME" in '') die 'HOME không hợp lệ.';; esac
log "Cubic custom-root được chọn: $ROOT"

# Read the target Ubuntu release from the image being prepared, not from the host.
TARGET_ID="$(. "$ROOT/etc/os-release"; printf '%s' "${ID:-}")"
TARGET_VERSION="$(. "$ROOT/etc/os-release"; printf '%s' "${VERSION_ID:-unknown}")"
TARGET_CODENAME="$(. "$ROOT/etc/os-release"; printf '%s' "${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}")"
[[ "$TARGET_ID" == ubuntu ]] || warn "Rootfs báo ID='$TARGET_ID' (mong đợi ubuntu)."
[[ -n "$TARGET_CODENAME" ]] || die 'Không xác định được codename Ubuntu từ custom-root/etc/os-release.'
log "Hệ điều hành đích: Ubuntu $TARGET_VERSION ($TARGET_CODENAME)"

copy_tree() {
  local src="$1" dst="$2"
  [[ -d "$src" ]] || die "Không tồn tại thư mục nguồn: $src"
  # A guard against accidentally trying to copy a destination into itself.
  local src_real dst_real
  src_real="$(readlink -f -- "$src")"
  dst_real="$(readlink -m -- "$dst")"
  [[ "$src_real" != "$dst_real" ]] || { log "Nguồn và đích giống nhau, bỏ qua: $src"; return 0; }
  mkdir -p "$dst"
  cp -a "$src"/. "$dst"/
  chown -hR root:root "$dst"
  log "Đã chép SDK: $src -> $dst"
}

# ------------------------------- Qt 6 detect -------------------------------
# Search common installation roots first, then a bounded fallback under HOME.
QT_SEARCH_ROOTS=("${QT_SDK_ROOT:-}" /opt/Qt /usr/local/Qt "$CALLER_HOME/Qt" "$CALLER_HOME/opt/Qt")
QT_QMAKE_FILES=()
for d in "${QT_SEARCH_ROOTS[@]}"; do
  [[ -d "$d" ]] || continue
  while IFS= read -r q; do QT_QMAKE_FILES+=("$q"); done < <(find "$d" -maxdepth 8 \( -type f -o -type l \) -path '*/bin/qmake' -print 2>/dev/null || true)
done
if ((${#QT_QMAKE_FILES[@]} == 0)); then
  while IFS= read -r q; do
    case "$q" in "$ROOT"/*) continue;; esac
    QT_QMAKE_FILES+=("$q")
  done < <(find "$CALLER_HOME" -mindepth 3 -maxdepth 9 \( -type f -o -type l \) -path '*/bin/qmake' \
             -not -path '*/.cache/*' -not -path '*/.local/share/Trash/*' -print 2>/dev/null || true)
fi
QT_ROWS=()
declare -A QT_SEEN=()
for q in "${QT_QMAKE_FILES[@]}"; do
  [[ -x "$q" ]] || continue
  v="$("$q" -query QT_VERSION 2>/dev/null | head -n1 || true)"
  [[ "$v" =~ ^6\.[0-9]+(\.[0-9]+)?$ ]] || continue
  prefix="$("$q" -query QT_INSTALL_PREFIX 2>/dev/null | head -n1 || true)"
  [[ -n "$prefix" && -d "$prefix" ]] || prefix="$(dirname "$(dirname "$q")")"
  prefix="$(readlink -f -- "$prefix")"
  [[ "$prefix" == "$ROOT"/* ]] && continue
  key="$v|$prefix"
  [[ -n "${QT_SEEN[$key]+x}" ]] && continue
  QT_SEEN[$key]=1
  QT_ROWS+=("$v|$prefix")
done
((${#QT_ROWS[@]} > 0)) || die "Không tìm thấy SDK Qt 6 có qmake trong /opt/Qt, /usr/local/Qt hoặc thư mục Qt của $CALLER. Có thể đặt QT_SDK_ROOT=/đường/dẫn/Qt rồi chạy lại."
QT_PICK="$(printf '%s\n' "${QT_ROWS[@]}" | sort -t'|' -k1,1V | tail -n1)"
QT_VERSION="${QT_PICK%%|*}"
QT_SRC="${QT_PICK#*|}"
if [[ "$(basename "$QT_SRC")" == gcc_64 ]]; then
  QT_DEST="/opt/Qt/$QT_VERSION/gcc_64"
else
  QT_DEST="/opt/Qt/$QT_VERSION"
fi
QT_TARGET="$ROOT$QT_DEST"
if [[ -x "$QT_TARGET/bin/qmake" ]]; then
  existing_ver="$("$QT_TARGET/bin/qmake" -query QT_VERSION 2>/dev/null || true)"
  [[ "$existing_ver" == "$QT_VERSION" ]] || die "Đích Qt đã tồn tại nhưng khác phiên bản: $QT_TARGET ($existing_ver thay vì $QT_VERSION). Hãy xử lý thư mục này trước, không ghi đè tự động."
  log "Qt $QT_VERSION đã có tại $QT_DEST; bỏ qua sao chép."
else
  [[ ! -e "$QT_TARGET" ]] || die "Đích Qt tồn tại nhưng không có qmake hợp lệ: $QT_TARGET. Không tự ghi đè."
  copy_tree "$QT_SRC" "$QT_TARGET"
fi
log "Qt được phát hiện: version=$QT_VERSION, nguồn=$QT_SRC, đích=$QT_DEST"

# ----------------------------- Snap7 SDK detect ----------------------------
SNAP7_SRC="${SNAP7_SDK_ROOT:-${SNAP7_ROOT:-}}"
if [[ -n "$SNAP7_SRC" && ! -d "$SNAP7_SRC" ]]; then die "SNAP7_SDK_ROOT/SNAP7_ROOT không tồn tại: $SNAP7_SRC"; fi
if [[ -z "$SNAP7_SRC" ]]; then
  for d in /opt/snap7 "$CALLER_HOME/snap7" "$CALLER_HOME/Snap7" "$CALLER_HOME/Downloads/snap7"; do
    if [[ -d "$d" ]] && find "$d" -maxdepth 7 -type f -iname snap7.h -print -quit 2>/dev/null | grep -q .; then SNAP7_SRC="$d"; break; fi
  done
fi
if [[ -z "$SNAP7_SRC" ]]; then
  while IFS= read -r d; do
    case "$d" in "$ROOT"/*) continue;; esac
    if find "$d" -maxdepth 7 -type f -iname snap7.h -print -quit 2>/dev/null | grep -q .; then
      # Prefer a source/SDK directory, not a bare include directory.
      if [[ -d "$d/src" || -d "$d/examples" || -d "$d/release" || -d "$d/build" ]]; then SNAP7_SRC="$d"; break; fi
    fi
  done < <(find /opt /usr/local "$CALLER_HOME" -mindepth 1 -maxdepth 5 -type d \( -iname '*snap7*' \) \
            -not -path '*/.cache/*' -not -path '*/.local/share/Trash/*' -print 2>/dev/null || true)
fi
[[ -n "$SNAP7_SRC" && -d "$SNAP7_SRC" ]] || die 'Không tìm thấy thư mục SDK/source Snap7. Đặt SNAP7_SDK_ROOT=/đường/dẫn/sdk rồi chạy lại.'
SNAP7_HEADER="$(find "$SNAP7_SRC" -maxdepth 9 -type f -iname snap7.h -print -quit 2>/dev/null || true)"
if [[ -z "$SNAP7_HEADER" ]]; then
  for h in /usr/local/include/snap7.h /usr/include/snap7.h; do [[ -f "$h" ]] && { SNAP7_HEADER="$h"; break; }; done
fi
[[ -n "$SNAP7_HEADER" ]] || die "Đã tìm thấy SDK Snap7 nhưng không tìm thấy snap7.h bên trong hay trong /usr/local/include, /usr/include: $SNAP7_SRC"
SNAP7_LIB=""
if command -v ldconfig >/dev/null 2>&1; then
  SNAP7_LIB="$(ldconfig -p 2>/dev/null | awk '$1 ~ /^libsnap7\.so([.]|$)/ {print $NF; exit}')"
fi
if [[ -z "$SNAP7_LIB" || ! -e "$SNAP7_LIB" ]]; then
  for d in /usr/local/lib /usr/lib /usr/lib64 /usr/lib/x86_64-linux-gnu "$SNAP7_SRC"; do
    [[ -d "$d" ]] || continue
    SNAP7_LIB="$(find "$d" -maxdepth 8 \( -type f -o -type l \) -name 'libsnap7.so*' -print -quit 2>/dev/null || true)"
    [[ -n "$SNAP7_LIB" ]] && break
  done
fi
[[ -n "$SNAP7_LIB" && -e "$SNAP7_LIB" ]] || die 'Không tìm thấy thư viện libsnap7.so* qua ldconfig hoặc trong SDK. Cần build/cài thư viện Snap7 trước.'
SNAP7_DEST='/opt/snap7'
copy_tree "$SNAP7_SRC" "$ROOT$SNAP7_DEST"
install -D -m 0644 "$SNAP7_HEADER" "$ROOT/usr/local/include/snap7.h"
SNAP7_LIB_REAL="$(readlink -f -- "$SNAP7_LIB")"
install -D -m 0755 "$SNAP7_LIB_REAL" "$ROOT/usr/local/lib/libsnap7.so"
log "Snap7 được phát hiện: SDK=$SNAP7_SRC, header=$SNAP7_HEADER, thư viện=$SNAP7_LIB -> /usr/local/lib/libsnap7.so"

# -------------------------------- Qwt detect --------------------------------
QWT_SRC="${QWT_SDK_ROOT:-${QWT_ROOT:-}}"
if [[ -n "$QWT_SRC" && ! -d "$QWT_SRC" ]]; then die "QWT_SDK_ROOT/QWT_ROOT không tồn tại: $QWT_SRC"; fi
QWT_CANDIDATES=()
if [[ -n "$QWT_SRC" ]]; then
  QWT_CANDIDATES+=("$QWT_SRC")
else
  for d in /usr/local /opt "$CALLER_HOME"; do
    [[ -d "$d" ]] || continue
    while IFS= read -r qd; do
      case "$qd" in "$ROOT"/*) continue;; esac
      if find "$qd" -maxdepth 7 \( -type f -o -type l \) \( -name 'libqwt*.so*' -o -name 'qwt_global.h' \) -print -quit 2>/dev/null | grep -q .; then
        QWT_CANDIDATES+=("$qd")
      fi
    done < <(find "$d" -mindepth 1 -maxdepth 5 -type d \( -iname 'qwt*' -o -iname '*qwt*' \) \
              -not -path '*/.cache/*' -not -path '*/.local/share/Trash/*' -print 2>/dev/null || true)
  done
fi
QWT_ROWS=()
declare -A QWT_SEEN=()
for qd in "${QWT_CANDIDATES[@]}"; do
  [[ -d "$qd" ]] || continue
  QWT_VER=""
  b="$(basename "$qd")"
  if [[ "$b" =~ ([0-9]+\.[0-9]+\.[0-9]+) ]]; then QWT_VER="${BASH_REMATCH[1]}"; fi
  if [[ -z "$QWT_VER" ]]; then
    qh="$(find "$qd" -maxdepth 8 -type f -name qwt_global.h -print -quit 2>/dev/null || true)"
    if [[ -n "$qh" ]]; then
      QWT_VER="$(sed -nE 's/.*QWT_VERSION_STR[[:space:]]+"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/p' "$qh" | head -n1)"
      [[ -n "$QWT_VER" ]] || QWT_VER="$(sed -nE 's/.*QWT_VERSION[[:space:]]+0x([0-9A-Fa-f]+).*/\1/p' "$qh" | head -n1)"
    fi
  fi
  [[ -n "$QWT_VER" ]] || continue
  qlib="$(find "$qd" -maxdepth 8 \( -type f -o -type l \) -name 'libqwt*.so*' -print -quit 2>/dev/null || true)"
  [[ -n "$qlib" ]] || continue
  qd="$(readlink -f -- "$qd")"
  [[ "$qd" == "$ROOT"/* ]] && continue
  key="$QWT_VER|$qd"
  [[ -n "${QWT_SEEN[$key]+x}" ]] && continue
  QWT_SEEN[$key]=1
  QWT_ROWS+=("$QWT_VER|$qd")
done
((${#QWT_ROWS[@]} > 0)) || die 'Không tìm thấy SDK Qwt có libqwt*.so* và không xác định được phiên bản. Đặt QWT_SDK_ROOT=/đường/dẫn/qwt rồi chạy lại.'
QWT_PICK="$(printf '%s\n' "${QWT_ROWS[@]}" | sort -t'|' -k1,1V | tail -n1)"
QWT_VERSION="${QWT_PICK%%|*}"
QWT_SRC="${QWT_PICK#*|}"
QWT_DEST="/usr/local/qwt-$QWT_VERSION"
QWT_TARGET="$ROOT$QWT_DEST"
if [[ -d "$QWT_TARGET" ]] && find "$QWT_TARGET" -maxdepth 8 \( -type f -o -type l \) -name 'libqwt*.so*' -print -quit 2>/dev/null | grep -q .; then
  log "Đã có thư viện Qwt tại $QWT_DEST; đồng bộ SDK để bảo đảm đầy đủ."
fi
copy_tree "$QWT_SRC" "$QWT_TARGET"
QWT_TARGET_LIB="$(find "$QWT_TARGET" -maxdepth 9 \( -type f -o -type l \) -name 'libqwt*.so*' -print -quit 2>/dev/null || true)"
[[ -n "$QWT_TARGET_LIB" ]] || die "Không thấy thư viện Qwt sau khi chép vào $QWT_TARGET"
QWT_TARGET_LIB_DIR="$(dirname "${QWT_TARGET_LIB#"$ROOT"}")"
log "Qwt được phát hiện: version=$QWT_VERSION, nguồn=$QWT_SRC, đích=$QWT_DEST"

# ------------------------------- ROS key setup ------------------------------
ROS_DISTRO="${ROS_DISTRO:-rolling}"
ROS_KEY_SOURCE=""
# Reuse the target root's existing key if present; otherwise use the host's ROS key.
for k in \
  "$ROOT/usr/share/keyrings/ros-archive-keyring.gpg" \
  "$ROOT/etc/apt/keyrings/ros-archive-keyring.gpg" \
  /usr/share/keyrings/ros-archive-keyring.gpg \
  /etc/apt/keyrings/ros-archive-keyring.gpg \
  /usr/share/keyrings/ros2-archive-keyring.gpg \
  /etc/apt/keyrings/ros2-archive-keyring.gpg; do
  if [[ -s "$k" ]]; then ROS_KEY_SOURCE="$k"; break; fi
done
if [[ -z "$ROS_KEY_SOURCE" ]]; then
  # Inspect the host's existing ROS repository for a custom signed-by key path.
  while IFS= read -r f; do
    k="$(grep -Eho 'signed-by=[^], ]+' "$f" 2>/dev/null | head -n1 | cut -d= -f2- || true)"
    if [[ -n "$k" && -s "$k" ]]; then ROS_KEY_SOURCE="$k"; break; fi
  done < <(find /etc/apt/sources.list.d -maxdepth 1 -type f \( -name '*.list' -o -name '*.sources' \) -print 2>/dev/null || true)
fi
if [[ -z "$ROS_KEY_SOURCE" ]]; then
  die 'Không tìm thấy ROS archive key trên máy nguồn/ảnh đích. Cài đặt hoặc tải key ROS 2 chính thức trước, rồi chạy lại; script không tự bỏ qua xác minh chữ ký APT.'
fi
ROS_KEY_DEST="$ROOT/usr/share/keyrings/ros-archive-keyring.gpg"
mkdir -p "$(dirname "$ROS_KEY_DEST")"
if [[ "$ROS_KEY_SOURCE" != "$ROS_KEY_DEST" ]]; then
  if file "$ROS_KEY_SOURCE" 2>/dev/null | grep -qi 'ASCII text'; then
    command -v gpg >/dev/null 2>&1 || die 'Key ROS dạng ASCII nhưng máy nguồn thiếu gpg để chuyển sang keyring.'
    gpg --batch --yes --dearmor --output "$ROS_KEY_DEST" "$ROS_KEY_SOURCE"
  else
    install -m 0644 "$ROS_KEY_SOURCE" "$ROS_KEY_DEST"
  fi
fi
chmod 0644 "$ROS_KEY_DEST"
mkdir -p "$ROOT/etc/apt/sources.list.d"
printf 'deb [signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] https://packages.ros.org/ros2/ubuntu %s main\n' "$TARGET_CODENAME" > "$ROOT/etc/apt/sources.list.d/ros2.list"
chmod 0644 "$ROOT/etc/apt/sources.list.d/ros2.list"
log "ROS 2 repository đã cấu hình cho codename đích '$TARGET_CODENAME' (distro dự kiến: $ROS_DISTRO)."

# ---------------------------- Shared env settings ---------------------------
mkdir -p "$ROOT/etc/profile.d" "$ROOT/usr/local/bin" "$ROOT/etc/ld.so.conf.d" "$ROOT/usr/share/applications" "$ROOT/root"
cat > "$ROOT/etc/profile.d/cubic-dev-environment.sh" <<EOF
# Generated automatically by prepare-cubic-dev-env-auto.sh.
export QT_ROOT='$QT_DEST'
export SNAP7_ROOT='$SNAP7_DEST'
export QWT_ROOT='$QWT_DEST'
export ROS_DISTRO='$ROS_DISTRO'
case ":\$PATH:" in *":\$QT_ROOT/bin:"*) ;; *) export PATH="\$QT_ROOT/bin:\$PATH" ;; esac
EOF
chmod 0644 "$ROOT/etc/profile.d/cubic-dev-environment.sh"
# Replace previous hard-coded profiles with compatibility wrappers pointing at the detected paths.
cat > "$ROOT/etc/profile.d/qt6.sh" <<'EOF'
# Compatibility wrapper: values are detected in cubic-dev-environment.sh.
[ -r /etc/profile.d/cubic-dev-environment.sh ] && . /etc/profile.d/cubic-dev-environment.sh
EOF
cat > "$ROOT/etc/profile.d/ros2.sh" <<'EOF'
# Enable the configured ROS distribution in interactive Bash login shells.
[ -r /etc/profile.d/cubic-dev-environment.sh ] && . /etc/profile.d/cubic-dev-environment.sh
if [ -n "${BASH_VERSION:-}" ] && [ -n "${ROS_DISTRO:-}" ] && [ -f "/opt/ros/${ROS_DISTRO}/setup.bash" ]; then
  . "/opt/ros/${ROS_DISTRO}/setup.bash"
fi
EOF
chmod 0644 "$ROOT/etc/profile.d/qt6.sh" "$ROOT/etc/profile.d/ros2.sh"
ln -sfn "$QT_DEST/bin/qmake" "$ROOT/usr/local/bin/qmake6"
printf '%s\n' '/usr/local/lib' > "$ROOT/etc/ld.so.conf.d/snap7.conf"
printf '%s\n' "$QWT_TARGET_LIB_DIR" > "$ROOT/etc/ld.so.conf.d/qwt.conf"

# Copy a user's Qt Creator SDK if found; otherwise the Cubic-side installer will install Ubuntu's qtcreator package.
CREATOR_SRC_ROOT=""
CREATOR_REL=""
for base in "$CALLER_HOME/Qt/Tools/QtCreator"; do
  [[ -d "$base" ]] || continue
  for rel in bin/qtcreator lib/qtcreator/bin/qtcreator; do
    if [[ -x "$base/$rel" ]]; then CREATOR_SRC_ROOT="$base"; CREATOR_REL="$rel"; break 2; fi
  done
done
if [[ -n "$CREATOR_SRC_ROOT" ]]; then
  CREATOR_DEST='/opt/Qt/Tools/QtCreator'
  copy_tree "$CREATOR_SRC_ROOT" "$ROOT$CREATOR_DEST"
  ln -sfn "$CREATOR_DEST/$CREATOR_REL" "$ROOT/usr/local/bin/qtcreator"
  log "Đã chép Qt Creator từ $CREATOR_SRC_ROOT"
else
  log 'Không tìm thấy Qt Creator standalone trong ~/Qt/Tools/QtCreator; installer trong Cubic sẽ cài package qtcreator.'
fi
cat > "$ROOT/usr/share/applications/org.qt-project.qtcreator.desktop" <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Qt Creator
Comment=Cross-platform IDE for Qt development
Exec=qtcreator %F
Terminal=false
Categories=Development;IDE;Qt;
EOF
chmod 0644 "$ROOT/usr/share/applications/org.qt-project.qtcreator.desktop"

# ----------------------------- Chroot installer -----------------------------
# This runs manually in Cubic's root terminal, after this host-side preparation.
cat > "$ROOT/root/install-dev-env.sh" <<'INSTALL'
#!/usr/bin/env bash
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then echo 'Chạy script này bằng root trong terminal Cubic.' >&2; exit 1; fi
[[ -r /etc/profile.d/cubic-dev-environment.sh ]] && source /etc/profile.d/cubic-dev-environment.sh
ROS_DISTRO="${ROS_DISTRO:-rolling}"

# Detect SDKs from the generated environment, and fall back to filesystem discovery.
if [[ -z "${QT_ROOT:-}" || ! -x "$QT_ROOT/bin/qmake" ]]; then
  qmake_candidate="$(find /opt/Qt -maxdepth 6 -type f -path '*/bin/qmake' -executable -print 2>/dev/null | while read -r q; do v="$($q -query QT_VERSION 2>/dev/null || true)"; [[ "$v" =~ ^6\.[0-9]+(\.[0-9]+)?$ ]] && printf '%s|%s\n' "$v" "$(dirname "$(dirname "$q")")"; done | sort -t'|' -k1,1V | tail -n1 | cut -d'|' -f2- || true)"
  QT_ROOT="${qmake_candidate:-}"
fi
[[ -n "${QT_ROOT:-}" && -x "$QT_ROOT/bin/qmake" ]] || { echo 'Không tìm thấy SDK Qt 6 và qmake.' >&2; exit 2; }
if [[ -z "${SNAP7_ROOT:-}" || ! -d "$SNAP7_ROOT" ]]; then
  [[ -d /opt/snap7 ]] && SNAP7_ROOT=/opt/snap7 || SNAP7_ROOT="$(find /opt /usr/local -maxdepth 5 -type f -iname snap7.h -print -quit 2>/dev/null | xargs -r dirname | head -n1 | xargs -r dirname)"
fi
[[ -n "${SNAP7_ROOT:-}" && -d "$SNAP7_ROOT" ]] || { echo 'Không tìm thấy SDK Snap7.' >&2; exit 3; }
if [[ -z "${QWT_ROOT:-}" || ! -d "$QWT_ROOT" ]]; then
  QWT_ROOT="$(find /usr/local /opt -maxdepth 5 -type d -iname 'qwt*' -print 2>/dev/null | while read -r d; do find "$d" -maxdepth 7 -name 'libqwt*.so*' -print -quit 2>/dev/null | grep -q . && printf '%s\n' "$d"; done | tail -n1)"
fi
[[ -n "${QWT_ROOT:-}" && -d "$QWT_ROOT" ]] || { echo 'Không tìm thấy SDK Qwt.' >&2; exit 4; }

PKGS=(
  build-essential gcc g++ make cmake ninja-build graphviz doxygen gettext git
  libboost-dev libglu1-mesa-dev freeglut3-dev mesa-common-dev libglfw3-dev
  libgl1-mesa-dev libglew-dev libftgl-dev libfontconfig1-dev libfreetype-dev
  libx11-dev libx11-xcb-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev
  libxcb1-dev libxcb-cursor-dev libxcb-glx0-dev libxcb-keysyms1-dev libxcb-image0-dev
  libxcb-shm0-dev libxcb-icccm4-dev libxcb-sync-dev libxcb-xfixes0-dev libxcb-shape0-dev
  libxcb-randr0-dev libxcb-render-util0-dev libxcb-util-dev libxcb-xinerama0-dev
  libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev libfontconfig1 libxcb-glx0
  libx11-xcb1 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-randr0
  libxcb-render-util0 libxcb-sync1 libxcb-xfixes0 libxcb-xinerama0 libxcb-xkb1
  libxkbcommon-x11-0 libgl1 libegl1 libxcb-shape0 libxcb-cursor0 libglx-dev
  zlib1g-dev qtscript5-dev libqt5svg5-dev qttools5-dev-tools qttools5-dev
  libqt5opengl5-dev qtmultimedia5-dev libqt5multimedia5-plugins libqt5serialport5
  libqt5serialport5-dev qtpositioning5-dev libgps-dev libqt5positioning5
  libqt5positioning5-plugins libclang-dev libgdal-dev libgoogle-glog-dev libglm-dev
  libcups2-dev librtlsdr-dev libsoundtouch-dev libasound2-dev openssh-server
  net-tools wireshark ffmpeg terminator fonts-roboto lsb-release locales
  python3-colcon-common-extensions iputils-arping
)

printf '===== apt-get update =====\n'
apt-get update
AVAILABLE=()
MISSING=()
for pkg in "${PKGS[@]}"; do
  if apt-cache show "$pkg" >/dev/null 2>&1; then AVAILABLE+=("$pkg"); else MISSING+=("$pkg"); fi
done
for required in "ros-${ROS_DISTRO}-desktop" ros-dev-tools; do
  if ! apt-cache show "$required" >/dev/null 2>&1; then
    echo "LỖI: không tìm thấy package bắt buộc $required. Kiểm tra kết nối, codename Ubuntu và nguồn ROS 2." >&2
    exit 5
  fi
done
if ! command -v qtcreator >/dev/null 2>&1; then
  if apt-cache show qtcreator >/dev/null 2>&1; then AVAILABLE+=(qtcreator); else MISSING+=(qtcreator); fi
fi
mapfile -t AVAILABLE < <(printf '%s\n' "${AVAILABLE[@]}" | awk 'NF && !seen[$0]++')
printf '===== Cài gói build/dev và ROS 2 %s =====\n' "$ROS_DISTRO"
apt-get install -y --no-install-recommends "${AVAILABLE[@]}" "ros-${ROS_DISTRO}-desktop" ros-dev-tools

if ((${#MISSING[@]})); then
  echo 'CẢNH BÁO: package không tồn tại trong nguồn APT hiện tại:'
  printf '  - %s\n' "${MISSING[@]}"
fi

printf '===== Đánh dấu các gói quan trọng để không bị auto-remove =====\n'
# Đảm bảo các gói không bị xóa khi dọn dẹp ISO
apt-mark manual "${AVAILABLE[@]}" "ros-${ROS_DISTRO}-desktop" ros-dev-tools 2>/dev/null || true

if ! grep -Eq '^en_US.UTF-8 UTF-8' /etc/locale.gen; then echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen; fi
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

# Register dynamically detected SDK library paths.
printf '%s\n' '/usr/local/lib' > /etc/ld.so.conf.d/snap7.conf
QWT_LIB="$(find "$QWT_ROOT" -maxdepth 9 \( -type f -o -type l \) -name 'libqwt*.so*' -print -quit 2>/dev/null || true)"
[[ -n "$QWT_LIB" ]] || { echo "Không tìm thấy libqwt*.so* trong $QWT_ROOT" >&2; exit 6; }
printf '%s\n' "$(dirname "$QWT_LIB")" > /etc/ld.so.conf.d/qwt.conf
ln -sfn "$QT_ROOT/bin/qmake" /usr/local/bin/qmake6
ldconfig

# Prevent a missing system Qt Creator package from being silently overlooked.
if ! command -v qtcreator >/dev/null 2>&1; then
  echo 'CẢNH BÁO: Qt Creator chưa có executable trong PATH.' >&2
fi

printf '===== Kiểm tra nhanh =====\n'
"$QT_ROOT/bin/qmake" -query QT_VERSION
source "/opt/ros/${ROS_DISTRO}/setup.bash"
command -v ros2
ros2 --help >/dev/null
ldconfig -p | grep -E 'libsnap7|libqwt' || true
printf 'QT_ROOT=%s\nSNAP7_ROOT=%s\nQWT_ROOT=%s\nROS_DISTRO=%s\n' "$QT_ROOT" "$SNAP7_ROOT" "$QWT_ROOT" "$ROS_DISTRO"

printf '===== Dọn dẹp =====\n'
apt-get clean
# KHÔNG xóa /var/lib/apt/lists/* vì sẽ làm mất metadata gói trong ISO
# rm -rf /var/lib/apt/lists/*
echo 'Hoàn tất cài môi trường trong custom-root. Chạy check_env.sh để xác nhận PASS/FAIL/WARN.'
INSTALL
chmod 0700 "$ROOT/root/install-dev-env.sh"

HERE="$(cd -- "$(dirname -- "$0")" && pwd)"
if [[ -f "$HERE/check_env_iso.sh" ]]; then
  install -D -m 0755 "$HERE/check_env_iso.sh" "$ROOT/usr/local/bin/check_env.sh"
  log 'Đã cài checker: /usr/local/bin/check_env.sh'
else
  warn "Không thấy $HERE/check_env_iso.sh; nếu cần hãy chép checker vào rootfs sau."
fi

# Tell the user if the abandoned capture archive may bloat the ISO. Do not delete anything automatically.
if [[ -d "$ROOT/root/env-migrate" ]]; then
  warn "Tồn tại $ROOT/root/env-migrate (có thể chứa gói capture cũ khá lớn). Script không tự xóa; kiểm tra và dọn nếu không còn cần trước khi build ISO."
fi

printf '\n===== Hoàn tất chuẩn bị SDK =====\n'
printf 'Cubic root : %s\n' "$ROOT"
printf 'Ubuntu     : %s (%s)\n' "$TARGET_VERSION" "$TARGET_CODENAME"
printf 'Qt         : %s\n  source=%s\n  target=%s\n' "$QT_VERSION" "$QT_SRC" "$QT_DEST"
printf 'Snap7      : %s -> %s\n' "$SNAP7_SRC" "$SNAP7_DEST"
printf 'Qwt        : %s -> %s\n' "$QWT_VERSION" "$QWT_DEST"
printf 'ROS        : %s (apt codename %s)\n' "$ROS_DISTRO" "$TARGET_CODENAME"
printf '\nQuay lại Terminal Cubic (root@cubic), chạy:\n  bash /root/install-dev-env.sh\n'
printf 'Sau đó kiểm tra:\n  /usr/local/bin/check_env.sh\n'
