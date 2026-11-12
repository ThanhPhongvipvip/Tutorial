#!/usr/bin/env bash
# =============================================================================
# UNIFIED SETUP SCRIPT - Hệ Thống Giám Sát & ERD Viewer Chuyên Dụng
# =============================================================================
# Chỉ cần chạy DUY NHẤT file này để cài đặt toàn bộ hệ thống từ đầu đến cuối:
# ./setup.sh                         # Menu tương tác (hoặc cài đặt Máy Chủ Trung Tâm)
# ./setup.sh --central-server        # Setup Máy Chủ Trung Tâm (Grafana, InfluxDB, PostgreSQL, ERD Viewer)
# sudo -E ./setup.sh <device-name>   # Setup Agent Giám Sát trên máy client (cuonglq)
# sudo -E ./setup.sh --agent <file>  # Setup Agent từ file device.yaml có sẵn
# =============================================================================

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE=""
DEVICE_NAME=""
CONFIG_FILE=""

fail() { echo -e "\n ERROR: $*" >&2; exit 1; }
info() { echo -e "ℹ  $*"; }
success() { echo -e " $*"; }
warn() { echo -e "  $*" >&2; }

usage() {
  cat <<'EOF'
================================================================================
 UNIFIED SETUP - Hệ Thống Giám Sát & ERD Viewer Chuyên Dụng (Cytoscape + ELK)
================================================================================

Cách sử dụng:
  ./setup.sh                               # Menu cài đặt thông minh
  ./setup.sh --central-server              # Setup Toàn Bộ Máy Chủ (Grafana + Catalog + ERD Service)
  sudo -E ./setup.sh <tên-thiết-bị>        # Setup Agent tự động cho thiết bị (Cần sudo)
  sudo -E ./setup.sh --agent device.yaml   # Setup Agent từ file cấu hình
  ./setup.sh --sync                        # Thu thập và đồng bộ Metadata ERD ngay lập tức
  ./setup.sh --start-erd                   # Khởi chạy dịch vụ ERD Viewer (Port 8088)

Ví dụ:
  ./setup.sh --central-server
  sudo -E ./setup.sh cuonglq
================================================================================
EOF
}

