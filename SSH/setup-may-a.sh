#!/usr/bin/env bash
# =============================================================================
# SETUP MÁY A (Ubuntu 1 - Client hiển thị GUI) cho SSH Remote + VirtualGL
# =============================================================================
# Dựa trên tài liệu: SSH/SSH-Remote.md
#
# Chức năng:
#   1. Cài đặt các gói cần thiết: openssh-client, xauth, x11-utils, wget, iproute2, netcat-openbsd
#   2. Cài đặt VirtualGL 3.1.5 (dùng file .deb offline nếu có sẵn, hoặc tự tải từ GitHub)
#   3. Tự động phát hiện X11 DISPLAY đang hoạt động trên Máy A (:1, :0, ...)
#   4. Tạo ~/bin/start-vglclient.sh và khởi động vglclient (IPv6, port 4242)
#   5. Mở port 4242/tcp trên UFW (nếu firewall đang bật)
#   6. Cấu hình ~/.ssh/config (idempotent) bật X11 Forwarding và tự động chạy
#      vglclient mỗi khi SSH (kể cả sau khi reboot Máy A)
#

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VGL_VERSION="3.1.5"
VGL_DEB_NAME="virtualgl_${VGL_VERSION}_amd64.deb"
VGL_URL="https://github.com/VirtualGL/virtualgl/releases/download/${VGL_VERSION}/${VGL_DEB_NAME}"
VGL_PORT="4242"
CUSTOM_DISPLAY=""
REMOTE_TARGET=""

