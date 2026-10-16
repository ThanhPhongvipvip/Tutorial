#!/usr/bin/env bash
set -Eeuo pipefail
umask 022

if [[ $EUID -ne 0 ]]; then
  echo "Chạy bằng: sudo bash $0" >&2
  exit 1
fi

CALLER="${SUDO_USER:-}"
if [[ -z "$CALLER" || "$CALLER" == root ]]; then
  echo "Hãy chạy bằng sudo từ tài khoản Ubuntu thường, ví dụ: sudo bash $0" >&2
  exit 1
fi
CALLER_HOME="$(getent passwd "$CALLER" | cut -d: -f6)"
PROJECT="$CALLER_HOME/ubuntu-iso-build/cubic-project"
ROOT="$PROJECT/custom-root"

[[ -d "$ROOT/etc" && -d "$ROOT/usr" ]] || {
  echo "Không tìm thấy Cubic custom-root: $ROOT" >&2; exit 1;
}
[[ -x /opt/Qt/6.7.2/gcc_64/bin/qmake ]] || { echo "Thiếu Qt nguồn /opt/Qt/6.7.2/gcc_64" >&2; exit 1; }
[[ -d /opt/snap7 ]] || { echo "Thiếu /opt/snap7 trên máy nguồn" >&2; exit 1; }
[[ -f /usr/local/lib/libsnap7.so && -f /usr/local/include/snap7.h ]] || { echo "Thiếu libsnap7.so hoặc snap7.h trên máy nguồn" >&2; exit 1; }
[[ -d /usr/local/qwt-6.3.0 ]] || { echo "Thiếu /usr/local/qwt-6.3.0 trên máy nguồn" >&2; exit 1; }

copy_tree() {
  local src="$1" dst="$2"
  mkdir -p "$dst"
  cp -a "$src"/. "$dst"/
  chown -R root:root "$dst"
  echo "Đã chép: $src -> $dst"
}

# Qt 6.7.2: copy SDK đúng phiên bản, không copy thư mục home hay project cá nhân.
if [[ ! -x "$ROOT/opt/Qt/6.7.2/gcc_64/bin/qmake" ]]; then
  copy_tree /opt/Qt/6.7.2/gcc_64 "$ROOT/opt/Qt/6.7.2/gcc_64"
else
  echo "Qt 6.7.2 đã có trong custom-root; bỏ qua copy để tránh chép lại 2.2 GB."
fi

# Snap7 source/tools, shared library and header.
copy_tree /opt/snap7 "$ROOT/opt/snap7"
install -D -m 0755 /usr/local/lib/libsnap7.so "$ROOT/usr/local/lib/libsnap7.so"
install -D -m 0644 /usr/local/include/snap7.h "$ROOT/usr/local/include/snap7.h"

# Qwt SDK.
copy_tree /usr/local/qwt-6.3.0 "$ROOT/usr/local/qwt-6.3.0"

# Copy the host's ROS repository signing key; use the standard ROS 2 Noble source.
KEY=""
for k in /usr/share/keyrings/ros-archive-keyring.gpg /etc/apt/keyrings/ros-archive-keyring.gpg /usr/share/keyrings/ros2-archive-keyring.gpg; do
  if [[ -s "$k" ]]; then KEY="$k"; break; fi
done
if [[ -z "$KEY" ]]; then
  echo "Không tìm thấy ROS archive key trên máy nguồn. Không thể cài ROS an toàn; đã dừng." >&2
  exit 1
fi
install -D -m 0644 "$KEY" "$ROOT/usr/share/keyrings/ros-archive-keyring.gpg"
mkdir -p "$ROOT/etc/apt/sources.list.d"
printf '%s\n' 'deb [arch=amd64 signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] https://packages.ros.org/ros2/ubuntu noble main' > "$ROOT/etc/apt/sources.list.d/ros2.list"
chmod 0644 "$ROOT/etc/apt/sources.list.d/ros2.list"

# System-wide Qt and ROS environment; no fixed user account/home is embedded.
mkdir -p "$ROOT/etc/profile.d" "$ROOT/usr/local/bin" "$ROOT/etc/ld.so.conf.d" "$ROOT/usr/share/applications"
cat > "$ROOT/etc/profile.d/qt6.sh" <<'EOF'
# Qt 6.7.2 installed system-wide for the customized Ubuntu image.
export QT_ROOT=/opt/Qt/6.7.2/gcc_64
case ":$PATH:" in *":$QT_ROOT/bin:"*) ;; *) export PATH="$QT_ROOT/bin:$PATH" ;; esac
EOF
cat > "$ROOT/etc/profile.d/ros2.sh" <<'EOF'
# Enable ROS 2 Rolling in interactive login shells when installed.
if [ -f /opt/ros/rolling/setup.bash ] && [ -n "${BASH_VERSION:-}" ]; then
  source /opt/ros/rolling/setup.bash