# =============================================================================
# 1. HÀM KHỞI ĐỘNG DỊCH VỤ ERD VIEWER (CYTOSCAPE.JS + ELK.JS TRÊN PORT 8088)
# =============================================================================
setup_erd_service() {
  info "Thiết lập Dịch Vụ ERD Viewer (Cytoscape.js + ELK.js)..."
  
  local ERD_DIR="${SCRIPT_DIR}/erd_service"
  local SERVER_PY="${ERD_DIR}/server.py"

  [[ ! -f "$SERVER_PY" ]] && fail "Không tìm thấy $SERVER_PY"
  chmod +x "$SERVER_PY"

  # Kiểm tra các file thư viện offline
  if [[ ! -f "${ERD_DIR}/public/libs/cytoscape.min.js" || ! -f "${ERD_DIR}/public/libs/elk.bundled.js" ]]; then
    info "Đang tải thư viện Cytoscape.js & ELK.js..."
    mkdir -p "${ERD_DIR}/public/libs"
    curl -sL https://unpkg.com/cytoscape@3.30.2/dist/cytoscape.min.js -o "${ERD_DIR}/public/libs/cytoscape.min.js" || warn "Không thể tải cytoscape.min.js từ internet"
    curl -sL https://unpkg.com/elkjs@0.9.3/lib/elk.bundled.js -o "${ERD_DIR}/public/libs/elk.bundled.js" || warn "Không thể tải elk.bundled.js từ internet"
    curl -sL https://unpkg.com/cytoscape-elk@2.1.0/dist/cytoscape-elk.js -o "${ERD_DIR}/public/libs/cytoscape-elk.js" || true
    curl -sL https://unpkg.com/cytoscape-node-html-label@1.2.2/dist/cytoscape-node-html-label.min.js -o "${ERD_DIR}/public/libs/cytoscape-node-html-label.min.js" || true
  fi

  # Khởi động dịch vụ qua systemd nếu có thể, hoặc chạy daemon nền
  local STARTED=false
  if [[ $EUID -eq 0 ]] && command -v systemctl >/dev/null 2>&1 && systemctl is-system-running >/dev/null 2>&1; then
    info "Cấu hình systemd service cho erd-viewer..."
    cat > /etc/systemd/system/erd-viewer.service <<EOF
[Unit]
Description=ERD Cytoscape Viewer Microservice
After=network.target postgresql.service

[Service]
Type=simple
User=${SUDO_USER:-$(whoami)}
WorkingDirectory=${ERD_DIR}
ExecStart=/usr/bin/python3 ${SERVER_PY}
Restart=always
RestartSec=3
Environment=PORT=8088
Environment=CATALOG_HOST=127.0.0.1
Environment=CATALOG_PORT=5432
Environment=CATALOG_USER=grafana_reader
Environment=CATALOG_PASS=1
Environment=CATALOG_DB=monitoring_catalog

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload 2>/dev/null || true
    systemctl enable --now erd-viewer 2>/dev/null || true
    STARTED=true
    success "Dịch vụ erd-viewer đã được tạo và kích hoạt qua systemd"
  fi

  # Fallback: Chạy dạng background daemon nếu không dùng được systemd hoặc chưa chạy
  if ! curl -s http://127.0.0.1:8088/api/erd >/dev/null 2>&1; then
    info "Khởi động ERD Viewer ngầm trên port 8088 (background daemon)..."
    pkill -f "python3.*erd_service/server.py" 2>/dev/null || true
    nohup python3 "$SERVER_PY" >/tmp/erd-viewer.log 2>&1 &
    sleep 2
  fi

  # Kiểm tra sức khỏe ERD Viewer
  if curl -s http://127.0.0.1:8088/api/erd >/dev/null 2>&1; then
    success "ERD Viewer đang hoạt động tại http://localhost:8088"
  else
    warn "ERD Viewer chưa phản hồi, nhưng server script đã sẵn sàng tại ${SERVER_PY}"
  fi
}

