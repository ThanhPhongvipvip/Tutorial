# Hướng Dẫn Cài Đặt Hệ Thống Giám Sát

## Tổng Quan

Hướng dẫn cài đặt từng bước để xây dựng hệ thống giám sát đầy đủ.

**Thời gian:** ~60 phút cho lần đầu

**Kiến trúc:**
```
Server Trung Tâm: InfluxDB + Grafana
Các Máy Agent: Telegraf agent
```

---

## Phần 1: Cài Đặt InfluxDB (Server Trung Tâm)

### Bước 1.1: Cài InfluxDB

Trên máy server trung tâm (ví dụ: 192.168.1.53):

```bash
# Add InfluxData repository
set -Eeuo pipefail

# 2. Cài công cụ cần thiết
sudo apt-get update
sudo apt-get install -y curl gnupg

# 3. Tạo thư mục lưu GPG key
sudo install -d -m 0755 /etc/apt/keyrings

# 4. Tải GPG key chính thức
cd /tmp
curl -fsSL -o influxdata-archive.key \
    https://repos.influxdata.com/influxdata-archive.key

# 5. Xác minh fingerprint
FINGERPRINT=$(gpg --show-keys --with-colons influxdata-archive.key \
    | awk -F: '$1 == "fpr" {print $10; exit}')

EXPECTED="24C975CBA61A024EE1B631787C3D57159FC2F927"

if [[ "$FINGERPRINT" != "$EXPECTED" ]]; then
    echo "ERROR: InfluxData GPG fingerprint không hợp lệ!"
    exit 1
fi

echo "GPG fingerprint verified: $FINGERPRINT"

# 6. Cài GPG key
gpg --dearmor --yes \
    --output /tmp/influxdata-archive.gpg \
    influxdata-archive.key

sudo install -o root -g root -m 0644 \
    /tmp/influxdata-archive.gpg \
    /etc/apt/keyrings/influxdata-archive.gpg

# 7. Thêm InfluxData repository
echo 'deb [signed-by=/etc/apt/keyrings/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main' \
    | sudo tee /etc/apt/sources.list.d/influxdata.list

# 8. Cập nhật repository
sudo apt-get update

# 9. Cài đặt InfluxDB 2
sudo apt-get install -y influxdb2

# 10. Khởi động cùng hệ thống
sudo systemctl enable --now influxdb

# 11. Kiểm tra
sudo systemctl status influxdb --no-pager
influxd version
curl -s http://localhost:8086/health
```

### Bước 1.2: Cấu Hình InfluxDB Lần Đầu

```bash
# Truy cập: http://192.168.1.53:8086
```

Trong trình duyệt:
1. **Username**: admin
2. **Password**: password_manh (ít nhất 8 ký tự)
3. **Organization**: monitoring
4. **Bucket**: system_metrics (bucket đầu tiên)
5. Click **Continue**

### Bước 1.3: Tạo Thêm Buckets

```bash
# Sau khi login vào InfluxDB UI:
# Settings → Buckets → Create Bucket
```

Tạo 2 buckets:
1. **device_csv** - Lưu CSV data
2. **device_database** - Lưu PostgreSQL metrics

### Bước 1.4: Tạo Token

```bash
# InfluxDB UI → Settings → API Tokens → Generate API Token
# Chọn: All Access API Token
```

**Lưu token này** - sẽ dùng để cấu hình agent:
```
Token ví dụ: xyzABC123...456DEF (dài ~100 ký tự)
```

### Bước 1.5: Kiểm Tra

```bash
# Kiểm tra InfluxDB đã chạy
systemctl status influxdb

# Test kết nối
curl -I http://192.168.1.53:8086/health
# Output: HTTP/1.1 200 OK
```

---

## Phần 2: Cài Đặt Grafana (Server Trung Tâm)

### Bước 2.1: Cài Grafana

Trên cùng máy server (hoặc máy khác):

```bash
# Add Grafana repository
sudo apt-get install -y software-properties-common
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -

# Install Grafana
sudo apt-get update
sudo apt-get install -y grafana

# Start Grafana
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
```

### Bước 2.2: Login Grafana Lần Đầu

