# Hướng Dẫn Cài Đặt Hệ Thống (SETUP)

Tài liệu hướng dẫn cài đặt từ đầu cho **Máy Chủ Trung Tâm (Máy A)** và **Các Máy Con Cần Giám Sát (Máy B, Máy C...)** trên Ubuntu 22.04 / 24.04 LTS.

---

## Tổng Quan:

### Trên Máy Chủ Trung Tâm (Máy A)

| Thành phần / Gói cài đặt | Cổng | Mục đích cài đặt để làm gì? |
| :--- | :---: | :--- |
| **`postgresql`, `postgresql-contrib`** | `5432` | Tạo database `monitoring_catalog` để lưu **cấu trúc bảng, cột, khóa chính/khóa ngoại** của các máy con gửi về phục vụ vẽ sơ đồ ERD. |
| **`influxdb2`** | `8086` | Cơ sở dữ liệu chuỗi thời gian dùng để lưu toàn bộ **chỉ số phần cứng** (CPU, RAM, Disk, Network, GPU) và **nội dung file CSV** theo mốc thời gian. |
| **`grafana` + plugin `volkovlabs-echarts-panel`** | `3000` | Giao diện web trung tâm để hiển thị biểu đồ giám sát, xem bảng CSV và nhúng khung sơ đồ ERD. Plugin thêm vào để hỗ trợ chạy mã nhúng khung ERD trong Panel. |
| **`erd-viewer.service`** *(dịch vụ Python tự tạo)* | `8088` | Dịch vụ web chạy ngầm lấy cấu trúc bảng từ PostgreSQL để vẽ **sơ đồ ERD tương tác** (kéo thả, tự sắp xếp, xuất ảnh PNG) rồi hiển thị lên Grafana. |

### Trên Máy Con Cần Giám Sát (Máy B, Máy C...)

| Thành phần / Gói cài đặt | Mục đích cài đặt để làm gì? |
| :--- | :--- |
| **`telegraf`** *(tải từ kho InfluxData)* | Phần mềm thu thập dữ liệu (Agent) chạy ngầm trên máy con: định kỳ đọc % CPU, RAM, ổ đĩa, mạng, GPU NVIDIA (`nvidia-smi`), thông số PostgreSQL và file CSV để đẩy về InfluxDB trên Máy A. |
| **`manage.py` + cronjob `erd-metadata-sync`** | Chạy tự động mỗi 5 phút để trích xuất danh sách bảng, cột, khóa chính/ngoại từ PostgreSQL trên máy con đẩy về PostgreSQL Máy A (vì Telegraf chỉ đo chỉ số vận hành chứ không đọc cấu trúc bảng để vẽ ERD). |


---

## Phần 1: Cài Đặt Máy Chủ Trung Tâm (Máy A)

### 1.1. Cài đặt các gói công cụ nền và PostgreSQL
```bash
sudo apt-get update
sudo apt-get install -y curl wget gnupg jq python3 python3-yaml postgresql postgresql-contrib
```

### 1.2. Cài đặt Grafana và InfluxDB 2.x

* **Cài đặt Grafana (Port 3000) và plugin hỗ trợ panel ERD:**
  ```bash
  sudo apt-get install -y software-properties-common
  sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
  wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
  sudo apt-get update && sudo apt-get install -y grafana
  sudo grafana-cli plugins install volkovlabs-echarts-panel
  sudo systemctl enable --now grafana-server
  ```

* **Cài đặt InfluxDB 2.x (Port 8086):**
  ```bash
  wget https://dl.influxdata.com/influxdb/releases/influxdb2-2.7.4-amd64.deb
  sudo dpkg -i influxdb2-2.7.4-amd64.deb
  sudo systemctl enable --now influxdb
  ```
  > Sau khi cài InfluxDB lần đầu, mở `http://<IP_MAY_A>:8086` (hoặc dùng `influx setup`) để tạo Organization tên `monitoring`, các Bucket `system_metrics`, `device_csv`, `device_database`, lấy **API Token** rồi điền vào [`Script/May_A/configs/config.json`](../Script/May_A/configs/config.json).