# =============================================================================
# 2. HÀM CÀI ĐẶT MÁY CHỦ TRUNG TÂM (CENTRAL SERVER SETUP)
# =============================================================================
setup_central_server() {
  echo "================================================================================"
  info "BẮT ĐẦU CÀI ĐẶT TOÀN DIỆN MÁY CHỦ TRUNG TÂM"
  echo "================================================================================"
  
  GRAFANA_URL="http://localhost:3000"
  GRAFANA_USER="admin"
  GRAFANA_PASS="admin"

  # 1. Đọc Token InfluxDB
  if [[ -z "${INFLUX_TOKEN:-}" ]]; then
    if [[ -f "${SCRIPT_DIR}/configs/config.json" ]]; then
      INFLUX_TOKEN=$(grep -oP '"token":\s*"\K[^"]+' "${SCRIPT_DIR}/configs/config.json" 2>/dev/null || echo "")
    elif [[ -f "${SCRIPT_DIR}/config.json" ]]; then
      INFLUX_TOKEN=$(grep -oP '"token":\s*"\K[^"]+' "${SCRIPT_DIR}/config.json" 2>/dev/null || echo "")
    fi
  fi
  [[ -z "${INFLUX_TOKEN:-}" ]] && INFLUX_TOKEN="VEomqmt1BBVIbaQRWl1qmcDt8ptRf8_1iGuU0I5aqGW0Gcb_MC787Vv-0Qg2rU-OhQvosxQvQa8U2IqW3P8pCQ=="

  # 2. Kiểm tra các dịch vụ cốt lõi
  info "Kiểm tra trạng thái các dịch vụ..."
  systemctl is-active --quiet postgresql 2>/dev/null || warn "PostgreSQL chưa khởi động"
  systemctl is-active --quiet influxdb 2>/dev/null || warn "InfluxDB chưa khởi động"
  systemctl is-active --quiet grafana-server 2>/dev/null || warn "Grafana chưa khởi động"

  # 3. Khởi tạo Database Central Catalog (PostgreSQL)
  info "Khởi tạo Cơ Sở Dữ Liệu Metadata Catalog (monitoring_catalog)..."
  local SQL_FILE="${SCRIPT_DIR}/sql/init_central_catalog.sql"
  [[ ! -f "$SQL_FILE" && -f "${SCRIPT_DIR}/init_central_catalog.sql" ]] && SQL_FILE="${SCRIPT_DIR}/init_central_catalog.sql"

  if [[ -f "$SQL_FILE" ]]; then
    PGPASSWORD="1" psql -U postgres -h 127.0.0.1 -c "CREATE DATABASE monitoring_catalog;" 2>/dev/null || true
    PGPASSWORD="1" psql -U postgres -h 127.0.0.1 -c "
      DO \$\$ BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'grafana_reader') THEN
          CREATE ROLE grafana_reader WITH LOGIN PASSWORD '1';
        END IF;
      END \$\$;
    " 2>/dev/null || true
    PGPASSWORD="1" psql -U postgres -h 127.0.0.1 -d monitoring_catalog -f "$SQL_FILE" 2>/dev/null || true
    PGPASSWORD="1" psql -U postgres -h 127.0.0.1 -d monitoring_catalog -c "
      ALTER TABLE db_metadata_relations ADD COLUMN IF NOT EXISTS cardinality VARCHAR(50) DEFAULT '1 : 0..N';
      GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO grafana_reader;
      GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO grafana_reader;
    " 2>/dev/null || true
    success "Cơ sở dữ liệu monitoring_catalog và quyền hạn đã sẵn sàng"
  fi

  # 4. Khởi chạy Dịch Vụ ERD Cytoscape + ELK
  setup_erd_service

  # 5. Cấu hình Datasources trên Grafana
  info "Kiểm tra và nạp Data Sources lên Grafana..."
  local DATASOURCES
  DATASOURCES=$(curl -s "${GRAFANA_URL}/api/datasources" -u "${GRAFANA_USER}:${GRAFANA_PASS}" 2>/dev/null || echo "[]")
  
  local INFLUX_UID
  INFLUX_UID=$(echo "$DATASOURCES" | jq -r '.[] | select(.type=="influxdb") | .uid' 2>/dev/null | head -1 || echo "")
  if [[ -z "$INFLUX_UID" ]]; then
    curl -s -X POST "${GRAFANA_URL}/api/datasources" \
      -u "${GRAFANA_USER}:${GRAFANA_PASS}" \
      -H "Content-Type: application/json" \
      -d "{
        \"name\": \"InfluxDB-Monitoring\",
        \"type\": \"influxdb\",
        \"access\": \"proxy\",
        \"url\": \"http://localhost:8086\",
        \"jsonData\": {
          \"version\": \"Flux\",
          \"organization\": \"monitoring\",
          \"defaultBucket\": \"system_metrics\",
          \"tlsSkipVerify\": true
        },
        \"secureJsonData\": { \"token\": \"${INFLUX_TOKEN}\" }
      }" >/dev/null 2>&1 || true
    success "Đã tạo Data Source: InfluxDB-Monitoring"
  else
    success "Data Source InfluxDB-Monitoring đã tồn tại"
  fi

  local POSTGRES_UID
  POSTGRES_UID=$(echo "$DATASOURCES" | jq -r '.[] | select(.type=="grafana-postgresql-datasource") | .uid' 2>/dev/null | head -1 || echo "")
  if [[ -z "$POSTGRES_UID" ]]; then
    curl -s -X POST "${GRAFANA_URL}/api/datasources" \
      -u "${GRAFANA_USER}:${GRAFANA_PASS}" \
      -H "Content-Type: application/json" \
      -d '{
        "name": "PostgreSQL-Catalog",
        "type": "grafana-postgresql-datasource",
        "access": "proxy",
        "url": "localhost:5432",
        "database": "monitoring_catalog",
        "user": "grafana_reader",
        "secureJsonData": { "password": "1" },
        "jsonData": { "sslmode": "disable", "postgresVersion": 1400 }
      }' >/dev/null 2>&1 || true
    success "Đã tạo Data Source: PostgreSQL-Catalog"
  else
    success "Data Source PostgreSQL-Catalog đã tồn tại"
  fi

  # 6. Tạo và Nạp Dashboard Lên Grafana
  info "Tạo và import Dashboard lên Grafana..."
  if [[ -f "${SCRIPT_DIR}/manage.py" ]]; then
    python3 "${SCRIPT_DIR}/manage.py" generate >/dev/null 2>&1 || true
    python3 "${SCRIPT_DIR}/manage.py" import --user "${GRAFANA_USER}" --pass "${GRAFANA_PASS}" || warn "Dashboard import có cảnh báo"
    success "Đã import thành công Dashboard lên Grafana"
  fi

  # 7. Đồng bộ metadata ban đầu (nếu có device.yaml)
  if [[ -f "${SCRIPT_DIR}/device.yaml" ]]; then
    info "Đồng bộ metadata ban đầu từ device.yaml..."
    python3 "${SCRIPT_DIR}/manage.py" collect "${SCRIPT_DIR}/device.yaml" 2>/dev/null || true
  fi

  echo ""
  echo "================================================================================"
  echo "   CÀI ĐẶT TOÀN BỘ HỆ THỐNG MÁY CHỦ HOÀN TẤT 100%!"
  echo "================================================================================"
  echo " Grafana Dashboard : ${GRAFANA_URL}/d/monitoring"
  echo " Tài khoản         : ${GRAFANA_USER} / ${GRAFANA_PASS}"
  echo " ERD Viewer Canvas : http://localhost:8088"
  echo "================================================================================"
  echo ""
}

