# Hướng Dẫn Cài Đặt Toàn Diện (SETUP GUIDE)

Tài liệu hướng dẫn cài đặt và thiết lập hệ thống từ đầu cho cả **Máy Chủ Trung Tâm (Máy A)** và **Các Thiết Bị Giám Sát (Máy B, Máy C...)**.

---

## PHẦN 1: CÀI ĐẶT MÁY CHỦ TRUNG TÂM (MÁY A)

Máy A đóng vai trò trung tâm lưu trữ toàn bộ chỉ số giám sát, cơ sở dữ liệu metadata ERD và hiển thị giao diện Grafana.

### 1.1. Yêu cầu môi trường
* Hệ điều hành: Ubuntu 22.04 hoặc 24.04 LTS.
* Đã cài đặt các gói cơ sở:
  ```bash
  sudo apt-get update
  sudo apt-get install -y curl wget gnupg python3 python3-yaml postgresql postgresql-contrib
  ```

### 1.2. Cài đặt các dịch vụ nền tảng (nếu chưa có)
* **Grafana (Port 3000):**
  ```bash
  sudo apt-get install -y software-properties-common
  sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
  wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
  sudo apt-get update && sudo apt-get install -y grafana
  sudo systemctl enable --now grafana-server
  ```
* **InfluxDB 2.x (Port 8086):**
  ```bash
  wget https://dl.influxdata.com/influxdb/releases/influxdb2-2.7.4-amd64.deb
  sudo dpkg -i influxdb2-2.7.4-amd64.deb
  sudo systemctl enable --now influxdb
  ```
  *(Tạo Organization `monitoring`, Bucket `system_metrics`, `device_csv`, `device_database` và cấp quyền Write Token).*

### 1.3. Chạy Script Thiết Lập Trọn Gói Máy A
Di chuyển vào thư mục script của Máy A:
```bash
cd /home/phongvt/phong/Tong_hop/grafana/Script/May_A
./setup.sh --central-server
```

**Script `setup.sh` sẽ tự động thực hiện:**
1. Khởi tạo Database Central Catalog (`monitoring_catalog`) trên PostgreSQL nội bộ và cấp quyền cho user `grafana_reader`.
2. Tạo và kích hoạt dịch vụ hệ thống `erd-viewer.service` chạy ngầm qua systemd trên cổng `8088`.
3. Tự động kiểm tra và thêm 2 Data Sources trên Grafana: `InfluxDB-Monitoring` (Flux) và `PostgreSQL-Catalog`.
4. Sinh tự động và import Dashboard hoàn chỉnh lên Grafana.

---

## PHẦN 2: CÀI ĐẶT AGENT TRÊN THIẾT BỊ CLIENT (MÁY B, MÁY C...)

### 2.1. Chuẩn bị file trên máy client
Sao chép toàn bộ thư mục `Script/May_Khac` sang máy client (ví dụ sang thư mục `/home/cuonglq/test_grafana/` trên Máy B):
```bash
# Thực hiện từ Máy A:
scp -r /home/phongvt/phong/Tong_hop/grafana/Script/May_Khac/* cuonglq@192.168.1.60:/home/cuonglq/test_grafana/
```

### 2.2. Kiểm tra và chỉnh sửa file `device.yaml` trên máy client
Mở file `/home/cuonglq/test_grafana/device.yaml` và kiểm tra các thông số:

```yaml
schema_version: 2

# 1. TÊN ĐỊNH DANH THIẾT BỊ
device:
  id: "cuonglq"             # Tên hiển thị trên menu Grafana (ví dụ: cuonglq, robot-01...)
  name: auto
  description: "Máy B - cuonglq"
  location: "Factory-B"

# 2. TRỎ VỀ MÁY CHỦ INFLUXDB (IP Máy A)
influxdb:
  enabled: true
  url: "http://192.168.1.53:8086"
  organization: "monitoring"
  token_env: "INFLUX_TOKEN"
  buckets:
    system: "system_metrics"
    csv: "device_csv"
    database: "device_database"

# 3. KHO METADATA ERD TẬP TRUNG (IP Máy A)
central_catalog:
  host: "192.168.1.53"
  port: 5432
  user: "grafana_reader"
  password: "1"
  database: "monitoring_catalog"

agent:
  interval: "10s"
  flush_interval: "10s"

monitoring:
  system:
    enabled: true
    cpu: true
    memory: true
    disk: true
    diskio: true
    network: true
    uptime: true
    processes: true
  heartbeat:
    enabled: true
    interval: "10s"

# 4. TỰ ĐỘNG QUÉT TOÀN BỘ CƠ SỞ DỮ LIỆU POSTGRESQL TRÊN MÁY NÀY
postgresql:
  enabled: true
  instances:
    - name: "cuonglq_pg"
      host: "localhost"       # Kết nối PostgreSQL cục bộ trên Máy B
      port: 5432
      username: "postgres"
      password: "1"
      databases:
        - "auto"              # <-- Tự động tìm mọi database người dùng
      sslmode: "disable"

# 5. TỰ ĐỘNG GIÁM SÁT MỌI TẬP TIN CSV TRONG THƯ MỤC
csv:
  enabled: true
  interval: "1m"
  paths:
    - "/home/cuonglq/test_grafana/*.csv"

docker:
  enabled: false

applications:
  enabled: auto
```

### 2.3. Khởi chạy cài đặt Agent
Trên máy client, thực hiện lệnh:
```bash
cd /home/cuonglq/test_grafana
sudo -E ./install-agent-v2.sh --config device.yaml
```

**Quá trình cài đặt sẽ:**
1. Cài đặt Telegraf mới nhất từ kho chính thức của InfluxData.
2. Tự động kiểm tra GPU NVIDIA qua `nvidia-smi` để cấu hình module giám sát GPU.
3. Tự động nạp bộ chỉ mục dòng `row_id` Starlark cho mọi file CSV tìm thấy.
4. Tự động truy vấn danh sách cơ sở dữ liệu trên máy và đưa vào Telegraf.
5. Thiết lập cronjob `/etc/cron.d/erd-metadata-sync` tự động đồng bộ cấu trúc bảng và khóa ngoại về Máy A mỗi 5 phút một lần.

---

## PHẦN 3: KIỂM TRA VÀ XÁC NHẬN HOẠT ĐỘNG

1. **Truy cập Grafana:**
   * URL: `http://192.168.1.53:3000/d/monitoring`
   * Tài khoản: `admin` / `admin`
2. **Kiểm tra dữ liệu:**
   * Chọn `Thiết Bị (Device)`: Chọn máy vừa cài đặt (`cuonglq` hoặc `phongvt`).
   * Kiểm tra các biểu đồ CPU, RAM, Disk, GPU xem có đường dữ liệu vẽ theo thời gian thực không.
   * Chọn tập tin CSV ở menu `Tập Tin CSV` để xem bảng dữ liệu đã hiển thị đầy đủ dòng chưa.
   * Chọn cơ sở dữ liệu ở menu `Cơ Sở Dữ Liệu` để kiểm tra sơ đồ ERD trực quan bên dưới.
