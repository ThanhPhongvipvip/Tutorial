#!/bin/bash
# Chạy tự động MỘT LẦN khi volume dữ liệu PostgreSQL còn trống
# (cơ chế /docker-entrypoint-initdb.d của image postgres).
# Truyền mật khẩu role ứng dụng cho schema.sql qua biến psql để không hard-code vào SQL.
set -euo pipefail

: "${APP_DB_PASSWORD:?APP_DB_PASSWORD is not set}"

psql -v ON_ERROR_STOP=1 \
     -v app_pw="$APP_DB_PASSWORD" \
     --username "$POSTGRES_USER" \
     --dbname "$POSTGRES_DB" \
     -f /sql/schema.sql
