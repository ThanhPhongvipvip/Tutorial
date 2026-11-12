# Thư Mục Script/May_A: Dành Riêng Cho Máy Chủ Trung Tâm (Central Server)

Thư mục này chứa toàn bộ mã nguồn, dịch vụ và công cụ quản trị dành cho **Máy Chủ Trung Tâm (Máy A)** trong hệ thống giám sát phân tán.

---

## 1. Danh sách và Mục đích Chi tiết của Từng Tệp

### 1. `setup.sh` (Script Thiết Lập Máy Chủ Trung Tâm ALL-IN-ONE)
* **Tác dụng:** Tự động hóa 100% quá trình cài đặt, cấu hình và khởi chạy các dịch vụ trên Máy A.
* **Quy trình hoạt động:**
  1. Kiểm tra trạng thái các dịch vụ cốt lõi: InfluxDB (8086), PostgreSQL (5432), Grafana (3000).
  2. Khởi tạo cơ sở dữ liệu `monitoring_catalog` trên PostgreSQL bằng tệp `sql/init_central_catalog.sql` và tạo user `grafana_reader` với mật khẩu mặc định `1`.
  3. Cài đặt và kích hoạt dịch vụ hệ thống `erd-viewer.service` chạy ngầm qua systemd trên cổng `8088`.
  4. Tự động kiểm tra và thêm 2 Data Sources trên Grafana: `InfluxDB-Monitoring` (Flux) và `PostgreSQL-Catalog`.
  5. Gọi `manage.py generate` và `manage.py import` để nạp Dashboard lên Grafana.
* **Cách sử dụng:**
  ```bash
  # Chạy cài đặt máy chủ trung tâm
  ./setup.sh --central-server

  # Hoặc mở menu tương tác
  ./setup.sh

  # Khởi chạy lại riêng dịch vụ ERD Viewer port 8088
  ./setup.sh --start-erd
  ```

---

### 2. `manage.py` (Công Cụ Quản Trị Hệ Thống Python CLI)
* **Tác dụng:** Quản trị sinh cấu trúc dashboard, import dashboard lên Grafana qua HTTP API và thu thập metadata cơ sở dữ liệu.
* **Các lệnh hỗ trợ:**
  * `python3 manage.py generate`: Tự động sinh tệp `monitoring-dashboard.json` chuẩn hóa mới nhất với đầy đủ các panel (System, GPU, CSV, ERD).
  * `python3 manage.py import`: Tự động nạp tệp `monitoring-dashboard.json` vào Grafana tại `http://localhost:3000`. Hỗ trợ tham số `--user` và `--pass`.
  * `python3 manage.py collect [file_config.yaml]`: Quét toàn bộ bảng, cột, khóa chính (PK) và khóa ngoại (FK) của các cơ sở dữ liệu PostgreSQL rồi đẩy về bảng `db_metadata_tables` và `db_metadata_relations` trong `monitoring_catalog`.
* **Cách sử dụng:**
  ```bash
  python3 manage.py generate
  python3 manage.py import
  python3 manage.py collect ../May_Khac/device.yaml
  ```

---

### 3. `monitoring-dashboard.json` (Cấu Hình Dashboard Chuẩn Grafana)
* **Tác dụng:** Tệp JSON chứa toàn bộ định nghĩa giao diện dashboard của Grafana.
* **Bao gồm:**
  * Biến động (Template Variables): `$ds_postgres`, `$device`, `$db_name`, `$csv_file`.
  * Hàng 1 (Tổng quan & Nhịp tim): Uptime, CPU %, RAM %, Disk %, Tình trạng Heartbeat.
  * Hàng 2 (Tài nguyên chi tiết): Biểu đồ CPU nhiều lõi, Bộ nhớ RAM (Used/Cached/Free), Tốc độ I/O ổ đĩa, Lưu lượng mạng Network I/O.
  * Hàng 3 (Giám sát GPU NVIDIA): Tự động hiển thị Nhiệt độ (°C), Công suất (W), Mức chiếm dụng bộ nhớ VRAM.
  * Hàng 4 (Dữ liệu bảng CSV): Bảng chi tiết toàn bộ các dòng của file CSV được chọn, hỗ trợ phân trang và tìm kiếm.
  * Hàng 5 (Sơ đồ ERD Cytoscape + ELK): Nhúng iframe canvas sơ đồ quan hệ cơ sở dữ liệu tương tác chuẩn pgAdmin 4.

---

### 4. `erd_service/` (Dịch Vụ ERD Viewer Microservice)
* **Tác dụng:** Microservice độc lập phục vụ giao diện vẽ sơ đồ thực thể quan hệ cơ sở dữ liệu động bằng thư viện Cytoscape.js và thuật toán sắp xếp ELK.
* **Cấu trúc bên trong:**
  * `server.py`: HTTP Server viết bằng Python chuẩn, lắng nghe tại cổng `8088`. Cung cấp API endpoint `/api/erd?device=<ten_may>&db=<ten_db>` để truy vấn dữ liệu quan hệ từ PostgreSQL Catalog trả về định dạng JSON cho giao diện web.
  * `public/index.html`: Giao diện canvas vẽ sơ đồ ERD, tích hợp các nút điều khiển (Căn giữa, Tự động xếp ELK, Phóng to, Thu nhỏ, Xuất ảnh PNG chất lượng cao).
  * `public/libs/`: Chứa các thư viện JavaScript đã tải sẵn chạy offline: `cytoscape.min.js`, `elk.bundled.js`, `cytoscape-elk.js`, `cytoscape-node-html-label.min.js`.
* **Quản lý dịch vụ qua systemd:**
  ```bash
  sudo systemctl status erd-viewer
  sudo systemctl restart erd-viewer
  ```

---

### 5. `configs/config.json` (Cấu Hình Tham Chiếu Máy Chủ)
* **Tác dụng:** Lưu trữ thông tin tham chiếu cấu hình của Máy Chủ Trung Tâm:
  * InfluxDB: Port 8086, Organization `monitoring`, write token, danh sách buckets.
  * PostgreSQL: Port 5432, database `monitoring_catalog`, user `grafana_reader`.
  * Grafana: Port 3000, user/pass mặc định `admin`/`admin`.

---

### 6. `sql/init_central_catalog.sql` (Kịch Bản Cơ Sở Dữ Liệu Catalog)
* **Tác dụng:** Tạo cấu trúc bảng lưu trữ metadata tập trung cho toàn bộ hệ thống:
  * Bảng `db_metadata_tables`: Lưu thông tin từng bảng (`device`, `database_name`, `schema_name`, `table_name`, `column_count`, `columns_detail`).
  * Bảng `db_metadata_relations`: Lưu thông tin ràng buộc khóa ngoại (`from_table`, `from_column`, `to_table`, `to_column`, `cardinality`).
  * View `v_grafana_erd_nodes` và `v_grafana_erd_edges`: Hỗ trợ truy vấn dữ liệu node và cạnh nối nhanh cho Grafana.
