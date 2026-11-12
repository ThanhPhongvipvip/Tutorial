# Thư Mục Other: Quản Lý Tệp Phụ Trợ & Báo Cáo Dọn Dẹp

Thư mục này chứa các tệp phụ trợ, dữ liệu mẫu phục vụ mục đích kiểm thử và ghi chú kiểm toán các tệp trong hệ thống giám sát Grafana.

---

## 1. Danh mục các tệp hiện có trong Other/

| Đường dẫn tệp | Mục đích sử dụng | Đánh giá tính cần thiết |
| :--- | :--- | :--- |
| `Other/sample_data/sample_bar_chart.csv` | File CSV dữ liệu mẫu có cả cột chuỗi và số nguyên (`Nhan_vien`, `Bo_phan`, `So_don_hang`) dùng để kiểm tra khả năng đọc CSV và vẽ biểu đồ Bar Chart trên Grafana. | **Tùy chọn (Optional):** Chỉ dùng để test thử nghiệm. Không bắt buộc khi chạy thật, có thể xóa nếu không cần test. |
| `Other/sample_data/sample_language.csv` | File CSV dữ liệu mẫu dạng danh mục từ điển (`Code`, `Name`) dùng để kiểm tra tính năng hiển thị bảng chuỗi và tự động lập chỉ mục dòng `row_id`. | **Tùy chọn (Optional):** Chỉ dùng để test thử nghiệm. Có thể xóa nếu không cần test. |
| `Other/README.md` | Tài liệu thuyết minh mục đích và tính cần thiết của từng tệp phụ trợ. | **Cần thiết:** Lưu trữ thông tin phân loại để người vận hành nắm rõ. |

---

## 2. Báo cáo kiểm kê và dọn dẹp tệp (Audit & Cleanup)

Trong quá trình chuẩn hóa lại hệ thống, các tệp sau đã được kiểm tra và xử lý:

1. **Bộ đệm Python (`__pycache__/`, `*.pyc`):**
   * *Đánh giá:* **Không cần thiết**. Đây là các tệp bytecode do Python tự sinh trong quá trình chạy `manage.py` và `server.py`.
   * *Hành động:* Đã xóa sạch khỏi kho lưu trữ để đảm bảo mã nguồn gọn gàng, tránh xung đột phiên bản Python.

2. **Các tệp hướng dẫn cũ nằm rải rác (`DASHBOARD.md`, `SETUP.md` ở root):**
   * *Đánh giá:* **Gây nhầm lẫn**. Nội dung các file này thuộc các phiên bản cũ trước khi hệ thống hỗ trợ Schema v2, tự động phát hiện PostgreSQL và xử lý Starlark CSV.
   * *Hành động:* Đã xóa bỏ ở thư mục gốc và chuẩn hóa, hợp nhất toàn diện vào thư mục `doc/` (`doc/SETUP.md`, `doc/USAGE.md`, `doc/README.md`).

3. **Cấu trúc sau khi dọn dẹp:**
   * Thư mục `Script/May_A`: Chỉ chứa các script và tài nguyên vận hành máy chủ trung tâm.
   * Thư mục `Script/May_Khac`: Chỉ chứa các script và cấu hình cần thiết để đóng gói mang sang máy client (Máy B, C...).
   * Thư mục `doc`: Chứa trọn bộ tài liệu hướng dẫn kỹ thuật chuẩn xác 100% với mã nguồn hiện tại.
