# Nhập Môn Cơ Sở Dữ Liệu và PostgreSQL 16

> Giáo trình cô đọng trình bày hệ thống kiến thức nền tảng về cơ sở dữ liệu quan hệ và hệ quản trị PostgreSQL 16, kết hợp ví dụ minh họa xuyên suốt cùng các sơ đồ kiến trúc minh họa. Phần mã nguồn ứng dụng mẫu hoàn chỉnh (Qt, PostgreSQL 16 và Docker) được trình bày tại [`qt-postgres-login-demo/`](qt-postgres-login-demo/README.md).

---

## Mục lục

- [**Phần 1: Nhập Môn Cơ Sở Dữ Liệu Quan Hệ**](#phần-1-nhập-môn-cơ-sở-dữ-liệu-quan-hệ)
  - [1.1 Cơ sở dữ liệu là gì và giới hạn của tệp bảng tính](#11-cơ-sở-dữ-liệu-là-gì-và-giới-hạn-của-tệp-bảng-tính)
  - [1.2 Cơ sở dữ liệu SQL và NoSQL: Đặc điểm và phạm vi áp dụng](#12-cơ-sở-dữ-liệu-sql-và-nosql-đặc-điểm-và-phạm-vi-áp-dụng)
  - [1.3 Cấu trúc Bảng, Cột, Hàng và Giá trị NULL](#13-cấu-trúc-bảng-cột-hàng-và-giá-trị-null)
  - [1.4 Các loại Khóa trong Cơ sở dữ liệu (PK, FK, Unique, Composite Key)](#14-các-loại-khóa-trong-cơ-sở-dữ-liệu-pk-fk-unique-composite-key)
  - [1.5 Các kiểu dữ liệu phổ biến trong PostgreSQL](#15-các-kiểu-dữ-liệu-phổ-biến-trong-postgresql)
  - [1.6 Ba mối quan hệ giữa các bảng (1-1, 1-N, N-N)](#16-ba-mối-quan-hệ-giữa-các-bảng-1-1-1-n-n-n)
  - [1.7 Chuẩn hóa dữ liệu (1NF, 2NF, 3NF) và Phản chuẩn hóa](#17-chuẩn-hóa-dữ-liệu-1nf-2nf-3nf-và-phản-chuẩn-hóa)
- [**Phần 2: Kiến Trúc PostgreSQL 16 và Môi Trường Thực Hành**](#phần-2-kiến-trúc-postgresql-16-và-môi-trường-thực-hành)
  - [2.1 Cấu trúc phân cấp 4 tầng của PostgreSQL](#21-cấu-trúc-phân-cấp-4-tầng-của-postgresql)
  - [2.2 Triển khai PostgreSQL 16 và pgAdmin 4 với Docker Compose](#22-triển-khai-postgresql-16-và-pgadmin-4-với-docker-compose)
  - [2.3 Chuỗi kết nối (Connection URI) và Biến môi trường](#23-chuỗi-kết-nối-connection-uri-và-biến-môi-trường)
  - [2.4 Các lệnh điều khiển thường dùng trong psql](#24-các-lệnh-điều-khiển-thường-dùng-trong-psql)
- [**Phần 3: Thực Hành Ngôn Ngữ Truy Vấn SQL**](#phần-3-thực-hành-ngôn-ngữ-truy-vấn-sql)
  - [3.1 Định nghĩa và sửa đổi cấu trúc bảng (DDL)](#31-định-nghĩa-và-sửa-đổi-cấu-trúc-bảng-ddl)
  - [3.2 Thêm, Đọc, Sửa và Xóa dữ liệu (DML)](#32-thêm-đọc-sửa-và-xóa-dữ-liệu-dml)
  - [3.3 Lọc và tìm kiếm dữ liệu với WHERE](#33-lọc-và-tìm-kiếm-dữ-liệu-với-where)
  - [3.4 Thống kê gom nhóm (GROUP BY, HAVING) và Thứ tự thực thi SQL](#34-thống-kê-gom-nhóm-group-by-having-và-thứ-tự-thực-thi-sql)
  - [3.5 Kết hợp nhiều bảng với JOIN](#35-kết-hợp-nhiều-bảng-với-join)
  - [3.6 Truy vấn con (Subquery), Biểu thức bảng chung (CTE), UPSERT và UNION](#36-truy-vấn-con-subquery-biểu-thức-bảng-chung-cte-upsert-và-union)
  - [3.7 Hàm cửa sổ (Window Functions) và Kiểu dữ liệu JSONB](#37-hàm-cửa-sổ-window-functions-và-kiểu-dữ-liệu-jsonb)
- [**Phần 4: Giao Dịch (Transaction) và Xử Lý Đồng Thời**](#phần-4-giao-dịch-transaction-và-xử-lý-đồng-thời)
  - [4.1 Giao dịch (Transaction) và Nguyên tắc ACID](#41-giao-dịch-transaction-và-nguyên-tắc-acid)
  - [4.2 Cơ chế kiểm soát đa phiên bản (MVCC)](#42-cơ-chế-kiểm-soát-đa-phiên-bản-mvcc)
  - [4.3 Các bất thường khi đọc đồng thời và Mức cô lập (Isolation Levels)](#43-các-bất-thường-khi-đọc-đồng-thời-và-mức-cô-lập-isolation-levels)
  - [4.4 Khóa mức dòng xử lý tranh chấp đồng thời: FOR UPDATE và SKIP LOCKED](#44-khóa-mức-dòng-xử-lý-tranh-chấp-đồng-thời-for-update-và-skip-locked)
- [**Phần 5: Chỉ Mục (Index), Tối Ưu Truy Vấn và Bảo Trì Dữ Liệu**](#phần-5-chỉ-mục-index-tối-ưu-truy-vấn-và-bảo-trì-dữ-liệu)
  - [5.1 Chỉ mục (Index) và cơ chế tăng tốc tìm kiếm](#51-chỉ-mục-index-và-cơ-chế-tăng-tốc-tìm-kiếm)
  - [5.2 Các loại Index phổ biến trong PostgreSQL](#52-các-loại-index-phổ-biến-trong-postgresql)
  - [5.3 Nguyên tắc viết câu lệnh SQL hiệu quả](#53-nguyên-tắc-viết-câu-lệnh-sql-hiệu-quả)
  - [5.4 Thu hồi không gian lưu trữ với VACUUM và Autovacuum](#54-thu-hồi-không-gian-lưu-trữ-với-vacuum-và-autovacuum)
- [**Phần 6: Phục Hồi Dữ Liệu và Bảo Mật Hệ Thống**](#phần-6-phục-hồi-dữ-liệu-và-bảo-mật-hệ-thống)
  - [6.1 Nhật ký ghi trước (WAL) và cơ chế phục hồi sau sự cố](#61-nhật-ký-ghi-trước-wal-và-cơ-chế-phục-hồi-sau-sự-cố)
  - [6.2 Quản lý phân quyền truy cập với ROLE](#62-quản-lý-phân-quyền-truy-cập-với-role)
  - [6.3 Lưu trữ mật khẩu an toàn bằng hàm băm và muối (pgcrypto / bcrypt)](#63-lưu-trữ-mật-khẩu-an-toàn-bằng-hàm-băm-và-muối-pgcrypto--bcrypt)
- [**Phần 7: Vận Hành Dữ Liệu Trong Hệ Thống Thực Tế**](#phần-7-vận-hành-dữ-liệu-trong-hệ-thống-thực-tế)
  - [7.1 Nhập dữ liệu hàng loạt và Làm sạch dữ liệu nguồn](#71-nhập-dữ-liệu-hàng-loạt-và-làm-sạch-dữ-liệu-nguồn)
  - [7.2 Xóa mềm, Lưu lịch sử biến động và Nhật ký kiểm toán](#72-xóa-mềm-lưu-lịch-sử-biến-động-và-nhật-ký-kiểm-toán)
  - [7.3 Bảo vệ dữ liệu nhạy cảm, Sao lưu và Quản lý phiên bản lược đồ](#73-bảo-vệ-dữ-liệu-nhạy-cảm-sao-lưu-và-quản-lý-phiên-bản-lược-đồ)

---

# Phần 1: Nhập Môn Cơ Sở Dữ Liệu Quan Hệ

## 1.1 Cơ sở dữ liệu là gì và giới hạn của tệp bảng tính

- **Cơ sở dữ liệu (Database — CSDL):** Là tập hợp dữ liệu có tổ chức, được lưu trữ bền vững trên hệ thống máy tính để phục vụ việc tra cứu, cập nhật và quản lý với độ chính xác cao khi nhiều tiến trình cùng truy cập.
- **Hệ quản trị cơ sở dữ liệu (Database Management System — DBMS):** Là lớp phần mềm trung gian đảm nhiệm việc lưu trữ, bảo toàn tính toàn vẹn và xử lý truy vấn trên dữ liệu đó (tiêu biểu như **PostgreSQL**, MySQL, SQL Server hay Oracle). Ứng dụng giao tiếp với DBMS thông qua ngôn ngữ truy vấn chuẩn **SQL (Structured Query Language)**.

![Hình 1.1: So sánh lưu trữ bằng tệp rời rạc với Hệ quản trị CSDL và Mô hình 3 tầng](img/01_excel_vs_db_arch.svg)

Để thấy rõ vai trò của một hệ quản trị cơ sở dữ liệu, hãy xét một hệ thống bán hàng ban đầu lưu trữ đơn đặt hàng trong tệp bảng tính `don_hang.xlsx`. Khi quy mô vận hành tăng lên, việc lưu trữ bằng tệp rời rạc bộc lộ bốn hạn chế mang tính cấu trúc: hai nhân viên mở cùng một tệp và lưu đồng thời sẽ khiến phiên bản lưu sau ghi đè mất dữ liệu của người trước; bảng tính thiếu cơ chế cưỡng chế kiểu dữ liệu nghiêm ngặt; việc đọc hàng trăm nghìn dòng đòi hỏi tải toàn bộ tệp vào bộ nhớ; và sự cố mất điện giữa lúc ghi dễ làm hỏng cấu trúc tệp. Ngược lại, một DBMS như **PostgreSQL** kết hợp trong kiến trúc phần mềm 3 tầng (**Hình 1.1**) cho phép hàng nghìn yêu cầu đọc và ghi diễn ra song song mà vẫn đảm bảo tính nhất quán tuyệt đối.

---

## 1.2 Cơ sở dữ liệu SQL và NoSQL: Đặc điểm và phạm vi áp dụng

Trong thiết kế hệ thống hiện đại, các công nghệ cơ sở dữ liệu thường được phân thành hai nhóm chính dựa trên mô hình dữ liệu:

| Tiêu chí | CSDL Quan hệ — SQL (PostgreSQL, MySQL) | CSDL Phi quan hệ — NoSQL (Redis, MongoDB) |
| :--- | :--- | :--- |
| **Mô hình tổ chức dữ liệu** | **Lược đồ cố định:** Dữ liệu tổ chức thành các bảng với danh sách cột và kiểu dữ liệu được khai báo chặt chẽ từ trước. | **Cấu trúc linh hoạt:** Lưu trữ tự do dưới dạng tài liệu JSON (MongoDB) hoặc cặp khóa-giá trị trên bộ nhớ RAM (Redis). |
| **Ưu thế cốt lõi** | Đảm bảo toàn vẹn dữ liệu nghiêm ngặt, liên kết đa bảng chính xác và hỗ trợ giao dịch an toàn (ACID). | Tốc độ đọc ghi bộ nhớ đệm (Cache) rất cao hoặc thuận tiện khi cấu trúc bản ghi thay đổi liên tục. |
| **Phạm vi áp dụng điển hình** | Quản lý tài khoản, đơn hàng, tồn kho, hệ thống ngân hàng và nghiệp vụ kế toán. | Lưu phiên đăng nhập tạm thời, bảng xếp hạng thời gian thực (Redis) hoặc nhật ký hệ thống, dữ liệu cảm biến (MongoDB). |

Trong thực tiễn kỹ thuật, **PostgreSQL** thường được lựa chọn làm kho dữ liệu trung tâm bởi bên cạnh mô hình quan hệ chuẩn mực, hệ quản trị này tích hợp sẵn kiểu dữ liệu **`JSONB`**, cho phép lưu trữ và đánh chỉ mục dữ liệu phi cấu trúc tương đương NoSQL ngay trong cùng một hệ thống.

---

## 1.3 Cấu trúc Bảng, Cột, Hàng và Giá trị NULL

![Hình 1.2: Cấu trúc một Bảng dữ liệu quan hệ và Phân biệt giá trị NULL](img/01b_table_and_null.svg)

Mô hình quan hệ biểu diễn dữ liệu dưới dạng các bảng hai chiều (**Hình 1.2**), cấu thành từ bốn khái niệm cơ bản:

- **Bảng (`Table`):** Tập hợp các bản ghi mô tả cùng một loại thực thể (chẳng hạn bảng `users` lưu thông tin khách hàng, bảng `products` lưu danh mục sản phẩm).
- **Cột (`Column`):** Đại diện cho một thuộc tính gắn với kiểu dữ liệu xác định (ví dụ cột `balance` chỉ tiếp nhận giá trị số, cột `username` tiếp nhận chuỗi ký tự).
- **Hàng (`Row` / Bản ghi):** Một bộ dữ liệu hoàn chỉnh tương ứng với một thực thể cụ thể trong bảng (chẳng hạn toàn bộ thông tin của khách hàng `phong`).
- **Giá trị `NULL`:** Biểu thị trạng thái *"chưa có thông tin / chưa xác định"*. Giá trị `NULL` hoàn toàn khác biệt về mặt ngữ nghĩa so với số `0` hoặc chuỗi rỗng `''`.

Trong logic ba giá trị (three-valued logic) của SQL, vì `NULL` mang nghĩa "không xác định", mọi phép so sánh thông thường như `WHERE phone = NULL` đều cho kết quả không xác định thay vì đúng (`TRUE`), dẫn đến câu truy vấn luôn trả về tập rỗng. Do đó, để kiểm tra dữ liệu bị khuyết, SQL quy định sử dụng toán tử chuyên biệt `IS NULL` hoặc `IS NOT NULL`:

```sql
SELECT * FROM users WHERE phone IS NULL;      -- Lọc các bản ghi chưa khai báo số điện thoại
SELECT * FROM users WHERE phone IS NOT NULL;  -- Lọc các bản ghi đã có số điện thoại
```

---

## 1.4 Các loại Khóa trong Cơ sở dữ liệu (PK, FK, Unique, Composite Key)

**Khóa (Key)** là tập hợp các ràng buộc dùng để định danh duy nhất từng bản ghi và thiết lập liên kết tham chiếu giữa các bảng:

| Loại khóa | Liên hệ thực tế | Quy tắc ràng buộc | Minh họa trên lược đồ |
| :--- | :--- | :--- | :--- |
| **Khóa chính (`Primary Key` — PK)** | Số định danh công dân | Định danh duy nhất mỗi bản ghi trong bảng; **không được phép trùng lặp và không được nhận `NULL`**. | `users.id` (`1, 2, 3...`) |
| **Khóa ngoại (`Foreign Key` — FK)** | Mã khách hàng ghi trên hóa đơn | Cột ở bảng con tham chiếu tới `PK` của bảng cha nhằm bảo đảm tính toàn vẹn liên kết. | `orders.user_id` tham chiếu tới `users.id` |
| **Khóa duy nhất (`Unique`)** | Địa chỉ email cá nhân | Ngăn chặn hai bản ghi mang cùng một giá trị, nhưng **cho phép tồn tại giá trị `NULL`**. | `users.email` |
| **Khóa ghép (`Composite Key`)** | Số phòng gồm cặp `(Tầng, Số cửa)` | Kết hợp từ hai cột trở lên để cùng tạo thành định danh duy nhất cho một bản ghi. | Bảng chi tiết đơn hàng: `(order_id, product_id)` |

---

## 1.5 Các kiểu dữ liệu phổ biến trong PostgreSQL

Việc xác định chính xác kiểu dữ liệu ngay từ giai đoạn thiết kế giúp tối ưu không gian lưu trữ, nâng cao hiệu quả bộ nhớ đệm và phòng tránh sai số tính toán:

| Nhóm dữ liệu | Kiểu khuyên dùng | Đặc tả kỹ thuật và lưu ý thực hành |
| :--- | :--- | :--- |
| **Số nguyên** | `int` (4 byte) / `bigint` (8 byte) | Dùng `int` cho giá trị vừa phải như `stock` (tồn kho) và `bigint` cho định danh bảng phát sinh lớn như `orders.id` (hỗ trợ khoảng giá trị tới hơn 9 tỷ tỷ). |
| **Tiền tệ và số thập phân chính xác** | `numeric(12, 2)` | Lưu trữ chính xác tới 12 chữ số với 2 chữ số phần thập phân. **Không dùng `float` hoặc `real` cho dữ liệu tài chính**, vì biểu diễn số thực dấu phẩy động nhị phân gây sai số làm tròn (chẳng hạn `0.1 + 0.2 = 0.30000000000000004`). |
| **Văn bản** | `varchar(n)` / `text` | Dùng `varchar(15)` khi cần giới hạn độ dài tối đa ở tầng lưu trữ (như số điện thoại) và `text` cho văn bản độ dài tự do; trong PostgreSQL cả hai có hiệu năng xử lý tương đương nhau. |
| **Ngày và giờ** | `timestamptz` / `date` | Kiểu `timestamptz` lưu dấu thời gian có kèm múi giờ và tự động chuẩn hóa theo UTC; kiểu `date` chỉ lưu ngày tháng (ví dụ `'2002-05-20'`). |
| **Logic nhị phân** | `boolean` | Chỉ tiếp nhận trạng thái `true`, `false` (hoặc `NULL`), phù hợp cho các cờ như `is_active`. |
| **Định danh ngẫu nhiên** | `uuid` | Mã 128-bit dạng `a0eebc99-9c0b-...` (tạo bằng `gen_random_uuid()`), dùng khi cần che giấu thứ tự tăng dần của khóa chính trước người dùng bên ngoài. |
| **Dữ liệu bán cấu trúc** | `jsonb` | Lưu trữ thuộc tính động dưới dạng nhị phân đã phân tích cú pháp sẵn (như thông số kỹ thuật riêng theo từng chủng loại sản phẩm). |

---

## 1.6 Ba mối quan hệ giữa các bảng (1-1, 1-N, N-N)

![Hình 1.3: Liên kết qua Khóa chính (PK), Khóa ngoại (FK) và Ba loại quan hệ giữa các bảng](img/02_keys_relations.svg)

Mọi mô hình dữ liệu quan hệ (**Hình 1.3**) đều được xây dựng từ ba dạng liên kết cơ bản sau:

1. **Quan hệ `1 - 1` (Một — Một):** Một tài khoản (`users`) tương ứng với duy nhất một hồ sơ định danh (`profiles`). Về mặt cài đặt, cột khóa ngoại `user_id` tại bảng `profiles` được gắn đồng thời cả hai ràng buộc `FOREIGN KEY` và `UNIQUE`.
2. **Quan hệ `1 - N` (Một — Nhiều):** Đây là mối quan hệ phổ biến nhất; chẳng hạn một khách hàng (`users`) có thể sở hữu nhiều đơn hàng (`orders`), nhưng mỗi đơn hàng chỉ thuộc về một khách hàng duy nhất. Quy tắc thiết kế chuẩn là **đặt cột khóa ngoại (`user_id`) tại bảng ở phía "Nhiều" (`orders`)**.
3. **Quan hệ `N - N` (Nhiều — Nhiều):** Một đơn hàng có thể bao gồm nhiều sản phẩm, đồng thời một sản phẩm có thể xuất hiện trong nhiều đơn hàng khác nhau. Do bảng quan hệ hai chiều không thể biểu diễn trực tiếp liên kết này, thiết kế **bắt buộc phải tách qua một bảng trung gian** (như `order_items`) chứa hai khóa ngoại `order_id` và `product_id` kèm các thuộc tính phát sinh của liên kết như `quantity`.

---

## 1.7 Chuẩn hóa dữ liệu (1NF, 2NF, 3NF) và Phản chuẩn hóa

Khi thiết kế thiếu cấu trúc, toàn bộ thuộc tính thường bị gộp chung vào một bảng lớn tương tự bảng tính phẳng. Cách tổ chức này tạo ra sự dư thừa dữ liệu trên quy mô lớn và dẫn đến các dị thường khi cập nhật: chẳng hạn khi đổi tên hoặc địa chỉ một phòng ban, hệ thống buộc phải sửa hàng loạt bản ghi nhân viên tương ứng. **Chuẩn hóa dữ liệu (Normalization)** là quy trình tái cấu trúc bảng qua ba dạng chuẩn kế tiếp nhau nhằm triệt tiêu sự dư thừa này (**Hình 1.4**):

![Hình 1.4: Chuẩn hóa dữ liệu (1NF → 2NF → 3NF) nhằm loại bỏ dư thừa và dị thường cập nhật](img/03_normalization_3nf.svg)

- **Dạng chuẩn 1 (`1NF`) — Tính nguyên tử của thuộc tính:** Mỗi ô dữ liệu chỉ chứa duy nhất một giá trị đơn, không gộp nhiều giá trị thành danh sách trong một cột (như `'0912.xxx, 0987.xxx'`). Trường hợp một nhân viên có nhiều số điện thoại cần tách thành bảng riêng `sdt_nv`, mỗi số nằm trên một bản ghi độc lập.
- **Dạng chuẩn 2 (`2NF`) — Phụ thuộc hoàn toàn vào khóa chính:** Mọi cột không thuộc khóa phải phụ thuộc vào toàn bộ khóa chính chứ không chỉ một phần của khóa ghép. Trong bảng `order_items(order_id, product_id, quantity)`, thuộc tính `ten_san_pham` chỉ phụ thuộc vào `product_id` mà không phụ thuộc vào `order_id`, do đó phải đặt tại bảng `products`.
- **Dạng chuẩn 3 (`3NF`) — Loại bỏ phụ thuộc bắc cầu:** Mọi cột không thuộc khóa chỉ phụ thuộc trực tiếp vào khóa chính, không phụ thuộc gián tiếp qua một cột không khóa khác. Bảng `nhan_vien` chỉ lưu khóa ngoại `ma_phong`, còn `ten_phong` và `dia_chi_phong` được tách về bảng `phong_ban`.

> **Phản chuẩn hóa có chủ đích (Denormalization):** Sau khi thiết kế đạt chuẩn `3NF`, trong một số kịch bản truy vấn đọc cường độ cao, kỹ sư có thể chủ động lưu dư thừa một số giá trị tổng hợp nhằm tránh thao tác ghép bảng và tính toán lặp lại. Ví dụ điển hình là lưu sẵn cột `tong_tien` trên bảng `orders` để hiển thị danh sách đơn hàng tức thì thay vì mỗi lần truy vấn đều phải quét bảng `order_items`.

---

# Phần 2: Kiến Trúc PostgreSQL 16 và Môi Trường Thực Hành

## 2.1 Cấu trúc phân cấp 4 tầng của PostgreSQL

Trong các tài liệu kỹ thuật hoặc thông báo của PostgreSQL, tên bảng thường đi kèm tiền tố như `public.users`. Cách định danh này bắt nguồn từ kiến trúc phân cấp logic bốn tầng của PostgreSQL, có thể hình dung tương đồng với cấu trúc một tòa nhà văn phòng đa cấp (**Hình 2.1**):

![Hình 2.1: Phân cấp logic 4 tầng của PostgreSQL và Cấu trúc chuỗi kết nối (URI)](img/04_pg_hierarchy_uri.svg)

1. **Cluster (Cụm máy chủ):** Một tiến trình máy chủ PostgreSQL đang vận hành (mặc định lắng nghe trên cổng TCP `5432`), quản lý đồng thời nhiều cơ sở dữ liệu.
2. **Database (Cơ sở dữ liệu):** Đơn vị phân vùng dữ liệu độc lập dành cho từng hệ thống hoặc ứng dụng (chẳng hạn `appdb` và `analytics_db`). Các Database được cách ly hoàn toàn ở cấp kết nối và không thể thực hiện `JOIN` trực tiếp xuyên qua nhau.
3. **Schema (Lược đồ / Không gian tên):** Lớp phân nhóm logic bên trong mỗi Database giúp phân tách các bảng theo phân hệ nghiệp vụ (ví dụ `sales.orders` hoặc `inventory.products`). Mặc định, mọi Database đều khởi tạo sẵn schema **`public`**; câu lệnh `CREATE TABLE users` thực chất tạo bảng tại `public.users`.
4. **Table (Bảng):** Đơn vị lưu trữ vật lý cuối cùng chứa cấu trúc cột và các bản ghi dữ liệu.

---

## 2.2 Triển khai PostgreSQL 16 và pgAdmin 4 với Docker Compose

Thay vì cài đặt trực tiếp các dịch vụ nền lên hệ điều hành máy trạm, Docker Compose cho phép đóng gói và khởi chạy đồng thời máy chủ **PostgreSQL 16** cùng công cụ quản trị đồ họa trên nền web **pgAdmin 4** trong một mạng nội bộ cô lập (**Hình 2.2**).

![Hình 2.2: Kiến trúc triển khai PostgreSQL 16 và pgAdmin 4 bằng Docker Compose](img/04b_docker_pgadmin_flow.svg)

Khởi tạo tệp cấu hình `docker-compose.yml` với nội dung sau:

```yaml
services:
  postgres:
    image: postgres:16-alpine
    container_name: postgres_pg16
    restart: unless-stopped
    environment:
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: SecretPassword123!
      POSTGRES_DB: appdb
    ports:
      - "127.0.0.1:5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U admin -d appdb"]
      interval: 5s
      timeout: 5s
      retries: 5

  pgadmin:
    image: dpage/pgadmin4:8
    container_name: pgadmin_ui
    restart: unless-stopped
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@example.com
      PGADMIN_DEFAULT_PASSWORD: SecretPassword123!
    ports:
      - "127.0.0.1:5050:80"
    depends_on:
      postgres:
        condition: service_healthy

volumes:
  pgdata:
```

Các thao tác cơ bản để vận hành cụm container qua dòng lệnh:

```bash
docker compose up -d              # Khởi chạy PostgreSQL (:5432) và pgAdmin (:5050) ở chế độ nền
docker compose logs -f postgres   # Theo dõi nhật ký hệ thống (nhấn Ctrl+C để ngừng theo dõi)
docker compose down               # Dừng và gỡ container (dữ liệu vẫn được bảo toàn trong volume pgdata)
```

Sau khi dịch vụ khởi động hoàn tất, mở trình duyệt tại địa chỉ `http://localhost:5050`, đăng nhập bằng `admin@example.com` và mật khẩu `SecretPassword123!`. Chọn mục **Add New Server**, sau đó trong thẻ **Connection** khai báo **Host name** là `postgres` (tên dịch vụ trong mạng nội bộ Docker), **Port** là `5432`, **Username** là `admin` và **Password** là `SecretPassword123!`.

---

## 2.3 Chuỗi kết nối (Connection URI) và Biến môi trường

Ở tầng ứng dụng (Python, Node.js, C++/Qt, Go), trình điều khiển (driver) kết nối tới máy chủ cơ sở dữ liệu thông qua **Connection URI** có cấu trúc chuẩn như minh họa tại **Hình 2.1**:

```text
postgresql://admin:SecretPassword123!@127.0.0.1:5432/appdb?sslmode=disable
```

> **Nguyên tắc an toàn thông tin:** Thông tin xác thực không được nhúng cố định bên trong mã nguồn ứng dụng mà phải được tách ra tệp biến môi trường (`.env`) hoặc hệ thống quản lý khóa bí mật. Thư viện kết nối chuẩn của PostgreSQL hỗ trợ tự động đọc các biến môi trường sau:
> ```ini
> PGHOST=127.0.0.1
> PGPORT=5432
> PGDATABASE=appdb
> PGUSER=admin
> PGPASSWORD=SecretPassword123!
> ```

---

## 2.4 Các lệnh điều khiển thường dùng trong `psql`

`psql` là trình khách dòng lệnh chính thức của PostgreSQL, cho phép thực thi truy vấn và kiểm tra trạng thái hệ thống trực tiếp từ cửa sổ dòng lệnh:

```bash
docker exec -it postgres_pg16 psql -U admin -d appdb
```

| Lệnh tắt | Chức năng | Ví dụ sử dụng |
| :--- | :--- | :--- |
| `\l` | Liệt kê toàn bộ cơ sở dữ liệu trên Cluster | `\l` |
| `\c <db>` | Chuyển kết nối sang cơ sở dữ liệu khác | `\c appdb` |
| `\dn` / `\du` | Liệt kê danh sách Schema (`\dn`) hoặc danh sách tài khoản (`\du`) | `\dn` |
| `\dt` / `\dt+` | Liệt kê các bảng hiện có; thêm `+` để hiển thị thêm dung lượng chiếm dụng | `\dt+` |
| `\d <bảng>` | Hiển thị chi tiết cấu trúc cột, kiểu dữ liệu, ràng buộc và chỉ mục của bảng | `\d users` |
| `\x` | Bật/tắt chế độ hiển thị mở rộng theo chiều dọc cho bảng có nhiều cột | `\x` |
| `\timing` | Bật/tắt chế độ đo thời gian thực thi (tính bằng mili-giây) cho từng truy vấn | `\timing` |
| `\i <file>` | Thực thi toàn bộ các câu lệnh SQL chứa trong một tệp kịch bản | `\i init.sql` |
| `\q` | Đóng phiên làm việc `psql` | `\q` |

---

# Phần 3: Thực Hành Ngôn Ngữ Truy Vấn SQL

Toàn bộ các ví dụ truy vấn trong Phần 3 sử dụng thống nhất mô hình dữ liệu **hệ thống thương mại điện tử gồm 4 bảng** (`categories`, `products`, `users`, `orders`) được trình bày tại **Hình 3.1**.

![Hình 3.1: Lược đồ 4 bảng dữ liệu mẫu dùng trong Phần 3](img/06b_sample_schema_erd.svg)

---

## 3.1 Định nghĩa và sửa đổi cấu trúc bảng (DDL)

Nhóm lệnh **DDL (Data Definition Language)** chịu trách nhiệm khởi tạo, thay đổi và hủy bỏ cấu trúc đối tượng trong cơ sở dữ liệu cũng như thiết lập các ràng buộc toàn vẹn:

```sql
-- Tạo bảng danh mục sử dụng chuẩn định danh tự tăng hiện đại (Identity Column)
CREATE TABLE categories (
    id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(100) NOT NULL UNIQUE
);

-- Tạo bảng sản phẩm kèm khóa ngoại và các ràng buộc kiểm tra miền giá trị
CREATE TABLE products (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(255) NOT NULL,
    price numeric(12, 2) NOT NULL CHECK (price >= 0),
    stock int NOT NULL DEFAULT 0 CHECK (stock >= 0),
    category_id int REFERENCES categories(id) ON DELETE SET NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);
```

| Thao tác biến đổi cấu trúc | Câu lệnh SQL tương ứng |
| :--- | :--- |
| **Bổ sung cột mới vào bảng hiện hữu** | `ALTER TABLE products ADD COLUMN brand varchar(50);` |
| **Đổi tên cột** | `ALTER TABLE products RENAME COLUMN stock TO quantity;` |
| **Bổ sung ràng buộc kiểm tra dữ liệu** | `ALTER TABLE products ADD CONSTRAINT chk_price CHECK (price >= 0);` |
| **Xóa bảng (kèm `IF EXISTS` tránh lỗi nếu chưa tồn tại)** | `DROP TABLE IF EXISTS products CASCADE;` |

---

## 3.2 Thêm, Đọc, Sửa và Xóa dữ liệu (DML)

Nhóm lệnh **DML (Data Manipulation Language)** thực hiện các thao tác trực tiếp trên các bản ghi dữ liệu bên trong bảng:

| Thao tác | Câu lệnh minh họa | Lưu ý kỹ thuật |
| :--- | :--- | :--- |
| **Chèn một bản ghi (`INSERT`)** | `INSERT INTO products (name, price, stock) VALUES ('Chuột không dây', 350000, 50) RETURNING id;` | Mệnh đề `RETURNING id` trả về ngay mã định danh vừa sinh ra mà không cần gửi thêm một lệnh `SELECT`. |
| **Chèn hàng loạt (`Multi-row INSERT`)** | `INSERT INTO categories (name) VALUES ('Laptop'), ('Phụ kiện'), ('Màn hình');` | Giảm đáng kể chi phí giao tiếp mạng và phân tích cú pháp so với thực thi từng lệnh `INSERT` đơn lẻ trong vòng lặp. |
| **Đọc dữ liệu (`SELECT`)** | `SELECT id, name, price FROM products ORDER BY price DESC LIMIT 10;` | Chỉ định tường minh danh sách cột cần lấy; hạn chế dùng `SELECT *` để tránh truyền tải các cột không cần thiết. |
| **Cập nhật dữ liệu (`UPDATE`)** | `UPDATE products SET stock = stock - 1 WHERE id = 1 RETURNING stock;` | Thiếu mệnh đề `WHERE` sẽ dẫn tới cập nhật ngoài ý muốn toàn bộ các dòng trong bảng. |
| **Xóa bản ghi có điều kiện (`DELETE`)** | `DELETE FROM products WHERE stock = 0;` | Tương tự `UPDATE`, thiếu mệnh đề `WHERE` sẽ xóa toàn bộ bản ghi trong bảng. |
| **Làm trống toàn bộ bảng (`TRUNCATE`)** | `TRUNCATE TABLE logs RESTART IDENTITY;` | Giải phóng toàn bộ dữ liệu trong bảng với tốc độ rất cao và đặt lại bộ đếm định danh tự tăng về `1`. |

---

## 3.3 Lọc và tìm kiếm dữ liệu với `WHERE`

| Nhu cầu lọc dữ liệu | Biểu thức ví dụ | Giải thích ngắn gọn |
| :--- | :--- | :--- |
| **So sánh bằng / khác** | `WHERE status = 'completed' AND amount <> 0` | Toán tử so sánh khác trong SQL là `<>` hoặc `!=`. |
| **Nằm trong đoạn (`BETWEEN`)** | `WHERE price BETWEEN 100000 AND 500000` | Lọc giá trị từ `100.000` đến `500.000`, bao gồm cả hai cận. |
| **Thuộc tập giá trị (`IN`)** | `WHERE category_id IN (1, 2, 5)` | Cách viết gọn và rõ nghĩa hơn so với nối nhiều điều kiện `OR`. |
| **Tìm kiếm theo mẫu (`LIKE` / `ILIKE`)** | `WHERE name ILIKE '%macbook%'` | Ký tự đại diện `%` khớp với chuỗi bất kỳ; `LIKE` phân biệt chữ hoa/thường, trong khi **`ILIKE`** (đặc trưng của PostgreSQL) không phân biệt hoa/thường. |
| **Kiểm tra khuyết dữ liệu (`IS NULL`)** | `WHERE email IS NULL` | Bắt buộc dùng `IS NULL` hoặc `IS NOT NULL` thay cho phép so sánh `= NULL`. |
| **Cung cấp giá trị thay thế (`COALESCE`)** | `SELECT name, COALESCE(phone, 'Chưa cập nhật') FROM users;` | Trả về tham số đầu tiên khác `NULL`, hữu ích khi hiển thị giá trị mặc định cho dữ liệu trống. |

---

## 3.4 Thống kê gom nhóm (`GROUP BY`, `HAVING`) và Thứ tự thực thi SQL

Để viết các truy vấn tổng hợp chính xác, cần phân biệt rõ giữa thứ tự viết câu lệnh SQL và **thứ tự thực thi logic** của hệ quản trị cơ sở dữ liệu (**Hình 3.2**). Mặc dù từ khóa `SELECT` được đặt ở đầu câu, bộ xử lý truy vấn luôn đánh giá `FROM` và `WHERE` trước khi gom nhóm bằng `GROUP BY` và lọc nhóm bằng `HAVING`. Do `SELECT` được đánh giá ở bước sau, các bí danh (alias) khai báo tại `SELECT` không thể dùng lại trong mệnh đề `WHERE`.

![Hình 3.2: Thứ tự thực thi logic của câu lệnh SQL và Phân biệt GROUP BY với Window Function](img/05_sql_execution_order.svg)

**Các hàm tổng hợp thống kê cơ bản:**
- `COUNT(*)`: Đếm tổng số dòng trong nhóm | `COUNT(email)`: Chỉ đếm các dòng có cột `email` khác `NULL`.
- `SUM(col)`: Tính tổng | `AVG(col)`: Tính trung bình cộng | `MIN(col)` / `MAX(col)`: Xác định giá trị nhỏ nhất / lớn nhất.

**Ví dụ phân biệt `WHERE` và `HAVING`:** Xét yêu cầu tìm các danh mục có từ **3 sản phẩm có giá trên 50.000đ** trở lên và tính đơn giá trung bình của từng danh mục đó:

```sql
SELECT
    category_id,
    COUNT(*) AS so_sp,
    ROUND(AVG(price), 0) AS gia_tb
FROM products
WHERE price > 50000          -- Giai đoạn 2: Loại bỏ các sản phẩm <= 50.000đ trước khi gom nhóm
GROUP BY category_id         -- Giai đoạn 3: Gom các sản phẩm đạt điều kiện theo từng danh mục
HAVING COUNT(*) >= 3         -- Giai đoạn 4: Chỉ giữ lại các nhóm có từ 3 sản phẩm trở lên
ORDER BY gia_tb DESC;        -- Giai đoạn 6: Sắp xếp danh mục theo giá trung bình giảm dần
```

---

## 3.5 Kết hợp nhiều bảng với `JOIN`

Sau khi chuẩn hóa dữ liệu, thông tin khách hàng nằm ở bảng `users` trong khi thông tin giao dịch nằm ở bảng `orders`. Mệnh đề `JOIN` cho phép liên kết lại hai tập dữ liệu này thông qua điều kiện khóa chung `u.id = o.user_id` (**Hình 3.3**).

![Hình 3.3: Minh họa tập hợp kết quả của các phép ghép bảng (SQL JOIN) giữa A (users) và B (orders)](img/06_sql_joins_visual.svg)

Để đối chiếu hành vi của từng loại phép ghép bảng, xét hai tập dữ liệu mẫu sau:
- Bảng trái **`users` (`u`)**: `(1, Phong)`, `(2, Linh)`, `(3, Tuấn — chưa phát sinh đơn hàng)`.
- Bảng phải **`orders` (`o`)**: `(101, user_id=1, 500k)`, `(102, user_id=1, 200k)`, `(103, user_id=2, 300k)`, `(104, user_id=99, 150k — đơn hàng chưa liên kết người dùng)`.

| Phép ghép bảng | Cú pháp minh họa | Kết quả trên dữ liệu mẫu | Ngữ cảnh áp dụng thực tế |
| :--- | :--- | :--- | :--- |
| **`INNER JOIN`** | `FROM users u INNER JOIN orders o ON u.id = o.user_id` | 3 dòng khớp nhau: `Phong (101)`, `Phong (102)`, `Linh (103)` (loại `Tuấn` và đơn `104`). | Truy xuất các đơn hàng hợp lệ có đầy đủ thông tin người mua tương ứng. |
| **`LEFT JOIN`** | `FROM users u LEFT JOIN orders o ON u.id = o.user_id` | 4 dòng: Giữ toàn bộ `Phong`, `Linh` và **`Tuấn (NULL, NULL)`**. | Thống kê toàn bộ khách hàng kèm doanh số, bảo đảm khách hàng chưa mua vẫn hiện diện. |
| **`ANTI-JOIN`** | `FROM users u LEFT JOIN orders o ON u.id = o.user_id WHERE o.id IS NULL` | 1 dòng duy nhất: **`Tuấn`**. | Lọc ra nhóm khách hàng đã đăng ký tài khoản nhưng chưa từng phát sinh giao dịch. |
| **`RIGHT JOIN`** | `FROM users u RIGHT JOIN orders o ON u.id = o.user_id` | 4 dòng: Các đơn hợp lệ kèm **`(NULL, 104, 150k)`** (thường viết đảo thứ tự bảng sang `LEFT JOIN` để đồng nhất cách đọc). | Phát hiện các bản ghi đơn hàng bị thiếu tham chiếu khách hàng hợp lệ. |
| **`FULL OUTER JOIN`** | `FROM users u FULL OUTER JOIN orders o ON u.id = o.user_id` | 5 dòng: Giữ đồng thời cả `Tuấn (NULL)` và `(NULL, 104)`. | Đối soát sai lệch dữ liệu hai chiều giữa hai bảng hoặc hai hệ thống. |
| **`CROSS JOIN`** | `FROM sizes CROSS JOIN colors` | Tích Descartes `3 kích cỡ × 2 màu = 6 tổ hợp` (không có mệnh đề `ON`). | Sinh toàn bộ tổ hợp biến thể sản phẩm từ các bảng thuộc tính độc lập. |
| **`SELF JOIN`** | `FROM employees e LEFT JOIN employees m ON e.manager_id = m.id` | Tự ghép bảng `employees` để ánh xạ nhân viên `e` với quản lý trực tiếp `m`. | Biểu diễn cấu trúc phân cấp cây như sơ đồ nhân sự hoặc danh mục đa cấp. |

---

## 3.6 Truy vấn con (Subquery), Biểu thức bảng chung (CTE), UPSERT và UNION

Đối với các bài toán phân tích hoặc ghi dữ liệu phức tạp hơn một truy vấn đơn lẻ, SQL cung cấp bốn cấu trúc quan trọng sau:

1. **Biểu thức bảng chung (`CTE` — mệnh đề `WITH`):** Phân tách một truy vấn phức tạp thành các bước trung gian có đặt tên, giúp mã SQL mạch lạc và dễ bảo trì:
   ```sql
   -- Bước 1: Tổng hợp chi tiêu của từng khách hàng để lọc nhóm khách hàng VIP (>= 10 triệu)
   WITH vip_users AS (
       SELECT user_id, SUM(amount) AS tong_chi
       FROM orders
       WHERE status = 'completed'
       GROUP BY user_id
       HAVING SUM(amount) >= 10000000
   )
   -- Bước 2: Liên kết với bảng users để lấy thông tin định danh và liên hệ
   SELECT u.name, u.email, v.tong_chi
   FROM users u
   INNER JOIN vip_users v ON u.id = v.user_id;
   ```

2. **Thao tác `UPSERT` (`INSERT ... ON CONFLICT`):** Thực hiện nguyên tử thao tác "thêm mới nếu chưa tồn tại, cập nhật nếu đã trùng khóa xung đột", tránh tình trạng tranh chấp (race condition) khi kiểm tra và ghi tách rời:
   ```sql
   INSERT INTO users (id, name, email)
   VALUES (1, 'Phong', 'phong_moi@mail.com')
   ON CONFLICT (id)
   DO UPDATE SET email = EXCLUDED.email, name = EXCLUDED.name;
   ```

3. **Kiểm tra sự tồn tại với `EXISTS`:** Đánh giá theo cơ chế đoản mạch (dừng tìm kiếm ngay khi gặp bản ghi đầu tiên thỏa điều kiện), cho hiệu năng cao và tránh bẫy logic `NULL` của toán tử `IN`:
   ```sql
   -- Liệt kê khách hàng đã có ít nhất một đơn hàng
   SELECT id, name
   FROM users u
   WHERE EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id);
   ```

4. **Gộp tập kết quả theo chiều dọc (`UNION` và `UNION ALL`):**
   - `UNION ALL`: Nối trực tiếp tập kết quả của hai câu `SELECT` mà không loại bỏ bản ghi trùng lặp, nhờ đó đạt tốc độ thực thi tối ưu.
   - `UNION`: Tự động sắp xếp hoặc băm dữ liệu để loại bỏ các dòng trùng nhau giữa hai tập kết quả, tốn thêm chi phí bộ nhớ và CPU.

---

## 3.7 Hàm cửa sổ (Window Functions) và Kiểu dữ liệu `JSONB`

### 1. Hàm cửa sổ (`OVER`) — Tính toán tổng hợp mà không làm mất chi tiết dòng

Như minh họa tại **Hình 3.2**, trong khi `GROUP BY` thu gọn nhiều bản ghi thành một dòng đại diện cho mỗi nhóm, **hàm cửa sổ (`OVER (...)`)** giữ nguyên toàn bộ các bản ghi chi tiết và bổ sung thêm cột tính toán theo từng phân vùng (window):

```sql
-- Xếp hạng sản phẩm theo giá giảm dần trong phạm vi từng danh mục
SELECT
    name,
    category_id,
    price,
    RANK() OVER (PARTITION BY category_id ORDER BY price DESC) AS thu_hang_gia
FROM products;
```

Bên cạnh `RANK()`, bộ hàm cửa sổ còn cung cấp `ROW_NUMBER()` để đánh số thứ tự liên tục `1, 2, 3...` và `LAG()` để truy xuất giá trị của bản ghi liền trước (thường dùng khi tính tỷ lệ tăng trưởng doanh thu qua từng kỳ).

### 2. Truy vấn dữ liệu bán cấu trúc `JSONB`

```sql
-- Giả sử bảng products có cột specs kiểu jsonb chứa: '{"ram": "16GB", "cpu": "M3"}'
-- 1. Trích xuất giá trị kiểu văn bản của thuộc tính 'ram' bằng toán tử ->>
SELECT name, specs->>'ram' AS dung_luong_ram FROM products;

-- 2. Lọc các sản phẩm thỏa mãn cấu hình bằng toán tử bao hàm @> (có thể tăng tốc bằng GIN Index)
SELECT id, name FROM products WHERE specs @> '{"ram": "16GB"}';
```

---

# Phần 4: Giao Dịch (Transaction) và Xử Lý Đồng Thời

## 4.1 Giao dịch (Transaction) và Nguyên tắc ACID

Trong các hệ thống thực tế, nhiều thao tác thay đổi dữ liệu bắt buộc phải đi liền với nhau thành một khối duy nhất. Hãy hình dung nghiệp vụ chuyển 1.000.000đ từ tài khoản A sang tài khoản B: hệ thống phải thực hiện hai bước là trừ tiền ở tài khoản A, sau đó cộng tiền vào tài khoản B. Nếu bước thứ nhất đã xong nhưng hệ thống gặp sự cố ngay trước khi bước thứ hai kịp thực thi, khoản tiền 1.000.000đ sẽ bị biến mất một cách vô lý.

Một **Transaction (Giao dịch)** giải quyết bài toán này bằng cách gom chuỗi các câu lệnh SQL thành một đơn vị bất khả phân theo nguyên tắc: **"hoặc thực thi trọn vẹn tất cả (`COMMIT`), hoặc hủy bỏ hoàn toàn để khôi phục trạng thái ban đầu (`ROLLBACK`)"** (**Hình 4.1**).

![Hình 4.1: Giao dịch (ACID), Kiểm soát đa phiên bản (MVCC) và Khóa dòng (Row Locking)](img/07_acid_mvcc_locking.svg)

```sql
BEGIN;                                                        -- Khởi đầu giao dịch
UPDATE accounts SET balance = balance - 1000000 WHERE id = 1; -- Trừ số dư tài khoản nguồn
UPDATE accounts SET balance = balance + 1000000 WHERE id = 2; -- Cộng số dư tài khoản đích
COMMIT;                                                       -- Xác nhận và lưu trữ bền vững
-- Nếu phát sinh lỗi ở bất kỳ bước nào trước khi COMMIT, thực thi ROLLBACK; để hoàn tác
```

**Ví dụ minh họa hoàn tác giao dịch (`ROLLBACK`):** Giả sử tài khoản A (`id = 1`) đang có số dư `5.000.000`. Khi mở giao dịch để chuyển tiền nhưng câu lệnh thứ hai gõ nhầm tên cột `balanc`, PostgreSQL lập tức báo lỗi và từ chối mọi thay đổi trước đó sau khi gọi `ROLLBACK`:

```sql
BEGIN;
UPDATE accounts SET balance = balance - 1000000 WHERE id = 1; -- Tạm trừ 1.000.000 trong giao dịch
UPDATE accounts SET balanc = balanc + 1000000 WHERE id = 2;   -- Lỗi cú pháp: thiếu chữ 'e'
-- Kết quả: ERROR:  column "balanc" of relation "accounts" does not exist
-- Giao dịch chuyển sang trạng thái lỗi; các lệnh tiếp theo bị từ chối cho tới khi hoàn tác
ROLLBACK;
SELECT balance FROM accounts WHERE id = 1; -- Kết quả vẫn giữ nguyên 5000000
```

Độ tin cậy của giao dịch trong hệ quản trị CSDL quan hệ được bảo chứng bởi bốn tính chất **ACID**:

| Tính chất | Ý nghĩa | Ví dụ trong bài toán chuyển tiền |
| :--- | :--- | :--- |
| **Atomicity (Tính nguyên tử)** | Giao dịch là đơn vị không thể chia nhỏ; mọi bước bên trong hoặc cùng thành công, hoặc cùng bị hủy bỏ. | Không bao giờ xảy ra trạng thái tài khoản A đã mất 1.000.000đ mà tài khoản B chưa nhận được tiền. |
| **Consistency (Tính nhất quán)** | Giao dịch luôn giữ dữ liệu tuân thủ mọi quy tắc ràng buộc (`CHECK`, `UNIQUE`, `FOREIGN KEY`) trước và sau khi kết thúc. | Nếu cột `balance` có ràng buộc `CHECK (balance >= 0)`, lệnh chuyển 6.000.000đ khi tài khoản A chỉ còn 5.000.000đ sẽ bị từ chối ngay. |
| **Isolation (Tính cô lập)** | Các giao dịch chạy đồng thời được che chắn hợp lý, không làm nhiễu số liệu dở dang của nhau. | Khi giao dịch chuyển tiền đang chạy giữa chừng và chưa `COMMIT`, người khác kiểm tra số dư sẽ không thấy tiền bị trừ nửa vời. |
| **Durability (Tính bền vững)** | Một khi giao dịch đã báo `COMMIT` thành công, mọi thay đổi được lưu trữ vĩnh viễn trên ổ đĩa. | Dù máy chủ gặp sự cố mất điện ngay sau khi `COMMIT`, khi khởi động lại dữ liệu chuyển tiền vẫn còn nguyên vẹn (nhờ cơ chế `WAL` ở mục **6.1**). |

---

## 4.2 Cơ chế kiểm soát đa phiên bản (MVCC)

Trong hệ thống vận hành thực tế, một truy vấn xuất báo cáo doanh thu kéo dài nhiều phút thường diễn ra song song với hàng loạt giao dịch cập nhật đơn hàng hoặc sửa giá sản phẩm. Nếu hệ thống bắt người đọc báo cáo và người cập nhật phải chờ nhau, ứng dụng sẽ bị chậm trễ nghiêm trọng. PostgreSQL tránh tình trạng khóa chặn lẫn nhau này nhờ cơ chế **MVCC (Multi-Version Concurrency Control)** (**Hình 4.1**).

Ý tưởng cốt lõi của MVCC rất trực quan: khi cập nhật một dòng dữ liệu, PostgreSQL **không ghi đè trực tiếp lên bản đang có**, mà tạo ra một **phiên bản mới (bản sao mới)** của dòng đó kèm thông tin định danh giao dịch. Nhờ vậy, người đang đọc vẫn nhìn thấy phiên bản cũ ổn định tại thời điểm giao dịch đọc bắt đầu, trong khi người sửa làm việc độc lập trên phiên bản mới.

**Ví dụ minh họa:** Bảng dưới đây theo dõi diễn biến theo thời gian giữa **Giao dịch A** (đọc báo cáo) và **Giao dịch B** (cập nhật giá một sản phẩm đang có giá `100.000`):

| Thời điểm | Giao dịch A (Người đọc báo cáo) | Giao dịch B (Người cập nhật giá) |
| :--- | :--- | :--- |
| **Thời điểm 1** | Chạy `BEGIN;`, đọc giá sản phẩm thấy `100.000`. | Chưa bắt đầu. |
| **Thời điểm 2** | Đang xử lý tiếp các tính toán khác. | Chạy `BEGIN;` và `UPDATE products SET price = 150000 WHERE id = 1;` (chưa `COMMIT`). |
| **Thời điểm 3** | Đọc lại giá sản phẩm vẫn thấy `100.000` (không bị chờ B, không thấy giá dở dang). | Vẫn đang mở giao dịch. |
| **Thời điểm 4** | Hoàn tất đọc báo cáo và `COMMIT;`. | Chạy `COMMIT;` để xác nhận mức giá mới `150.000`. |
| **Thời điểm 5** | Một giao dịch mới mở sau Thời điểm 4 sẽ đọc thấy giá mới `150.000`. | Đã kết thúc. |

Như vậy, trong suốt quá trình Giao dịch B sửa dữ liệu, Giao dịch A không hề bị chặn chờ. Những phiên bản cũ không còn giao dịch nào tham chiếu tới sẽ trở thành *Dead Tuples* và được tiến trình `Autovacuum` tự động thu hồi về sau (trình bày chi tiết ở mục **5.4**).

---

## 4.3 Các bất thường khi đọc đồng thời và Mức cô lập (Isolation Levels)

Khi nhiều giao dịch vừa đọc vừa ghi cùng lúc, người thiết kế cần quyết định **Mức cô lập (Isolation Level)** — tức mức độ một giao dịch được che chắn khỏi các thay đổi đang diễn ra ở những giao dịch khác. Trước khi chọn mức phù hợp, cần hiểu rõ ba hiện tượng đọc lệch dữ liệu có thể xảy ra.

### 1. Dirty Read (Đọc dữ liệu bẩn)

Đây là tình huống một giao dịch đọc phải dữ liệu mà giao dịch khác vừa sửa nhưng **chưa `COMMIT`**. Nếu giao dịch kia hủy bỏ (`ROLLBACK`), giao dịch đọc sẽ sử dụng nhầm một con số chưa từng tồn tại chính thức.

| Thời điểm | Giao dịch A (Người đọc) | Giao dịch B (Người sửa) |
| :--- | :--- | :--- |
| **Thời điểm 1** | Chưa bắt đầu. | Chạy `BEGIN;` và sửa giá áo từ `100.000` thành `150.000` (chưa `COMMIT`). |
| **Thời điểm 2** | Đọc giá áo và nhận nhầm giá tạm `150.000` (nếu Dirty Read xảy ra). | Vẫn chưa `COMMIT`. |
| **Thời điểm 3** | Đã dùng nhầm số `150.000` để tính hóa đơn. | Gặp lỗi và chạy `ROLLBACK;`, giá áo quay lại `100.000`. |

*Lưu ý quan trọng:* **PostgreSQL không bao giờ cho phép Dirty Read, ngay cả ở mức cô lập thấp nhất.**

### 2. Non-repeatable Read (Đọc không lặp lại)

Trong cùng một giao dịch đang chạy, cùng một câu lệnh đọc một dòng dữ liệu ở hai thời điểm lại cho hai kết quả khác nhau do ở giữa có giao dịch khác đã `COMMIT` thay đổi mới.

| Thời điểm | Giao dịch A (Mức mặc định `READ COMMITTED`) | Giao dịch B (Người sửa) |
| :--- | :--- | :--- |
| **Thời điểm 1** | Chạy `BEGIN;`, đọc giá áo lần 1 thấy `100.000`. | Chưa bắt đầu. |
| **Thời điểm 2** | Đang xử lý bước tiếp theo. | Chạy `BEGIN;`, sửa giá áo thành `150.000` rồi `COMMIT;`. |
| **Thời điểm 3** | Đọc lại chính chiếc áo đó lần 2 thấy nhảy lên `150.000`. | Đã kết thúc. |

### 3. Phantom Read (Đọc bóng ma)

Trong cùng một giao dịch, hai lần đếm số lượng dòng theo cùng một điều kiện lại cho ra số lượng khác nhau vì có giao dịch khác vừa chèn thêm (hoặc xóa bớt) bản ghi thỏa điều kiện đó và `COMMIT`.

| Thời điểm | Giao dịch A (Mức mặc định `READ COMMITTED`) | Giao dịch B (Người thêm đơn mới) |
| :--- | :--- | :--- |
| **Thời điểm 1** | Chạy `BEGIN;`, đếm số đơn hàng hôm nay được `100` đơn. | Chưa bắt đầu. |
| **Thời điểm 2** | Đang tổng hợp số liệu. | Chạy `BEGIN;`, thêm 1 đơn hàng mới vào bảng `orders` và `COMMIT;`. |
| **Thời điểm 3** | Đếm lại đơn hàng cuối giao dịch thấy tăng thành `101` đơn (xuất hiện 1 dòng mới). | Đã kết thúc. |

Bảng dưới đây tổng hợp khả năng ngăn chặn của ba mức cô lập phổ biến trong PostgreSQL:

| Bất thường dữ liệu | Mô tả hiện tượng trong cùng một giao dịch | `READ COMMITTED` (Mặc định) | `REPEATABLE READ` | `SERIALIZABLE` |
| :--- | :--- | :---: | :---: | :---: |
| **1. Dirty Read (Đọc dữ liệu bẩn)** | Đọc phải thay đổi của giao dịch khác khi giao dịch đó **chưa `COMMIT`**. | Đã ngăn chặn | Đã ngăn chặn | Đã ngăn chặn |
| **2. Non-repeatable Read (Đọc không lặp lại)** | Đọc cùng một dòng hai lần trong một giao dịch nhưng nhận hai giá trị khác nhau sau khi giao dịch khác `COMMIT`. | Có thể xảy ra | **Đã ngăn chặn** | **Đã ngăn chặn** |
| **3. Phantom Read (Đọc bóng ma)** | Đếm tập bản ghi theo cùng điều kiện hai lần nhưng số lượng dòng thay đổi do có giao dịch khác chèn/xóa và `COMMIT`. | Có thể xảy ra | **Đã ngăn chặn** | **Đã ngăn chặn** |

**Lựa chọn mức cô lập trong thực tiễn:**

- **Mức mặc định (`READ COMMITTED`):** Đáp ứng tốt khoảng 95% tác vụ ứng dụng thông thường nhờ chi phí quản lý xung đột thấp nhất và ít gây chờ đợi.
- **Mức ảnh chụp nhất quán (`REPEATABLE READ`):** Phù hợp cho tác vụ xuất báo cáo tài chính hoặc đối soát nhiều bảng đòi hỏi toàn bộ số liệu đứng yên xuyên suốt giao dịch:
  ```sql
  BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
  SELECT COUNT(*), SUM(amount) FROM orders; -- Kết quả luôn nhất quán với thời điểm mở giao dịch
  COMMIT;
  ```
- **Mức cô lập tuần tự (`SERIALIZABLE`):** Đảm bảo kết quả của các giao dịch chạy song song giống hệt như khi xếp hàng chạy lần lượt từng giao dịch một. Mức này chỉ dùng cho nghiệp vụ tài chính đặc thù và đòi hỏi tầng ứng dụng cài đặt cơ chế tự động thử lại (retry) nếu phát sinh lỗi xung đột tuần tự hóa.

---

## 4.4 Khóa mức dòng xử lý tranh chấp đồng thời: `FOR UPDATE` và `SKIP LOCKED`

### 1. Chống bán vượt tồn kho bằng khóa bi quan (`FOR UPDATE`)

Khi một mặt hàng trong kho chỉ còn `stock = 1` và hai khách hàng cùng nhấn thanh toán tại một thời điểm, việc kiểm tra tồn kho thông thường sẽ dẫn đến sai sót nghiêm trọng.

**Ví dụ minh họa khi không sử dụng khóa:**

| Thời điểm | Giao dịch A (Khách 1) | Giao dịch B (Khách 2) |
| :--- | :--- | :--- |
| **Thời điểm 1** | Đọc `stock` thấy bằng `1` (kiểm tra `1 >= 1` hợp lệ). | Đọc `stock` cũng thấy bằng `1` (kiểm tra `1 >= 1` hợp lệ). |
| **Thời điểm 2** | Trừ kho: `stock = 1 - 1 = 0` và `COMMIT;`. | Trừ kho: `stock = 0 - 1 = -1` (bán vượt tồn kho hoặc lỗi `CHECK stock >= 0`). |

Để tránh tình trạng này, mệnh đề **`FOR UPDATE`** (**Hình 4.1**) cho phép khóa giữ độc quyền chính dòng sản phẩm đang xét. Bất kỳ giao dịch nào khác đọc cùng dòng đó bằng `FOR UPDATE` sẽ phải đứng chờ cho tới khi giao dịch đầu tiên `COMMIT` hoặc `ROLLBACK`:

| Thời điểm | Giao dịch A (Khách 1 — vào trước) | Giao dịch B (Khách 2 — vào sau) |
| :--- | :--- | :--- |
| **Thời điểm 1** | Chạy `SELECT ... FOR UPDATE`, đọc thấy `stock = 1` và **giữ khóa dòng `id = 100`**. | Chạy `SELECT ... FOR UPDATE` trên `id = 100`, **phải tạm dừng chờ A**. |
| **Thời điểm 2** | Cập nhật `stock = 0` và chạy `COMMIT;` (mở khóa). | Vẫn đang chờ tới khi A hoàn tất. |
| **Thời điểm 3** | Đã hoàn tất bán hàng. | Được mở khóa, đọc được `stock = 0`, kiểm tra thấy hết hàng và dừng giao dịch an toàn. |

```sql
BEGIN;
SELECT stock FROM products WHERE id = 100 FOR UPDATE; -- Khóa giữ dòng id=100; giao dịch đến sau phải chờ
-- Sau khi tầng ứng dụng kiểm tra stock >= 1 mới thực hiện trừ kho:
UPDATE products SET stock = stock - 1 WHERE id = 100;
COMMIT; -- Giải phóng khóa; giao dịch kế tiếp đọc được stock = 0 và dừng xử lý an toàn
```

### 2. Phân phối hàng đợi tác vụ song song không nghẽn (`SKIP LOCKED`)

Trong các hệ thống gửi email hoặc xử lý tác vụ nền, nhiều tiến trình (worker) thường cùng lấy việc từ một bảng hàng đợi `task_queue`. Nếu chỉ dùng `FOR UPDATE`, khi Worker 1 đang xử lý dòng `id = 1`, Worker 2 và Worker 3 đều bị chặn lại để chờ Worker 1 làm xong, khiến hệ thống không thể chạy song song.

Từ khóa **`SKIP LOCKED`** giải quyết vấn đề này bằng cách cho phép mỗi tiến trình **bỏ qua ngay các dòng đang bị tiến trình khác khóa** để nhận ngay dòng khả dụng tiếp theo.

**Ví dụ minh họa:** Giả sử bảng `task_queue` đang có 5 email chờ gửi (`id` từ `1` đến `5`) và 3 tiến trình worker cùng lấy việc một lúc:

| Tiến trình | Hành động với `FOR UPDATE SKIP LOCKED` | Tác vụ nhận được |
| :--- | :--- | :--- |
| **Worker 1** | Quét từ đầu danh sách, dòng `id = 1` đang tự do nên khóa lấy. | Xử lý email `id = 1`. |
| **Worker 2** | Thấy dòng `id = 1` đang bị khóa, bỏ qua ngay và lấy dòng kế tiếp. | Xử lý email `id = 2`. |
| **Worker 3** | Thấy dòng `id = 1` và `id = 2` đang bị khóa, bỏ qua cả hai và lấy dòng tiếp theo. | Xử lý email `id = 3`. |

```sql
BEGIN;
SELECT id, email_to
FROM task_queue
WHERE status = 'pending'
ORDER BY id
LIMIT 1
FOR UPDATE SKIP LOCKED;
-- Sau khi gửi email xong, cập nhật trạng thái hoàn tất tác vụ:
UPDATE task_queue SET status = 'done' WHERE id = :id;
COMMIT;
```

---

# Phần 5: Chỉ Mục (Index), Tối Ưu Truy Vấn và Bảo Trì Dữ Liệu

## 5.1 Chỉ mục (Index) và cơ chế tăng tốc tìm kiếm

![Hình 5.1: So sánh tìm kiếm bản ghi id = 85 trong bảng 10 triệu dòng (Không Index và Có B-Tree Index)](img/08_index_btree_vs_seqscan.svg)

Có thể hình dung một bảng dữ liệu gồm 10 triệu dòng giống như một cuốn sách dày nhiều nghìn trang, còn **Chỉ mục (Index)** chính là phần mục lục đã được sắp xếp theo thứ tự tra cứu ở đầu sách (**Hình 5.1**). Tùy thuộc vào việc cột tìm kiếm có chỉ mục hay không và tỷ lệ dữ liệu cần lấy, bộ lập kế hoạch truy vấn (Query Planner) của PostgreSQL sẽ chọn một trong ba phương thức đọc dữ liệu sau:

| Phương thức quét | Phép ẩn dụ tương ứng | Điều kiện kích hoạt |
| :--- | :--- | :--- |
| **`Seq Scan` (Quét tuần tự)** | Đọc lướt từng trang từ trang đầu đến trang cuối sách. | Bảng chưa có Index phù hợp, bảng rất nhỏ, hoặc truy vấn cần lấy phần lớn số dòng của bảng. |
| **`Index Scan` (Quét qua chỉ mục)** | Tra mục lục tìm số trang rồi lật thẳng tới trang dữ liệu đó. | Truy vấn lọc một tập con nhỏ bản ghi thông qua cột đã đánh Index (ví dụ `WHERE email = '...'`). |
| **`Index Only Scan`** | Mọi thông tin cần đọc nằm sẵn ngay trên mục lục, không cần mở vào ruột sách. | Toàn bộ các cột liệt kê ở `SELECT` và `WHERE` đều nằm trọn trong cấu trúc của Index (**tốc độ cao nhất**). |

**Ví dụ minh họa trước và sau khi tạo Index:** Xét bảng `users` chứa 1 triệu bản ghi và câu truy vấn tìm người dùng theo email:

```sql
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'linh@mail.com';
```

- **Trước khi có Index** (kết quả minh họa; con số thực tế phụ thuộc vào phần cứng): Bộ lập kế hoạch phải duyệt toàn bộ bảng với dòng thông báo `Seq Scan on users ... Execution Time: 180 ms`.
- **Sau khi tạo Index:**
  ```sql
  CREATE INDEX idx_users_email ON users(email);
  EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'linh@mail.com';
  ```
  Kết quả minh họa lúc này chuyển thành `Index Scan using idx_users_email on users ... Execution Time: 0.05 ms` nhờ nhảy thẳng tới trang chứa dòng cần tìm chỉ sau vài phép so sánh.

**Ví dụ minh họa về chi phí của Index:** Index tăng tốc độ đọc nhưng không miễn phí. Nếu một bảng có tới 6 chỉ mục khác nhau, mỗi khi ứng dụng chạy một câu lệnh `INSERT` để thêm 1 dòng mới, PostgreSQL không chỉ ghi dữ liệu vào 1 bảng mà còn phải cập nhật thêm cả 6 cấu trúc chỉ mục đi kèm, làm chậm thao tác ghi và tiêu tốn thêm dung lượng ổ đĩa.

**Hai nguyên tắc thiết kế chỉ mục quan trọng:**

1. Các cột có ràng buộc **`PRIMARY KEY`** hoặc **`UNIQUE`** được PostgreSQL **tự động tạo sẵn chỉ mục B-Tree**; không cần tạo thêm chỉ mục trùng lặp.
2. **Tránh tạo chỉ mục tràn lan trên mọi cột:** Chỉ nên đánh chỉ mục cho các cột thường xuyên dùng để lọc trong **`WHERE`**, các cột khóa ngoại tham gia **`JOIN`**, và các cột dùng để sắp xếp trong **`ORDER BY`**.

---

## 5.2 Các loại Index phổ biến trong PostgreSQL

| Loại chỉ mục | Phạm vi áp dụng tối ưu | Câu lệnh khởi tạo mẫu |
| :--- | :--- | :--- |
| **B-Tree (Mặc định)** | Đáp ứng khoảng 90% nhu cầu tìm kiếm với các phép toán `=`, `>`, `<`, `BETWEEN`, `IN`, `ORDER BY` và tiền tố `LIKE 'abc%'`. | `CREATE INDEX idx_orders_user ON orders(user_id);` |
| **Composite (Đa cột)** | Phục vụ truy vấn lọc đồng thời theo nhiều cột (ưu tiên đặt cột lọc so sánh bằng `=` ở đầu danh sách). | `CREATE INDEX idx_orders_user_status ON orders(user_id, status);` |
| **Partial (Chỉ mục bộ phận)** | Chỉ đánh chỉ mục trên một tập con dữ liệu thỏa điều kiện `WHERE`, giúp giảm mạnh kích thước chỉ mục. | `CREATE INDEX idx_orders_pending ON orders(created_at) WHERE status = 'pending';` |
| **Expression (Theo biểu thức)** | Tăng tốc truy vấn lọc qua hàm biến đổi, chẳng hạn tìm kiếm email không phân biệt hoa/thường. | `CREATE INDEX idx_users_lower_email ON users(lower(email));` |
| **GIN (Generalized Inverted Index)** | Chuyên dụng cho tìm kiếm thành phần bên trong cột **`JSONB`**, mảng (array) hoặc tìm kiếm toàn văn (Full-Text Search). | `CREATE INDEX idx_products_specs ON products USING gin (specs);` |

### Ví dụ minh họa cho từng loại chỉ mục

- **B-Tree:** Câu lệnh `SELECT * FROM orders WHERE user_id = 7;` đi thẳng theo cây chỉ mục đã sắp xếp tới các đơn hàng của khách hàng `7` thay vì đọc cả bảng `orders`.
- **Composite (`(user_id, status)`):** Truy vấn `SELECT * FROM orders WHERE user_id = 7 AND status = 'pending';` dùng được chỉ mục này, nhưng truy vấn chỉ lọc `WHERE status = 'pending'` đứng một mình lại **không dùng được**. Có thể hình dung cấu trúc này giống một cuốn danh bạ điện thoại sắp xếp theo **Họ** trước rồi mới đến **Tên**: nếu biết trước Họ thì tìm rất nhanh, còn nếu chỉ biết Tên mà không biết Họ thì vẫn phải lật kiểm tra toàn bộ cuốn danh bạ.
- **Partial:** Truy vấn `SELECT id, created_at FROM orders WHERE status = 'pending' ORDER BY created_at;` khai thác chỉ mục `idx_orders_pending` có dung lượng rất nhỏ vì hàng triệu đơn hàng đã hoàn tất (`'completed'`) không nằm trong chỉ mục này.
- **Expression:** Câu lệnh `SELECT id FROM users WHERE lower(email) = 'abc@mail.com';` sử dụng được chỉ mục `idx_users_lower_email` vì biểu thức ở mệnh đề `WHERE` trùng khớp với biểu thức đã dùng khi tạo Index.
- **GIN:** Câu lệnh `SELECT id, name FROM products WHERE specs @> '{"ram": "16GB"}';` định vị nhanh các sản phẩm có cấu hình RAM 16GB bên trong cột `JSONB`.

Như đã minh họa ở mục **5.1**, đặt từ khóa **`EXPLAIN ANALYZE`** ngay trước câu lệnh `SELECT` là cách trực tiếp nhất để kiểm chứng xem truy vấn có thực sự sử dụng `Index Scan` hay đang rơi vào `Seq Scan`.

---

## 5.3 Nguyên tắc viết câu lệnh SQL hiệu quả

Ngay cả khi bảng đã có đầy đủ chỉ mục, cách viết điều kiện truy vấn thiếu tối ưu vẫn có thể khiến chỉ mục bị vô hiệu hóa hoặc làm tăng đột biến chi phí đọc đĩa:

| Tình huống | Cách viết hạn chế hiệu năng / dễ lỗi | Cách viết tối ưu | Cơ sở kỹ thuật |
| :--- | :--- | :--- | :--- |
| **1. Chọn cột truy vấn** | `SELECT * FROM orders;` | `SELECT id, amount FROM orders;` | Giảm dung lượng đọc đĩa và băng thông truyền tải đối với các cột dài không sử dụng. |
| **2. Lọc theo khoảng thời gian** | `WHERE EXTRACT(YEAR FROM created_at) = 2026` | `WHERE created_at >= '2026-01-01' AND created_at < '2027-01-01'` | Bọc cột dữ liệu trong hàm biến đổi khiến bộ lập kế hoạch không thể dùng B-Tree Index trên `created_at`. |
| **3. Tìm chuỗi với `LIKE`** | `WHERE name LIKE '%iphone'` | `WHERE name LIKE 'iphone%'` | Cây B-Tree sắp xếp chuỗi từ trái sang phải; ký tự `%` ở đầu chuỗi vô hiệu hóa việc tìm kiếm theo tiền tố. |
| **4. Kiểm tra phần tử vắng mặt** | `WHERE id NOT IN (SELECT user_id FROM orders)` | `WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id)` | Nếu truy vấn con của `NOT IN` chứa dù chỉ một giá trị `NULL`, toàn bộ kết quả trả về sẽ rỗng; `NOT EXISTS` vừa chính xác vừa nhanh hơn. |
| **5. Phân trang dữ liệu sâu** | `ORDER BY id LIMIT 20 OFFSET 500000` | `WHERE id > 500000 ORDER BY id LIMIT 20` | `OFFSET` lớn buộc cơ sở dữ liệu quét và loại bỏ tuần tự 500.000 dòng đầu; phân trang theo con trỏ (`id > ...`) định vị thẳng tới vị trí cần đọc qua Index. |
| **6. Chèn dữ liệu số lượng lớn** | Lặp 1.000 lần các lệnh `INSERT` đơn lẻ | Gộp nhiều bộ giá trị trong một câu lệnh `VALUES (...), (...);` | Triệt tiêu hàng nghìn lượt khứ hồi mạng (round-trip) và giảm chi phí ghi nhận giao dịch xuống còn một lần. |

### Ví dụ minh họa chi tiết hai lỗi phổ biến

- **Bẫy `NOT IN` khi gặp giá trị `NULL`:** Giả sử bảng `users` có các `id` là `1, 2, 3`, còn bảng `orders` có các giá trị `user_id` gồm `1` và một đơn hàng vãng lai mang giá trị `NULL`. Khi chạy câu lệnh `SELECT id FROM users WHERE id NOT IN (SELECT user_id FROM orders);`, điều kiện bên trong tương đương `id NOT IN (1, NULL)`. Theo logic ba giá trị của SQL (mục **1.3**), phép so sánh `3 <> NULL` cho kết quả không xác định, khiến điều kiện lọc không thỏa mãn cho bất kỳ dòng nào và trả về **0 dòng** thay vì `2` và `3` như mong đợi. Khi chuyển sang `WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id)`, truy vấn trả về chính xác `2` và `3`.
- **Phân trang bằng `OFFSET` và phân trang theo con trỏ:** Lệnh `ORDER BY id LIMIT 20 OFFSET 500000` hoạt động giống như yêu cầu người đọc phải đếm bỏ qua 500.000 dòng đầu tiên rồi mới lấy 20 dòng tiếp theo; trang càng sâu thì thời gian chờ càng lâu. Ngược lại, với phân trang theo con trỏ (keyset pagination), ở trang 1 ứng dụng chạy `SELECT id, name FROM orders ORDER BY id LIMIT 20;` và lưu lại `id` cuối cùng vừa nhận (ví dụ `20`); sang trang 2, ứng dụng chỉ cần truy vấn `SELECT id, name FROM orders WHERE id > 20 ORDER BY id LIMIT 20;` để nhảy thẳng đến vị trí cần đọc thông qua Index.

---

## 5.4 Thu hồi không gian lưu trữ với `VACUUM` và `Autovacuum`

Do cơ chế **MVCC** (mục **4.2**), mỗi thao tác `UPDATE` hoặc `DELETE` không xóa ngay dữ liệu cũ trên ổ đĩa mà để lại các phiên bản dòng hết hiệu lực (*Dead Tuples*).

**Ví dụ minh họa:** Nếu giá của một sản phẩm trong bảng `products` bị cập nhật 3 lần liên tiếp, trên ổ đĩa lúc này sẽ tồn tại 1 phiên bản mới nhất đang được sử dụng và 3 phiên bản cũ (*Dead Tuples*) vẫn chiếm chỗ trống, giống như những tờ giấy nháp chưa được thu dọn sau khi đã viết xong bản chính. Nếu không dọn dẹp, dung lượng bảng sẽ phình to dần theo thời gian.

Người quản trị có thể quan sát số lượng dòng sống, số lượng *Dead Tuples* đang chờ thu hồi và thời điểm dọn dẹp gần nhất của một bảng (ví dụ bảng `orders`) thông qua khung nhìn thống kê hệ thống:

```sql
SELECT relname, n_live_tup, n_dead_tup, last_autovacuum
FROM pg_stat_user_tables
WHERE relname = 'orders';
```

Trong kết quả trả về: `relname` là tên bảng; `n_live_tup` là số dòng đang còn hiệu lực; `n_dead_tup` là số phiên bản cũ đang chờ thu hồi; còn `last_autovacuum` cho biết thời điểm hệ thống tự động dọn dẹp gần nhất.

- **`Autovacuum` (Tiến trình nền tự động — Mặc định luôn bật):** Định kỳ quét và đánh dấu tái sử dụng không gian lưu trữ của các *Dead Tuples* cho các bản ghi mới, đồng thời cập nhật thống kê phân bố dữ liệu (`ANALYZE`) giúp bộ lập kế hoạch chọn đúng chỉ mục. Tiến trình này cần được duy trì hoạt động liên tục trong môi trường vận hành thực tế.
- **Bảo trì chủ động khi cần thiết:** Lệnh `VACUUM ANALYZE orders;` dọn dẹp và cập nhật thống kê trực tuyến mà không khóa các thao tác đọc/ghi thông thường của ứng dụng. Ngược lại, cần tránh thực thi `VACUUM FULL` khi hệ thống đang phục vụ người dùng vì lệnh này áp đặt khóa độc quyền toàn bảng trong suốt quá trình nén lại tệp vật lý.

---

# Phần 6: Phục Hồi Dữ Liệu và Bảo Mật Hệ Thống

## 6.1 Nhật ký ghi trước (WAL) và cơ chế phục hồi sau sự cố

Bộ nhớ RAM cho tốc độ đọc ghi rất nhanh nhưng sẽ mất trắng khi ngắt điện; ngược lại, ổ cứng lưu trữ bền vững nhưng việc tìm và sửa rải rác từng trang dữ liệu trên các bảng lớn tốn nhiều chi phí I/O. PostgreSQL kết hợp ưu điểm của cả hai nhờ cơ chế **Nhật ký ghi trước (`WAL` — Write-Ahead Logging)** (**Hình 6.1**).

![Hình 6.1: Cơ chế nhật ký WAL (Write-Ahead Logging) và Hai nguyên tắc bảo mật cơ bản](img/09_wal_and_security.svg)

Có thể hình dung cơ chế này giống như quy trình làm việc của một thủ kho cẩn trọng: mỗi khi có giao dịch phát sinh, thủ kho ghi chép nhanh ngay vào một cuốn sổ nhật ký tổng hợp trước, đến cuối ngày mới sắp xếp và cập nhật lại từng kệ hàng lớn trong kho. Nhờ vậy, nếu kho hàng bị mất điện giữa chừng, người quản lý chỉ cần mở lại cuốn sổ nhật ký để khôi phục đầy đủ các giao dịch đã ghi nhận.

Trong PostgreSQL, chu trình lưu trữ bền vững diễn ra qua ba bước tuần tự:

1. **Cập nhật trên bộ nhớ đệm (RAM):** Mọi thay đổi dữ liệu trước hết được thực hiện ở tốc độ bộ nhớ trên vùng đệm `Shared Buffers`.
2. **Ghi nối vào nhật ký `WAL`:** Khi thực thi `COMMIT`, PostgreSQL chỉ ghi nối tuần tự một bản ghi mô tả thay đổi vào cuối tệp nhật ký `WAL` trên ổ đĩa, sau đó mới báo giao dịch thành công. Việc ghi nối tiếp vào cuối tệp giống như viết thêm một dòng vào trang cuối cuốn sổ, nhanh hơn rất nhiều so với việc phải lật tìm và tẩy xóa ở 10 trang khác nhau nằm rải rác trên ổ đĩa.
3. **Đồng bộ xuống tệp bảng chính (Checkpoint):** Theo chu kỳ định sẵn, tiến trình nền gom nhiều thay đổi từ `Shared Buffers` để ghi đồng bộ xuống các tệp dữ liệu chính tại thư mục `base/`.

Bảng dưới đây tóm tắt trạng thái dữ liệu khi xảy ra sự cố mất điện ở từng thời điểm:

| Thời điểm xảy ra sự cố mất điện | Trạng thái giao dịch sau khi khởi động lại PostgreSQL |
| :--- | :--- |
| **Trước khi `COMMIT` hoàn tất** | Giao dịch coi như chưa từng xảy ra; mọi thay đổi dở dang bị loại bỏ hoàn toàn. |
| **Sau `COMMIT` nhưng trước `Checkpoint`** | Dữ liệu chưa kịp ghi xuống `base/`, nhưng PostgreSQL tự động đọc lại nhật ký `WAL` để tái tạo đầy đủ 100% giao dịch đã `COMMIT`. |
| **Sau khi `Checkpoint` hoàn tất** | Dữ liệu đã được đồng bộ an toàn vào cả các tệp bảng chính `base/`. |

---

## 6.2 Quản lý phân quyền truy cập với `ROLE`

Theo **nguyên tắc đặc quyền tối thiểu (Principle of Least Privilege)**, mỗi thành phần chỉ nên được cấp đúng những quyền cần thiết cho công việc của mình. Tài khoản quản trị tối cao (`postgres` hoặc `admin`) tuyệt đối không được dùng làm tài khoản kết nối cho mã nguồn ứng dụng hay công cụ báo cáo, nhằm ngăn ngừa rủi ro lộ thông tin hoặc thực thi nhầm lệnh phá hủy cấu trúc như `DROP TABLE`. Hệ thống cần phân tách quyền hạn qua **`ROLE`** (**Hình 6.1**):

```sql
-- 1. Nhóm quyền chỉ đọc phục vụ công cụ thống kê, báo cáo (BI / Grafana)
CREATE ROLE role_readonly;
GRANT CONNECT ON DATABASE appdb TO role_readonly;
GRANT USAGE ON SCHEMA public TO role_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO role_readonly;

-- 2. Nhóm quyền đọc và thao tác dòng dữ liệu cho ứng dụng Backend (không có quyền sửa/xóa cấu trúc bảng)
CREATE ROLE role_readwrite;
GRANT CONNECT ON DATABASE appdb TO role_readwrite;
GRANT USAGE ON SCHEMA public TO role_readwrite;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO role_readwrite;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO role_readwrite; -- Bảo đảm cột ID tự tăng hoạt động

-- 3. Khởi tạo tài khoản đăng nhập riêng biệt và gán vào từng nhóm quyền tương ứng
CREATE USER bi_viewer WITH PASSWORD 'MatKhauBaoCao_123!';
GRANT role_readonly TO bi_viewer;

CREATE USER app_backend WITH PASSWORD 'MatKhauUngDung_123!';
GRANT role_readwrite TO app_backend;
```

**Ví dụ minh họa kiểm chứng phân quyền:** Khi đăng nhập vào `psql` bằng tài khoản báo cáo `bi_viewer` (`psql -U bi_viewer -d appdb`) và thử chạy `DELETE FROM orders WHERE id = 1;`, PostgreSQL lập tức từ chối với thông báo `ERROR:  permission denied for table orders`. Tương tự, nếu tài khoản `app_backend` thực thi `DROP TABLE orders;`, hệ thống trả về `ERROR:  must be owner of table orders`, giúp bảo vệ toàn bộ cấu trúc bảng ngay cả khi mã nguồn ứng dụng gặp lỗi.

**Lưu ý khi tạo thêm bảng mới trong tương lai:** Hai câu lệnh `GRANT ... ON ALL TABLES` ở trên chỉ có tác dụng với những bảng đang tồn tại tại thời điểm cấp quyền. Để các bảng được tạo thêm về sau tự động áp dụng đúng quyền hạn (lưu ý lệnh này áp dụng cho các bảng do chính tài khoản thực thi `ALTER DEFAULT PRIVILEGES` tạo ra), cần cấu hình bổ sung quyền mặc định:

```sql
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO role_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO role_readwrite;
```

---

## 6.3 Lưu trữ mật khẩu an toàn bằng hàm băm và muối (`pgcrypto` / `bcrypt`)

Khi thiết kế chức năng xác thực tài khoản, **mật khẩu gốc (plaintext) tuyệt đối không được phép lưu trực tiếp trong cơ sở dữ liệu**, bởi bất kỳ ai đọc được bảng (hoặc tệp sao lưu) đều biết ngay mật khẩu của toàn bộ người dùng. Phương pháp tiêu chuẩn là áp dụng **hàm băm mật mã một chiều (`Hash`) kết hợp muối ngẫu nhiên (`Salt`)** theo thuật toán **`bcrypt`** (**Hình 6.1**).

- **Băm một chiều:** Có thể hình dung hàm băm giống như chiếc máy xay sinh tố — từ trái cây có thể xay ra ly nước ép, nhưng từ ly nước ép không có cách nào ghép ngược trở lại thành trái cây ban đầu. Hàm băm biến `'MatKhau123'` thành một chuỗi ký tự cố định sao cho không thể dịch ngược về mật khẩu gốc.
- **Trộn muối ngẫu nhiên (`Salt`):** Hệ thống tự sinh một chuỗi ký tự ngẫu nhiên riêng cho từng tài khoản để trộn vào mật khẩu trước khi băm. Nhờ vậy, hai người dùng cùng đặt một mật khẩu vẫn tạo ra hai chuỗi băm khác nhau hoàn toàn, làm vô hiệu hóa kỹ thuật dò bằng bảng mật khẩu băm sẵn (Rainbow Table).
- **Xác thực khi đăng nhập:** Lấy mật khẩu người dùng vừa nhập, băm lại cùng đúng chuỗi `Salt` đã dùng trước đó và đối chiếu với chuỗi đang lưu trong bảng.

**Ví dụ minh họa tác dụng của `Salt` và cấu trúc chuỗi `bcrypt`:** Thử băm cùng một mật khẩu `'123456'` hai lần liên tiếp bằng `pgcrypto`:

```sql
SELECT crypt('123456', gen_salt('bf', 10)) AS lan_1,
       crypt('123456', gen_salt('bf', 10)) AS lan_2;
```

Kết quả trả về ở cột `lan_1` và `lan_2` là hai chuỗi hoàn toàn khác nhau, chẳng hạn có dạng `$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy`. Chuỗi này chứa đầy đủ thông tin để xác thực về sau:
- `$2a$` là ký hiệu thuật toán `bcrypt`.
- `10$` là hệ số chi phí (cost factor); mỗi khi tăng giá trị này thêm 1 đơn vị thì thời gian tính toán băm sẽ tăng gấp đôi, khiến kẻ tấn công không thể dò thử hàng tỷ mật khẩu mỗi giây.
- 22 ký tự tiếp theo chính là chuỗi `Salt` ngẫu nhiên được sinh ra lúc đăng ký.
- Phần ký tự còn lại ở cuối là giá trị băm thực sự.

Chính vì chuỗi `Salt` đã được lưu ghép ngay bên trong cột `password_hash`, khi kiểm tra đăng nhập bằng `crypt(mat_khau_nhap, password_hash)`, hàm `crypt()` tự động đọc lấy phần `Salt` nằm sẵn trong `password_hash` để băm lại mật khẩu người dùng vừa nhập và đối chiếu.

Trong PostgreSQL, phần mở rộng tích hợp sẵn **`pgcrypto`** thực hiện trọn vẹn quy trình này qua hai hàm `gen_salt()` và `crypt()`:

```sql
-- Kích hoạt phần mở rộng mã hóa (thực hiện một lần trên mỗi Database)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE accounts (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username varchar(50) NOT NULL UNIQUE,
    password_hash text NOT NULL,
    created_at timestamptz DEFAULT now()
);

-- 1. Đăng ký tài khoản: Trộn muối Blowfish (bcrypt, hệ số chi phí 10) và lưu chuỗi băm
INSERT INTO accounts (username, password_hash)
VALUES ('phongvt', crypt('MatKhau123!@#', gen_salt('bf', 10)));

-- 2. Xác thực đăng nhập: Băm lại mật khẩu nhập vào với chuỗi Salt từ password_hash để đối chiếu
SELECT id, username
FROM accounts
WHERE username = 'phongvt'
  AND password_hash = crypt('MatKhau123!@#', password_hash);
-- Trả về 1 bản ghi: xác thực hợp lệ; trả về 0 bản ghi: sai tên đăng nhập hoặc mật khẩu
```

---

# Phần 7: Vận Hành Dữ Liệu Trong Hệ Thống Thực Tế

## 7.1 Nhập dữ liệu hàng loạt và Làm sạch dữ liệu nguồn

Khi đưa một hệ thống vào vận hành — chẳng hạn tiếp nhận danh sách hàng trăm nhân viên từ tệp bảng tính hoặc phần mềm cũ — việc gửi từng câu lệnh `INSERT` rời rạc sẽ gây nghẽn do chi phí kết nối mạng và ghi nhận giao dịch lặp đi lặp lại. Trong thực tế, dữ liệu được nạp theo ba hướng chính tùy thuộc vào nguồn dữ liệu:

| Phương thức nạp | Tình huống áp dụng | Đặc điểm thực thi |
| :--- | :--- | :--- |
| **Chèn nhiều dòng (`Multi-row INSERT`)** | Dữ liệu từ vài chục đến vài nghìn dòng trong kịch bản SQL hoặc dịch vụ nền. | Gộp nhiều bộ giá trị vào một câu lệnh; có thể kết hợp `ON CONFLICT ... DO NOTHING` hoặc `DO UPDATE` để tránh gián đoạn khi gặp bản ghi trùng lặp. |
| **Luồng `COPY` / `\copy` từ tệp CSV** | Nạp trực tiếp danh sách lớn xuất từ bảng tính Excel. | Tốc độ cao nhất trong PostgreSQL nhờ đọc luồng dữ liệu theo lô; bắt buộc xuất tệp ở định dạng **CSV UTF-8** để giữ nguyên dấu tiếng Việt. |
| **Nạp theo lô trong một `Transaction`** | Người dùng tải tệp Excel/CSV lên giao diện ứng dụng. | Tầng ứng dụng kiểm tra tính hợp lệ toàn bộ tệp trước, sau đó mở một `Transaction` (`BEGIN ... COMMIT`) để đẩy cả lô dữ liệu, bảo đảm tính nguyên tử khi có dòng bị lỗi. |

Ví dụ nạp danh sách nhân viên từ tệp `nhan_vien.csv` qua công cụ `psql`:

```sql
\copy employees (full_name, email, phone, department_id, salary) FROM 'nhan_vien.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
```

**Các nguyên tắc kỹ thuật khi chuẩn bị và nạp dữ liệu:**
1. **Tuân thủ thứ tự khóa ngoại và dùng bảng tạm (`Staging Table`):** Bảng cha (như `departments`) phải được nạp trước bảng con (`employees`). Nếu tệp nguồn chỉ lưu tên phòng ban thay vì mã số, cần nạp thô vào một bảng tạm (`staging_employees`), sau đó dùng câu lệnh `INSERT INTO employees (...) SELECT ... JOIN departments ...` để ánh xạ tự động sang `department_id`.
2. **Làm sạch và chuẩn hóa dữ liệu trước khi ghi:** Loại bỏ khoảng trắng thừa (`TRIM`), chuẩn hóa chữ thường cho địa chỉ email (`LOWER`), đồng bộ định dạng ngày (`YYYY-MM-DD`), và phát hiện các dòng trùng lặp ngay trong tệp nguồn. Đặc biệt, số điện thoại và mã định danh công dân cần được xử lý dưới dạng chuỗi (`varchar`) để tránh lỗi bảng tính tự động cắt mất chữ số `0` ở đầu.
3. **Đồng bộ bộ đếm tự tăng (`Sequence`) khi giữ lại mã cũ:** Nếu dữ liệu chuyển đổi có mang theo sẵn cột `id` từ hệ thống cũ (ví dụ `id` từ `1` đến `250`), bộ đếm tự tăng của PostgreSQL có thể chưa cập nhật theo giá trị lớn nhất đó, gây lỗi trùng khóa chính ở lần thêm mới tiếp theo. Cần đồng bộ lại bộ đếm ngay sau khi hoàn tất nhập liệu:
   ```sql
   SELECT setval(pg_get_serial_sequence('employees', 'id'), COALESCE(MAX(id), 1)) FROM employees;
   ```
   *(Trường hợp bảng khai báo cột định danh `GENERATED ALWAYS AS IDENTITY`, câu lệnh `INSERT` mang theo `id` cũ cần bổ sung tùy chọn `OVERRIDING SYSTEM VALUE` trước mệnh đề `VALUES`.)*

---

## 7.2 Xóa mềm, Lưu lịch sử biến động và Nhật ký kiểm toán

Trong các hệ thống nghiệp vụ dài hạn, dữ liệu ít khi chỉ được thêm mới rồi xóa bỏ hoàn toàn mà cần duy trì tính liên tục để phục vụ đối soát và kiểm toán:

- **Xóa mềm (`Soft Delete`) thay cho xóa cứng (`DELETE`):** Khi một nhân viên nghỉ việc hoặc một sản phẩm ngừng kinh doanh, việc xóa vĩnh viễn bản ghi bằng `DELETE` sẽ làm đứt gãy tham chiếu tới hóa đơn, phiếu duyệt chi, dữ liệu chấm công hay lịch sử giao dịch cũ (hoặc bị chặn bởi ràng buộc `FOREIGN KEY`). Thay vào đó, hệ thống đánh dấu trạng thái ngừng hoạt động bằng cột `status` (`'active'`, `'resigned'`) hoặc dấu thời gian `deleted_at timestamptz`. Để duy trì tốc độ truy vấn các bản ghi đang hoạt động, có thể kết hợp với một **Partial Index** (mục **5.2**):
  ```sql
  CREATE INDEX idx_employees_active ON employees(department_id) WHERE deleted_at IS NULL;
  ```
- **Lưu trữ lịch sử biến động theo thời gian:** Các thuộc tính có thể thay đổi qua nhiều giai đoạn như mức lương, chức danh hoặc phòng ban không nên ghi đè trực tiếp lên một cột duy nhất nếu cần thống kê hoặc tính toán lại số liệu của các kỳ trước. Mô hình phù hợp là tách sang bảng lịch sử (chẳng hạn `salary_history`) kèm cặp mốc thời gian hiệu lực `effective_from` và `effective_to`.
- **Dấu vết kiểm toán (`Audit Trail`):** Các bảng nghiệp vụ cốt lõi thường đi kèm các cột theo dõi thời điểm tạo (`created_at`), thời điểm cập nhật (`updated_at`) và tài khoản thực hiện (`updated_by`). Với những thao tác nhạy cảm như điều chỉnh lương hoặc thay đổi quyền hạn, hệ thống ghi nhận thêm bảng `audit_logs` lưu giá trị trước và sau khi chỉnh sửa.

---

## 7.3 Bảo vệ dữ liệu nhạy cảm, Sao lưu và Quản lý phiên bản lược đồ

Bên cạnh bảo mật xác thực ở tầng kết nối, việc vận hành cơ sở dữ liệu trong môi trường doanh nghiệp đòi hỏi tuân thủ ba quy chuẩn sau:

1. **Kiểm soát dữ liệu định danh cá nhân (PII) và Môi trường thử nghiệm:**
   - Hồ sơ nhân sự hoặc khách hàng thường chứa dữ liệu nhạy cảm như mức lương, số căn cước công dân và thông tin ngân hàng. Ngoài phân quyền qua `ROLE` (mục **6.2**), cần tách các trường nhạy cảm sang bảng riêng hoặc áp dụng cơ chế **bảo mật mức dòng (`Row-Level Security` — RLS)** để giới hạn phạm vi đọc theo từng người dùng, đồng thời bật mã hóa **SSL/TLS** trên kết nối mạng.
   - Không sao chép nguyên bản cơ sở dữ liệu vận hành (Production) về máy cá nhân hoặc môi trường thử nghiệm (Dev/Test); mọi dữ liệu cá nhân nhạy cảm phải được ẩn danh hóa (data masking) hoặc thay bằng dữ liệu giả lập trước khi sử dụng cho việc phát triển.
2. **Sao lưu tự động và Diễn tập khôi phục:**
   - Cơ chế nhật ký `WAL` (mục **6.1**) bảo vệ trước sự cố mất điện hoặc khởi động lại đột ngột, nhưng không thay thế được bản sao lưu khi xảy ra hỏng ổ đĩa vật lý hay thao tác xóa nhầm dữ liệu.
   - Cần thiết lập lịch sao lưu tự động định kỳ (qua `pg_dump` cho sao lưu logic hoặc `pg_basebackup` cho sao lưu vật lý), lưu trữ bản sao tại hạ tầng độc lập với máy chủ chính và **định kỳ thực hiện kiểm thử khôi phục (restore test)** để bảo đảm tệp sao lưu luôn toàn vẹn.
3. **Quản lý thay đổi cấu trúc bằng Migration:**
   - Không chỉnh sửa cấu trúc bảng trực tiếp bằng tay trên cơ sở dữ liệu đang vận hành. Mọi thay đổi (`ALTER TABLE`, thêm ràng buộc, tạo chỉ mục) cần được đóng gói thành các tệp **Migration** có đánh số phiên bản (thông qua các công cụ như Flyway, Liquibase, Alembic hoặc Prisma), giúp kiểm soát lịch sử thay đổi trong kho mã nguồn và triển khai đồng nhất qua các môi trường.
