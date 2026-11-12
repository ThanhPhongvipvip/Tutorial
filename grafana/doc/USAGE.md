# Cẩm Nang Sử Dụng & Vận Hành Hệ Thống (USAGE GUIDE)

Tài liệu hướng dẫn chi tiết cách sử dụng các tính năng giám sát CSV, cơ sở dữ liệu PostgreSQL, sơ đồ quan hệ ERD và cách khắc phục sự cố vận hành.

---

## 1. GIÁM SÁT DỮ LIỆU TẬP TIN CSV

### 1.1. Thêm một file CSV mới vào hệ thống
Nhờ cấu hình đường dẫn động (`paths`), bạn không cần khai báo từng cột hay sửa file cấu hình mỗi khi có file mới:
1. Sao chép file `.csv` mới của bạn vào thư mục giám sát trên máy client (ví dụ `/home/cuonglq/test_grafana/doanh_thu.csv`).
2. Chạy lại lệnh nạp agent trên máy client:
   ```bash
   sudo -E ./install-agent-v2.sh --config device.yaml
   ```
3. Hệ thống sẽ tự động:
   * Nhận diện dấu phân cách (dấu phẩy `,`, chấm phẩy `;`, tab `\t`).
   * Nhận diện dòng tiêu đề header.
   * Gán `csv_name` là tên file (`doanh_thu`).
   * Đánh chỉ mục dòng `row_id` từ 1 đến hết bằng Starlark processor.
4. Mở Grafana, tại mục biến **Tập Tin CSV**, chọn `doanh_thu`, toàn bộ dữ liệu bảng sẽ xuất hiện ngay lập tức.

### 1.2. Cách chuyển dữ liệu CSV sang dạng biểu đồ (Visualization)
Muốn chuyển bảng CSV thành biểu đồ cột (Bar Chart) hoặc biểu đồ đường:
1. Bấm vào nút dấu 3 chấm góc phải của bảng CSV trên Grafana -> Chọn **Edit**.
2. Ở bảng bên phải (Panel options):
   * Đổi loại hiển thị từ **Table** sang **Bar chart** (hoặc **Time series**).
3. Chuyển sang tab **Transformations**:
   * Thêm **Convert field type**: Chọn cột chứa số lượng (ví dụ `So_don_hang`) chuyển sang kiểu **Number** (hoặc Integer).
4. Ở phần thiết lập trục X/Y:
   * **X Column**: Chọn cột tên (ví dụ `Nhan_vien`).
   * **Y Column**: Chọn cột số liệu vừa chuyển đổi (`So_don_hang`).
5. Bấm **Apply** để lưu lại biểu đồ.

---

## 2. GIÁM SÁT CƠ SỞ DỮ LIỆU & SƠ ĐỒ ERD

### 2.1. Cơ chế tự động phát hiện Database
Trong `device.yaml`, khi mục `postgresql.instances.databases` để là `"auto"`:
```yaml
postgresql:
  enabled: true
  instances:
    - name: "my_pg"
      host: "localhost"
      port: 5432
      username: "postgres"
      password: "1"
      databases:
        - "auto"
```
* **Khi cài đặt Agent:** Script sẽ tự động liệt kê toàn bộ database đang có và nạp vào Telegraf.
* **Khi đồng bộ ERD:** Hệ thống quét toàn bộ database người dùng (bỏ qua database hệ thống `monitoring_catalog`), trích xuất:
  * Tên bảng, schema.
  * Danh sách cột, kiểu dữ liệu, ràng buộc `NOT NULL`.
  * Khóa chính (PK) và các liên kết khóa ngoại (FK) nối giữa các bảng.

### 2.2. Đồng bộ cấu trúc Database ngay lập tức
Nếu bạn vừa tạo thêm bảng mới hoặc tạo database mới trong PostgreSQL:
* **Cách 1 (Tự động):** Đợi cronjob chạy tự động (mỗi 5 phút một lần).
* **Cách 2 (Thủ công ngay lập tức):** Chạy lệnh đồng bộ:
  ```bash
  # Chạy trên máy client (hoặc máy A)
  python3 manage.py collect device.yaml
  ```
  Metadata mới sẽ được đẩy ngay về kho trung tâm trên Máy A.

### 2.3. Thao tác trên khung Sơ Đồ ERD Viewer
* **Chọn Database:** Dùng dropdown **Cơ Sở Dữ Liệu** trên đỉnh dashboard Grafana để chuyển đổi giữa các DB.
* **Tự Động Xếp (ELK):** Bấm nút **"Tự Động Xếp (ELK)"** để thuật toán tự tính toán khoảng cách và vẽ lại dây liên kết khóa ngoại tối ưu, không bị đè lên nhau.
* **Căn Giữa / Phóng To / Thu Nhỏ:** Sử dụng các nút điều khiển hoặc lăn chuột để tương tác với canvas.
* **Xuất Ảnh PNG:** Bấm nút **"Xuất PNG"** để tải sơ đồ chất lượng cao về máy tính phục vụ báo cáo.

---

## 3. QUẢN LÝ DỊCH VỤ HỆ THỐNG (SYSTEMD)

### 3.1. Dịch vụ ERD Viewer trên Máy A (`erd-viewer.service`)
Dịch vụ ERD Canvas chạy trên cổng 8088 được quản lý bằng systemd:
```bash
# Kiểm tra trạng thái
sudo systemctl status erd-viewer

# Khởi động lại dịch vụ
sudo systemctl restart erd-viewer

# Xem nhật ký log chạy
sudo journalctl -u erd-viewer -f
```

### 3.2. Dịch vụ Telegraf Agent trên các máy client (`telegraf.service`)
```bash
# Kiểm tra trạng thái Agent
sudo systemctl status telegraf

# Khởi động lại Agent
sudo systemctl restart telegraf

# Kiểm tra file cấu hình đang nạp
telegraf --config /etc/telegraf/telegraf.d/90-device-agent.conf --test
```

---

## 4. XỬ LÝ SỰ CỐ THƯỜNG GẶP (TROUBLESHOOTING)

| Hiện tượng | Nguyên nhân | Cách khắc phục |
| :--- | :--- | :--- |
| **Khung ERD báo "Unable to connect at 192.168.1.53:8088"** | Dịch vụ `erd-viewer` trên Máy A chưa chạy hoặc firewall chặn port 8088. | Trên Máy A, chạy: `sudo systemctl restart erd-viewer`. Kiểm tra `curl -I http://127.0.0.1:8088`. |
| **Bảng CSV chỉ hiện 1 dòng hoặc tiêu đề cột có dạng `{csv_name=...}`** | Tab trình duyệt Grafana vẫn đang giữ truy vấn cũ trong bộ nhớ RAM. | Bấm **F5** (hoặc `Ctrl + R`) để tải lại toàn bộ trang web trên trình duyệt. |
| **Không thấy Database mới tạo trong danh sách chọn** | Cronjob chưa đến chu kỳ quét 5 phút. | Chạy lệnh quét thủ công: `python3 manage.py collect device.yaml`. |
| **Lỗi kết nối PostgreSQL khi cài Agent** | Mật khẩu sai hoặc PostgreSQL chưa cấu hình cho phép kết nối trong `pg_hba.conf`. | Mở `/etc/postgresql/*/main/pg_hba.conf`, đảm bảo dòng `host all all 127.0.0.1/32 md5` hoặc `scram-sha-256` được cho phép, sau đó reload PostgreSQL. |
