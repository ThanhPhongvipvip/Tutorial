#!/usr/bin/env bash
# Build + chạy demo Qt login với PostgreSQL 16 trong Docker.
# Chỉ cần:  ./run.sh
#
#   ./run.sh          Build image, khởi động PostgreSQL và mở ứng dụng Qt
#   ./run.sh test     Chạy bộ kiểm thử tự động (không cần giao diện)
#   ./run.sh psql     Mở psql vào database (quyền superuser)
#   ./run.sh logs     Xem log PostgreSQL
#   ./run.sh down     Dừng các container (giữ dữ liệu)
#   ./run.sh reset    Dừng và XÓA toàn bộ dữ liệu + file .env
#   ./run.sh help     Hiện hướng dẫn này
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

PROJECT_VOLUME="qt-login-pg_pgdata"   # khớp với `name:` trong docker-compose.yml

die()  { echo "Lỗi: $*" >&2; exit 1; }
info() { echo ">> $*"; }
warn() { echo "Cảnh báo: $*" >&2; }

usage() { sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; }

# ---------------------------------------------------------------- kiểm tra Docker
command -v docker >/dev/null 2>&1 \
    || die "Chưa cài Docker. Xem https://docs.docker.com/get-docker/"

if docker compose version >/dev/null 2>&1; then
    COMPOSE=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE=(docker-compose)
else
    die "Cần Docker Compose (lệnh 'docker compose' hoặc 'docker-compose')."
fi

docker info >/dev/null 2>&1 \
    || die "Docker daemon chưa chạy hoặc tài khoản chưa có quyền (Linux: sudo usermod -aG docker \$USER rồi đăng nhập lại)."

# ---------------------------------------------------------------- file .env
rand_hex() { od -An -N16 -tx1 /dev/urandom | tr -d ' \n'; }

ensure_env() {
    if [[ -f .env ]]; then
        return
    fi
    if docker volume inspect "$PROJECT_VOLUME" >/dev/null 2>&1; then
        die "Đã có dữ liệu DB cũ nhưng thiếu file .env (mật khẩu không còn khớp). Chạy './run.sh reset' để tạo lại từ đầu."
    fi
    {
        echo "POSTGRES_USER=postgres"
        echo "POSTGRES_PASSWORD=$(rand_hex)"
        echo "POSTGRES_DB=appdb"
        echo "APP_DB_PASSWORD=$(rand_hex)"
    } > .env
    chmod 600 .env
    info "Đã tạo .env với mật khẩu ngẫu nhiên."
}

# ---------------------------------------------------------------- cấu hình hiển thị (X11)
# Đặt các biến HOST_UID, HOST_GID, DISPLAY_FOR_CONTAINER, XAUTH_FILE cho docker compose.
setup_display() {
    HOST_UID="$(id -u)"
    HOST_GID="$(id -g)"
    export HOST_UID HOST_GID

    local os
    os="$(uname -s)"

    if [[ "$os" == "Darwin" ]]; then
        # macOS: cần XQuartz (https://www.xquartz.org), bật "Allow connections from network clients".
        local xhost_bin="/opt/X11/bin/xhost"
        [[ -x "$xhost_bin" ]] || die "Chưa có XQuartz. Cài: brew install --cask xquartz, mở XQuartz, bật 'Allow connections from network clients', đăng xuất/đăng nhập lại."
        "$xhost_bin" +localhost >/dev/null 2>&1 || warn "Không chạy được 'xhost +localhost'; hãy mở XQuartz trước."
        export DISPLAY_FOR_CONTAINER="host.docker.internal:0"
        export XAUTH_FILE=/dev/null
        return
    fi

    [[ -n "${DISPLAY:-}" ]] \
        || die "Không có \$DISPLAY. Hãy chạy trong phiên đồ họa (X11/XWayland, hoặc WSL2 có WSLg). Chạy kiểm thử không giao diện: ./run.sh test"
    export DISPLAY_FOR_CONTAINER="$DISPLAY"

    # Cho phép đúng người dùng hiện tại (không mở cho mọi người) truy cập X server.
    if command -v xhost >/dev/null 2>&1; then
        xhost "+SI:localuser:$(id -un)" >/dev/null 2>&1 \
            || warn "xhost thất bại; nếu cửa sổ không hiện, kiểm tra quyền truy cập X server."
    fi

    local xauth="${XAUTHORITY:-$HOME/.Xauthority}"
    if [[ -f "$xauth" ]]; then
        export XAUTH_FILE="$xauth"
    else
        export XAUTH_FILE=/dev/null
    fi
}

# ---------------------------------------------------------------- lệnh
cmd="${1:-run}"

case "$cmd" in
    help|-h|--help)
        usage
        ;;

    down)
        POSTGRES_PASSWORD=x APP_DB_PASSWORD=x "${COMPOSE[@]}" down
        ;;

    reset)
        POSTGRES_PASSWORD=x APP_DB_PASSWORD=x "${COMPOSE[@]}" down -v
        rm -f .env
        info "Đã xóa container, dữ liệu và .env."
        ;;

    logs)
        ensure_env
        "${COMPOSE[@]}" logs -f db
        ;;

    psql)
        ensure_env
        info "Khởi động PostgreSQL..."
        "${COMPOSE[@]}" up -d --wait db
        "${COMPOSE[@]}" exec db sh -c 'exec psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"'
        ;;

    test)
        ensure_env
        setup_display_test() { export HOST_UID="$(id -u)" HOST_GID="$(id -g)" XAUTH_FILE=/dev/null; }
        setup_display_test
        info "Build image (lần đầu mất vài phút)..."
        "${COMPOSE[@]}" build app
        info "Khởi động PostgreSQL và chạy kiểm thử..."
        "${COMPOSE[@]}" run --rm -T -e QT_QPA_PLATFORM=offscreen app --selftest
        ;;

    run)
        ensure_env
        setup_display
        info "Build image (lần đầu mất vài phút)..."
        "${COMPOSE[@]}" build app
        info "Khởi động PostgreSQL 16 và mở ứng dụng..."
        "${COMPOSE[@]}" run --rm app
        info "Ứng dụng đã đóng. PostgreSQL vẫn chạy nền; dừng bằng './run.sh down'."
        ;;

    *)
        usage >&2
        exit 2
        ;;
esac