fi
EOF
ln -sfn /opt/Qt/6.7.2/gcc_64/bin/qmake "$ROOT/usr/local/bin/qmake6"
printf '%s\n' '/usr/local/lib' > "$ROOT/etc/ld.so.conf.d/snap7.conf"
QWT_LIB="$(find /usr/local/qwt-6.3.0 -name 'libqwt*.so*' -print -quit 2>/dev/null || true)"
if [[ -n "$QWT_LIB" ]]; then
  QWT_LIB_REL="${QWT_LIB#/usr/local/qwt-6.3.0/}"
  QWT_LIB_DIR="$(dirname "$QWT_LIB_REL")"
  printf '/usr/local/qwt-6.3.0/%s\n' "$QWT_LIB_DIR" > "$ROOT/etc/ld.so.conf.d/qwt.conf"
else
  echo "CẢNH BÁO: chưa tìm thấy libqwt*.so* trong /usr/local/qwt-6.3.0; cần kiểm tra sau khi vào Cubic." >&2
  printf '%s\n' '/usr/local/qwt-6.3.0/lib' > "$ROOT/etc/ld.so.conf.d/qwt.conf"
fi

# Discover the user's Qt Creator installation if it exists. Otherwise the in-Cubic installer installs Ubuntu's qtcreator package.
CREATOR_BIN=""
for p in "$CALLER_HOME/Qt/Tools/QtCreator/bin/qtcreator" "$CALLER_HOME/Qt/Tools/QtCreator/lib/qtcreator/bin/qtcreator"; do
  if [[ -x "$p" ]]; then CREATOR_BIN="$p"; break; fi
done
if [[ -n "$CREATOR_BIN" ]]; then
  CREATOR_SRC_ROOT="$(dirname "$(dirname "$CREATOR_BIN")")"
  copy_tree "$CREATOR_SRC_ROOT" "$ROOT/opt/Qt/Tools/QtCreator"
  ln -sfn /opt/Qt/Tools/QtCreator/bin/qtcreator "$ROOT/usr/local/bin/qtcreator"
  echo "Đã chuẩn bị Qt Creator từ: $CREATOR_SRC_ROOT"
else
  echo "Không thấy Qt Creator trong ~/Qt/Tools/QtCreator; installer bên trong Cubic sẽ cài package qtcreator."
fi

# Add a generic system desktop launcher; it works with either the copied binary or apt package.
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

# Prepare the complete package installer for the open Cubic terminal.
cat > "$ROOT/root/install-dev-env.sh" <<'INSTALL'
#!/usr/bin/env bash
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then echo 'Chạy script này bằng root trong terminal Cubic.' >&2; exit 1; fi

PKGS=(
  build-essential gcc g++ make cmake ninja-build graphviz doxygen gettext git
  libboost-dev
  libglu1-mesa-dev freeglut3-dev mesa-common-dev libglfw3-dev libgl1-mesa-dev libglew-dev libftgl-dev
  libfontconfig1-dev libfreetype-dev libx11-dev libx11-xcb-dev libxext-dev
  libxfixes-dev libxi-dev libxrender-dev libxcb1-dev libxcb-cursor-dev
  libxcb-glx0-dev libxcb-keysyms1-dev libxcb-image0-dev libxcb-shm0-dev
  libxcb-icccm4-dev libxcb-sync-dev libxcb-xfixes0-dev libxcb-shape0-dev
  libxcb-randr0-dev libxcb-render-util0-dev libxcb-util-dev
  libxcb-xinerama0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev
  libfontconfig1 libxcb-glx0 libx11-xcb1 libxcb-icccm4 libxcb-image0
  libxcb-keysyms1 libxcb-randr0 libxcb-render-util0 libxcb-sync1
  libxcb-xfixes0 libxcb-xinerama0 libxcb-xkb1 libxkbcommon-x11-0
  libgl1 libegl1 libxcb-shape0 libxcb-cursor0 libglx-dev
  zlib1g-dev qtscript5-dev libqt5svg5-dev qttools5-dev-tools qttools5-dev
  libqt5opengl5-dev qtmultimedia5-dev libqt5multimedia5-plugins
  libqt5serialport5 libqt5serialport5-dev qtpositioning5-dev libgps-dev
  libqt5positioning5 libqt5positioning5-plugins
  libclang-dev libgdal-dev libgoogle-glog-dev libglm-dev libcups2-dev
  libxcb-cursor0 librtlsdr-dev libsoundtouch-dev libasound2-dev
  git openssh-server net-tools wireshark ffmpeg terminator fonts-roboto lsb-release locales
  python3-colcon-common-extensions
)