```bash
# Truy cập: http://192.168.1.53:3000
```

Login:
- **Username**: admin
- **Password**: admin
- Sau đó đổi password mới

### Bước 2.3: Kết Nối Grafana Với InfluxDB

1. **Vào: Configuration** (⚙️) → **Data Sources** → **Add data source**
2. Chọn **InfluxDB**
3. Cấu hình:
   ```
   Name: InfluxDB-Monitoring
   Query Language: Flux
   URL: http://localhost:8086 (nếu cùng máy)
        http://192.168.1.53:8086 (nếu khác máy)
   
   Custom HTTP Headers:
   + Add Header
   Header: Authorization
   Value: Token xyzABC123...456DEF (token từ bước 1.4)
   
   Organization: monitoring
   Default Bucket: system_metrics
   ```
4. Click **Save & Test** → Thấy "datasource is working"

---

## Phần 3: Cài Agent Trên Các Máy

### Bước 3.1: Chuẩn Bị File Config

Trên máy cần cài agent:

```bash
# Copy file mẫu
cp device.yaml device.may-01.yaml
nano device.may-01.yaml
```

**Chỉ sửa 2 dòng này:**
```yaml
device:
  id: "may-01"                       # ← TÊN MÁY (duy nhất)

influxdb:
  url: "http://192.168.1.53:8086"    # ← IP SERVER INFLUXDB
```

Lưu file.

### Bước 3.2: Cài Agent

```bash
# Set token (lấy từ bước 1.4)
export INFLUX_TOKEN="xyzABC123...456DEF"

# Cài agent
sudo -E ./install-agent-v2.sh --config device.may-01.yaml
```

**Lưu ý:** Cờ `-E` rất quan trọng để giữ biến môi trường INFLUX_TOKEN

### Bước 3.3: Kiểm Tra Agent

```bash
# Xem trạng thái
systemctl status telegraf

# Xem log
journalctl -u telegraf -n 20

# Nếu thấy "Connected to InfluxDB" → Thành công
```

### Bước 3.4: Lặp Lại Cho Các Máy Khác

Với mỗi máy:
1. Copy device.yaml
2. Sửa `device.id` thành tên máy khác (may-02, may-03, ...)
3. Chạy install-agent-v2.sh
4. Kiểm tra status

**Ví dụ cho máy thứ 2:**
```bash
# Trên may-02
cp device.yaml device.may-02.yaml
sed -i 's/cuonglq/may-02/' device.may-02.yaml
export INFLUX_TOKEN="xyzABC123...456DEF"
sudo -E ./install-agent-v2.sh --config device.may-02.yaml
```

---

## Phần 4: Kiểm Tra Metrics Trong InfluxDB

### Bước 4.1: Query Metrics

Vào InfluxDB UI → Data Explorer:

```flux
from(bucket: "system_metrics")
  |> range(start: -5m)
  |> filter(fn: (r) => r._measurement == "cpu")
  |> filter(fn: (r) => r._field == "usage_idle")
```

Nếu thấy data → Agent đã gửi metrics thành công

### Bước 4.2: Kiểm Tra Tất Cả Các Máy

```flux
from(bucket: "system_metrics")
  |> range(start: -5m)
  |> filter(fn: (r) => r._measurement == "cpu")
  |> group(columns: ["device"])
  |> distinct(column: "device")
```

Sẽ thấy danh sách: may-01, may-02, may-03, ...

---

## Xử Lý Lỗi Thường Gặp

### Lỗi 1: "Schema v2 requires token from environment variable"

**Nguyên nhân:** Chưa export INFLUX_TOKEN

**Fix:**
```bash
export INFLUX_TOKEN="token"
sudo -E ./install-agent-v2.sh   # Nhớ cờ -E
```

### Lỗi 2: Telegraf Không Kết Nối Được InfluxDB

**Nguyên nhân:** Firewall chặn port 8086

**Fix:**
```bash
# Trên server InfluxDB
sudo ufw allow 8086/tcp
sudo ufw reload
```

### Lỗi 3: "unauthorized access"

**Nguyên nhân:** Token sai hoặc hết hạn

