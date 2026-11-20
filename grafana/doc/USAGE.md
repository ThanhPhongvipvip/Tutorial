# Hướng Dẫn Vận Hành Hệ Thống (USAGE)

Tài liệu hướng dẫn thao tác hàng ngày với dữ liệu CSV, cơ sở dữ liệu PostgreSQL / sơ đồ ERD, quản lý dịch vụ chạy ngầm và xử lý nhanh các lỗi thường gặp.

---

## 1. Giám Sát Dữ Liệu File CSV

### 1.1. Thêm một file CSV mới
Nhờ khai báo đường dẫn theo mẫu trong `device.yaml` (ví dụ `/path/to/data/*.csv`), bạn chỉ cần làm 2 bước:
1. Chép file `.csv` mới vào thư mục đang giám sát trên máy con.
2. Chạy lại lệnh nạp cấu hình cho Agent để nhận diện file mới:
   ```bash
   sudo -E ./install-agent-v2.sh --config device.yaml
   ```
   *(Agent sẽ tự nhận dấu phân cách `,` / `;` / `\t`, nhận dòng tiêu đề, đặt `csv_name` theo tên file và đánh số thứ tự `row_id` để không bị lặp dòng).*
3. Mở Grafana, chọn tên file mới trong menu **Tập Tin CSV** ở đầu Dashboard.

### 1.2. Đổi bảng CSV sang biểu đồ cột (Bar Chart)

Mặc định dữ liệu CSV hiển thị dạng **Bảng (Table)** và các cột đều được đưa về dạng chữ (`String`) để tránh xung đột kiểu dữ liệu giữa nhiều file khác nhau. Để vẽ biểu đồ cột từ một file CSV có số liệu:

1. **Mở chỉnh sửa Panel:** Di chuột vào tiêu đề panel **"Bảng Dữ Liệu CSV Chi Tiết"** → chọn **Edit**. *(Mẹo: Nếu muốn giữ lại bảng cũ, bấm `... → More → Duplicate` trước rồi sửa trên bản sao).*
2. **Đổi kiểu hiển thị:** Ở góc trên bên phải, đổi từ **Table** sang **Bar chart**.
3. **Chuyển cột số liệu từ chữ sang số:**
   * Chọn tab **Transformations** (bên dưới khung xem trước) → **Add transformation** → chọn **Convert field type**.
   * Ở mục **Field**, chọn cột chứa số liệu muốn vẽ (vd: `So_luong`, `Doanh_so`); mục **as**, chọn **Numeric**.
4. **Chỉnh hiển thị (thanh cài đặt bên phải):**
   * **X Column:** Chọn cột tên làm trục ngang (vd: `Nhan_vien`, `Thang`).
   * **Orientation:** Chọn `Vertical` (cột dọc) hoặc `Horizontal` (cột ngang nếu tên dài).
   * **Show values:** Chọn `Always` để hiện số trực tiếp trên đầu cột.
5. **Lưu lại:** Bấm **Apply** ở góc trên phải → bấm biểu tượng **Save dashboard** (`Ctrl + S`).

---

## 2. Giám Sát PostgreSQL & Sơ Đồ ERD

### 2.1. Cách hệ thống tự phát hiện Database
Trong `device.yaml`, khi để `databases: ["auto"]`:
* **Telegraf** tự lấy danh sách tất cả database người dùng trên máy con để theo dõi kết nối/trạng thái.
* **`manage.py collect`** tự quét bảng, cột, kiểu dữ liệu, khóa chính (PK) và khóa ngoại (FK) (bỏ qua `monitoring_catalog`) để đưa vào kho trung tâm vẽ sơ đồ ERD.

### 2.2. Cập nhật sơ đồ ERD ngay sau khi tạo/sửa bảng
* **Tự động:** Cronjob chạy lại sau tối đa **5 phút**.
* **Thủ công ngay lập tức:** Chạy trên máy con:
  ```bash
  python3 manage.py collect device.yaml
  ```

### 2.3. Thao tác trên khung ERD Viewer
* **Chọn Database:** Dùng dropdown **Cơ Sở Dữ Liệu** trên đầu Dashboard Grafana.
* **Tự Động Xếp (ELK):** Tự động sắp xếp lại vị trí các bảng và dây nối để tránh chồng chéo.
* **Xuất Ảnh PNG:** Tải sơ đồ ERD chất lượng cao (bao gồm cả các bảng và đường nối) về máy. *(Nếu vừa cập nhật giao diện mà chưa thấy nút mới, nhấn **F5** tải lại trang).*

---

## 3. Quản Lý Các Dịch Vụ Chạy Ngầm (Systemd)

* **Trên Máy A — Dịch vụ vẽ ERD (`erd-viewer`, cổng `8088`):**
  ```bash
  sudo systemctl status erd-viewer        # Xem trạng thái
  sudo systemctl restart erd-viewer       # Khởi động lại
  sudo journalctl -u erd-viewer -f        # Xem log trực tiếp
  ```
* **Trên Máy con — Agent thu thập dữ liệu (`telegraf`):**
  ```bash
  sudo systemctl status telegraf          # Xem trạng thái
  sudo systemctl restart telegraf         # Khởi động lại
  telegraf --config /etc/telegraf/telegraf.d/90-device-agent.conf --test   # Kiểm tra cấu hình chạy thử
  ```

---

## 4. Kiểm Tra Nhanh Khi Gặp Sự Cố

| Hiện tượng | Cách kiểm tra & xử lý |
| :--- | :--- |
| **Không thấy tên máy hoặc mất biểu đồ trên Grafana** | 1. Trên máy con, chạy `sudo systemctl status telegraf` và `sudo journalctl -u telegraf -n 50` để xem có lỗi kết nối tới IP `:8086` hoặc sai `INFLUX_TOKEN` không.<br>2. Kiểm tra trên Máy A đã mở cổng `8086`, `3000`, `5432`, `8088` trong tường lửa chưa. |
| **Sơ đồ ERD trống hoặc không thấy bảng mới tạo** | 1. Chạy thử `python3 manage.py collect device.yaml` trên máy con xem có báo lỗi kết nối tới PostgreSQL Máy A không.<br>2. Kiểm tra dịch vụ ERD trên Máy A: `sudo systemctl status erd-viewer`. |
| **Không tìm thấy file CSV mới trên dropdown** | Chắc chắn file nằm đúng đường dẫn `csv.paths` trong `device.yaml` và đã chạy lại `sudo -E ./install-agent-v2.sh --config device.yaml`. |