info()    { echo -e "[INFO]  $*"; }
success() { echo -e "[OK]    $*"; }
warn()    { echo -e "[WARN]  $*" >&2; }
fail()    { echo -e "[ERROR] $*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Cài đặt tự động Máy A (Client hiển thị GUI) cho SSH X11 Forwarding + VirtualGL.

Cách sử dụng:
  ./setup-may-a.sh [TÙY_CHỌN] [remote_user@remote_ipv6_or_host]

Tùy chọn:
  -d, --display <:X>    Chỉ định X11 DISPLAY cục bộ trên Máy A (mặc định: tự động dò)
  -p, --port <PORT>     Port cho vglclient lắng nghe (mặc định: 4242)
  -h, --help            Hiển thị hướng dẫn này

Ví dụ:
  ./setup-may-a.sh
  ./setup-may-a.sh phongvt@2001:ee0:40e1:7322::10
  ./setup-may-a.sh --display :1 --port 4242 phongvt@2001:ee0:40e1:7322::10
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--display)
      [[ $# -lt 2 ]] && fail "Thiếu giá trị cho $1"
      CUSTOM_DISPLAY="$2"
      shift 2
      ;;
    -p|--port)
      [[ $# -lt 2 ]] && fail "Thiếu giá trị cho $1"
      VGL_PORT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      fail "Tùy chọn không hợp lệ: $1 (dùng --help để xem hướng dẫn)"
      ;;
    *)
      if [[ -n "$REMOTE_TARGET" ]]; then
        fail "Chỉ nhận tối đa 1 tham số đích SSH (đã có '$REMOTE_TARGET', thừa '$1')"
      fi
      REMOTE_TARGET="$1"
      shift
      ;;
  esac
done

if ! [[ "$VGL_PORT" =~ ^[0-9]+$ ]] || (( VGL_PORT < 1 || VGL_PORT > 65535 )); then
  fail "Port không hợp lệ: '$VGL_PORT'"
fi

# -----------------------------------------------------------------------------
# 1. Xác định user desktop thực tế & helper phân quyền
# -----------------------------------------------------------------------------
TARGET_USER="${SUDO_USER:-${USER:-$(id -un)}}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6 || true)"
if [[ -z "$TARGET_HOME" ]]; then
  TARGET_HOME="$HOME"
fi
TARGET_UID="$(id -u "$TARGET_USER")"
TARGET_GROUP="$(id -gn "$TARGET_USER")"

run_sudo() {
  if [[ $EUID -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

run_as_target() {
  if [[ $EUID -eq 0 && "$TARGET_USER" != "root" ]]; then
    sudo -u "$TARGET_USER" env HOME="$TARGET_HOME" USER="$TARGET_USER" "$@"
  else
    env HOME="$TARGET_HOME" USER="$TARGET_USER" "$@"
  fi
}

info "User mục tiêu: ${TARGET_USER} (HOME: ${TARGET_HOME})"

# -----------------------------------------------------------------------------
# 2. Cài đặt các gói hệ thống cần thiết
# -----------------------------------------------------------------------------
info "Bước 1/6: Cập nhật apt và cài các gói cần thiết..."
run_sudo apt-get update
run_sudo apt-get install -y \
  openssh-client \
  xauth \
  x11-utils \
  wget \
  iproute2 \
  netcat-openbsd
success "Đã cài xong các gói phụ thuộc."

# -----------------------------------------------------------------------------
# 3. Cài đặt VirtualGL 3.1.5
# -----------------------------------------------------------------------------
info "Bước 2/6: Kiểm tra và cài đặt VirtualGL ${VGL_VERSION}..."
if command -v vglclient >/dev/null 2>&1; then
  success "VirtualGL đã được cài sẵn: $(command -v vglclient)"
else
  DEB_PATH=""
  if [[ -s "${SCRIPT_DIR}/${VGL_DEB_NAME}" ]]; then
    DEB_PATH="${SCRIPT_DIR}/${VGL_DEB_NAME}"
    info "Tìm thấy file cài đặt local cạnh script: ${DEB_PATH}"
  elif [[ -s "${TARGET_HOME}/${VGL_DEB_NAME}" ]]; then
    DEB_PATH="${TARGET_HOME}/${VGL_DEB_NAME}"
    info "Tìm thấy file cài đặt sẵn trong HOME: ${DEB_PATH}"
  else
    DEB_PATH="${TARGET_HOME}/${VGL_DEB_NAME}"
    info "Đang tải ${VGL_DEB_NAME} từ GitHub..."
    run_as_target wget -O "$DEB_PATH" "$VGL_URL"
  fi

  if [[ ! -s "$DEB_PATH" ]]; then
    fail "File ${DEB_PATH} không tồn tại hoặc rỗng."
  fi

  if command -v file >/dev/null 2>&1; then
    file "$DEB_PATH" || true
  fi
  ls -lh "$DEB_PATH"

  run_sudo apt-get install -y "$DEB_PATH"
  command -v vglclient >/dev/null 2>&1 || fail "Cài VirtualGL thất bại: không tìm thấy lệnh vglclient."
  success "Đã cài đặt VirtualGL: $(command -v vglclient)"
fi

# -----------------------------------------------------------------------------
# 4. Tự động dò X11 DISPLAY đang hoạt động trên Máy A
# -----------------------------------------------------------------------------
info "Bước 3/6: Xác định X11 DISPLAY trên Máy A..."

probe_x_display() {
  local d="$1"
  local xa
  for xa in "${XAUTHORITY:-}" "${TARGET_HOME}/.Xauthority" "/run/user/${TARGET_UID}/gdm/Xauthority"; do
    if [[ -n "$xa" && -r "$xa" ]]; then
      if run_as_target env DISPLAY="$d" XAUTHORITY="$xa" xdpyinfo >/dev/null 2>&1; then
        echo "${d}|${xa}"
        return 0
      fi
    fi
  done
  if run_as_target env DISPLAY="$d" xdpyinfo >/dev/null 2>&1; then
    echo "${d}|"
    return 0
  fi
  return 1
}

LOCAL_DISPLAY=""
LOCAL_XAUTH=""
X11_REACHABLE=false

if [[ -n "$CUSTOM_DISPLAY" ]]; then
  if probe_res="$(probe_x_display "$CUSTOM_DISPLAY")"; then
    LOCAL_DISPLAY="${probe_res%%|*}"
    LOCAL_XAUTH="${probe_res#*|}"
    X11_REACHABLE=true
    success "X11 ${LOCAL_DISPLAY} hoạt động OK."
  else
    LOCAL_DISPLAY="$CUSTOM_DISPLAY"
    warn "Không kiểm tra được xdpyinfo trên DISPLAY=${LOCAL_DISPLAY} (có thể đang chạy từ TTY/SSH không có quyền X11). Vẫn dùng ${LOCAL_DISPLAY}."
  fi
else
  CANDIDATES=()
  if [[ -n "${DISPLAY:-}" && "${DISPLAY}" =~ ^:[0-9]+(\.[0-9]+)?$ ]]; then
    CANDIDATES+=("${DISPLAY%%.*}")
  fi
  for d in ":1" ":0" ":2"; do
    already=false
    for c in "${CANDIDATES[@]:-}"; do
      if [[ "$c" == "$d" ]]; then
        already=true
        break
      fi
    done
    if [[ "$already" == false ]]; then
      CANDIDATES+=("$d")
    fi
  done

  for d in "${CANDIDATES[@]}"; do
    if probe_res="$(probe_x_display "$d")"; then
      LOCAL_DISPLAY="${probe_res%%|*}"
      LOCAL_XAUTH="${probe_res#*|}"
      X11_REACHABLE=true
      success "Phát hiện X11 đang hoạt động tại DISPLAY=${LOCAL_DISPLAY}"
      break
    fi
  done

  if [[ -z "$LOCAL_DISPLAY" ]]; then
    LOCAL_DISPLAY=":1"
    warn "Chưa phát hiện được X server qua xdpyinfo (nếu đang đứng ở TTY hoặc chưa đăng nhập Desktop). Dùng mặc định DISPLAY=${LOCAL_DISPLAY}."
  fi
fi

# -----------------------------------------------------------------------------
# 5. Tạo ~/bin/start-vglclient.sh và khởi chạy vglclient
# -----------------------------------------------------------------------------
info "Bước 4/6: Tạo ${TARGET_HOME}/bin/start-vglclient.sh và khởi động vglclient..."

BIN_DIR="${TARGET_HOME}/bin"
START_SCRIPT="${BIN_DIR}/start-vglclient.sh"
run_as_target mkdir -p "$BIN_DIR"

cat > "$START_SCRIPT" <<EOF
#!/usr/bin/env bash
# Tự động tạo bởi setup-may-a.sh - Khởi động vglclient cho SSH VirtualGL

DEFAULT_DISPLAY="${LOCAL_DISPLAY}"
VGL_PORT="${VGL_PORT}"
EOF

cat >> "$START_SCRIPT" <<'EOF'
CURRENT_USER="$(id -un)"

# Nếu vglclient đã chạy cho user hiện tại thì thoát luôn
if pgrep -u "$CURRENT_USER" -x vglclient >/dev/null 2>&1; then
    exit 0
fi

detect_display() {
    local candidates=()
    if [[ -n "${DISPLAY:-}" && "$DISPLAY" =~ ^:[0-9]+(\.[0-9]+)?$ ]]; then
        candidates+=("${DISPLAY%%.*}")
    fi
    local d
    for d in "$DEFAULT_DISPLAY" ":1" ":0" ":2"; do
        local seen=false c
        for c in "${candidates[@]:-}"; do
            [[ "$c" == "$d" ]] && seen=true && break
        done
        [[ "$seen" == false ]] && candidates+=("$d")
    done

    local uid_val
    uid_val="$(id -u)"
    for d in "${candidates[@]}"; do
        local xa
        for xa in "${XAUTHORITY:-}" "$HOME/.Xauthority" "/run/user/${uid_val}/gdm/Xauthority"; do
            if [[ -n "$xa" && -r "$xa" ]]; then
                if DISPLAY="$d" XAUTHORITY="$xa" xdpyinfo >/dev/null 2>&1; then
                    echo "${d}|${xa}"
                    return 0
                fi
            fi
        done
        if DISPLAY="$d" xdpyinfo >/dev/null 2>&1; then
            echo "${d}|"
            return 0
        fi
    done

    echo "${DEFAULT_DISPLAY}|"
}

PROBE_RES="$(detect_display)"
LOCAL_DISPLAY="${PROBE_RES%%|*}"
LOCAL_XAUTH="${PROBE_RES#*|}"

if [[ -n "$LOCAL_XAUTH" ]]; then
    export XAUTHORITY="$LOCAL_XAUTH"
fi

DISPLAY="$LOCAL_DISPLAY" \
VGLCLIENT_IPV6=1 \
nohup vglclient \
    -display "$LOCAL_DISPLAY" \
    -port "$VGL_PORT" \
    -ipv6 \
    </dev/null > "$HOME/.vglclient.log" 2>&1 &

# Đợi ngắn để vglclient kịp mở port khi khởi động lần đầu
for _ in 1 2 3 4 5 6 7 8 9 10; do
    if ss -lnt 2>/dev/null | grep -q ":${VGL_PORT}[[:space:]]"; then
        break
    fi
    sleep 0.1
done
EOF

chown "${TARGET_USER}:${TARGET_GROUP}" "$START_SCRIPT"
chmod +x "$START_SCRIPT"
success "Đã tạo ${START_SCRIPT}"

# Khởi động lại vglclient để đảm bảo áp dụng đúng DISPLAY/port mới nhất
if pgrep -u "$TARGET_USER" -x vglclient >/dev/null 2>&1; then
  info "Đang dừng vglclient cũ để khởi động lại sạch..."
  pkill -u "$TARGET_USER" -x vglclient || true
  sleep 1
fi

if [[ "$X11_REACHABLE" == true ]]; then
  if [[ -n "$LOCAL_XAUTH" ]]; then
    run_as_target env DISPLAY="$LOCAL_DISPLAY" XAUTHORITY="$LOCAL_XAUTH" "$START_SCRIPT"
  else
    run_as_target env DISPLAY="$LOCAL_DISPLAY" "$START_SCRIPT"
  fi
  sleep 1

  if pgrep -u "$TARGET_USER" -x vglclient >/dev/null 2>&1; then
    success "vglclient đang chạy:"
    pgrep -u "$TARGET_USER" -a vglclient || true
  else
    warn "vglclient chưa chạy được. Log (${TARGET_HOME}/.vglclient.log):"
    tail -n 20 "${TARGET_HOME}/.vglclient.log" 2>/dev/null || true
  fi

  if ss -lntp 2>/dev/null | grep -q ":${VGL_PORT}[[:space:]]"; then
    success "Port ${VGL_PORT} đang lắng nghe:"
    ss -lntp 2>/dev/null | grep ":${VGL_PORT}[[:space:]]" || true
  else
    warn "Chưa thấy port ${VGL_PORT} lắng nghe qua ss -lntp. Kiểm tra ${TARGET_HOME}/.vglclient.log."
  fi
else
  warn "Bỏ qua bước khởi động ngay vglclient vì chưa thấy X11 session khả dụng. Khi SSH từ môi trường Desktop, ~/.ssh/config sẽ tự động chạy ${START_SCRIPT}."
fi

# Mở firewall UFW nếu đang bật
if command -v ufw >/dev/null 2>&1; then
  if run_sudo ufw status 2>/dev/null | grep -qi "^Status: active"; then
    info "Phát hiện UFW đang bật -> mở port ${VGL_PORT}/tcp..."
    run_sudo ufw allow "${VGL_PORT}/tcp"
    success "Đã thêm rule UFW allow ${VGL_PORT}/tcp."
  fi
fi

# -----------------------------------------------------------------------------
# 6. Kiểm tra IPv6 & Cấu hình ~/.ssh/config
# -----------------------------------------------------------------------------
info "Bước 5/6: Kiểm tra địa chỉ IPv6 của Máy A..."
IPV6_LIST="$(ip -6 addr show scope global 2>/dev/null | awk '/inet6/ {print $2}' || true)"
if [[ -n "$IPV6_LIST" ]]; then
  echo "$IPV6_LIST" | while IFS= read -r addr; do
    echo "        - $addr"
  done
else
  warn "Không tìm thấy địa chỉ IPv6 global trên Máy A. Đảm bảo IPv6 được bật để Máy B kết nối tới vglclient."
fi

info "Bước 6/6: Cấu hình ${TARGET_HOME}/.ssh/config (idempotent)..."
SSH_DIR="${TARGET_HOME}/.ssh"
SSH_CONFIG="${SSH_DIR}/config"
run_as_target mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
chown "${TARGET_USER}:${TARGET_GROUP}" "$SSH_DIR"

if [[ ! -f "$SSH_CONFIG" ]]; then
  run_as_target touch "$SSH_CONFIG"
fi
chmod 600 "$SSH_CONFIG"
chown "${TARGET_USER}:${TARGET_GROUP}" "$SSH_CONFIG"

START_MARK="# >>> VGL-CLIENT-AUTO-SETUP >>>"
END_MARK="# <<< VGL-CLIENT-AUTO-SETUP <<<"

TMP_SSH_CONFIG="$(mktemp)"
trap 'rm -f "$TMP_SSH_CONFIG"' EXIT

awk -v start="$START_MARK" -v end="$END_MARK" '
  $0 == start { skip=1; next }
  $0 == end   { skip=0; next }
  !skip       { lines[++n] = $0 }
  END {
    while (n > 0 && lines[n] ~ /^[[:space:]]*$/) n--
    for (i = 1; i <= n; i++) print lines[i]
  }
' "$SSH_CONFIG" > "$TMP_SSH_CONFIG"

# Đảm bảo có dòng trống ngăn cách nếu file không rỗng
if [[ -s "$TMP_SSH_CONFIG" ]]; then
  printf '\n' >> "$TMP_SSH_CONFIG"
fi

{
  echo "$START_MARK"
  if [[ -n "$REMOTE_TARGET" ]]; then
    if [[ "$REMOTE_TARGET" == *@* ]]; then
      REMOTE_USER="${REMOTE_TARGET%%@*}"
      REMOTE_HOST="${REMOTE_TARGET#*@}"
    else
      REMOTE_USER=""
      REMOTE_HOST="$REMOTE_TARGET"
    fi

    echo "Host ubuntu-remote"
    echo "    HostName ${REMOTE_HOST}"
    if [[ -n "$REMOTE_USER" ]]; then
      echo "    User ${REMOTE_USER}"
    fi
    echo "    Port 22"
    if [[ "$REMOTE_HOST" == *:* ]]; then
      echo "    AddressFamily inet6"
    fi
    echo "    ForwardX11 yes"
    echo "    ForwardX11Trusted yes"
    echo ""
  fi

  echo "Host *"
  echo "    ForwardX11 yes"
  echo "    ForwardX11Trusted yes"
  echo "    PermitLocalCommand yes"
  echo "    LocalCommand ~/bin/start-vglclient.sh"
  echo "$END_MARK"
} >> "$TMP_SSH_CONFIG"

cat "$TMP_SSH_CONFIG" > "$SSH_CONFIG"
chown "${TARGET_USER}:${TARGET_GROUP}" "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"
success "Đã cập nhật ${SSH_CONFIG}"

# -----------------------------------------------------------------------------
# 7. Hướng dẫn bước tiếp theo
# -----------------------------------------------------------------------------
cat <<EOF

===============================================================================
 HOÀN TẤT SETUP TRÊN MÁY A (Client hiển thị GUI)
===============================================================================
  - VirtualGL      : $(command -v vglclient)
  - DISPLAY cục bộ : ${LOCAL_DISPLAY}
  - vglclient port : ${VGL_PORT} (IPv6)
  - Auto-start     : ${START_SCRIPT}
  - SSH Config     : ${SSH_CONFIG}

BƯỚC TIẾP THEO:
1. SSH sang Máy B (từ Máy A):
EOF

if [[ -n "$REMOTE_TARGET" ]]; then
  echo "     ssh ubuntu-remote"
else
  echo "     ssh -Y <username>@<IPv6-May-B>"
fi

cat <<'EOF'

2. Trên Máy B, kiểm tra nhanh X11 forwarding (phải là localhost:10.0 hoặc tương tự, KHÔNG được là :0 hay :1):
     echo $DISPLAY

3. Trên Máy B, tạo và chạy remote-run.sh trong thư mục ứng dụng:
cat <<'RUNEOF' > remote-run.sh
#!/bin/bash
vglrun -d :1 \
  -c jpeg \
  -q 30 \
  -np 8 \
  -fps 60 \
  ./run.sh
RUNEOF
chmod +x remote-run.sh
./remote-run.sh
===============================================================================
EOF
