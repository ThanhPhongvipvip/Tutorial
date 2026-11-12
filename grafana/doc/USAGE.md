# Sử Dụng & Vận Hành Hệ Thống (USAGE GUIDE)

Tài liệu hướng dẫn chi tiết cách sử dụng các tính năng giám sát CSV, cơ sở dữ liệu PostgreSQL, sơ đồ quan hệ ERD và cách khắc phục sự cố vận hành.

---

## 1. GIÁM SÁT DỮ LIỆU TẬP TIN CSV

### 1.1. Thêm một file CSV mới vào hệ thống
Nhờ cấu hình đường dẫn động (`paths`), bạn không cần khai báo từng cột hay sửa file cấu hình mỗi khi có file mới:
1. Sao chép file `.csv` mới của bạn vào thư mục giám sát trên máy client (ví dụ: `/path/to/data/doanh_thu.csv`).
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

### 1.2. Hướng dẫn chi tiết từng bước: Chuyển từ Table sang Bar Chart (Biểu Đồ Cột)

Mặc định, Panel dữ liệu CSV hiển thị dưới dạng **Bảng dữ liệu (Table)** để bạn có thể xem đầy đủ mọi dòng và cột của bất kỳ file CSV nào. Khi bạn muốn trực quan hóa dữ liệu (ví dụ: biểu đồ số lượng đơn hàng theo nhân viên, biểu đồ doanh thu theo phòng ban...), bạn có thể chuyển đổi sang **Bar chart** (hoặc **Time series**) chỉ với vài thao tác đơn giản theo các bước sau:

#### Lưu ý kỹ thuật quan trọng trước khi làm
Để hệ thống có thể hiển thị linh hoạt mọi file CSV với cấu trúc cột tùy ý mà không bị xung đột kiểu dữ liệu (Schema Collision), câu lệnh truy vấn Flux đã chuẩn hóa các trường về dạng văn bản (`String`). Do đó, khi vẽ biểu đồ số liệu (cột Bar chart), bạn **cần thêm 1 bước Transformation để chỉ định cột nào là số (Number)** như hướng dẫn ở Bước 3.

---

#### BƯỚC 1: Vào chế độ chỉnh sửa Panel (Edit Panel)
1. Trên Dashboard Grafana, di chuột đến tiêu đề của panel CSV: **"Bảng Dữ Liệu CSV Chi Tiết"**.
2. Chọn Edit.

---

#### BƯỚC 2: Đổi Visualization sang Bar Chart
1. Nhìn sang góc trên cùng bên phải màn hình (khung cấu hình Visualization).
2. Nhấp vào loại hiển thị hiện tại (đang là **Table**).
3. Trong ô tìm kiếm hoặc danh sách hiện ra, chọn **Bar chart**.
   *(Lúc này Grafana có thể báo cảnh báo chưa thấy cột số liệu phù hợp vì các cột CSV đang mang kiểu String, bạn sang Bước 3 để định kiểu)*.

---

#### BƯỚC 3: Chuyển đổi cột số liệu từ String sang Number (Transformations)
1. Ở khu vực giữa màn hình (phía dưới khung xem trước biểu đồ), nhấp vào tab **Transformations** (nằm cạnh tab **Query**).
2. Nhấp vào nút **Add transformation** (hoặc gõ tìm kiếm):
   * Tìm và chọn bộ biến đổi tên là: **Convert field type**.
3. Trong cấu hình của **Convert field type**:
   * Mục **Field**: Chọn tên cột chứa số liệu bạn muốn vẽ lên trục tung Y (Ví dụ: `So_don_hang`, `Doanh_so`, `So_luong`...).
   * Mục **as**: Chọn **Numeric** (hoặc **Integer** / **Number**).
   *(Ngay khi chọn xong, dữ liệu cột đó sẽ chuyển thành số và biểu đồ Bar Chart sẽ lập tức hiển thị các cột)*.

---

#### BƯỚC 4: Tinh chỉnh trục X và cách hiển thị (Panel Options)
Ở thanh cài đặt bên phải màn hình (mục **Bar chart**):
1. **X Column (Trục hoành):**
   * Chọn cột chứa nhãn tên bạn muốn đặt ở đáy biểu đồ (Ví dụ: `Nhan_vien`, `Bo_phan` hoặc `Thang`).
2. **Orientation (Hướng cột):**
   * **Vertical**: Cột dọc truyền thống.
   * **Horizontal**: Cột ngang (rất thích hợp nếu tên nhân viên hoặc nhãn quá dài).
3. **Show values (Hiện số liệu trên đỉnh cột):**
   * Chọn **Always** để số lượng (ví dụ 125, 98, 143...) luôn hiện rõ trên đầu mỗi cột mà không cần rê chuột.
4. **Color scheme (Màu sắc):**
   * Chọn **Single color** hoặc **By value** / **Palette classic** tùy ý thích.

---

#### BƯỚC 5: Lưu và Hoàn tất
1. Nhấp nút **Apply** màu xanh ở góc trên bên phải để áp dụng thay đổi vào Dashboard.
2. Nhấp vào biểu tượng **Lưu (Save dashboard)** (hình đĩa mềm ở thanh công cụ trên cùng) hoặc nhấn tổ hợp `Ctrl + S`.
3. Nhập ghi chú lưu (ví dụ: `Chuyển bảng CSV sang Bar chart`) rồi bấm **Save**.

*Mẹo: Nếu bạn muốn vừa giữ bảng Table, vừa có thêm biểu đồ Bar chart, bạn chỉ cần bấm 3 chấm ở panel Table -> **More...** -> **Duplicate**, sau đó chuyển bản sao thành Bar chart!*

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
* **Xuất Ảnh PNG:** Bấm nút **"Xuất PNG"** để tải sơ đồ chất lượng cao (độ phân giải 2x - 4x) về máy tính phục vụ báo cáo. Hệ thống sử dụng công nghệ kết xuất `html2canvas` giúp tự động căn chỉnh và lưu đầy đủ cả các bảng dữ liệu (tên bảng, cột, khóa PK/FK) lẫn các đường liên kết quan hệ. Lưu ý: Hãy bấm **F5** trên trình duyệt để tải lại trang nếu đang mở sẵn.

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