### 1.3. Chạy Script thiết lập tự động Máy A
```bash
cd Script/May_A
sudo ./setup.sh --central-server
```
*(Chạy với `sudo` nếu muốn script tự đăng ký dịch vụ `erd-viewer.service` vào `systemd`)*.

Script `setup.sh` sẽ tự động làm 4 việc:
1. Tạo database `monitoring_catalog` và user `grafana_reader` (mật khẩu mặc định `1`) trong PostgreSQL.
2. Cài đặt và bật dịch vụ `erd-viewer.service` chạy ngầm ở cổng `8088`.
3. Tạo 2 Data Source trên Grafana: `InfluxDB-Monitoring` (Flux) và `PostgreSQL-Catalog`.
4. Sinh file cấu hình và nạp sẵn Dashboard lên Grafana.

---

## Phần 2: Cài Đặt Agent Trên Máy Con (Máy B, Máy C...)

### 2.1. Chép thư mục `Script/May_Khac` sang máy con
```bash
# Ví dụ chạy từ Máy A để chép sang máy client:
scp -r Script/May_Khac <tai_khoan>@<IP_MAY_CLIENT>:/home/<tai_khoan>/agent/
```

### 2.2. Chỉnh sửa file `device.yaml` trên máy con
Mở file `device.yaml` trong thư mục vừa chép và sửa 5 nhóm thông tin chính theo thực tế máy của bạn:

| Nhóm cấu hình | Trường cần sửa | Giá trị mẫu / Giải thích |
| :--- | :--- | :--- |
| **`device`** | `id`, `name`, `location` | `id: "may-client-01"` (tên hiển thị trên menu Grafana; `name: auto` sẽ tự lấy hostname). |
| **`influxdb`** | `url` | Đổi thành IP của Máy A, ví dụ `"http://192.168.1.53:8086"`. |
| **`central_catalog`** | `host`, `password` | Đổi `host` thành IP của Máy A (ví dụ `"192.168.1.53"`), `user: "grafana_reader"`, `password: "1"`. |
| **`postgresql`** | `username`, `password`, `databases` | Thông tin kết nối PostgreSQL **trên chính máy con** (`databases: ["auto"]` để tự quét tất cả DB). |
| **`csv`** | `paths` | Đường dẫn thư mục chứa file CSV cần theo dõi, ví dụ `["/home/user/data/*.csv"]`. |

> Nếu Máy A đang đổi token InfluxDB khác mặc định, xuất biến môi trường token trước khi cài: `export INFLUX_TOKEN="<token_cua_ban>"`.

### 2.3. Chạy lệnh cài đặt Agent
```bash
cd /duong/dan/thu_muc_agent
sudo -E ./install-agent-v2.sh --config device.yaml
```

Script `install-agent-v2.sh` sẽ tự động:
1. Cài đặt **Telegraf** từ kho chính thức của InfluxData.
2. Kiểm tra lệnh `nvidia-smi`; nếu máy có GPU NVIDIA thì tự bật module giám sát GPU.
3. Quét các file CSV theo `paths` và gắn bộ đánh số dòng `row_id` (Starlark) để không bị lặp/ghi đè dữ liệu.
4. Tự động tìm các database PostgreSQL cục bộ để đưa vào Telegraf theo dõi.
5. Tạo cronjob `/etc/cron.d/erd-metadata-sync` chạy `manage.py collect` mỗi 5 phút để đẩy cấu trúc bảng/khóa ngoại về Máy A.

---

## Phần 3: Kiểm Tra Sau Khi Cài Đặt

1. Mở trình duyệt truy cập Grafana tại: `http://<IP_MAY_A>:3000/d/monitoring` (tài khoản mặc định: `admin` / `admin`).
2. Trên thanh chọn **Thiết Bị (Device)**, chọn đúng `device.id` vừa cài.
3. Kiểm tra nhanh 3 phần:
   * **Biểu đồ hệ thống & GPU:** CPU, RAM, Disk, Mạng (và GPU nếu có) hiển thị số liệu mới.
   * **Tập Tin CSV:** Chọn tên file CSV trong dropdown để xem bảng dữ liệu.
   * **Cơ Sở Dữ Liệu:** Chọn tên DB để kiểm tra sơ đồ ERD hiển thị ở cuối Dashboard.