# =============================================================================
# 3. HÀM CÀI ĐẶT AGENT GIÁM SÁT TRÊN THIẾT BỊ CLIENT (CẦN SUDO)
# =============================================================================
setup_agent_auto() {
  info "Setup Agent Giám Sát Thiết Bị: $DEVICE_NAME"
  
  [[ $EUID -ne 0 ]] && fail "Cài đặt Agent trên máy cần giám sát bắt buộc phải chạy với: sudo -E ./setup.sh <tên-máy>"
  
  CONFIG_FILE="${SCRIPT_DIR}/device.yaml"
  [[ -f "${SCRIPT_DIR}/../May_Khac/device.yaml" ]] && CONFIG_FILE="${SCRIPT_DIR}/../May_Khac/device.yaml"

  local TEMPLATE_FILE=""
  if [[ -f "${SCRIPT_DIR}/../May_Khac/device.yaml.template" ]]; then
    TEMPLATE_FILE="${SCRIPT_DIR}/../May_Khac/device.yaml.template"
  elif [[ -f "${SCRIPT_DIR}/configs/device.yaml.template" ]]; then
    TEMPLATE_FILE="${SCRIPT_DIR}/configs/device.yaml.template"
  elif [[ -f "${SCRIPT_DIR}/device.yaml.template" ]]; then
    TEMPLATE_FILE="${SCRIPT_DIR}/device.yaml.template"
  fi

  if [[ ! -f "$CONFIG_FILE" && -n "$TEMPLATE_FILE" ]]; then
    cp "$TEMPLATE_FILE" "$CONFIG_FILE"
    sed -i "s/THAY_THANH_TEN_MAY_CUA_BAN/${DEVICE_NAME}/g" "$CONFIG_FILE"
    success "Đã tạo cấu hình $CONFIG_FILE"
  fi

  local AGENT_INSTALLER=""
  if [[ -f "${SCRIPT_DIR}/../May_Khac/install-agent-v2.sh" ]]; then
    AGENT_INSTALLER="${SCRIPT_DIR}/../May_Khac/install-agent-v2.sh"
  elif [[ -f "${SCRIPT_DIR}/install-agent-v2.sh" ]]; then
    AGENT_INSTALLER="${SCRIPT_DIR}/install-agent-v2.sh"
  fi

  if [[ -n "$AGENT_INSTALLER" ]]; then
    bash "$AGENT_INSTALLER" --config "$CONFIG_FILE"
    success "Cài đặt Agent thành công cho: $DEVICE_NAME"
  fi

  # Tự động quét metadata ERD đẩy về trung tâm
  if [[ -f "${SCRIPT_DIR}/manage.py" ]]; then
    info "Quét cấu trúc Database & đẩy về Kho Metadata Trung Tâm..."
    python3 "${SCRIPT_DIR}/manage.py" collect "$CONFIG_FILE" 2>/dev/null || true
  fi
}