**Fix:**
1. Vào InfluxDB UI → Settings → API Tokens
2. Tạo token mới với quyền Read/Write
3. Dùng token mới

### Lỗi 4: Agent Gửi Metrics Nhưng Grafana Không Thấy

**Nguyên nhân:** Grafana data source cấu hình sai

**Fix:**
1. Grafana → Configuration → Data Sources
2. Chọn InfluxDB-Monitoring
3. Click **Test** → Phải thấy "working"
4. Nếu lỗi, check lại URL, Token, Organization

### Lỗi 5: Không Thấy Metrics Từ Máy Cụ Thể

**Kiểm tra:**
```bash
# Trên máy agent
systemctl status telegraf
journalctl -u telegraf -n 50

# Tìm lỗi:
# - "connection refused" → Firewall
# - "unauthorized" → Token sai
# - "invalid bucket" → Bucket name sai
```

---

## Cấu Hình Nâng Cao

### Giảm Tần Suất Thu Thập (Tiết Kiệm Disk)

Sửa device.yaml:
```yaml
agent:
  interval: "30s"        # Mặc định: 10s
  flush_interval: "30s"
```

### Chỉ Giám Sát CPU và RAM

Sửa device.yaml:
```yaml
monitoring:
  system:
    enabled: true
csv:
  enabled: false
postgresql:
  enabled: false
docker:
  enabled: false
applications:
  enabled: false
```

### Thêm Location Cho Máy

```yaml
device:
  id: "may-01"
  location: "Xưởng A - Tầng 2"    # Hiển thị trong dashboard
```

---

## Triển Khai Hàng Loạt (10+ Máy)

### Script Tự Động

Tạo file `deploy.sh`:
```bash
#!/bin/bash
TOKEN="xyzABC123...456DEF"
INFLUXDB_URL="http://192.168.1.53:8086"

machines=("may-01" "may-02" "may-03" "may-04" "may-05")

for machine in "${machines[@]}"; do
  echo "=== Deploying to $machine ==="
  
  # Tạo config
  cp device.yaml device.$machine.yaml
  sed -i "s/cuonglq/$machine/" device.$machine.yaml
  sed -i "s|http://192.168.1.53:8086|$INFLUXDB_URL|" device.$machine.yaml
  
  # Copy sang máy remote
  scp device.$machine.yaml install-agent-v2.sh $machine:/tmp/
  
  # Cài agent remote
  ssh $machine "export INFLUX_TOKEN='$TOKEN' && cd /tmp && sudo -E ./install-agent-v2.sh --config device.$machine.yaml"
  
  echo "=== Done: $machine ==="
done
```

Chạy:
```bash
chmod +x deploy.sh
./deploy.sh
```

---

## Bảo Trì

### Backup Token

Lưu token vào file an toàn:
```bash
# Trên server
echo "xyzABC123...456DEF" > ~/.influx_token
chmod 600 ~/.influx_token
```

Khi cần dùng:
```bash
export INFLUX_TOKEN=$(cat ~/.influx_token)
```

### Monitoring Disk Space

```bash
# Kiểm tra disk InfluxDB
du -sh /var/lib/influxdb/

# Nếu quá lớn, giảm retention
# InfluxDB UI → Buckets → Edit → Retention = 30 days
```

### Update Agent

```bash
# Trên máy agent
sudo apt-get update
sudo apt-get upgrade telegraf

# Restart
sudo systemctl restart telegraf
```

---

## Checklist Hoàn Thành

Sau khi làm xong phần Setup:

- [ ] InfluxDB chạy và accessible từ các máy agent
- [ ] Grafana chạy và kết nối được InfluxDB
- [ ] Tạo được token với quyền Read/Write
- [ ] Agent cài trên ít nhất 1 máy
- [ ] Thấy metrics trong InfluxDB Data Explorer
- [ ] Grafana Test data source thành công

**→ Tiếp theo: Đọc DASHBOARD.md để tạo dashboard giám sát**

---

**Thời gian hoàn thành:** ~45-60 phút  
**Khó khăn:** Trung bình  
**Kết quả:** Hệ thống giám sát hoạt động đầy đủ