# Update first, then install all dependencies that exist in the configured Ubuntu/Noble repositories.
echo '===== apt-get update ====='
apt-get update
AVAILABLE=()
MISSING=()
for pkg in "${PKGS[@]}"; do
  if apt-cache show "$pkg" >/dev/null 2>&1; then AVAILABLE+=("$pkg"); else MISSING+=("$pkg"); fi
done
if ! apt-cache show ros-rolling-desktop >/dev/null 2>&1 || ! apt-cache show ros-dev-tools >/dev/null 2>&1; then
  echo 'LỖI: không tìm thấy ros-rolling-desktop hoặc ros-dev-tools. Kiểm tra nguồn ROS 2/key trong /etc/apt/sources.list.d/ros2.list.' >&2
  exit 2
fi
if ! command -v qtcreator >/dev/null 2>&1; then
  if apt-cache show qtcreator >/dev/null 2>&1; then AVAILABLE+=(qtcreator); else MISSING+=(qtcreator); fi
fi
# De-duplicate names while preserving order.
mapfile -t AVAILABLE < <(printf '%s\n' "${AVAILABLE[@]}" | awk '!seen[$0]++')
echo '===== Cài các gói build/dev và ROS 2 Rolling ====='
apt-get install -y --no-install-recommends "${AVAILABLE[@]}" ros-rolling-desktop ros-dev-tools

if ((${#MISSING[@]})); then
  echo
  echo 'CẢNH BÁO: các package sau không tồn tại trong apt sources hiện tại:'
  printf '  - %s\n' "${MISSING[@]}"
  echo 'Các package này cần đối chiếu lại bằng check_env.sh sau khi cài.'
fi

# Generate the locale expected by check_env.sh.
if ! grep -Eq '^en_US.UTF-8 UTF-8' /etc/locale.gen; then echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen; fi
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

# Ensure dynamic linker knows about copied native libraries and Qwt.
printf '%s\n' '/usr/local/lib' > /etc/ld.so.conf.d/snap7.conf
if ! find /usr/local/qwt-6.3.0 -name 'libqwt*.so*' -print -quit 2>/dev/null | grep -q .; then
  echo 'LỖI: không tìm thấy libqwt*.so* dưới /usr/local/qwt-6.3.0.' >&2
  exit 3
fi
QWT_LIB="$(find /usr/local/qwt-6.3.0 -name 'libqwt*.so*' -print -quit)"
printf '%s\n' "$(dirname "$QWT_LIB")" > /etc/ld.so.conf.d/qwt.conf
ldconfig

# Ensure Qt binaries are discoverable by the original checker.
ln -sfn /opt/Qt/6.7.2/gcc_64/bin/qmake /usr/local/bin/qmake6

# Keep X11 as configured by this environment profile; do not install an NVIDIA kernel driver into the generic ISO.
if [[ -f /etc/gdm3/custom.conf ]]; then
  if grep -q '^#WaylandEnable=false' /etc/gdm3/custom.conf; then
    sed -i 's/^#WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf
  elif ! grep -q '^WaylandEnable=false' /etc/gdm3/custom.conf; then
    printf '\nWaylandEnable=false\n' >> /etc/gdm3/custom.conf
  fi
fi

# Validate required binaries before cleaning apt caches.
echo '===== Kiểm tra nhanh ====='
/opt/Qt/6.7.2/gcc_64/bin/qmake -query QT_VERSION
source /opt/ros/rolling/setup.bash
command -v ros2
ros2 --help >/dev/null
ldconfig -p | grep -E 'libsnap7|libqwt' || true

echo '===== Dọn cache apt để giảm dung lượng ISO ====='
apt-get clean
rm -rf /var/lib/apt/lists/*
echo 'Hoàn tất cài đặt trong custom-root. Chạy check_env.sh để xem các mục PASS/FAIL/WARN.'
INSTALL
chmod 0700 "$ROOT/root/install-dev-env.sh"

# Copy the supplied checker if its fixed version is available next to this script.
HERE="$(cd -- "$(dirname -- "$0")" && pwd)"
if [[ -f "$HERE/check_env.sh" ]]; then
  install -D -m 0755 "$HERE/check_env.sh" "$ROOT/usr/local/bin/check_env.sh"
  echo "Đã cài checker đã chỉnh: /usr/local/bin/check_env.sh"
else
  echo "Gợi ý: đặt check_env.sh cạnh script này rồi chạy lại, hoặc chép vào $ROOT/usr/local/bin/check_env.sh."
fi

# Make sure copied files are readable to the eventual live user.
chmod -R a+rX "$ROOT/opt/Qt/6.7.2/gcc_64" "$ROOT/opt/snap7" "$ROOT/usr/local/qwt-6.3.0"
echo
echo "Chuẩn bị xong các file trong: $ROOT"
echo "Bây giờ quay lại terminal Cubic (root@cubic) và chạy: bash /root/install-dev-env.sh"
