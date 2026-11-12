# Thư Mục Script/May_Khac: Dành Cho Các Máy Con Cần Giám Sát (Client Agents)

Thư mục này được đóng gói độc lập để mang sang các máy con (Máy B, Máy C... ví dụ: máy trạm, server phụ, thiết bị nhúng chạy Ubuntu) nhằm cài đặt Telegraf Agent và thiết lập cơ chế giám sát tự động.

---

## 1. Danh sách và Mục đích Chi tiết của Từng Tệp

### 1. `install-agent-v2.sh` (Script Cài Đặt Agent Tự Động Toàn Diện)
* **Tác dụng:** Tự động cài đặt Telegraf, nạp cấu hình từ `device.yaml`, kiểm tra tài nguyên phần cứng, GPU, Database và khởi động dịch vụ giám sát.
* **Các tính năng tự động:**
  1. **Tự động nhận diện GPU NVIDIA:** Kiểm tra sự tồn tại của lệnh `nvidia-smi`. Nếu máy có GPU (ví dụ: RTX A2000, RTX 3060, A100...), script sẽ tự động chèn module `[[inputs.nvidia_smi]]` vào Telegraf để theo dõi nhiệt độ (°C), công suất tiêu thụ (W) và mức chiếm dụng VRAM.
  2. **Tự động phát hiện mọi Database PostgreSQL:** Khi trong cấu hình để `databases: ["auto"]`, script sẽ kết nối vào PostgreSQL nội bộ máy con, truy vấn danh sách cơ sở dữ liệu người dùng và đưa tất cả vào danh sách theo dõi của Telegraf.
  3. **Bộ xử lý chỉ mục dòng CSV Starlark (Universal CSV Row Indexer):**
     * Tự động quét toàn bộ tệp `.csv` theo mẫu đường dẫn `paths: ["/path/*.csv"]`.
     * Tự động sinh module `[[processors.starlark]]` đánh số thứ tự dòng `row_id` cho từng dòng dữ liệu CSV. Nhờ đó, InfluxDB lưu trọn vẹn 100% tất cả các dòng mà không bị ghi đè dữ liệu, đồng thời ngăn chặn hiện tượng bị nhân bản dòng theo thời gian trên Grafana.
  4. **Tự động thiết lập lịch đồng bộ ERD:** Tự động cài đặt `manage.py` vào `/usr/local/bin/manage.py` và tạo cronjob `/etc/cron.d/erd-metadata-sync` chạy mỗi 5 phút một lần để đồng bộ cấu trúc bảng và khóa ngoại về Máy A.
* **Các chế độ chạy:**
  ```bash
  # 1. Cài đặt thực tế trên máy con (yêu cầu quyền sudo)
  sudo -E ./install-agent-v2.sh --config device.yaml

  # 2. Kiểm tra tính hợp lệ của file cấu hình YAML mà không thay đổi hệ thống
  ./install-agent-v2.sh --validate-only --config device.yaml

  # 3. Xuất file cấu hình Telegraf TOML ra tệp cục bộ để xem trước
  ./install-agent-v2.sh --render-only /tmp/telegraf.conf --config device.yaml
  ```

---

### 2. `device.yaml` (Tệp Cấu Hình Giám Sát Của Thiết Bị)
* **Tác dụng:** File cấu hình khai báo trung tâm cho máy con, bao gồm định danh thiết bị, IP kết nối về Máy A, và các danh mục muốn theo dõi.
* **Các mục chính cần lưu ý:**
  * `device.id`: Tên định danh thiết bị hiển thị trên Grafana.
  * `influxdb.url`: Địa chỉ InfluxDB trên Máy A (ví dụ: `http://192.168.1.100:8086`).
  * `central_catalog.host`: Địa chỉ IP máy chủ PostgreSQL chứa kho Catalog trên Máy A (ví dụ: `192.168.1.100`).
  * `postgresql.instances`: Khai báo kết nối PostgreSQL. Để `databases: ["auto"]` để tự động nhận hết toàn bộ DB.
  * `csv.paths`: Đường dẫn thư mục chứa các tệp CSV cần theo dõi (ví dụ: `["/path/to/data/*.csv"]`).
* *Mọi mục trong tệp đều có sẵn khối chú thích ví dụ mẫu bên dưới để người dùng dễ dàng thay thế.*

---

### 3. `device.yaml.template` (Tệp Mẫu Cấu Hình Tự Động)
* **Tác dụng:** Tệp template chứa đầy đủ các ghi chú giải thích chi tiết và placeholder `THAY_THANH_TEN_MAY_CUA_BAN`.
* **Mục đích:** Được các script cài đặt tự động sử dụng để sinh ra file `device.yaml` cho từng máy mới khi triển khai hàng loạt.

---

### 4. `manage.py` (Công Cụ Thu Thập Metadata ERD Trên Máy Con)
* **Tác dụng:** Được cronjob chạy tự động mỗi 5 phút một lần với lệnh `python3 manage.py collect device.yaml`.
* **Tại sao máy con cần file này:**
  * Telegraf chỉ đọc được các chỉ số số liệu định lượng (CPU %, RAM %, số lượng connections).
  * `manage.py` đóng vai trò bóc tách cấu trúc bảng, danh sách cột, kiểu dữ liệu, khóa chính (PK) và khóa ngoại (FK) từ PostgreSQL trên máy con, sau đó đẩy về kho `monitoring_catalog` trên Máy A để vẽ sơ đồ ERD.

---

## 2. Hướng Dẫn Mang Sang Máy Mới

Khi muốn thêm một máy mới (Máy B, Máy C...) vào hệ thống giám sát:
1. Copy toàn bộ thư mục `May_Khac` sang máy đó:
   ```bash
   # Ví dụ: scp -r Script/May_Khac user@192.168.1.60:/home/user/agent/
   scp -r Script/May_Khac <tai_khoan>@<IP_MAY_CLIENT>:/duong/dan/thu_muc_cai_dat/
   ```
2. Trên máy mới, mở file `device.yaml`, chỉnh sửa IP Máy A và tên thiết bị.
3. Chạy lệnh cài đặt:
   ```bash
   sudo -E ./install-agent-v2.sh --config device.yaml
   ```
4. Kiểm tra dịch vụ Telegraf hoạt động:
   ```bash
   sudo systemctl status telegraf
   ```