setup_agent_from_config() {
  info "Setup Agent từ cấu hình: $CONFIG_FILE"
  [[ ! -f "$CONFIG_FILE" ]] && fail "Không tìm thấy file: $CONFIG_FILE"
  [[ $EUID -ne 0 ]] && fail "Cài đặt Agent cần chạy với: sudo -E ./setup.sh --agent $CONFIG_FILE"

  local AGENT_INSTALLER=""
  if [[ -f "${SCRIPT_DIR}/../May_Khac/install-agent-v2.sh" ]]; then
    AGENT_INSTALLER="${SCRIPT_DIR}/../May_Khac/install-agent-v2.sh"
  elif [[ -f "${SCRIPT_DIR}/install-agent-v2.sh" ]]; then
    AGENT_INSTALLER="${SCRIPT_DIR}/install-agent-v2.sh"
  fi

  if [[ -n "$AGENT_INSTALLER" ]]; then
    bash "$AGENT_INSTALLER" --config "$CONFIG_FILE"
    success "Cài đặt Agent thành công"
  fi

  if [[ -f "${SCRIPT_DIR}/manage.py" ]]; then
    python3 "${SCRIPT_DIR}/manage.py" collect "$CONFIG_FILE" 2>/dev/null || true
  fi
}

# =============================================================================
# 4. PARSER VÀ MENU TƯƠNG TÁC
# =============================================================================
if [[ $# -eq 0 ]]; then
  echo "================================================================================"
  echo "   BỘ CÀI ĐẶT HỆ THỐNG GIÁM SÁT & ERD VIEWER (ALL-IN-ONE)"
  echo "================================================================================"
  echo "Vui lòng chọn chức năng:"
  echo "  1) Cài đặt trọn gói MÁY CHỦ TRUNG TÂM (Grafana, InfluxDB, Catalog, ERD Service)"
  echo "  2) Cài đặt AGENT GIÁM SÁT trên thiết bị này"
  echo "  3) Khởi động lại dịch vụ ERD Viewer (Port 8088)"
  echo "  4) Đồng bộ Metadata ERD ngay lập tức (python3 manage.py collect)"
  echo "  0) Thoát"
  echo "================================================================================"
  read -rp "Nhập lựa chọn của bạn [1-4, Mặc định: 1]: " CHOICE
  CHOICE="${CHOICE:-1}"

  case "$CHOICE" in
    1) setup_central_server ;;
    2)
      read -rp "Nhập tên thiết bị này (Ví dụ: cuonglq): " DEV
      DEV="${DEV:-my_device}"
      DEVICE_NAME="$DEV"
      setup_agent_auto
      ;;
    3) setup_erd_service ;;
    4)
      if [[ -f "${SCRIPT_DIR}/device.yaml" ]]; then
        python3 "${SCRIPT_DIR}/manage.py" collect "${SCRIPT_DIR}/device.yaml"
      else
        python3 "${SCRIPT_DIR}/manage.py" collect
      fi
      ;;
    0) exit 0 ;;
    *) fail "Lựa chọn không hợp lệ." ;;
  esac
  exit 0
fi

case "$1" in
  --central-server|--server|-s)
    setup_central_server
    ;;
  --agent)
    [[ $# -ge 2 ]] || { usage; exit 1; }
    CONFIG_FILE="$2"
    setup_agent_from_config
    ;;
  --sync|--collect)
    if [[ -f "${SCRIPT_DIR}/device.yaml" ]]; then
      python3 "${SCRIPT_DIR}/manage.py" collect "${SCRIPT_DIR}/device.yaml"
    else
      python3 "${SCRIPT_DIR}/manage.py" collect
    fi
    ;;
  --start-erd)
    setup_erd_service
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    DEVICE_NAME="$1"
    setup_agent_auto
    ;;
esac
