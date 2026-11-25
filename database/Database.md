# Nhập Môn Cơ Sở Dữ Liệu và PostgreSQL 16

> Giáo trình từng bước giúp người mới bắt đầu đi từ con số 0 đến hiểu cách thiết kế bảng, viết truy vấn SQL, xử lý giao dịch đồng thời, tối ưu hiệu năng và vận hành PostgreSQL 16 trong ứng dụng phần mềm thực tế.
>
> - **Bộ dữ liệu thực hành xuyên suốt Phần 3 – 5:** [`database-demo/`](database-demo/01_create_tables.sql) (`01_create_tables.sql`, `02_insert_sample_data.sql`, `03_verify_database.sql`).
> - **Ứng dụng desktop mẫu (Qt 6 + PostgreSQL 16 + Docker):** [`qt-postgres-login-demo/`](qt-postgres-login-demo/README.md).

---

## Lộ trình học tập gợi ý

Tùy theo nền tảng hiện tại, bạn có thể chọn một trong ba lộ trình sau:

| Đối tượng người học | Lộ trình khuyên đọc | Mục tiêu đạt được |
| :--- | :--- | :--- |
| **Người mới từ con số 0** | **Phần 0 → Phần 1 → Phần 2 → Phần 3** + **Phụ lục B** | Hiểu ứng dụng giao tiếp với DB ra sao, tự thiết kế bảng chuẩn 3NF, dựng PostgreSQL và viết thành thạo các câu lệnh SQL cơ bản đến trung cấp. |
| **Người đã biết sơ qua SQL** | **Phần 2 → Phần 3 → Phần 4 → Phần 5** | Chuẩn hóa tư duy trên PostgreSQL 16, làm chủ MVCC, Isolation Levels, khóa dòng (`FOR UPDATE`, `SKIP LOCKED`), Index và `EXPLAIN ANALYZE`. |
| **Lập trình viên phát triển phần mềm** | Toàn bộ **Phần 0 – Phần 7**, **Phụ lục A** + [`qt-postgres-login-demo/`](qt-postgres-login-demo/README.md) | Nắm vững bảo mật truy vấn (SQL Injection & Prepared Statements), phân quyền `ROLE`, `bcrypt`, `WAL`, sao lưu, Migration và kiến trúc ứng dụng thực tế. |

---

## Mục lục

- [**Phần 0: Tổng Quan Cơ Sở Dữ Liệu Trong Ứng Dụng Phần Mềm**](#phần-0-tổng-quan-cơ-sở-dữ-liệu-trong-ứng-dụng-phần-mềm) *(Cơ bản)*
  - [0.1 Năm câu hỏi đầu tiên trước khi học Database](#01-năm-câu-hỏi-đầu-tiên-trước-khi-học-database)
  - [0.2 Hành trình một lần đăng nhập từ giao diện tới Database](#02-hành-trình-một-lần-đăng-nhập-từ-giao-diện-tới-database)
  - [0.3 Phân biệt PostgreSQL Server, SQL, Client (`psql` / `pgAdmin`) và Driver](#03-phân-biệt-postgresql-server-sql-client-psql--pgadmin-và-driver)
- [**Phần 1: Nhập Môn Cơ Sở Dữ Liệu Quan Hệ**](#phần-1-nhập-môn-cơ-sở-dữ-liệu-quan-hệ) *(Cơ bản)*
  - [1.1 Cơ sở dữ liệu là gì và giới hạn của tệp bảng tính](#11-cơ-sở-dữ-liệu-là-gì-và-giới-hạn-của-tệp-bảng-tính)
  - [1.2 Cơ sở dữ liệu SQL và NoSQL: Đặc điểm và phạm vi áp dụng](#12-cơ-sở-dữ-liệu-sql-và-nosql-đặc-điểm-và-phạm-vi-áp-dụng)
  - [1.3 Cấu trúc Bảng, Cột, Hàng và Giá trị NULL](#13-cấu-trúc-bảng-cột-hàng-và-giá-trị-null)
  - [1.4 Các loại Khóa và Ràng buộc toàn vẹn (Constraints)](#14-các-loại-khóa-và-ràng-buộc-toàn-vẹn-constraints)
  - [1.5 Các kiểu dữ liệu phổ biến trong PostgreSQL](#15-các-kiểu-dữ-liệu-phổ-biến-trong-postgresql)
  - [1.6 Sơ đồ ERD và Ba mối quan hệ giữa các bảng (1-1, 1-N, N-N)](#16-sơ-đồ-erd-và-ba-mối-quan-hệ-giữa-các-bảng-1-1-1-n-n-n)
  - [1.7 Chuẩn hóa dữ liệu (1NF, 2NF, 3NF) và Phản chuẩn hóa](#17-chuẩn-hóa-dữ-liệu-1nf-2nf-3nf-và-phản-chuẩn-hóa)
- [**Phần 2: Kiến Trúc PostgreSQL 16 và Môi Trường Thực Hành**](#phần-2-kiến-trúc-postgresql-16-và-môi-trường-thực-hành) *(Cơ bản)*
  - [2.1 Cấu trúc phân cấp 4 tầng của PostgreSQL](#21-cấu-trúc-phân-cấp-4-tầng-của-postgresql)
  - [2.2 Triển khai PostgreSQL 16 và pgAdmin 4 với Docker Compose](#22-triển-khai-postgresql-16-và-pgadmin-4-với-docker-compose)
  - [2.3 Chuỗi kết nối (Connection URI) và Biến môi trường](#23-chuỗi-kết-nối-connection-uri-và-biến-môi-trường)
  - [2.4 Kết nối `psql`, phân biệt tài khoản quản trị và khởi tạo dữ liệu mẫu](#24-kết-nối-psql-phân-biệt-tài-khoản-quản-trị-và-khởi-tạo-dữ-liệu-mẫu)
- [**Phần 3: Thực Hành Ngôn Ngữ Truy Vấn SQL**](#phần-3-thực-hành-ngôn-ngữ-truy-vấn-sql) *(Cơ bản → Trung cấp)*
  - [3.1 Khởi tạo mô hình 5 bảng thương mại điện tử (DDL)](#31-khởi-tạo-mô-hình-5-bảng-thương-mại-điện-tử-ddl)
  - [3.2 Thêm, Đọc, Sửa và Xóa dữ liệu (DML)](#32-thêm-đọc-sửa-và-xóa-dữ-liệu-dml)
  - [3.3 Lọc và tìm kiếm dữ liệu với `WHERE`](#33-lọc-và-tìm-kiếm-dữ-liệu-với-where)
  - [3.4 Thống kê gom nhóm (`GROUP BY`, `HAVING`) và Thứ tự thực thi SQL](#34-thống-kê-gom-nhóm-group-by-having-và-thứ-tự-thực-thi-sql)
  - [3.5 Kết hợp nhiều bảng với `JOIN`](#35-kết-hợp-nhiều-bảng-với-join)
  - [3.6 Truy vấn con, CTE (`WITH`), `UPSERT`, `EXISTS` và `UNION`](#36-truy-vấn-con-cte-with-upsert-exists-và-union)
  - [3.7 Hàm cửa sổ (`Window Functions`) và Kiểu dữ liệu `JSONB`](#37-hàm-cửa-sổ-window-functions-và-kiểu-dữ-liệu-jsonb)
- [**Phần 4: Giao Dịch (Transaction) và Xử Lý Đồng Thời**](#phần-4-giao-dịch-transaction-và-xử-lý-đồng-thời) *(Trung cấp)*
  - [4.1 Giao dịch (Transaction) và Nguyên tắc ACID](#41-giao-dịch-transaction-và-nguyên-tắc-acid)
  - [4.2 Cơ chế kiểm soát đa phiên bản (MVCC) và Snapshot](#42-cơ-chế-kiểm-soát-đa-phiên-bản-mvcc-và-snapshot)
  - [4.3 Bốn bất thường đồng thời và Các mức cô lập (Isolation Levels)](#43-bốn-bất-thường-đồng-thời-và-các-mức-cô-lập-isolation-levels)
  - [4.4 Khóa mức dòng xử lý tranh chấp đồng thời: `FOR UPDATE` và `SKIP LOCKED`](#44-khóa-mức-dòng-xử-lý-tranh-chấp-đồng-thời-for-update-và-skip-locked)
- [**Phần 5: Chỉ Mục (Index), Tối Ưu Truy Vấn và Bảo Trì Dữ Liệu**](#phần-5-chỉ-mục-index-tối-ưu-truy-vấn-và-bảo-trì-dữ-liệu) *(Trung cấp)*
  - [5.1 Chỉ mục (Index) và cách đọc `EXPLAIN ANALYZE`](#51-chỉ-mục-index-và-cách-đọc-explain-analyze)
  - [5.2 Các loại Index phổ biến trong PostgreSQL](#52-các-loại-index-phổ-biến-trong-postgresql)
  - [5.3 Nguyên tắc viết câu lệnh SQL hiệu quả](#53-nguyên-tắc-viết-câu-lệnh-sql-hiệu-quả)
  - [5.4 Thu hồi không gian lưu trữ với `VACUUM` và `Autovacuum`](#54-thu-hồi-không-gian-lưu-trữ-với-vacuum-và-autovacuum)
- [**Phần 6: Phục Hồi Dữ Liệu và Bảo Mật Hệ Thống**](#phần-6-phục-hồi-dữ-liệu-và-bảo-mật-hệ-thống) *(Trung cấp → Nâng cao)*
  - [6.1 Nhật ký ghi trước (WAL) và cơ chế phục hồi sau sự cố](#61-nhật-ký-ghi-trước-wal-và-cơ-chế-phục-hồi-sau-sự-cố)
  - [6.2 Quản lý phân quyền truy cập với `ROLE`](#62-quản-lý-phân-quyền-truy-cập-với-role)
  - [6.3 Lưu trữ mật khẩu an toàn bằng hàm băm và muối (`pgcrypto` / `bcrypt`)](#63-lưu-trữ-mật-khẩu-an-toàn-bằng-hàm-băm-và-muối-pgcrypto--bcrypt)
  - [6.4 Bảo mật tầng truy vấn: SQL Injection và Prepared Statements](#64-bảo-mật-tầng-truy-vấn-sql-injection-và-prepared-statements)
- [**Phần 7: Vận Hành Dữ Liệu Trong Hệ Thống Thực Tế**](#phần-7-vận-hành-dữ-liệu-trong-hệ-thống-thực-tế) *(Nâng cao)*
  - [7.1 Nhập dữ liệu hàng loạt (`COPY` vs `\copy`) và Đồng bộ Sequence](#71-nhập-dữ-liệu-hàng-loạt-copy-vs-copy-và-đồng-bộ-sequence)
  - [7.2 Xóa mềm, Lưu lịch sử biến động và Nhật ký kiểm toán](#72-xóa-mềm-lưu-lịch-sử-biến-động-và-nhật-ký-kiểm-toán)
  - [7.3 Bảo vệ dữ liệu nhạy cảm, Sao lưu và Quản lý phiên bản lược đồ](#73-bảo-vệ-dữ-liệu-nhạy-cảm-sao-lưu-và-quản-lý-phiên-bản-lược-đồ)
- [**Phụ lục A: Kiến Thức PostgreSQL Nâng Cao**](#phụ-lục-a-kiến-thức-postgresql-nâng-cao) *(Nâng cao)*
  - [A.1 View và Materialized View](#a1-view-và-materialized-view)
  - [A.2 Function, Stored Procedure và Trigger](#a2-function-stored-procedure-và-trigger)
  - [A.3 Quản lý kết nối với Connection Pooling](#a3-quản-lý-kết-nối-với-connection-pooling)
  - [A.4 Phân vùng bảng lớn (Partitioning)](#a4-phân-vùng-bảng-lớn-partitioning)
  - [A.5 Nhân bản dữ liệu (Streaming Replication)](#a5-nhân-bản-dữ-liệu-streaming-replication)
- [**Phụ lục B: Bài Tập Thực Hành và Đáp Án**](#phụ-lục-b-bài-tập-thực-hành-và-đáp-án) *(Thực hành)*
- [**Phụ lục C: Bảng Tra Cứu Thuật Ngữ Database và PostgreSQL**](#phụ-lục-c-bảng-tra-cứu-thuật-ngữ-database-và-postgresql) *(Tra cứu)*

---

# Phần 0: Tổng Quan Cơ Sở Dữ Liệu Trong Ứng Dụng Phần Mềm

> **Mục tiêu Phần 0:** Giúp người chưa từng làm việc với cơ sở dữ liệu hình dung được vị trí của Database trong một phần mềm thực tế, hiểu rõ ứng dụng giao tiếp với PostgreSQL như thế nào và phân biệt đúng các công cụ thường gặp trước khi đi vào lý thuyết.

## 0.1 Năm câu hỏi đầu tiên trước khi học Database

Khi bạn mở một ứng dụng trên máy tính hoặc điện thoại — ví dụ một app quản lý bán hàng hoặc màn hình đăng nhập — toàn bộ thông tin tài khoản, sản phẩm, đơn hàng đều cần được giữ lại an toàn ngay cả khi tắt chương trình hoặc tắt máy. Trước khi viết bất kỳ dòng lệnh nào, hãy nắm rõ năm câu hỏi cốt lõi sau:

1. **Tại sao ứng dụng cần Database thay vì lưu vào biến trong RAM hoặc tệp văn bản?**
   - Biến trong bộ nhớ RAM bị xóa sạch ngay khi chương trình đóng lại.
   - Tệp rời rạc như `.txt`, `.json` hay `.xlsx` không thể xử lý an toàn khi nhiều người dùng cùng đọc và ghi một lúc, rất dễ bị ghi đè mất dữ liệu, chậm khi tìm kiếm hàng trăm nghìn dòng và dễ hỏng khi mất điện đột ngột.
2. **Database nằm ở đâu trong một ứng dụng phần mềm?**
   - Database không phải là giao diện mà người dùng nhìn thấy. Nó nằm ở **tầng lưu trữ phía sau** (trên cùng máy cá nhân trong lúc học, hoặc trên một máy chủ riêng trong mạng nội bộ / đám mây khi triển khai thật).
3. **Ứng dụng giao tiếp với Database bằng cách nào?**
   - Giao diện người dùng không tự mở trực tiếp tệp dữ liệu trên đĩa. Mã nguồn ứng dụng (C++/Qt, Python, Node.js, Java...) sử dụng một thư viện trung gian gọi là **Database Driver** để gửi câu lệnh yêu cầu tới máy chủ Database qua kết nối mạng (ví dụ cổng `5432`) và nhận bảng kết quả trả về.
4. **PostgreSQL và SQL khác nhau như thế nào?**
   - **SQL (Structured Query Language)** là **ngôn ngữ** (giống như tiếng Anh hay tiếng Việt) dùng để diễn đạt yêu cầu: *"hãy tìm khách hàng tên Phong"*, *"hãy lưu đơn hàng mới"*.
   - **PostgreSQL** là **phần mềm máy chủ quản trị dữ liệu** (DBMS) có nhiệm vụ lắng nghe câu lệnh SQL đó, kiểm tra quyền hạn, bảo đảm quy tắc dữ liệu, đọc/ghi xuống ổ đĩa và trả kết quả về. Nhiều hệ thống khác như MySQL hay SQL Server cũng dùng ngôn ngữ SQL nhưng có phần mềm máy chủ và một số cú pháp mở rộng riêng.
5. **pgAdmin và PostgreSQL có phải là cùng một phần mềm không?**
   - **Không.** **PostgreSQL** là phần mềm máy chủ chạy ngầm lưu trữ dữ liệu; còn **pgAdmin 4** (giao diện web) và **`psql`** (công cụ dòng lệnh) chỉ là **trình điều khiển / công cụ khách (Client)** giúp con người kết nối vào PostgreSQL để xem bảng và gõ lệnh SQL. Nếu tắt PostgreSQL Server thì cả ứng dụng lẫn pgAdmin đều không truy cập được dữ liệu.

---

## 0.2 Hành trình một lần đăng nhập từ giao diện tới Database

Để thấy toàn bộ bức tranh hoạt động ra sao, hãy theo dõi đúng kịch bản trong ứng dụng mẫu [`qt-postgres-login-demo/`](qt-postgres-login-demo/README.md) của dự án này khi người dùng nhập tên đăng nhập (`username`) và mật khẩu (`password`):

![Hình 0.1: Luồng giao tiếp giữa Ứng dụng và Cơ sở dữ liệu (Ví dụ: Đăng nhập trong dự án Qt)](img/00_app_db_overview.svg)

Chuỗi xử lý diễn ra qua 6 bước tuần tự như **Hình 0.1**:

1. **Người dùng nhập thông tin:** Trên màn hình đăng nhập (`LoginWindow`), người dùng gõ `demo` và `demo123` rồi nhấn nút **Login**.
2. **Qt Application tiếp nhận nghiệp vụ:** Tầng xử lý nghiệp vụ (`AuthService`) kiểm tra tính hợp lệ sơ bộ và chuẩn bị câu lệnh SQL có tham số giữ chỗ (`:u`, `:p`) để tra cứu tài khoản.
3. **PostgreSQL Driver truyền lệnh qua mạng:** Qt sử dụng driver **`QPSQL`** (đóng vai trò "người phiên dịch") đóng gói câu lệnh SQL cùng giá trị người dùng vừa nhập, gửi qua giao thức TCP tới máy chủ PostgreSQL ở cổng `5432`.
4. **PostgreSQL Server kiểm tra và xử lý:** Máy chủ PostgreSQL xác thực quyền kết nối của tài khoản ứng dụng (`login_app`), đối chiếu mật khẩu đã băm bằng hàm `crypt()` trên bảng `app_users` thuộc cơ sở dữ liệu `appdb`.
5. **PostgreSQL trả kết quả về cho ứng dụng:** Nếu khớp, PostgreSQL trả về 1 bản ghi thông tin người dùng (`id`, `username`, `full_name`, `last_login_at`), sau đó `AuthService` gửi tiếp một lệnh `UPDATE` cập nhật thời điểm đăng nhập mới nhất. Nếu không khớp, PostgreSQL trả về 0 dòng.
6. **Ứng dụng hiển thị phản hồi:** Giao diện Qt nhận kết quả từ `AuthService` để mở màn hình chào mừng (`WelcomeWindow`) hoặc báo lỗi chung `"Invalid username or password"`.

---

## 0.3 Phân biệt PostgreSQL Server, SQL, Client (`psql` / `pgAdmin`) và Driver

Bảng đối chiếu dưới đây giúp bạn không bao giờ nhầm lẫn vai trò của bốn khái niệm xuất hiện xuyên suốt giáo trình:

| Thành phần | Bản chất | Dùng cho ai? | Ví dụ cụ thể trong dự án |
| :--- | :--- | :--- | :--- |
| **PostgreSQL Server** | Phần mềm máy chủ quản trị CSDL (DBMS), trực tiếp quản lý bộ nhớ và tệp dữ liệu trên đĩa | Chạy nền 24/7 phục vụ mọi kết nối | Container `postgres:16` ở cổng `5432` |
| **SQL** | Ngôn ngữ chuẩn để mô tả cấu trúc bảng và truy vấn dữ liệu | Cả lập trình viên, quản trị viên lẫn mã nguồn ứng dụng | `SELECT id, username FROM app_users WHERE ...;` |
| **Database Client** | Phần mềm giao diện hoặc dòng lệnh giúp con người thao tác trực quan với máy chủ | Người học, kỹ sư kiểm tra bảng, quản trị viên DB | **`psql`** (terminal), **`pgAdmin 4`** (trình duyệt web), DBeaver |
| **Database Driver** | Thư viện nhúng trong mã nguồn phần mềm để code gửi SQL tới PostgreSQL Server | Chính ứng dụng phần mềm (`Qt`, `Python`, `Node.js`...) | **`QPSQL`** trong Qt (`AuthService.cpp`), `psycopg` trong Python |

> **Ghi nhớ Phần 0:**
> - **SQL** là ngôn ngữ, **PostgreSQL** là phần mềm máy chủ lưu dữ liệu, còn **`pgAdmin` / `psql`** là công cụ điều khiển.
> - Người dùng cuối chỉ làm việc với giao diện ứng dụng (như Qt); ứng dụng mới là nơi dùng **Driver** kết nối tới PostgreSQL Server.

---

# Phần 1: Nhập Môn Cơ Sở Dữ Liệu Quan Hệ

Trong mỗi mục từ Phần 1 trở đi, kiến thức được trình bày nhất quán theo 6 bước sư phạm: **Mục tiêu → Giải thích → Minh họa → Thực hành → Kết quả → Ghi nhớ**, giúp bạn hiểu bản chất trước khi ghi nhớ cú pháp kỹ thuật.

## 1.1 Cơ sở dữ liệu là gì và giới hạn của tệp bảng tính

- **Mục tiêu:** Hiểu khái niệm Cơ sở dữ liệu (`Database`), Hệ quản trị cơ sở dữ liệu (`DBMS`) và lý do phần mềm thực tế không lưu dữ liệu chính bằng tệp Excel hay CSV.
- **Giải thích:**
  - **Cơ sở dữ liệu (Database — CSDL):** Là tập hợp dữ liệu có tổ chức, được lưu trữ bền vững trên đĩa để phục vụ việc tra cứu, thêm, sửa, xóa với độ chính xác cao.
  - **Hệ quản trị cơ sở dữ liệu (Database Management System — DBMS):** Là lớp phần mềm trung gian đứng ra quản lý toàn bộ việc đọc/ghi tệp trên đĩa, kiểm soát quy tắc hợp lệ và điều phối nhiều người truy cập cùng lúc (tiêu biểu như **PostgreSQL**, MySQL, SQL Server hay Oracle).
- **Minh họa:**

![Hình 1.1: So sánh lưu trữ bằng tệp rời rạc với Hệ quản trị CSDL và Mô hình 3 tầng](img/01_excel_vs_db_arch.svg)

Hãy tưởng tượng một cửa hàng ban đầu lưu đơn đặt hàng trong tệp bảng tính `don_hang.xlsx`. Khi quy mô tăng lên, cách lưu bằng tệp rời rạc bộc lộ 4 điểm yếu cấu trúc (**Hình 1.1**):
1. **Ghi đè mất dữ liệu:** Hai nhân viên mở cùng một tệp và lưu đồng thời, bản lưu sau sẽ xóa mất công sức của người trước.
2. **Thiếu kiểm soát kiểu dữ liệu:** Một ô giá tiền hoàn toàn có thể bị gõ nhầm thành chữ `"miễn phí"` mà tệp bảng tính không ngăn chặn chặt chẽ.
3. **Tra cứu chậm:** Để tìm vài dòng trong 500.000 đơn hàng, phần mềm thường phải nạp gần như cả tệp vào bộ nhớ.
4. **Rủi ro hỏng tệp khi sự cố:** Mất điện giữa lúc đang lưu rất dễ làm hỏng cấu trúc tệp.

Ngược lại, **PostgreSQL** đặt ở tầng dữ liệu trong mô hình phần mềm 3 tầng cho phép hàng nghìn yêu cầu đọc/ghi diễn ra song song mà vẫn đảm bảo an toàn và nhất quán.
- **Ghi nhớ:** Bạn không trực tiếp mở tệp nhị phân của PostgreSQL để sửa như Excel; mọi thao tác đều đi qua **DBMS** bằng câu lệnh **SQL**.

---

## 1.2 Cơ sở dữ liệu SQL và NoSQL: Đặc điểm và phạm vi áp dụng

- **Mục tiêu:** Phân biệt hai nhóm công nghệ lưu trữ phổ biến (**SQL** và **NoSQL**) và hiểu đúng vai trò của kiểu `JSONB` bên trong PostgreSQL.
- **Giải thích:**
  - **CSDL Quan hệ (SQL / RDBMS):** Dữ liệu tổ chức thành các **bảng** có tên cột và kiểu dữ liệu khai báo chặt chẽ từ trước, liên kết với nhau qua các khóa. Mạnh về tính chính xác, giao dịch tài chính và báo cáo đa bảng.
  - **CSDL Phi quan hệ (NoSQL):** Không bắt buộc cấu trúc bảng cố định; lưu theo tài liệu JSON tự do (MongoDB) hoặc cặp khóa–giá trị siêu nhanh trên RAM (Redis). Mạnh về tốc độ bộ nhớ đệm (Cache) hoặc dữ liệu nhật ký thay đổi liên tục.
- **Minh họa đối chiếu:**

| Tiêu chí | CSDL Quan hệ — SQL (PostgreSQL, MySQL) | CSDL Phi quan hệ — NoSQL (Redis, MongoDB) |
| :--- | :--- | :--- |
| **Mô hình tổ chức dữ liệu** | **Lược đồ cố định:** Dữ liệu tổ chức thành bảng với cột và kiểu dữ liệu khai báo chặt chẽ từ trước. | **Cấu trúc linh hoạt:** Lưu dưới dạng tài liệu JSON (MongoDB) hoặc cặp khóa–giá trị trên bộ nhớ RAM (Redis). |
| **Ưu thế cốt lõi** | Toàn vẹn dữ liệu nghiêm ngặt, liên kết đa bảng (`JOIN`) chính xác và giao dịch an toàn (ACID). | Đọc/ghi bộ nhớ đệm tốc độ rất cao (Redis) hoặc dễ thay đổi cấu trúc từng bản ghi (MongoDB). |
| **Phạm vi áp dụng điển hình** | Quản lý tài khoản, đơn hàng, tồn kho, ngân hàng và nghiệp vụ kế toán. | Lưu phiên đăng nhập tạm thời, bảng xếp hạng thời gian thực (Redis) hoặc log sự kiện, dữ liệu cảm biến (MongoDB). |

- **Lưu ý kỹ thuật về `JSONB` trong PostgreSQL:** PostgreSQL bản chất là **hệ quản trị CSDL quan hệ (RDBMS)**. Việc tích hợp sẵn kiểu dữ liệu **`JSONB`** mang lại khả năng **lưu trữ và đánh chỉ mục dữ liệu bán cấu trúc ngay trong mô hình quan hệ** (ví dụ cột thông số kỹ thuật sản phẩm thay đổi theo từng ngành hàng), chứ không có nghĩa PostgreSQL thay thế hoàn toàn mọi tính chất của hệ NoSQL chuyên biệt (như khả năng cache trên RAM của Redis hay kiến trúc phân tán document mặc định của MongoDB).
- **Ghi nhớ:** Dùng **PostgreSQL (SQL)** làm kho lưu trữ dữ liệu nghiệp vụ chính; khi một bảng cần thêm một số trường động linh hoạt, kết hợp thêm cột `JSONB` thay vì phải dựng thêm hệ thống NoSQL rời rạc ngay từ đầu.

---

## 1.3 Cấu trúc Bảng, Cột, Hàng và Giá trị NULL

- **Mục tiêu:** Nắm vững 4 khái niệm nền tảng cấu tạo nên một bảng dữ liệu và tránh lỗi kinh điển khi so sánh với `NULL`.
- **Giải thích:**
  - **Bảng (`Table`):** Tập hợp các bản ghi mô tả cùng một loại đối tượng (ví dụ `users` lưu khách hàng, `products` lưu sản phẩm).
  - **Cột (`Column`):** Một thuộc tính cụ thể gắn với kiểu dữ liệu cố định (cột `price` chỉ chứa số, cột `name` chứa văn bản).
  - **Hàng (`Row` / Bản ghi):** Một bộ dữ liệu hoàn chỉnh đại diện cho một đối tượng cụ thể (ví dụ toàn bộ thông tin của khách hàng `Phong`).
  - **Giá trị `NULL`:** Biểu thị trạng thái *"chưa có thông tin / chưa xác định"*. **`NULL` hoàn toàn khác số `0` và khác chuỗi rỗng `''`**.
- **Minh họa:**

![Hình 1.2: Cấu trúc một Bảng dữ liệu quan hệ và Phân biệt giá trị NULL](img/01b_table_and_null.svg)

Vì `NULL` mang nghĩa *"chưa biết"*, trong logic ba giá trị (*three-valued logic*: `TRUE`, `FALSE`, `UNKNOWN`), câu hỏi *"số điện thoại chưa biết có bằng chưa biết hay không?"* (`phone = NULL`) cho kết quả `UNKNOWN` chứ không phải `TRUE`. Do đó `WHERE phone = NULL` luôn trả về **0 dòng**. Để kiểm tra ô bị khuyết, SQL bắt buộc dùng `IS NULL` hoặc `IS NOT NULL`.

- **Thực hành** *(trên bảng `users` của [`database-demo/`](database-demo/01_create_tables.sql))*:
```sql
SELECT id, name, phone FROM users WHERE phone IS NULL ORDER BY id;
SELECT id, name, phone FROM users WHERE phone IS NOT NULL ORDER BY id;
```
- **Kết quả mong đợi (trên bộ dữ liệu mẫu):**

*Câu 1 (`WHERE phone IS NULL`):*

| id | name | phone |
| :---: | :--- | :--- |
| 2 | Linh | `NULL` |
| 4 | An | `NULL` |

*Câu 2 (`WHERE phone IS NOT NULL`):*

| id | name | phone |
| :---: | :--- | :--- |
| 1 | Phong | 0912345678 |
| 3 | Tuấn | 0987654321 |
| 5 | Minh | 0901122334 |

- **Ghi nhớ:** Không bao giờ viết `= NULL` hay `<> NULL` trong `WHERE`; luôn dùng **`IS NULL`** hoặc **`IS NOT NULL`**.

---

## 1.4 Các loại Khóa và Ràng buộc toàn vẹn (`Constraints`)

- **Mục tiêu:** Hiểu lý do phải có khóa chính, khóa ngoại và cách PostgreSQL tự động bảo vệ dữ liệu sạch bằng các ràng buộc (`Constraints`) ngay tại tầng bảng.
- **Tình huống mở đầu:** Giả sử cửa hàng có bảng khách hàng như sau:

| id | name | email |
| :---: | :--- | :--- |
| 1 | Phong | phong@mail.com |
| 2 | Linh | linh@mail.com |
| 1 | Nam | nam@mail.com |

Nếu hai khách hàng cùng mang `id = 1`, khi hệ thống tra đơn hàng của `user_id = 1` sẽ không thể biết đơn hàng thuộc về Phong hay Nam, dẫn tới sai sót hóa đơn và thanh toán.
- **Giải thích 4 loại Khóa (`Key`):**

| Loại khóa | Liên hệ thực tế | Quy tắc ràng buộc | Ví dụ trong hệ thống |
| :--- | :--- | :--- | :--- |
| **Khóa chính (`PRIMARY KEY` — PK)** | Số căn cước công dân | Định danh duy nhất mỗi hàng; **không được trùng lặp và không được nhận `NULL`**. | `users.id` (`1, 2, 3...`) |
| **Khóa ngoại (`FOREIGN KEY` — FK)** | Mã khách hàng in trên hóa đơn | Cột ở bảng con tham chiếu tới `PK` (hoặc cột `UNIQUE`) của bảng cha để bảo đảm không trỏ tới đối tượng không tồn tại. | `orders.user_id` → `users.id` |
| **Khóa duy nhất (`UNIQUE`)** | Địa chỉ email đăng nhập | Ngăn hai dòng có cùng một giá trị; **mặc định trong PostgreSQL cho phép nhiều giá trị `NULL`**. | `users.email` |
| **Khóa ghép (`Composite Key`)** | Cặp `(Tầng, Số phòng)` | Kết hợp 2 cột trở lên làm một khóa duy nhất. | `PRIMARY KEY (order_id, product_id)` trong `order_items` |

- **Giải thích sâu về `UNIQUE` và `NULL` trong PostgreSQL:** Vì `NULL` mang nghĩa *"chưa xác định"*, PostgreSQL mặc định coi hai giá trị `NULL` không bằng nhau nên cho phép nhiều dòng cùng có `email = NULL` trong cột `UNIQUE` (hữu ích khi khách mua không cung cấp email). Từ **PostgreSQL 15+**, nếu nghiệp vụ muốn **chỉ cho phép tối đa một dòng mang giá trị `NULL`**, hãy khai báo `UNIQUE NULLS NOT DISTINCT`.
- **Các ràng buộc toàn vẹn (`Constraints`) quan trọng khác:**

| Ràng buộc | Tác dụng | Ví dụ chuẩn DDL |
| :--- | :--- | :--- |
| **`NOT NULL`** | Cấm bỏ trống ô dữ liệu | `name varchar(100) NOT NULL` |
| **`DEFAULT`** | Tự điền giá trị mặc định nếu khi `INSERT` không truyền cột này | `stock int NOT NULL DEFAULT 0` |
| **`CHECK`** | Kiểm tra điều kiện logic trước khi lưu dòng | `price numeric(12, 2) NOT NULL CHECK (price >= 0)` |
| **`ON DELETE`** trên FK | Quy định hành xử khi xóa dòng ở bảng cha:<br>• `RESTRICT` (mặc định): Chặn xóa nếu còn dữ liệu con tham chiếu.<br>• `CASCADE`: Xóa cha thì tự động xóa các dòng con đi kèm.<br>• `SET NULL`: Xóa cha thì đặt cột FK ở bảng con thành `NULL`. | `order_id bigint REFERENCES orders(id) ON DELETE CASCADE`<br>`category_id int REFERENCES categories(id) ON DELETE SET NULL` |

- **Thực hành minh họa Primary Key và `UNIQUE NULLS NOT DISTINCT`:**
```sql
CREATE TEMP TABLE demo_users (
    id int PRIMARY KEY,
    name varchar(100) NOT NULL,
    email varchar(150) UNIQUE
);

INSERT INTO demo_users VALUES (1, 'Phong', 'phong@mail.com');
INSERT INTO demo_users VALUES (2, 'Linh', NULL);
INSERT INTO demo_users VALUES (3, 'An', NULL);   -- Hợp lệ: UNIQUE mặc định cho phép nhiều NULL
INSERT INTO demo_users VALUES (1, 'Nam', 'nam@mail.com'); -- Lỗi: trùng Primary Key id = 1
```
- **Kết quả:** Ba câu `INSERT` đầu thành công (dù có 2 dòng `email` là `NULL`). Câu thứ tư bị PostgreSQL từ chối ngay với lỗi:
  `ERROR: duplicate key value violates unique constraint "demo_users_pkey" — DETAIL: Key (id)=(1) already exists.`
- **Ghi nhớ:** Đừng chỉ kiểm tra dữ liệu hợp lệ ở giao diện ứng dụng; luôn đặt `PRIMARY KEY`, `FOREIGN KEY`, `NOT NULL`, `CHECK` và `UNIQUE` ngay trong bảng để bảo vệ dữ liệu từ gốc.

---

## 1.5 Các kiểu dữ liệu phổ biến trong PostgreSQL

- **Mục tiêu:** Chọn đúng kiểu dữ liệu cho từng cột để tiết kiệm dung lượng, tránh sai số tiền tệ và tránh hiểu nhầm về múi giờ.
- **Giải thích & Minh họa:**

| Nhóm dữ liệu | Kiểu khuyên dùng | Đặc tả kỹ thuật và lưu ý thực hành |
| :--- | :--- | :--- |
| **Số nguyên** | `int` (4 byte) / `bigint` (8 byte) | Dùng `int` cho số lượng vừa phải (`stock`), `bigint` cho `id` của bảng phát sinh nhiều dòng (`orders.id` chứa tới > 9 tỷ tỷ). Nên dùng chuẩn hiện đại `GENERATED ALWAYS AS IDENTITY` thay cho `serial`. |
| **Tiền tệ & số thập phân chính xác** | `numeric(12, 2)` | Lưu chính xác tới 12 chữ số với 2 chữ số thập phân. **Tuyệt đối không dùng `float`/`real` cho tiền**, vì số thực nhị phân gây sai số làm tròn (như `0.1 + 0.2 = 0.30000000000000004`). |
| **Văn bản** | `varchar(n)` / `text` | Dùng `varchar(15)` khi muốn giới hạn độ dài tối đa ở tầng DB (như số điện thoại), dùng `text` cho nội dung tự do; trong PostgreSQL cả hai có tốc độ xử lý như nhau. |
| **Ngày và giờ** | `timestamptz` / `date` | **`timestamptz` (timestamp with time zone)** lưu **một điểm thời gian theo chuẩn UTC (8 byte) và KHÔNG lưu lại múi giờ ban đầu lúc nhập**. Khi truy vấn, PostgreSQL tự động chuyển đổi mốc UTC đó sang múi giờ của phiên kết nối (`TimeZone`). Kiểu `date` chỉ lưu ngày (`'2026-03-01'`). |
| **Logic nhị phân** | `boolean` | Chỉ nhận `true`, `false` (hoặc `NULL`), dùng cho các cờ như `is_active`. |
| **Định danh ngẫu nhiên** | `uuid` | Mã 128-bit tạo bằng `gen_random_uuid()`, hữu ích khi không muốn để lộ số thứ tự tăng dần ra API công khai. |
| **Dữ liệu bán cấu trúc** | `jsonb` | Lưu đối tượng JSON dạng nhị phân đã phân tích sẵn, hỗ trợ đánh chỉ mục GIN cực nhanh (như cột `products.specs`). |

- **Thực hành kiểm chứng hành vi của `timestamptz`:**
```sql
SET TIME ZONE 'UTC';
SELECT id, created_at AS utc_view FROM orders WHERE id = 1;

SET TIME ZONE 'Asia/Ho_Chi_Minh';
SELECT id, created_at AS vn_view FROM orders WHERE id = 1;
```
- **Kết quả thực tế trên PostgreSQL 16:**

| Phiên kết nối (`TimeZone`) | Giá trị hiển thị cho cùng 1 bản ghi (`orders.id = 1`) |
| :--- | :--- |
| `UTC` | `2026-03-01 02:30:00+00` |
| `Asia/Ho_Chi_Minh` | `2026-03-01 09:30:00+07` |

- **Ghi nhớ:** Luôn dùng `numeric` cho tiền tệ và **`timestamptz`** cho mốc thời gian; không dùng `timestamp` (không có `tz`) cho hệ thống có thể phục vụ nhiều múi giờ.

---

## 1.6 Sơ đồ ERD và Ba mối quan hệ giữa các bảng (`1-1`, `1-N`, `N-N`)

- **Mục tiêu:** Biết cách đọc một sơ đồ thiết kế cơ sở dữ liệu (**ERD — Entity Relationship Diagram**) theo ký hiệu Crow's Foot và biết chuyển trực tiếp 3 loại quan hệ sang bảng SQL.
- **Giải thích:**
  **ERD** là bản vẽ mô tả các bảng (thực thể — *Entity*), các cột (thuộc tính — *Attribute*) và đường liên kết giữa chúng (*Cardinality* — số lượng bản ghi tham gia quan hệ). Trong ký hiệu phổ biến **Crow's Foot ("chân chim")**:
  - Vạch thẳng **`|`** biểu thị **"1"**.
  - Vòng tròn **`○`** biểu thị **"0 (có thể khuyết / NULL)"**.
  - Ba chẽ **"chân chim"** biểu thị **"Nhiều (N)"**.
- **Minh họa:**

![Hình 1.3: Liên kết qua Khóa chính (PK), Khóa ngoại (FK) và Ba loại quan hệ giữa các bảng](img/02_keys_relations.svg)

Mọi hệ thống quan hệ đều được cấu thành từ 3 quy tắc chuyển đổi từ ERD sang bảng SQL (**Hình 1.3**):

1. **Quan hệ `1 - 1` (Một — Một):** Một tài khoản (`users`) tương ứng với tối đa một hồ sơ chi tiết (`profiles`).
   - *Cách thiết kế SQL:* Đặt khóa ngoại `user_id` ở bảng `profiles` và gắn đồng thời cả `FOREIGN KEY` lẫn **`UNIQUE`**.
2. **Quan hệ `1 - N` (Một — Nhiều):** Một khách hàng (`users`) có thể đặt nhiều đơn hàng (`orders`), nhưng mỗi đơn hàng chỉ thuộc một khách hàng (hoặc `NULL` nếu là khách vãng lai: ký hiệu `0..1 : N`).
   - *Cách thiết kế SQL:* **Luôn đặt cột khóa ngoại (`user_id`) ở bảng phía "Nhiều" (`orders`)**.
3. **Quan hệ `N - N` (Nhiều — Nhiều):** Một đơn hàng có nhiều sản phẩm, và một sản phẩm nằm trong nhiều đơn hàng. Bảng hai chiều không thể chứa danh sách sản phẩm trong một ô.
   - *Cách thiết kế SQL:* **Tách ra một bảng trung gian** (`order_items`) gồm hai khóa ngoại `order_id` và `product_id` (thường ghép lại thành `PRIMARY KEY (order_id, product_id)`), kèm các thuộc tính của mối quan hệ như `quantity`, `unit_price`.

- **Thực hành đọc hiểu:** Nhìn nhanh vào **Hình 3.1** ở đầu Phần 3, bạn sẽ thấy ngay cả 4 liên kết của hệ thống thương mại điện tử mẫu đều tuân theo đúng quy tắc trên (`categories 1:N products`, `users 0..1:N orders`, và `orders N:N products` thông qua `order_items`).
- **Ghi nhớ:** Gặp quan hệ `1 - N` đặt FK ở phía `N`; gặp quan hệ `N - N` bắt buộc tạo bảng trung gian.

---

## 1.7 Chuẩn hóa dữ liệu (`1NF`, `2NF`, `3NF`) và Phản chuẩn hóa

- **Mục tiêu:** Tránh thiết kế "bảng khổng lồ" gây trùng lặp dữ liệu và sai lệch khi cập nhật, đồng thời biết khi nào được phép chủ động lưu dư thừa để tăng tốc đọc.
- **Giải thích:** Nếu gộp chung thông tin nhân viên, nhiều số điện thoại và thông tin phòng ban vào một bảng như tệp Excel, khi đổi tên hoặc địa chỉ phòng ban, bạn phải sửa hàng trăm dòng nhân viên — chỉ cần sót 1 dòng là dữ liệu bị mâu thuẫn. **Chuẩn hóa (Normalization)** là 3 bước tách bảng để triệt tiêu tình trạng này.
- **Minh họa:**

![Hình 1.4: Chuẩn hóa dữ liệu (1NF → 2NF → 3NF) nhằm loại bỏ dư thừa và dị thường cập nhật](img/03_normalization_3nf.svg)

Ba dạng chuẩn cơ bản (**Hình 1.4**):
1. **Dạng chuẩn 1 (`1NF`) — Mỗi ô một giá trị đơn (nguyên tử):** Không nhét danh sách nhiều giá trị vào một ô (như `'0912.xxx, 0987.xxx'`). Nếu một nhân viên có nhiều số điện thoại, tách sang bảng con `sdt_nv` mỗi dòng một số.
2. **Dạng chuẩn 2 (`2NF`) — Phụ thuộc toàn bộ vào khóa chính:** Áp dụng cho bảng có khóa chính ghép. Trong `order_items(order_id, product_id, quantity)`, tên sản phẩm chỉ phụ thuộc vào `product_id` chứ không phụ thuộc vào `order_id`, nên tên sản phẩm phải nằm ở bảng `products`.
3. **Dạng chuẩn 3 (`3NF`) — Không phụ thuộc bắc cầu:** Mọi cột thường chỉ phụ thuộc trực tiếp vào khóa chính, không phụ thuộc qua một cột thường khác. Bảng `nhan_vien` chỉ giữ `ma_phong` (FK), còn `ten_phong` và `dia_chi_phong` tách sang bảng `phong_ban`.

- **Thực hành thiết kế trên hệ thống bán hàng:** Nhờ áp dụng `1NF → 3NF`, khi sửa tên sản phẩm trong `products`, tất cả đơn hàng đều thấy tên mới mà không cần sửa `order_items`. Riêng giá bán tại thời điểm mua (`unit_price`) vẫn **cố tình lưu bản sao trong `order_items`** để giữ nguyên lịch sử hóa đơn khi giá gốc sản phẩm thay đổi về sau — đây không phải dư thừa lỗi mà là dữ liệu lịch sử nghiệp vụ!
- **Phản chuẩn hóa có chủ đích (`Denormalization`):** Sau khi thiết kế đạt `3NF`, với các màn hình đọc liên tục (như danh sách đơn hàng), ta có thể chủ động lưu sẵn cột tổng hợp `amount` trên bảng `orders` thay vì mỗi lần hiển thị đều phải `JOIN` và cộng lại toàn bộ `order_items`.
- **Ghi nhớ:** Thiết kế chuẩn `3NF` trước để dữ liệu sạch; chỉ **phản chuẩn hóa** khi đã đo đạc và cần tối ưu đọc, đồng thời phải có cơ chế giữ đồng bộ (Transaction / Trigger).

---

# Phần 2: Kiến Trúc PostgreSQL 16 và Môi Trường Thực Hành

## 2.1 Cấu trúc phân cấp 4 tầng của PostgreSQL

- **Mục tiêu:** Hiểu ý nghĩa của tên gọi dạng `public.users`, cách PostgreSQL phân tách các cơ sở dữ liệu độc lập và nắm đúng khái niệm **Cluster**.
- **Giải thích:** Trong thông báo lỗi hoặc tài liệu PostgreSQL, bảng thường được viết kèm tiền tố `public.users`. Điều này xuất phát từ kiến trúc phân cấp logic 4 tầng, tương tự mô hình một tòa nhà văn phòng:

![Hình 2.1: Phân cấp logic 4 tầng của PostgreSQL và Cấu trúc chuỗi kết nối (URI)](img/04_pg_hierarchy_uri.svg)

1. **Cluster (Cụm CSDL của một Instance):** Trong thuật ngữ PostgreSQL, **Cluster** là **tập hợp các Database (cùng các đối tượng dùng chung toàn cục như Role, Tablespace) được quản lý bởi một PostgreSQL server instance** vận hành trên cùng một thư mục dữ liệu (`PGDATA`), lắng nghe kết nối ở một cổng TCP (mặc định `5432`). *(Lưu ý: khái niệm PostgreSQL Database Cluster khác với cụm nhiều máy chủ vật lý HA Cluster.)*
2. **Database (Cơ sở dữ liệu):** Đơn vị phân vùng độc lập cho từng hệ thống (chẳng hạn `appdb` và `analytics_db`). Mỗi kết nối chỉ gắn vào **một Database duy nhất** và không thể `JOIN` trực tiếp xuyên từ Database này sang Database khác.
3. **Schema (Lược đồ / Không gian tên):** Ngăn phân chia logic bên trong một Database giúp nhóm bảng theo phân hệ (ví dụ `sales.orders`, `inventory.products`). Mặc định mọi Database có sẵn schema **`public`**; khi viết `CREATE TABLE users`, bảng thực chất nằm tại `public.users`.
4. **Table (Bảng):** Đơn vị lưu trữ cuối cùng chứa các cột và hàng dữ liệu.

- **Ghi nhớ:** Một PostgreSQL server (**Cluster**) có thể chứa nhiều **Database** độc lập; mỗi Database chứa nhiều **Schema**; mỗi Schema chứa nhiều **Table**.

---

## 2.2 Triển khai PostgreSQL 16 và pgAdmin 4 với Docker Compose

- **Mục tiêu:** Tự dựng hoàn chỉnh máy chủ PostgreSQL 16 và giao diện quản trị web pgAdmin 4 chỉ với một tệp cấu hình, không cần cài đặt phức tạp lên máy chủ.
- **Minh họa kiến trúc:**

![Hình 2.2: Kiến trúc triển khai PostgreSQL 16 và pgAdmin 4 bằng Docker Compose](img/04b_docker_pgadmin_flow.svg)

- **Thực hành:** Tạo tệp `docker-compose.yml` với nội dung sau:

```yaml
services:
  postgres:
    image: postgres:16-alpine
    container_name: postgres_pg16
    restart: unless-stopped
    environment:
      POSTGRES_USER: pg_admin
      POSTGRES_PASSWORD: SecretPassword123!
      POSTGRES_DB: appdb
    ports:
      - "127.0.0.1:5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U pg_admin -d appdb"]
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

Khởi chạy và kiểm tra qua dòng lệnh:

```bash
docker compose up -d              # Chạy PostgreSQL (:5432) và pgAdmin (:5050) ở chế độ nền
docker compose logs -f postgres   # Xem nhật ký khởi động (nhấn Ctrl+C để thoát xem log)
docker compose down               # Dừng container (dữ liệu vẫn an toàn trong volume pgdata)
```

Sau khi container chạy, truy cập `http://localhost:5050` trên trình duyệt, đăng nhập bằng `admin@example.com` / `SecretPassword123!`, chọn **Add New Server** và khai báo ở thẻ **Connection**:
- **Host name:** `postgres` *(tên service bên trong mạng Docker, không dùng `localhost` vì pgAdmin đang chạy trong container khác)*
- **Port:** `5432` | **Maintenance database:** `appdb` | **Username:** `pg_admin` | **Password:** `SecretPassword123!`

- **Ghi nhớ:** Nhờ `volumes: pgdata`, việc dừng hay khởi động lại container không làm mất dữ liệu (chỉ mất nếu dùng `docker compose down -v`).

---

## 2.3 Chuỗi kết nối (`Connection URI`) và Biến môi trường

- **Mục tiêu:** Đọc hiểu chuỗi kết nối chuẩn mà mọi Driver (Qt, Python, Node.js, Go...) sử dụng để kết nối tới PostgreSQL và biết cách bảo vệ mật khẩu kết nối.
- **Minh họa:** Cấu trúc Connection URI nằm ở nửa dưới **Hình 2.1**:

```text
postgresql://app_backend:MatKhauUngDung_123!@127.0.0.1:5432/appdb?sslmode=disable
```

- **Nguyên tắc an toàn thông tin:** Không bao giờ viết cứng tên đăng nhập/mật khẩu DB vào mã nguồn ứng dụng rồi đẩy lên Git. Hãy tách sang tệp biến môi trường `.env` (xem mẫu trong [`qt-postgres-login-demo/.env.example`](qt-postgres-login-demo/.env.example)) hoặc dùng các biến môi trường chuẩn mà thư viện `libpq` / `psql` tự nhận diện:

```ini
PGHOST=127.0.0.1
PGPORT=5432
PGDATABASE=appdb
PGUSER=app_backend
PGPASSWORD=MatKhauUngDung_123!
```

- **Ghi nhớ:** Ở môi trường cục bộ chưa cấu hình chứng chỉ nội bộ có thể dùng `sslmode=disable`; khi chạy trên mạng thật hoặc Internet, cần bật `sslmode=require` hoặc `verify-full`.

---

## 2.4 Kết nối `psql`, phân biệt tài khoản quản trị và khởi tạo dữ liệu mẫu

- **Mục tiêu:** Mở được phiên làm việc dòng lệnh `psql` trên cả Docker lẫn Ubuntu cài trực tiếp, phân biệt rõ **tài khoản quản trị** với **tài khoản ứng dụng**, và nạp xong bộ 5 bảng mẫu [`database-demo/`](database-demo/01_create_tables.sql).

### Cách 1: Kết nối khi PostgreSQL chạy trong Docker Compose (mục 2.2)

```bash
docker exec -it postgres_pg16 psql -U pg_admin -d appdb
```

### Cách 2: Kết nối khi PostgreSQL cài trực tiếp trên Ubuntu (`apt`)

Nếu máy chủ cài PostgreSQL trực tiếp trên hệ điều hành, sẽ không có container `postgres_pg16`. Bạn thực hiện 3 bước sau:

**Bước 1 — Kiểm tra PostgreSQL đang lắng nghe cổng `5432`:**

```bash
sudo ss -tulpn | grep 5432
```

Kết quả minh họa cho thấy tiến trình `postgres` của hệ điều hành đang giữ cổng `5432`:

```text
tcp  LISTEN 0 200  0.0.0.0:5432  0.0.0.0:*  users:(("postgres",pid=1835,fd=6))
```

**Bước 2 — Phân tách tài khoản quản trị và tài khoản ứng dụng:**
Đăng nhập vào dấu nhắc quản trị mặc định `postgres`:

```bash
sudo -u postgres psql
```

> **Cảnh báo bảo mật quan trọng:** Tuyệt đối **không dùng tài khoản `SUPERUSER`** và **không đặt mật khẩu yếu** (như `'1'`) làm tài khoản cho ứng dụng phần mềm kết nối. Hãy phân biệt hai vai trò rõ ràng ngay từ đầu:
> - **Tài khoản quản trị (`postgres` hoặc `pg_admin`):** Chỉ dùng khi cần cài phần mở rộng (`CREATE EXTENSION`), tạo cơ sở dữ liệu (`CREATE DATABASE`) hoặc tạo người dùng/quyền (`CREATE ROLE`).
> - **Tài khoản thực hành / ứng dụng (`app_user`):** Không mang quyền `SUPERUSER`, chỉ sở hữu hoặc được cấp quyền trên đúng cơ sở dữ liệu `appdb`.

```sql
-- 1. Tạo tài khoản thông thường (không SUPERUSER) làm chủ sở hữu DB học tập appdb
CREATE USER app_user WITH PASSWORD 'HocTapAnToan_2026!';
CREATE DATABASE appdb OWNER app_user;
\q
```

*(Các lệnh cần quyền cao nhất như `CREATE EXTENSION pgcrypto;` ở mục **6.3** hay `CREATE ROLE` ở mục **6.2**, quản trị viên sẽ chạy riêng bằng tài khoản `postgres` hoặc `pg_admin`, sau đó ứng dụng kết nối bằng `app_user` hoặc `app_backend` theo nguyên tắc đặc quyền tối thiểu.)*

**Bước 3 — Kết nối trực tiếp qua `localhost`:**

```bash
psql -h localhost -p 5432 -U app_user -d appdb
```

> **Xử lý xung đột cổng 5432:** Nếu PostgreSQL Ubuntu đang chạy sẵn, lệnh `docker compose up -d` ở mục **2.2** sẽ báo lỗi `address already in use`. Bạn có thể tạm dừng dịch vụ Ubuntu bằng `sudo systemctl stop postgresql` khi dùng Docker, hoặc đổi ánh xạ cổng trong `docker-compose.yml` thành `"127.0.0.1:5433:5432"` rồi kết nối với tham số `-p 5433`.

### Các lệnh meta thường dùng bên trong `psql`

| Lệnh tắt | Chức năng | Ví dụ sử dụng |
| :--- | :--- | :--- |
| `\l` | Liệt kê toàn bộ cơ sở dữ liệu trong Cluster | `\l` |
| `\c <db>` | Chuyển sang cơ sở dữ liệu khác | `\c appdb` |
| `\dn` / `\du` | Liệt kê Schema (`\dn`) hoặc danh sách tài khoản/nhóm quyền (`\du`) | `\du` |
| `\dt` / `\dt+` | Liệt kê các bảng hiện có; thêm `+` để xem dung lượng chiếm dụng | `\dt+` |
| `\d <bảng>` | Xem chi tiết cột, kiểu dữ liệu, ràng buộc và chỉ mục của một bảng | `\d products` |
| `\x` | Bật/tắt chế độ hiển thị dọc cho bảng nhiều cột | `\x` |
| `\timing` | Bật/tắt đo thời gian thực thi (ms) sau mỗi truy vấn | `\timing` |
| `\i <file>` | Thực thi toàn bộ câu lệnh SQL trong một tệp kịch bản | `\i database-demo/01_create_tables.sql` |
| `\q` | Thoát khỏi `psql` | `\q` |

### Nạp bộ cơ sở dữ liệu mẫu 5 bảng cho Phần 3 – 5

Từ thư mục `database/`, nạp lần lượt 3 tệp trong [`database-demo/`](database-demo/01_create_tables.sql) để tạo đủ 5 bảng và dữ liệu kiểm chứng:

```bash
# Nếu dùng PostgreSQL cục bộ:
psql -h localhost -p 5432 -U app_user -d appdb \
  -f database-demo/01_create_tables.sql \
  -f database-demo/02_insert_sample_data.sql \
  -f database-demo/03_verify_database.sql

# Nếu dùng container Docker (mục 2.2):
docker exec -i postgres_pg16 psql -U pg_admin -d appdb < database-demo/01_create_tables.sql
docker exec -i postgres_pg16 psql -U pg_admin -d appdb < database-demo/02_insert_sample_data.sql
docker exec -i postgres_pg16 psql -U pg_admin -d appdb < database-demo/03_verify_database.sql
```

- **Kết quả kiểm tra từ `03_verify_database.sql`:** Bạn sẽ thấy 5 bảng đã có đầy đủ bản ghi (`categories`: 4, `products`: 10, `users`: 5, `orders`: 6, `order_items`: 6) và tổng tiền ở cột `orders.amount` khớp 100% với tổng chi tiết trong `order_items`.

---
# Phần 3: Thực Hành Ngôn Ngữ Truy Vấn SQL

Toàn bộ các ví dụ trong Phần 3, Phần 4 và Phần 5 sử dụng chung **một cơ sở dữ liệu thương mại điện tử gồm 5 bảng** (`categories`, `products`, `users`, `orders`, `order_items`) có trong [`database-demo/`](database-demo/01_create_tables.sql). Bạn chỉ cần chạy 3 tệp `01_create_tables.sql`, `02_insert_sample_data.sql`, `03_verify_database.sql` (đã hướng dẫn ở cuối mục **2.4**) là có thể thực hành ngay mọi câu lệnh SQL dưới đây.

![Hình 3.1: Lược đồ 5 bảng dữ liệu mẫu (ERD) dùng xuyên suốt Phần 3 – 5 (database-demo/)](img/06b_sample_schema_erd.svg)

---

## 3.1 Khởi tạo mô hình 5 bảng thương mại điện tử (DDL)

- **Mục tiêu:** Biết dùng nhóm lệnh **DDL (Data Definition Language)** (`CREATE TABLE`, `ALTER TABLE`, `DROP TABLE`) để định nghĩa đầy đủ 5 bảng có khóa chính, khóa ngoại, `JSONB` và các ràng buộc kiểm tra.
- **Giải thích:** Nhóm lệnh DDL tạo ra "bộ khung" (cấu trúc cột và luật kiểm soát dữ liệu) trước khi đưa dữ liệu vào bảng.
- **Thực hành (trích chuẩn từ [`01_create_tables.sql`](database-demo/01_create_tables.sql)):**

```sql
CREATE TABLE categories (
    id          int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        varchar(100) NOT NULL UNIQUE,
    description text
);

CREATE TABLE products (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        varchar(255)   NOT NULL,
    price       numeric(12, 2) NOT NULL CHECK (price >= 0),
    stock       int            NOT NULL DEFAULT 0 CHECK (stock >= 0),
    category_id int            REFERENCES categories(id) ON DELETE SET NULL,
    specs       jsonb          NOT NULL DEFAULT '{}'::jsonb,
    created_at  timestamptz    NOT NULL DEFAULT now()
);

CREATE TABLE users (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        varchar(100) NOT NULL,
    email       varchar(255) UNIQUE,
    phone       varchar(15),
    is_active   boolean      NOT NULL DEFAULT true,
    created_at  timestamptz  NOT NULL DEFAULT now()
);

CREATE TABLE orders (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     bigint         REFERENCES users(id) ON DELETE SET NULL,
    amount      numeric(12, 2) NOT NULL CHECK (amount >= 0),
    status      varchar(20)    NOT NULL DEFAULT 'pending'
                               CHECK (status IN ('pending', 'completed', 'cancelled')),
    created_at  timestamptz    NOT NULL DEFAULT now()
);

CREATE TABLE order_items (
    order_id    bigint         NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id  bigint         NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    quantity    int            NOT NULL CHECK (quantity > 0),
    unit_price  numeric(12, 2) NOT NULL CHECK (unit_price >= 0),
    PRIMARY KEY (order_id, product_id)
);
```

Các thao tác chỉnh sửa cấu trúc bảng khi hệ thống phát triển:

| Thao tác biến đổi cấu trúc | Câu lệnh SQL tương ứng |
| :--- | :--- |
| **Bổ sung cột mới vào bảng hiện có** | `ALTER TABLE products ADD COLUMN brand varchar(50);` |
| **Đổi tên cột** | `ALTER TABLE products RENAME COLUMN stock TO quantity;` |
| **Bổ sung ràng buộc kiểm tra dữ liệu** | `ALTER TABLE products ADD CONSTRAINT chk_price CHECK (price >= 0);` |
| **Xóa bảng (tránh lỗi nếu chưa có)** | `DROP TABLE IF EXISTS order_items CASCADE;` |

- **Ghi nhớ:** Bảng cha (`categories`, `users`) phải được tạo trước bảng con (`products`, `orders`, `order_items`), và khi xóa toàn bộ thì xóa theo chiều ngược lại từ con đến cha.

---

## 3.2 Thêm, Đọc, Sửa và Xóa dữ liệu (DML)

- **Mục tiêu:** Thành thạo 4 thao tác cơ bản **CRUD** (Create / Read / Update / Delete) trên dữ liệu bằng nhóm lệnh **DML (Data Manipulation Language)**.
- **Thực hành trên bộ dữ liệu mẫu (`database-demo/`):**

```sql
-- 1. Đọc 5 sản phẩm đắt nhất
SELECT id, name, price
FROM products
ORDER BY price DESC
LIMIT 5;

-- 2. Thêm mới 1 sản phẩm và lấy ngay id vừa tự sinh (chạy trong BEGIN ... ROLLBACK để không làm bẩn dữ liệu mẫu)
BEGIN;
INSERT INTO products (name, price, stock, category_id, specs)
VALUES ('Bàn phím cơ K2', 1250000, 15, 2, '{"switch": "Brown", "wireless": true}')
RETURNING id, name;

-- 3. Giảm tồn kho của sản phẩm id = 4 đi 1 và xem ngay số lượng còn lại
UPDATE products
SET stock = stock - 1
WHERE id = 4
RETURNING id, name, stock;
ROLLBACK;
```

- **Kết quả thực tế:**

*Truy vấn 1 (`SELECT ... LIMIT 5`):*

| id | name | price |
| :---: | :--- | ---: |
| 2 | ThinkPad X1 Carbon Gen 11 | 34500000.00 |
| 1 | MacBook Air M3 13" | 27990000.00 |
| 3 | Laptop Gaming Phiên Bản Giới Hạn | 24000000.00 |
| 8 | Màn hình Dell UltraSharp 27" | 8500000.00 |
| 9 | Màn hình LG IPS 24" | 3200000.00 |

*Truy vấn 2 (`INSERT ... RETURNING`) trên DB mới nạp 10 sản phẩm:* trả về `id = 11 | name = Bàn phím cơ K2`.  
*Truy vấn 3 (`UPDATE ... RETURNING`):* trả về `id = 4 | name = Chuột không dây MX | stock = 49` (sau đó `ROLLBACK` hoàn trả về `50`).

| Thao tác mở rộng | Câu lệnh minh họa | Lưu ý kỹ thuật |
| :--- | :--- | :--- |
| **Chèn nhiều dòng một lần** | `INSERT INTO categories (name) VALUES ('Phụ kiện gaming'), ('Thiết bị mạng');` | Giảm đáng kể lượt gửi mạng so với chạy từng lệnh `INSERT` trong vòng lặp. |
| **Xóa dòng có điều kiện** | `DELETE FROM products WHERE stock = 0;` | **Bắt buộc kiểm tra kỹ mệnh đề `WHERE`**; thiếu `WHERE` sẽ xóa toàn bộ bảng. |
| **Làm trống bảng nhanh** | `TRUNCATE TABLE logs RESTART IDENTITY;` | Xóa sạch mọi dòng với tốc độ rất cao và đặt lại bộ đếm tự tăng về `1`. |

- **Ghi nhớ:** Hạn chế dùng `SELECT *` trong mã nguồn ứng dụng; luôn chỉ định rõ tên cột cần lấy và luôn dùng `WHERE` khi `UPDATE` / `DELETE`.

---

## 3.3 Lọc và tìm kiếm dữ liệu với `WHERE`

- **Mục tiêu:** Biết kết hợp các điều kiện lọc dữ liệu và xử lý giá trị trống (`NULL`) khi hiển thị.
- **Thực hành & Kết quả:**

| Nhu cầu lọc | Câu lệnh chạy thử trên `database-demo/` | Kết quả thực tế |
| :--- | :--- | :--- |
| **So sánh bằng / khác** | `SELECT id, amount FROM orders WHERE status = 'completed' AND amount <> 350000 ORDER BY id;` | Trả về 3 đơn `completed` có giá trị khác `350000` (`id = 1, 2, 3`). Toán tử khác trong SQL là `<>` hoặc `!=`. |
| **Trong khoảng (`BETWEEN`)** | `SELECT id, name, price FROM products WHERE price BETWEEN 100000 AND 1000000 ORDER BY price;` | Trả về 3 sản phẩm: Chuột (`350.000`), Hub USB-C (`650.000`), Tai nghe (`890.000`). `BETWEEN` lấy cả hai cận. |
| **Thuộc tập giá trị (`IN`)** | `SELECT id, name FROM products WHERE category_id IN (3, 4) ORDER BY id;` | Trả về 3 sản phẩm thuộc danh mục Màn hình (`3`) và Âm thanh (`4`). |
| **Tìm chuỗi (`LIKE` / `ILIKE`)** | `SELECT id, name FROM products WHERE name ILIKE '%macbook%';` | Trả về `1 \| MacBook Air M3 13"`. `ILIKE` (đặc trưng PostgreSQL) không phân biệt chữ hoa/thường. |
| **Kiểm tra khuyết (`IS NULL`)** | `SELECT id, name FROM users WHERE email IS NULL ORDER BY id;` | Trả về `4 \| An` và `5 \| Minh`. |
| **Giá trị thay thế (`COALESCE`)** | `SELECT id, name, COALESCE(phone, 'Chưa cập nhật') AS dien_thoai FROM users ORDER BY id;` | Phong (`0912345678`), Linh (`Chưa cập nhật`), Tuấn (`0987654321`), An (`Chưa cập nhật`), Minh (`0901122334`). |

- **Ghi nhớ:** `COALESCE(a, b)` nhận vào nhiều đối số và trả về giá trị đầu tiên khác `NULL`, cực kỳ hữu ích khi định dạng báo cáo.

---

## 3.4 Thống kê gom nhóm (`GROUP BY`, `HAVING`) và Thứ tự thực thi SQL

- **Mục tiêu:** Viết đúng câu lệnh thống kê theo nhóm và hiểu bản chất khác nhau giữa `WHERE` và `HAVING` thông qua thứ tự thực thi logic của SQL.
- **Giải thích trực quan:** Dù từ khóa `SELECT` đứng ở đầu câu khi viết, hệ quản trị lại chạy từ `FROM` → `WHERE` → `GROUP BY` → `HAVING` → `SELECT` → `ORDER BY` → `LIMIT`. Vì `SELECT` chạy ở bước thứ 5 nên bí danh (alias) khai báo ở `SELECT` không dùng được ở `WHERE`.
- **Minh họa:**

![Hình 3.2: Thứ tự thực thi logic của câu lệnh SQL và Phân biệt GROUP BY với Window Function](img/05_sql_execution_order.svg)

**Các hàm tổng hợp cơ bản:**
- `COUNT(*)`: Đếm tổng số dòng trong nhóm | `COUNT(email)`: Chỉ đếm các dòng có `email` khác `NULL`.
- `SUM(col)`: Tính tổng | `AVG(col)`: Tính trung bình | `MIN(col)` / `MAX(col)`: Nhỏ nhất / Lớn nhất.

- **Thực hành (Phân biệt `WHERE` và `HAVING` trên bảng `products`):** Tìm các danh mục có **từ 3 sản phẩm có giá trên 50.000đ** trở lên và tính giá trung bình của từng danh mục:

```sql
SELECT
    category_id,
    COUNT(*) AS so_sp,
    ROUND(AVG(price), 0) AS gia_tb
FROM products
WHERE price > 50000          -- Bước 2: Loại bỏ 'Cáp sạc USB-C cơ bản' (45.000đ) trước khi gom nhóm
GROUP BY category_id         -- Bước 3: Gom các sản phẩm đạt điều kiện theo từng danh mục
HAVING COUNT(*) >= 3         -- Bước 4: Chỉ giữ nhóm có từ 3 sản phẩm trở lên
ORDER BY gia_tb DESC;        -- Bước 6: Sắp xếp danh mục có giá trung bình cao nhất lên đầu
```

- **Kết quả thực tế:**

| category_id | so_sp | gia_tb |
| :---: | :---: | ---: |
| 1 | 3 | 28830000 |
| 2 | 3 | 630000 |

- **Giải thích từng dòng kết quả:**
  - **Vì sao danh mục `1` (Laptop) có 3 sản phẩm?** Cả 3 laptop (`27.990.000`, `34.500.000`, `24.000.000`) đều lớn hơn `50.000`, đạt `so_sp = 3`, giá trung bình đúng bằng `28.830.000`.
  - **Vì sao danh mục `2` (Phụ kiện) có 4 sản phẩm nhưng chỉ tính 3?** Vì `Cáp sạc USB-C cơ bản` giá `45.000đ <= 50.000đ` đã bị mệnh đề **`WHERE price > 50000`** loại bỏ ngay ở bước 2 trước khi gom nhóm; 3 sản phẩm còn lại (`350.000`, `650.000`, `890.000`) có trung bình `630.000`.
  - **`HAVING` đã loại bỏ nhóm nào?** Danh mục `3` (Màn hình, chỉ có 2 sản phẩm) và danh mục `4` (Âm thanh, chỉ có 1 sản phẩm) đều không đạt `COUNT(*) >= 3` nên bị loại ở bước 4.
  - **Vì sao danh mục `1` đứng đầu?** Nhờ `ORDER BY gia_tb DESC` xếp từ cao xuống thấp (`28.830.000 > 630.000`).
- **Ghi nhớ:** `WHERE` lọc **từng dòng thô** *trước* khi gom nhóm; `HAVING` lọc **cả nhóm** *sau* khi đã `GROUP BY`.

---

## 3.5 Kết hợp nhiều bảng với `JOIN`

- **Mục tiêu:** Ghép dữ liệu từ nhiều bảng đã chuẩn hóa (`users`, `orders`, `order_items`, `products`) và hiểu chính xác 7 kiểu `JOIN`.
- **Giải thích:** Nhờ chuẩn hóa 3NF, tên khách hàng nằm ở `users`, thông tin đơn hàng ở `orders`, sản phẩm mua ở `order_items` và tên sản phẩm ở `products`. `JOIN` là cầu nối ghép các bảng đó lại theo khóa ngoại.
- **Minh họa:**

![Hình 3.3: Minh họa tập hợp kết quả của các phép ghép bảng (SQL JOIN) giữa A (users) và B (orders)](img/06_sql_joins_visual.svg)

- **Lưu ý quan trọng về dữ liệu không khớp khóa ngoại (`user_id = NULL` vs `user_id = 99`):**
  - Trong **Hình 3.3**, đơn hàng `104 (user_id = 99)` minh họa trường hợp dữ liệu mồ côi khi đối soát bảng tạm nhập từ hệ thống ngoài (`staging_orders` *không* gắn ràng buộc Foreign Key). Khi bảng `orders` đã gắn chuẩn `FOREIGN KEY (user_id) REFERENCES users(id)`, PostgreSQL sẽ **từ chối ngay** nếu cố chèn `user_id = 99` không tồn tại.
  - Tuy nhiên, bảng `orders` trong `database-demo/` **cho phép `user_id = NULL`** để đại diện cho **đơn hàng khách vãng lai tại quầy** (đơn `#6`, `350.000đ`). Chính đơn `#6` cùng hai khách hàng chưa từng mua hàng (`Tuấn`, `An`) cho phép bạn thực hành trực tiếp toàn bộ các phép `JOIN` trên dữ liệu thật mà vẫn tuân thủ chặt chẽ khóa ngoại!

- **Thực hành & Kết quả trực tiếp trên `database-demo/`:**

1. **`INNER JOIN` (Chỉ lấy đơn hàng có gắn tài khoản khách):**
```sql
SELECT u.id AS user_id, u.name, o.id AS order_id, o.amount, o.status
FROM users u
INNER JOIN orders o ON u.id = o.user_id
ORDER BY o.id;
```
| user_id | name | order_id | amount | status |
| :---: | :--- | :---: | ---: | :--- |
| 1 | Phong | 1 | 27990000.00 | completed |
| 1 | Phong | 2 | 700000.00 | completed |
| 2 | Linh | 3 | 8500000.00 | completed |
| 2 | Linh | 4 | 650000.00 | pending |
| 5 | Minh | 5 | 890000.00 | cancelled |

*(Loại Tuấn, An vì chưa có đơn; loại đơn #6 vì `user_id IS NULL`.)*

2. **`LEFT JOIN` (Giữ toàn bộ khách hàng kể cả chưa mua):**
```sql
SELECT u.id AS user_id, u.name, o.id AS order_id, o.amount
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
ORDER BY u.id, o.id;
```
| user_id | name | order_id | amount |
| :---: | :--- | :---: | ---: |
| 1 | Phong | 1 | 27990000.00 |
| 1 | Phong | 2 | 700000.00 |
| 2 | Linh | 3 | 8500000.00 |
| 2 | Linh | 4 | 650000.00 |
| 3 | Tuấn | `NULL` | `NULL` |
| 4 | An | `NULL` | `NULL` |
| 5 | Minh | 5 | 890000.00 |

3. **`ANTI-JOIN` (Tìm khách hàng chưa từng đặt đơn nào):**
```sql
SELECT u.id, u.name
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE o.id IS NULL
ORDER BY u.id;
```
Trả về 2 dòng: `(3, Tuấn)` và `(4, An)`.

4. **`RIGHT JOIN` và `FULL OUTER JOIN`:**
   - `RIGHT JOIN` giữ toàn bộ 6 dòng của `orders`, làm lộ đơn vãng lai `#6` có cột `u.name` là `NULL`.
   - `FULL OUTER JOIN` trả về 8 dòng: giữ cả `Tuấn`, `An` (chưa mua hàng) lẫn đơn `#6` (`NULL` khách hàng) — dùng để đối soát hai chiều.
5. **Ghép liên tiếp 4 bảng (`orders` → `users` → `order_items` → `products`) xem chi tiết từng hóa đơn:**
```sql
SELECT
    o.id AS order_id,
    COALESCE(u.name, 'Khách vãng lai') AS khach_hang,
    p.name AS san_pham,
    oi.quantity,
    oi.unit_price
FROM orders o
LEFT JOIN users u ON u.id = o.user_id
JOIN order_items oi ON oi.order_id = o.id
JOIN products p ON p.id = oi.product_id
ORDER BY o.id;
```
| order_id | khach_hang | san_pham | quantity | unit_price |
| :---: | :--- | :--- | :---: | ---: |
| 1 | Phong | MacBook Air M3 13" | 1 | 27990000.00 |
| 2 | Phong | Chuột không dây MX | 2 | 350000.00 |
| 3 | Linh | Màn hình Dell UltraSharp 27" | 1 | 8500000.00 |
| 4 | Linh | Hub chuyển đổi USB-C 6-in-1 | 1 | 650000.00 |
| 5 | Minh | Tai nghe chụp tai Studio | 1 | 890000.00 |
| 6 | Khách vãng lai | Chuột không dây MX | 1 | 350000.00 |

6. **Hai phép `JOIN` chuyên biệt khác (`CROSS JOIN` và `SELF JOIN`):**
   - **`CROSS JOIN`:** Ghép mọi dòng bảng A với mọi dòng bảng B không cần `ON` (ví dụ `sizes CROSS JOIN colors` sinh biến thể sản phẩm).
   - **`SELF JOIN`:** Một bảng tự ghép với chính nó (ví dụ `employees e LEFT JOIN employees m ON e.manager_id = m.id` để ghép nhân viên với quản lý trực tiếp).

- **Ghi nhớ:** Dùng `LEFT JOIN` khi muốn giữ đủ đối tượng chính (kể cả chưa phát sinh giao dịch), và cẩn thận khi ghép `INNER JOIN` với `orders` nếu đơn hàng có thể mang `user_id = NULL`.

---

## 3.6 Truy vấn con, CTE (`WITH`), `UPSERT`, `EXISTS` và `UNION`

- **Mục tiêu:** Tổ chức truy vấn phức tạp theo từng bước sạch sẽ bằng CTE, ghi dữ liệu an toàn với `UPSERT`, kiểm tra tồn tại bằng `EXISTS` và gộp dữ liệu dọc bằng `UNION`.

### 1. Biểu thức bảng chung (`CTE` — mệnh đề `WITH`)
Chia truy vấn lớn thành bảng tạm trung gian có đặt tên, chỉ tồn tại trong câu lệnh đó:

```sql
WITH vip_users AS (
    SELECT user_id, SUM(amount) AS tong_chi
    FROM orders
    WHERE status = 'completed'
    GROUP BY user_id
    HAVING SUM(amount) >= 10000000
)
SELECT u.name, u.email, v.tong_chi
FROM users u
INNER JOIN vip_users v ON u.id = v.user_id;
```

**Kết quả thực tế:**

| name | email | tong_chi |
| :--- | :--- | ---: |
| Phong | phong@mail.com | 28690000.00 |

*(Linh chỉ chi `8.500.000` ở đơn `completed` — đơn `650.000` đang ở trạng thái `pending` — nên chưa đạt ngưỡng `10.000.000`.)*

### 2. Thao tác `UPSERT` (`INSERT ... ON CONFLICT`)
"Thêm mới nếu chưa có, cập nhật nếu đã trùng khóa xung đột" trong **một lệnh nguyên tử duy nhất**.

> **Lưu ý kỹ thuật cực quan trọng với cột `GENERATED ALWAYS AS IDENTITY`:** Vì cột `users.id` được khai báo `GENERATED ALWAYS AS IDENTITY`, PostgreSQL **cấm** bạn tự truyền giá trị vào `id` trong câu `INSERT` thông thường (sẽ báo lỗi `cannot insert a non-DEFAULT value into column "id"`). Có hai cách viết đúng chuẩn:

```sql
BEGIN;

-- Cách 1 (Khuyên dùng): Bỏ cột id, dùng khóa tự nhiên có UNIQUE (như email) làm khóa xung đột
INSERT INTO users (name, email, phone)
VALUES ('Phong Nguyễn', 'phong@mail.com', '0999888777')
ON CONFLICT (email)
DO UPDATE SET
    name  = EXCLUDED.name,
    phone = EXCLUDED.phone
RETURNING id, name, email, phone;

-- Cách 2 (Khi bắt buộc đồng bộ kèm id cụ thể từ hệ thống khác): Thêm OVERRIDING SYSTEM VALUE
INSERT INTO users (id, name, email)
OVERRIDING SYSTEM VALUE
VALUES (1, 'Phong Updated', 'phong_moi@mail.com')
ON CONFLICT (id)
DO UPDATE SET
    name  = EXCLUDED.name,
    email = EXCLUDED.email
RETURNING id, name, email;

ROLLBACK;
```

**Kết quả thực tế:**
- Cách 1 tìm thấy `phong@mail.com` đang tồn tại ở `id = 1`, tự động cập nhật thành `(1, Phong Nguyễn, phong@mail.com, 0999888777)`.
- Cách 2 ghi đè giá trị `id = 1` hợp lệ nhờ `OVERRIDING SYSTEM VALUE` và cập nhật lại `name`, `email`.

### 3. Kiểm tra sự tồn tại với `EXISTS`
Đánh giá theo cơ chế đoản mạch (dừng tìm ngay khi thấy bản ghi đầu tiên khớp) và không bị bẫy `NULL` như `IN`:

```sql
SELECT id, name
FROM users u
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id)
ORDER BY id;
```

**Kết quả thực tế:** Trả về 3 dòng `1 | Phong`, `2 | Linh`, `5 | Minh`.

### 4. Gộp tập kết quả theo chiều dọc (`UNION` và `UNION ALL`)
- `UNION ALL`: Nối trực tiếp hai kết quả `SELECT` (nhanh nhất vì không kiểm tra trùng).
- `UNION`: Tự động loại các dòng trùng nhau giữa hai tập kết quả (tốn thêm CPU/RAM để sắp xếp hoặc băm).

- **Ghi nhớ:** Ưu tiên dùng **CTE** cho truy vấn nhiều bước, dùng **khóa `UNIQUE` tự nhiên** (hoặc `OVERRIDING SYSTEM VALUE`) khi `UPSERT` trên cột Identity, và ưu tiên **`UNION ALL`** nếu chắc chắn hai tập không cần khử trùng.

---

## 3.7 Hàm cửa sổ (`Window Functions`) và Kiểu dữ liệu `JSONB`

- **Mục tiêu:** Biết xếp hạng/so sánh giữa các dòng mà không làm mất chi tiết dòng như `GROUP BY`, và biết truy vấn thuộc tính động bên trong cột `JSONB`.

### 1. Hàm cửa sổ (`OVER`)
Như đã đối chiếu ở **Hình 3.2**, `GROUP BY` thu gọn nhiều dòng thành một dòng cho mỗi nhóm, còn **Window Function (`OVER (...)`)** giữ nguyên từng dòng sản phẩm và tính thêm cột phụ:

```sql
SELECT
    name,
    category_id,
    price,
    RANK() OVER (PARTITION BY category_id ORDER BY price DESC) AS thu_hang_gia
FROM products
WHERE category_id IN (1, 2)
ORDER BY category_id, thu_hang_gia;
```

**Kết quả thực tế:**

| name | category_id | price | thu_hang_gia |
| :--- | :---: | ---: | :---: |
| ThinkPad X1 Carbon Gen 11 | 1 | 34500000.00 | 1 |
| MacBook Air M3 13" | 1 | 27990000.00 | 2 |
| Laptop Gaming Phiên Bản Giới Hạn | 1 | 24000000.00 | 3 |
| Tai nghe chụp tai Studio | 2 | 890000.00 | 1 |
| Hub chuyển đổi USB-C 6-in-1 | 2 | 650000.00 | 2 |
| Chuột không dây MX | 2 | 350000.00 | 3 |
| Cáp sạc USB-C cơ bản | 2 | 45000.00 | 4 |

Ngoài `RANK()`, còn có `DENSE_RANK()` (không nhảy số khi đồng hạng), `ROW_NUMBER()` (đánh số liên tục `1, 2, 3...`), và `LAG()` / `LEAD()` (lấy giá trị dòng trước / dòng sau để tính tăng trưởng doanh thu qua từng tháng).

### 2. Truy vấn dữ liệu bán cấu trúc `JSONB`
Trên bảng `products` của `database-demo/`, cột `specs` đã được khai báo kiểu `jsonb`:

```sql
-- 1. Trích xuất giá trị chuỗi của khóa 'ram' bằng toán tử ->>
SELECT name, specs->>'ram' AS dung_luong_ram
FROM products
WHERE category_id = 1
ORDER BY id;

-- 2. Lọc các sản phẩm chứa cặp thuộc tính bằng toán tử bao hàm @> (hỗ trợ tăng tốc bằng GIN Index)
SELECT id, name, specs
FROM products
WHERE specs @> '{"ram": "16GB"}'
ORDER BY id;
```

**Kết quả thực tế:**
- Truy vấn 1 trả về: MacBook Air M3 (`16GB`), ThinkPad X1 (`16GB`), Laptop Gaming (`32GB`).
- Truy vấn 2 trả về 2 sản phẩm có `ram = 16GB`:

| id | name | specs |
| :---: | :--- | :--- |
| 1 | MacBook Air M3 13" | `{"cpu": "Apple M3", "ram": "16GB", "storage": "512GB"}` |
| 2 | ThinkPad X1 Carbon Gen 11 | `{"cpu": "Core i7", "ram": "16GB", "storage": "1TB"}` |

- **Ghi nhớ:** Toán tử `->` trả về kiểu `jsonb`, còn **`->>`** trả về kiểu văn bản `text`. Dùng **`@>`** kết hợp với **GIN Index** (mục **5.2**) để lọc trên `JSONB` với tốc độ cao.

---

# Phần 4: Giao Dịch (Transaction) và Xử Lý Đồng Thời

## 4.1 Giao dịch (Transaction) và Nguyên tắc ACID

- **Mục tiêu:** Đảm bảo một nhóm thao tác liên quan chặt chẽ (như chuyển tiền hoặc tạo đơn + trừ tồn kho) luôn thực hiện trọn vẹn hoặc hủy bỏ sạch sẽ khi có sự cố.
- **Giải thích:** Khi chuyển 1.000.000đ từ ví A sang ví B, hệ thống phải chạy hai lệnh: trừ tiền A và cộng tiền B. Nếu bước 1 xong mà máy chủ tắt điện trước bước 2, 1.000.000đ sẽ "bốc hơi". **Transaction** bọc cả hai bước thành một khối duy nhất: chỉ ghi nhận vĩnh viễn khi gặp **`COMMIT`**, còn nếu có lỗi hay gọi **`ROLLBACK`** thì toàn bộ quay lại như chưa từng xảy ra.
- **Minh họa:**

![Hình 4.1: Giao dịch (ACID), Kiểm soát đa phiên bản (MVCC) và Khóa dòng (Row Locking)](img/07_acid_mvcc_locking.svg)

- **Thực hành (tạo bảng tạm chạy thử trực tiếp ngay trong `psql`):**

```sql
CREATE TEMP TABLE wallets (
    id      int PRIMARY KEY,
    owner   text NOT NULL,
    balance numeric(12, 2) NOT NULL CHECK (balance >= 0)
);
INSERT INTO wallets VALUES (1, 'Phong', 5000000), (2, 'Linh', 2000000);

-- Trường hợp 1: Chuyển 1.000.000đ thành công
BEGIN;
UPDATE wallets SET balance = balance - 1000000 WHERE id = 1;
UPDATE wallets SET balance = balance + 1000000 WHERE id = 2;
COMMIT;

-- Trường hợp 2: Gặp lỗi ở bước 2 -> ROLLBACK bảo toàn số dư cũ
BEGIN;
UPDATE wallets SET balance = balance - 1000000 WHERE id = 1; -- Tạm trừ xuống 3.000.000
UPDATE wallets SET balance = balance + 1000000 WHERE id = 999; -- Giả lập lỗi logic / hoặc gõ sai tên cột
-- Nếu gõ nhầm cột hoặc ứng dụng phát hiện lỗi nghiệp vụ -> chạy ROLLBACK:
ROLLBACK;

SELECT * FROM wallets ORDER BY id;
```

- **Kết quả:** Sau Trường hợp 1, Phong còn `4.000.000`, Linh có `3.000.000`. Sau khi Trường hợp 2 gọi `ROLLBACK`, số dư của Phong vẫn giữ nguyên `4.000.000` (không bị trừ oan).

Bốn tính chất **ACID** bảo chứng độ tin cậy của Transaction:

| Tính chất | Ý nghĩa đơn giản | Ví dụ trong bài toán chuyển tiền |
| :--- | :--- | :--- |
| **Atomicity (Nguyên tử)** | Hoặc xong hết, hoặc hủy hết | Không bao giờ A mất tiền mà B chưa nhận được. |
| **Consistency (Nhất quán)** | Luôn thỏa mọi ràng buộc (`CHECK`, `FK`, `UNIQUE`) | Chuyển 6.000.000đ khi A chỉ có 4.000.000đ bị `CHECK (balance >= 0)` từ chối ngay. |
| **Isolation (Cô lập)** | Giao dịch chạy song song không thấy dữ liệu dở dang của nhau | Khi giao dịch chuyển tiền chưa `COMMIT`, người khác xem số dư vẫn thấy số dư ổn định. |
| **Durability (Bền vững)** | Đã `COMMIT` thành công thì mất điện vẫn còn nguyên | Nhờ cơ chế nhật ký ghi trước `WAL` (mục **6.1**). |

- **Ghi nhớ:** Mọi nghiệp vụ nhiều bước ghi dữ liệu (tạo đơn hàng + thêm `order_items` + trừ `products.stock`) đều phải nằm trong một khối `BEGIN ... COMMIT`.

---

## 4.2 Cơ chế kiểm soát đa phiên bản (MVCC) và Snapshot

- **Mục tiêu:** Hiểu lý do PostgreSQL cho phép hàng nghìn người vừa đọc báo cáo vừa cập nhật dữ liệu mà không làm tắc nghẽn nhau, và hiểu chính xác cách **`Snapshot`** hoạt động ở hai mức cô lập phổ biến.
- **Giải thích trực quan trước thuật ngữ:**
  Hãy tưởng tượng hai người cùng mở một tài liệu. Một người đang đọc để tổng hợp báo cáo, người còn lại chỉnh sửa nội dung. Nếu hệ thống bắt người đọc phải ngồi chờ người sửa làm xong mới được xem tiếp, toàn bộ hệ thống sẽ chạy rất chậm.
  PostgreSQL giải quyết vấn đề này bằng cách **không ghi đè trực tiếp lên dòng dữ liệu cũ**, mà tạo ra một **phiên bản mới** của dòng đó mỗi khi có `UPDATE`.
  - Cơ chế lưu giữ nhiều phiên bản đồng thời này gọi là **MVCC (Multi-Version Concurrency Control)**.
  - Bức ảnh dữ liệu nhất quán mà một câu lệnh hoặc một giao dịch nhìn thấy tại thời điểm bắt đầu chạy gọi là **Snapshot** (*ảnh chụp dữ liệu*).
  - Những phiên bản dòng cũ không còn giao dịch nào đọc tới nữa gọi là **Dead Tuples** (*bản ghi chết*), về sau sẽ được tiến trình nền `Autovacuum` dọn dẹp (mục **5.4**).

- **Thực hành phân biệt hành vi MVCC giữa `READ COMMITTED` và `REPEATABLE READ`:**
  Điểm rất dễ nhầm ở người mới là: *Nếu Giao dịch B sửa giá sản phẩm `id = 4` từ `350.000` thành `420.000` và **`COMMIT` ngay ở giữa**, thì câu `SELECT` lần thứ 2 của Giao dịch A sẽ thấy `350.000` hay `420.000`?*
  Câu trả lời phụ thuộc vào **Mức cô lập** mà Giao dịch A đang sử dụng (**Hình 4.1**):

  **Kịch bản 1 — Mức mặc định `READ COMMITTED` (Snapshot tạo mới cho *từng câu lệnh SQL*):**

  | Thời điểm | Giao dịch A (`BEGIN;` — mặc định `READ COMMITTED`) | Giao dịch B (Cập nhật giá) |
  | :--- | :--- | :--- |
  | **T1** | Chạy `BEGIN;` rồi `SELECT price FROM products WHERE id = 4;` → thấy **`350.000`**. | Chưa bắt đầu. |
  | **T2** | Đang xử lý bước trung gian. | Chạy `BEGIN; UPDATE products SET price = 420000 WHERE id = 4;` (**chưa** `COMMIT`). |
  | **T3** | Đọc lại `price` → **không bị chặn**, vẫn thấy **`350.000`** (vì B chưa `COMMIT`). | Vẫn đang mở giao dịch. |
  | **T4** | Đang xử lý tiếp. | Chạy **`COMMIT;`** (xác nhận giá `420.000`). |
  | **T5** | Chạy `SELECT price FROM products WHERE id = 4;` lần nữa → thấy **`420.000`** vì câu `SELECT` mới lấy Snapshot mới nhất sau khi B đã `COMMIT`. | Đã kết thúc. |

  **Kịch bản 2 — Mức `REPEATABLE READ` (Snapshot cố định cho *toàn bộ giao dịch*):**

  | Thời điểm | Giao dịch A (`BEGIN ISOLATION LEVEL REPEATABLE READ;`) | Giao dịch B (Cập nhật giá) |
  | :--- | :--- | :--- |
  | **T1** | Chạy `BEGIN ISOLATION LEVEL REPEATABLE READ;` và `SELECT price ...` → thiết lập Snapshot của cả giao dịch, thấy **`350.000`**. | Chưa bắt đầu. |
  | **T2** | Đang tính toán báo cáo. | Chạy `BEGIN; UPDATE products SET price = 420000 WHERE id = 4; COMMIT;` (**đã `COMMIT`**). |
  | **T3** | Chạy lại `SELECT price FROM products WHERE id = 4;` → **vẫn thấy `350.000`** dù B đã `COMMIT`! | Đã kết thúc. |
  | **T4** | Kết thúc `COMMIT;`. Một giao dịch mới mở sau đó mới thấy `420.000`. | — |

- **Ghi nhớ:** Trong PostgreSQL, **người đọc không chặn người ghi và người ghi không chặn người đọc**. Ở mức mặc định `READ COMMITTED`, mỗi câu SQL thấy dữ liệu mới nhất đã `COMMIT`; còn `REPEATABLE READ` đóng băng một *Snapshot* xuyên suốt cả giao dịch.

---

## 4.3 Bốn bất thường đồng thời và Các mức cô lập (Isolation Levels)

- **Mục tiêu:** Hiểu rõ 4 hiện tượng sai lệch dữ liệu có thể xảy ra khi nhiều giao dịch chạy song song và chọn đúng mức cô lập cho từng bài toán.
- **Giải thích trực quan trước thuật ngữ:** Hãy tưởng tượng bạn đang kiểm kê kho hàng trong lúc nhân viên thu ngân liên tục tạo hóa đơn mới:

1. **Dirty Read (Đọc dữ liệu bẩn):** Nhân viên A sửa nháp giá từ `350k` lên `420k` (chưa bấm lưu), bạn nhìn lướt qua và ghi nhầm `420k` vào báo cáo; ngay sau đó nhân viên A bấm hủy.
   - *Trong PostgreSQL:* **Không bao giờ xảy ra** ở mọi mức cô lập.
2. **Non-repeatable Read (Đọc không lặp lại):** Bạn xem giá sản phẩm A lúc 9h00 thấy `350k`. Lúc 9h01 thu ngân sửa giá thành `420k` và lưu xong. Lúc 9h02, vẫn trong phiên làm báo cáo đó, bạn đọc lại dòng sản phẩm A thì giá đã biến thành `420k`.
3. **Phantom Read (Đọc bóng ma):** Bạn đếm số đơn hàng hôm nay được `6` đơn. Ngay lúc đó nhân viên khác thêm 1 đơn hàng mới và lưu xong. Cuối buổi kiểm kê bạn đếm lại theo đúng điều kiện cũ thì tự dưng mọc thêm thành `7` đơn.
4. **Serialization Anomaly (Bất thường tuần tự hóa):** Từng giao dịch riêng lẻ đều đọc dữ liệu đã `COMMIT` và hợp lệ, nhưng **kết quả cuối cùng khi chạy song song lại không thể đạt được nếu cho chúng chạy lần lượt từng cái một**.
   - *Ví dụ trực quan (Write Skew):* Quy định bệnh viện yêu cầu **luôn phải có ít nhất 1 bác sĩ trực**. Hiện tại có 2 bác sĩ (`An` và `Bình`) đang trong ca trực. Cả hai cùng mở app xin nghỉ trực cùng lúc ở mức `REPEATABLE READ`:
     - Giao dịch của `An` đọc Snapshot thấy còn 2 người trực → hợp lệ để `An` chuyển sang `off`.
     - Giao dịch của `Bình` đọc cùng Snapshot cũng thấy còn 2 người trực → hợp lệ để `Bình` chuyển sang `off`.
     - Cả hai cùng `COMMIT` thành công! Kết quả cuối cùng là **0 bác sĩ trực** — điều không bao giờ xảy ra nếu An và Bình chạy lần lượt từng người một!

**Bảng tổng hợp khả năng ngăn chặn theo tài liệu PostgreSQL 16 chính thức:**

| Bất thường đồng thời | `READ COMMITTED` *(Mặc định)* | `REPEATABLE READ` | `SERIALIZABLE` |
| :--- | :---: | :---: | :---: |
| **1. Dirty Read** *(Đọc dữ liệu chưa `COMMIT`)* | Đã ngăn chặn | Đã ngăn chặn | Đã ngăn chặn |
| **2. Non-repeatable Read** *(Đọc lại 1 dòng bị đổi giá trị)* | Có thể xảy ra | **Đã ngăn chặn** | **Đã ngăn chặn** |
| **3. Phantom Read** *(Đếm lại tập dòng bị thêm/bớt dòng)* | Có thể xảy ra | **Đã ngăn chặn** *(trong PostgreSQL)* | **Đã ngăn chặn** |
| **4. Serialization Anomaly** *(Hai giao dịch chạy song song tạo kết quả mâu thuẫn)* | Có thể xảy ra | Có thể xảy ra | **Đã ngăn chặn** |

- **Lựa chọn mức cô lập trong thực tế:**
  - **`READ COMMITTED` (Mặc định):** Đáp ứng khoảng 95% tác vụ ứng dụng thông thường, chi phí quản lý xung đột thấp nhất.
  - **`REPEATABLE READ`:** Phù hợp xuất báo cáo tài chính/đối soát nhiều bảng đòi hỏi toàn bộ số liệu không biến động trong suốt quá trình đọc:
    ```sql
    BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    SELECT COUNT(*), SUM(amount) FROM orders WHERE status = 'completed';
    COMMIT;
    ```
  - **`SERIALIZABLE`:** Dùng cho nghiệp vụ có ràng buộc chéo nhiều dòng/nhiều bảng (như lịch trực, hạn mức tổng hợp nhiều ví). Ứng dụng **bắt buộc phải cài cơ chế tự thử lại (retry)** khi PostgreSQL ném lỗi `ERROR: could not serialize access due to read/write dependencies among transactions` (SQLSTATE `40001`).

- **Ghi nhớ:** Điểm phân biệt cốt lõi giữa `REPEATABLE READ` và `SERIALIZABLE` trong PostgreSQL nằm ở **Serialization Anomaly** (chứ không chỉ là Phantom Read, vì PostgreSQL đã chặn Phantom Read ngay từ `REPEATABLE READ`).

---

## 4.4 Khóa mức dòng xử lý tranh chấp đồng thời: `FOR UPDATE` và `SKIP LOCKED`

- **Mục tiêu:** Giải quyết bài toán hai khách hàng mua cùng lúc 1 sản phẩm cuối cùng trong kho và bài toán nhiều tiến trình (worker) xử lý song song một hàng đợi công việc.

### 1. Chống bán vượt tồn kho bằng khóa bi quan (`FOR UPDATE`)
- **Tình huống:** Trong `database-demo/`, sản phẩm `id = 3` (`Laptop Gaming Phiên Bản Giới Hạn`) chỉ còn **`stock = 1`**. Nếu hai khách hàng cùng bấm thanh toán tại một thời điểm mà chỉ dùng `SELECT stock` thông thường, cả hai đều thấy `1 >= 1`, dẫn tới bán 2 máy khi kho chỉ có 1 (hoặc chạm lỗi `CHECK (stock >= 0)`).
- **Giải pháp:** Dùng `SELECT ... FOR UPDATE` để khóa độc quyền dòng sản phẩm đó cho tới khi `COMMIT` hoặc `ROLLBACK` (**Hình 4.1**):

| Thời điểm | Giao dịch A (Khách 1 — vào trước) | Giao dịch B (Khách 2 — vào sau) |
| :--- | :--- | :--- |
| **T1** | Chạy `SELECT stock FROM products WHERE id = 3 FOR UPDATE;` → thấy `stock = 1` và **giữ khóa dòng `id = 3`**. | Chạy `SELECT ... FOR UPDATE` trên `id = 3` → **bị tạm dừng chờ A**. |
| **T2** | Trừ kho `stock = 0` rồi `COMMIT;` (mở khóa). | Tiếp tục chờ cho tới khi A kết thúc. |
| **T3** | Hoàn tất đơn hàng thành công. | Được mở khóa, đọc thấy **`stock = 0`**, kiểm tra không đủ hàng và `ROLLBACK;` an toàn. |

```sql
BEGIN;
SELECT stock FROM products WHERE id = 3 FOR UPDATE;
-- Ứng dụng kiểm tra stock >= 1 rồi mới trừ kho:
UPDATE products SET stock = stock - 1 WHERE id = 3 AND stock >= 1;
COMMIT;
```

### 2. Phân phối hàng đợi tác vụ song song không nghẽn (`SKIP LOCKED`)
- **Tình huống:** Nhiều tiến trình nền (Worker) cùng lấy việc từ bảng hàng đợi `task_queue` để gửi email xác nhận đơn hàng. Nếu chỉ dùng `FOR UPDATE`, Worker 2 và 3 phải đứng đợi Worker 1 làm xong dòng `id = 1`.
- **Giải pháp:** Kết hợp **`FOR UPDATE SKIP LOCKED`** để mỗi Worker **bỏ qua ngay dòng đang bị Worker khác giữ khóa** và nhận ngay tác vụ tiếp theo:

```sql
-- Tạo bảng hàng đợi minh họa để chạy thử trực tiếp
CREATE TEMP TABLE task_queue (
    id       int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email_to text NOT NULL,
    status   text NOT NULL DEFAULT 'pending'
);
INSERT INTO task_queue (email_to) VALUES ('a@mail.com'), ('b@mail.com'), ('c@mail.com');

-- Lấy đúng 1 việc khả dụng và đổi trạng thái sang 'processing' trong một câu lệnh nguyên tử
WITH picked AS (
    SELECT id
    FROM task_queue
    WHERE status = 'pending'
    ORDER BY id
    LIMIT 1
    FOR UPDATE SKIP LOCKED
)
UPDATE task_queue t
SET status = 'processing'
FROM picked
WHERE t.id = picked.id
RETURNING t.id, t.email_to, t.status;
```

- **Kết quả thực tế:** Worker 1 nhận `(1, a@mail.com, processing)`; cùng lúc đó nếu Worker 2 chạy câu lệnh này sẽ tự động bỏ qua dòng `1` và nhận ngay `(2, b@mail.com, processing)` mà không chờ đợi.
- **Ghi nhớ:** Dùng `FOR UPDATE` khi cần bảo vệ tính nhất quán trên **cùng một đối tượng** (tồn kho, số dư); dùng `FOR UPDATE SKIP LOCKED` khi muốn **nhiều worker chia việc song song** trên hàng đợi.

---

# Phần 5: Chỉ Mục (Index), Tối Ưu Truy Vấn và Bảo Trì Dữ Liệu

## 5.1 Chỉ mục (`Index`) và cách đọc `EXPLAIN ANALYZE`

- **Mục tiêu:** Hiểu cơ chế tăng tốc tìm kiếm của Index, nắm vững cách đọc kết quả `EXPLAIN ANALYZE` của Query Planner và phân biệt đúng `Seq Scan`, `Index Scan`, `Index Only Scan`.
- **Giải thích trực quan:** Một bảng dữ liệu 10 triệu dòng giống như cuốn sách dày hàng nghìn trang, còn **Chỉ mục (Index)** chính là mục lục được sắp xếp sẵn theo thứ tự tra cứu ở đầu sách (**Hình 5.1**). Thay vì đọc lướt từ trang 1 tới trang cuối, PostgreSQL chỉ cần vài bước tra mục lục là nhảy thẳng tới trang chứa dòng cần tìm.

![Hình 5.1: So sánh tìm kiếm bản ghi id = 85 trong bảng 10 triệu dòng (Không Index và Có B-Tree Index)](img/08_index_btree_vs_seqscan.svg)

**Ba phương thức đọc dữ liệu chính của Query Planner:**

| Phương thức quét | Phép ẩn dụ | Điều kiện kích hoạt và lưu ý kỹ thuật |
| :--- | :--- | :--- |
| **`Seq Scan`** *(Quét tuần tự)* | Đọc lướt từ trang đầu tới trang cuối bảng | Bảng nhỏ, chưa có Index phù hợp, hoặc truy vấn cần lấy phần lớn số dòng của bảng. |
| **`Index Scan`** *(Quét qua chỉ mục)* | Tra mục lục tìm số trang rồi lật vào ruột sách lấy thêm cột khác | Lọc một tập con nhỏ qua cột có Index (ví dụ `WHERE email = '...'`), sau đó đọc thêm các cột không nằm trong Index từ bảng chính (*heap*). |
| **`Index Only Scan`** *(Chỉ đọc trên chỉ mục)* | Mọi cột cần đọc đều nằm sẵn ngay trên mục lục | Mọi cột trong `SELECT` và `WHERE` đều nằm trọn trong Index. **Tuy nhiên, không phải lúc nào cũng nhanh hơn mọi trường hợp**: hiệu quả phụ thuộc vào **Visibility Map** (bảng đồ đánh dấu các trang dữ liệu đã sạch do `VACUUM` / `Autovacuum` cập nhật). Nếu dữ liệu vừa thay đổi nhiều và trang chưa được đánh dấu sạch (`Heap Fetches > 0`), PostgreSQL vẫn phải ghé vào bảng chính để kiểm tra khả năng hiển thị theo MVCC. |

- **Thực hành tạo bảng 50.000 dòng và đọc kế hoạch thực thi bằng `EXPLAIN ANALYZE`:**

```sql
CREATE TEMP TABLE perf_users (
    id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email text NOT NULL,
    name  text NOT NULL
);
INSERT INTO perf_users (email, name)
SELECT 'user' || g || '@mail.com', 'User ' || g
FROM generate_series(1, 50000) AS g;
ANALYZE perf_users; -- Cập nhật thống kê phân bố dữ liệu cho Query Planner

-- 1. Trước khi có Index trên email:
EXPLAIN ANALYZE SELECT id, email FROM perf_users WHERE email = 'user42000@mail.com';

-- 2. Tạo B-Tree Index và cập nhật Visibility Map bằng VACUUM:
CREATE INDEX idx_perf_users_email ON perf_users(email);
VACUUM ANALYZE perf_users;

-- 3. Lấy cả cột name (không nằm trong Index) -> Index Scan:
EXPLAIN ANALYZE SELECT id, name FROM perf_users WHERE email = 'user42000@mail.com';

-- 4. Chỉ lấy cột email (nằm sẵn trong Index) khi Visibility Map sạch -> Index Only Scan:
EXPLAIN ANALYZE SELECT email FROM perf_users WHERE email = 'user42000@mail.com';
```

- **Kết quả thực tế thu được trên PostgreSQL 16:**

```text
-- 1. Trước khi có Index:
Seq Scan on perf_users  (cost=0.00..1042.00 rows=1 width=26) (actual time=0.986..1.170 rows=1 loops=1)
  Filter: (email = 'user42000@mail.com'::text)
  Rows Removed by Filter: 49999
Execution Time: 1.177 ms

-- 2. Sau khi có Index (Index Scan vì cần đọc thêm cột name):
Index Scan using idx_perf_users_email on perf_users  (cost=0.41..8.43 rows=1 width=18) (actual time=0.014..0.014 rows=1 loops=1)
  Index Cond: (email = 'user42000@mail.com'::text)
Execution Time: 0.022 ms

-- 3. Index Only Scan (chỉ đọc email và đã VACUUM):
Index Only Scan using idx_perf_users_email on perf_users  (cost=0.41..4.43 rows=1 width=18) (actual time=0.002..0.002 rows=1 loops=1)
  Index Cond: (email = 'user42000@mail.com'::text)
  Heap Fetches: 0
Execution Time: 0.004 ms
```

**Cách đọc nhanh các thông số của Query Planner trong `EXPLAIN ANALYZE`:**
- **`cost=startup..total`:** Chi phí ước lượng (đơn vị quy ước nội bộ, không phải mili-giây) trước khi chạy.
- **`rows` (bên `cost`) vs `rows` (bên `actual`):** Nếu số dòng ước lượng và số dòng thực tế lệch nhau quá lớn, cần chạy `ANALYZE` để cập nhật lại thống kê bảng.
- **`actual time=first..last` (tính bằng ms):** Thời gian thực tế để lấy dòng đầu tiên và hoàn tất tất cả các dòng; nhân với `loops` nếu bước đó lặp nhiều lần.
- **`Heap Fetches: 0`:** Dấu hiệu cho thấy `Index Only Scan` không hề phải đọc vào bảng chính.

- **Chi phí của Index & Hai nguyên tắc thiết kế:**
  - Index giúp đọc nhanh nhưng làm chậm thao tác ghi (`INSERT`/`UPDATE`/`DELETE`) vì PostgreSQL phải cập nhật thêm tất cả các cây Index của bảng đó.
  - **Nguyên tắc 1:** Các cột gắn `PRIMARY KEY` và `UNIQUE` đã được PostgreSQL **tự động tạo sẵn B-Tree Index**, không cần tạo trùng lặp.
  - **Nguyên tắc 2:** Chỉ đánh Index cho các cột hay xuất hiện trong `WHERE`, khóa ngoại trong `JOIN`, và `ORDER BY`.

---

## 5.2 Các loại Index phổ biến trong PostgreSQL

- **Mục tiêu:** Chọn đúng cấu trúc Index cho từng kiểu truy vấn trên bộ 5 bảng mẫu (`orders`, `users`, `products`).

| Loại chỉ mục | Phạm vi áp dụng tối ưu | Câu lệnh khởi tạo trên `database-demo/` |
| :--- | :--- | :--- |
| **B-Tree** *(Mặc định)* | Chiếm ~90% nhu cầu: `=`, `>`, `<`, `BETWEEN`, `IN`, `ORDER BY` và tìm tiền tố `LIKE 'abc%'`. | `CREATE INDEX idx_orders_user ON orders(user_id);` |
| **Composite** *(Đa cột)* | Lọc đồng thời theo nhiều cột (đặt cột lọc bằng `=` ở đầu danh sách). | `CREATE INDEX idx_orders_user_status ON orders(user_id, status);` |
| **Partial** *(Bộ phận)* | Chỉ đánh Index trên tập con thỏa điều kiện `WHERE`, giảm mạnh dung lượng Index. | `CREATE INDEX idx_orders_pending ON orders(created_at) WHERE status = 'pending';` |
| **Expression** *(Theo biểu thức)* | Tăng tốc tìm kiếm có dùng hàm biến đổi (ví dụ email không phân biệt hoa/thường). | `CREATE INDEX idx_users_lower_email ON users(lower(email));` |
| **GIN** *(Inverted Index)* | Tìm bên trong cột **`JSONB`**, mảng (`array`) hoặc Full-Text Search. | `CREATE INDEX idx_products_specs ON products USING gin (specs);` |

- **Minh họa cách dùng từng loại:**
  - **Composite `(user_id, status)`:** Lệnh `WHERE user_id = 2 AND status = 'pending'` dùng được chỉ mục, nhưng `WHERE status = 'pending'` đứng một mình lại **không dùng được** — giống danh bạ xếp theo **Họ** rồi mới đến **Tên**: biết Họ thì tra ngay, chỉ biết Tên thì vẫn phải lật cả danh bạ.
  - **Partial:** Chỉ lưu các đơn `'pending'` trong Index, bỏ qua hàng triệu đơn `'completed'` cũ nên Index cực gọn.
  - **Expression:** Khớp với câu `SELECT id FROM users WHERE lower(email) = 'linh@mail.com';` (đây chính là kỹ thuật được dùng trong [`qt-postgres-login-demo/db/schema.sql`](qt-postgres-login-demo/db/schema.sql) với `uq_app_users_username ON app_users (lower(username))`).
  - **GIN:** Tăng tốc mạnh cho câu `SELECT id, name FROM products WHERE specs @> '{"ram": "16GB"}';`.

---

## 5.3 Nguyên tắc viết câu lệnh SQL hiệu quả

- **Mục tiêu:** Tránh những cách viết làm vô hiệu hóa Index sẵn có hoặc gây sai lệch kết quả do `NULL`.

| Tình huống | Cách viết kém hiệu quả / dễ lỗi | Cách viết đúng & tối ưu | Lý do kỹ thuật |
| :--- | :--- | :--- | :--- |
| **1. Chọn cột cần lấy** | `SELECT * FROM orders;` | `SELECT id, amount, status FROM orders;` | Giảm đọc đĩa và băng thông truyền tải. |
| **2. Lọc theo khoảng ngày** | `WHERE EXTRACT(YEAR FROM created_at) = 2026` | `WHERE created_at >= '2026-01-01' AND created_at < '2027-01-01'` | Bọc cột trong hàm khiến B-Tree Index trên `created_at` bị vô hiệu hóa. |
| **3. Tìm chuỗi với `LIKE`** | Tìm hậu tố `WHERE name LIKE '%iphone'` bằng B-Tree chuẩn | • Tìm tiền tố (*bắt đầu* bằng): `WHERE name LIKE 'MacBook%'`<br>• Tìm chuỗi con ở *bất kỳ vị trí* nào (`'%MacBook%'`): dùng **GIN + `pg_trgm`** | Hai mẫu `'%abc'` (kết thúc bằng) và `'abc%'` (bắt đầu bằng) **khác nghĩa tìm kiếm nhau**. B-Tree chỉ hỗ trợ tìm theo **tiền tố `'abc%'`**; nếu nghiệp vụ bắt buộc tìm chuỗi con giữa/cuối câu, cần cài `CREATE EXTENSION pg_trgm` và tạo `GIN` index (`gin_trgm_ops`). |
| **4. Tìm phần tử vắng mặt** | `WHERE id NOT IN (SELECT user_id FROM orders)` | `WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id)` | Nếu danh sách `NOT IN` chứa dù chỉ 1 giá trị `NULL`, kết quả trả về sẽ rỗng! |
| **5. Phân trang dữ liệu sâu** | `ORDER BY id LIMIT 20 OFFSET 500000` | `WHERE id > 500000 ORDER BY id LIMIT 20` | `OFFSET` lớn buộc đếm bỏ qua 500.000 dòng đầu; phân trang con trỏ (`id > ...`) nhảy thẳng qua Index. |
| **6. Nạp nhiều dòng** | Lặp 1.000 lệnh `INSERT` đơn lẻ | Gộp nhiều `VALUES (...), (...);` hoặc dùng `COPY` | Triệt tiêu hàng nghìn vòng lặp gửi/nhận mạng. |

- **Thực hành kiểm chứng bẫy `NOT IN` với giá trị `NULL` ngay trên `database-demo/`:**
  Trong bảng `orders`, đơn `#6` của khách vãng lai có `user_id = NULL`. Chạy hai câu lệnh tìm khách hàng chưa từng đặt đơn:

```sql
-- Câu 1 (Sai do dính NULL từ đơn #6):
SELECT id, name FROM users WHERE id NOT IN (SELECT user_id FROM orders);

-- Câu 2 (Chính xác):
SELECT u.id, u.name FROM users u WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id);
```

- **Kết quả thực tế:**
  - Câu 1 trả về **`(0 rows)`** (sai hoàn toàn vì `3 <> NULL` cho ra `UNKNOWN`).
  - Câu 2 trả về đúng **`3 | Tuấn`** và **`4 | An`**.
- **Ghi nhớ:** Không bao giờ dùng `NOT IN (SELECT ...)` nếu cột bên trong có khả năng chứa `NULL`; hãy luôn dùng `NOT EXISTS`.

---

## 5.4 Thu hồi không gian lưu trữ với `VACUUM` và `Autovacuum`

- **Mục tiêu:** Hiểu lý do bảng bị phình dung lượng theo thời gian do MVCC và phân biệt chính xác giữa **`VACUUM`** và **`VACUUM FULL`**.
- **Giải thích trực quan:** Vì cơ chế MVCC (mục **4.2**) giữ lại các phiên bản dòng cũ sau mỗi lần `UPDATE` hoặc `DELETE`, trên đĩa xuất hiện các *Dead Tuples* giống như những tờ giấy nháp chưa vứt sau khi viết xong bản chính. Nếu không dọn, bảng và Index sẽ phình to mãi.

Kiểm tra số dòng sống và *Dead Tuples* trên bảng `orders` qua khung nhìn hệ thống:

```sql
SELECT relname, n_live_tup, n_dead_tup, last_autovacuum
FROM pg_stat_user_tables
WHERE relname = 'orders';
```

**Phân biệt rõ hai cơ chế thu hồi không gian:**

| Thao tác | Không gian giải phóng đi đâu? | Có khóa ứng dụng không? | Khi nào dùng? |
| :--- | :--- | :--- | :--- |
| **`Autovacuum` / `VACUUM ANALYZE`** | Đánh dấu khoảng trống của *Dead Tuples* để PostgreSQL **tái sử dụng cho dữ liệu mới bên trong tệp hiện tại** (hầu như **không giảm kích thước tệp vật lý trả về cho hệ điều hành**, trừ các trang trống ở cuối tệp); đồng thời cập nhật **Visibility Map** và thống kê `ANALYZE`. | **Không khóa** đọc/ghi bình thường của ứng dụng. | Tiến trình nền `Autovacuum` luôn bật mặc định để tự động xử lý; chạy thủ công `VACUUM ANALYZE` sau khi xóa/cập nhật lô dữ liệu lớn. |
| **`VACUUM FULL`** | Nén và viết lại toàn bộ bảng sang tệp mới để **trả dung lượng đĩa vật lý về lại cho hệ điều hành**. | **Áp đặt khóa độc quyền toàn bảng (`ACCESS EXCLUSIVE`)**, chặn mọi đọc & ghi trong suốt quá trình chạy. | Chỉ dùng trong khung giờ bảo trì ngoại tuyến sau khi xóa phần lớn dữ liệu của một bảng khổng lồ và cần thu hồi dung lượng ổ đĩa ngay. |

- **Ghi nhớ:** Không tắt `Autovacuum`; hiểu rằng `VACUUM` thường giúp **tái sử dụng chỗ trống nội bộ** mà không làm nghẽn hệ thống, còn `VACUUM FULL` mới thu nhỏ tệp vật lý nhưng gây khóa toàn bảng.

---

# Phần 6: Phục Hồi Dữ Liệu và Bảo Mật Hệ Thống

## 6.1 Nhật ký ghi trước (`WAL`) và cơ chế phục hồi sau sự cố

- **Mục tiêu:** Hiểu cách PostgreSQL vừa đạt tốc độ ghi cao trên RAM, vừa đảm bảo không mất dữ liệu đã `COMMIT` khi mất điện đột ngột.
- **Giải thích trực quan:** Hãy hình dung một thủ kho cẩn thận: mỗi khi có giao dịch phát sinh, thay vì chạy đi lật từng kệ hàng rải rác để sửa ngay, thủ kho ghi nhanh 1 dòng nối tiếp vào cuốn **sổ nhật ký tổng hợp** ở bàn làm việc trước, đến cuối ca mới sắp xếp lại các kệ. Nhờ đó vừa nhanh, vừa có thể khôi phục nguyên trạng từ sổ nhật ký nếu mất điện giữa chừng.

![Hình 6.1: Cơ chế nhật ký WAL (Write-Ahead Logging) và Hai nguyên tắc bảo mật cơ bản](img/09_wal_and_security.svg)

Chu trình 3 bước của **`WAL` (Write-Ahead Logging)** (**Hình 6.1**):
1. **Cập nhật trên RAM (`Shared Buffers`):** Mọi thay đổi được ghi ở tốc độ bộ nhớ đệm.
2. **Ghi nối vào tệp `WAL` trên đĩa:** Trước khi báo `COMMIT` thành công cho ứng dụng, PostgreSQL ghi nối tuần tự bản ghi thay đổi vào cuối tệp `WAL` trên ổ đĩa (thao tác ghi tuần tự cực nhanh).
3. **Đồng bộ xuống tệp bảng chính (`Checkpoint`):** Tiến trình nền định kỳ gom các trang đã sửa từ RAM ghi đồng bộ xuống thư mục dữ liệu `base/`.

| Thời điểm mất điện | Trạng thái sau khi PostgreSQL khởi động lại |
| :--- | :--- |
| **Trước khi `COMMIT` xong** | Giao dịch tự động bị hủy bỏ, không để lại dữ liệu dở dang. |
| **Sau `COMMIT`, trước `Checkpoint`** | PostgreSQL tự động đọc lại `WAL` (crash recovery) để tái tạo đủ 100% giao dịch đã `COMMIT`. |
| **Sau `Checkpoint`** | Dữ liệu đã an toàn cả trong các tệp bảng chính `base/`. |

- **Ghi nhớ:** `WAL` bảo vệ khỏi mất điện / sập tiến trình đột ngột, **không** thay thế được bản sao lưu (`pg_dump` / `pg_basebackup`) nếu hỏng ổ cứng vật lý hoặc chạy nhầm lệnh `DROP`/`DELETE`.

---

## 6.2 Quản lý phân quyền truy cập với `ROLE`

- **Mục tiêu:** Áp dụng **nguyên tắc đặc quyền tối thiểu (Principle of Least Privilege)** — mỗi ứng dụng và công cụ chỉ có đúng quyền tối thiểu cần thiết.
- **Giải thích:** Tuyệt đối không dùng tài khoản `postgres` hay `pg_admin` trong mã nguồn ứng dụng, vì chỉ một lỗ hổng nhỏ hoặc lỗi lập trình cũng có thể dẫn tới xóa sạch cấu trúc bảng (`DROP TABLE`) hoặc lộ toàn bộ hệ thống. Hãy phân nhóm quyền qua `ROLE` (**Hình 6.1**):

```sql
-- (Thực thi với quyền quản trị postgres / pg_admin)
-- 1. Nhóm quyền chỉ đọc cho công cụ báo cáo (BI / Grafana)
CREATE ROLE role_readonly;
GRANT CONNECT ON DATABASE appdb TO role_readonly;
GRANT USAGE ON SCHEMA public TO role_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO role_readonly;

-- 2. Nhóm quyền đọc & ghi dòng cho Backend (không được phép DROP/ALTER bảng)
CREATE ROLE role_readwrite;
GRANT CONNECT ON DATABASE appdb TO role_readwrite;
GRANT USAGE ON SCHEMA public TO role_readwrite;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO role_readwrite;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO role_readwrite;

-- 3. Tạo tài khoản đăng nhập riêng biệt và gán nhóm quyền
CREATE USER bi_viewer WITH PASSWORD 'MatKhauBaoCao_2026!';
GRANT role_readonly TO bi_viewer;

CREATE USER app_backend WITH PASSWORD 'MatKhauUngDung_2026!';
GRANT role_readwrite TO app_backend;

-- 4. Áp dụng tự động cho các bảng mới do tài khoản quản trị hiện tại tạo về sau
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO role_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO role_readwrite;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO role_readwrite;
```

- **Kiểm chứng thực tế:** Khi đăng nhập bằng `bi_viewer` và chạy `DELETE FROM orders WHERE id = 1;`, PostgreSQL chặn ngay với `ERROR: permission denied for table orders`. Khi `app_backend` thử `DROP TABLE orders;`, PostgreSQL trả về `ERROR: must be owner of table orders`.
- **Liên hệ dự án thực tế:** Trong [`qt-postgres-login-demo/db/schema.sql`](qt-postgres-login-demo/db/schema.sql), role `login_app` thậm chí được siết chặt hơn nữa: chỉ có quyền `SELECT, INSERT` trên `app_users` và chỉ được `UPDATE` duy nhất cột `(last_login_at)` — không thể xóa người dùng và không thể sửa `password_hash`!

---

## 6.3 Lưu trữ mật khẩu an toàn bằng hàm băm và muối (`pgcrypto` / `bcrypt`)

- **Mục tiêu:** Hiểu tại sao không bao giờ lưu mật khẩu dạng chữ rõ (plaintext) và cách triển khai băm `bcrypt` bằng phần mở rộng `pgcrypto`.
- **Giải thích trực quan:**
  - **Hàm băm một chiều (`Hash`):** Giống như chiếc máy xay sinh tố — từ trái cây xay ra ly nước ép, nhưng từ ly nước ép không thể ghép ngược lại thành trái cây ban đầu.
  - **Muối ngẫu nhiên (`Salt`):** Trước khi băm, hệ thống trộn thêm một chuỗi ngẫu nhiên riêng cho từng tài khoản, khiến hai người đặt chung một mật khẩu vẫn ra hai chuỗi băm hoàn toàn khác nhau, vô hiệu hóa bảng tra cứu sẵn (*Rainbow Table*).
  - **Thuật toán `bcrypt` với hệ số chi phí (`cost factor`):** Khi tăng hệ số chi phí thêm `1`, thời gian tính toán tăng gấp đôi, làm kẻ tấn công không thể dò thử hàng tỷ mật khẩu mỗi giây.

- **Thực hành với `pgcrypto`:**

```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Kiểm chứng tác dụng của Salt khi băm cùng một mật khẩu '123456' hai lần
SELECT crypt('123456', gen_salt('bf', 10)) AS lan_1,
       crypt('123456', gen_salt('bf', 10)) AS lan_2;

-- 2. Tạo bảng tài khoản đăng nhập (tương tự bảng app_users trong qt-postgres-login-demo)
CREATE TABLE IF NOT EXISTS auth_accounts (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username      varchar(50) NOT NULL UNIQUE,
    password_hash text NOT NULL,
    created_at    timestamptz NOT NULL DEFAULT now()
);

-- 3. Đăng ký tài khoản
INSERT INTO auth_accounts (username, password_hash)
VALUES ('phongvt', crypt('MatKhau123!@#', gen_salt('bf', 10)));

-- 4. Xác thực khi đăng nhập: crypt() tự trích Salt nằm sẵn trong password_hash để băm đối chiếu
SELECT id, username
FROM auth_accounts
WHERE username = 'phongvt'
  AND password_hash = crypt('MatKhau123!@#', password_hash);
```

- **Kết quả thực tế của hàm `crypt()` trên PostgreSQL 16:**

| lan_1 | lan_2 |
| :--- | :--- |
| `$2a$10$HKRrt10vfSnC8Z1A4gP8sOBAljpLGtZnX4PV7Z9RYT1lh.VfUJyNO` | `$2a$10$83p.ddgqfkpCvMPB5eyZPux82ZPcA63MZY7gFCg4bDTy32tua5wsu` |

Cấu trúc chuỗi bcrypt gồm: `$2a$` (thuật toán) + `10$` (cost factor) + 22 ký tự tiếp theo (`Salt` ngẫu nhiên) + phần giá trị băm cuối cùng. Vì `Salt` nằm sẵn bên trong `password_hash`, khi kiểm tra đăng nhập ta chỉ cần truyền chính `password_hash` làm đối số thứ 2 của `crypt()`.

---

## 6.4 Bảo mật tầng truy vấn: SQL Injection và Prepared Statements

- **Mục tiêu:** Hiểu cách lỗ hổng **SQL Injection** xảy ra khi ứng dụng nối chuỗi SQL thủ công, và cách triệt tiêu hoàn toàn lỗ hổng này bằng **Prepared Statements (Tham số giữ chỗ)**.
- **Giải thích:** Khi viết ứng dụng (như Qt, Python, Node.js), sai lầm chết người của người mới là **nối trực tiếp chuỗi người dùng nhập vào giữa câu lệnh SQL**. Kẻ tấn công chỉ cần nhập các ký tự đặc biệt như dấu nháy đơn `'`, `--`, hoặc `OR '1'='1'` để bẻ gãy ý nghĩa câu lệnh SQL gốc!

- **Minh họa lỗ hổng (KHÔNG BAO GIỜ VIẾT NHƯ SAU):**
  Giả sử một đoạn code C++/Qt nối chuỗi trực tiếp:
  ```cpp
  // NGUY HIỂM: Nối chuỗi trực tiếp từ biến username của người dùng!
  QString sql = "SELECT id, username FROM app_users WHERE username = '" + username + "'";
  ```
  Nếu kẻ tấn công nhập `username` là `admin' OR '1'='1`, câu lệnh gửi sang PostgreSQL biến thành:
  ```sql
  SELECT id, username FROM app_users WHERE username = 'admin' OR '1'='1';
  ```
  Do `'1'='1'` **luôn đúng**, truy vấn có thể trả về tài khoản đầu tiên trong bảng (thường là `admin`) mà không cần biết tên đăng nhập đúng, hoặc thậm chí bị chèn thêm lệnh phá hoại nếu không kiểm soát chặt.

- **Cách phòng chống chuẩn mực: Prepared Statements (Bind Parameters):**
  Thay vì trộn dữ liệu vào cấu trúc câu lệnh SQL, ứng dụng gửi **bộ khung câu lệnh SQL cố định** kèm các **tham số giữ chỗ** (`:u`, `:p` hoặc `$1`, `$2`). PostgreSQL biên dịch xong cấu trúc câu lệnh trước, rồi mới điền giá trị vào ô dữ liệu thuần túy — nên mọi dấu nháy đơn `'` hay từ khóa `OR` người dùng gõ vào chỉ bị xem là **văn bản bình thường**, không bao giờ biến thành lệnh SQL!

  Xem cách triển khai thực tế ngay trong [`qt-postgres-login-demo/app/src/AuthService.cpp`](qt-postgres-login-demo/app/src/AuthService.cpp):

  ```cpp
  QSqlQuery q(m_db);
  q.prepare(QStringLiteral(
      "SELECT id, username, coalesce(full_name, ''), last_login_at "
      "FROM app_users "
      "WHERE lower(username) = lower(:u) "
      "  AND password_hash = crypt(:p, password_hash)"));
  q.bindValue(QStringLiteral(":u"), username);
  q.bindValue(QStringLiteral(":p"), password);
  q.exec();
  ```

  *(Khi bạn chạy `./run.sh test` trong thư mục `qt-postgres-login-demo/`, bộ kiểm thử tự động có hẳn một kịch bản nhập `admin' OR '1'='1` để chứng minh hệ thống từ chối đăng nhập an toàn.)*

  Trong SQL thuần (`psql`), bạn cũng có thể dùng `PREPARE` / `EXECUTE` để hiểu cơ chế tương tự:
  ```sql
  PREPARE find_user (text) AS
  SELECT id, name FROM users WHERE email = $1;

  EXECUTE find_user('phong@mail.com');
  -- Nếu truyền ' OR '1'='1', PostgreSQL chỉ tìm người dùng có email đúng chuỗi đó -> trả 0 dòng!
  ```

- **Ghi nhớ:** Tuyệt đối không nối biến người dùng nhập vào chuỗi SQL bằng `+`, `format()`, hay f-string; **luôn dùng `prepare()` + `bindValue()`** (hoặc `$1, $2` / `%s` theo đúng Driver của ngôn ngữ bạn dùng).

---

# Phần 7: Vận Hành Dữ Liệu Trong Hệ Thống Thực Tế

## 7.1 Nhập dữ liệu hàng loạt (`COPY` vs `\copy`) và Đồng bộ Sequence

- **Mục tiêu:** Nạp hàng nghìn bản ghi từ tệp CSV an toàn, phân biệt chính xác `COPY` và `\copy`, và tránh lỗi trùng khóa chính sau khi nhập dữ liệu mang theo `id` cũ.

### 1. Bảng chuẩn bị cho kịch bản nhập nhân sự
```sql
CREATE TABLE IF NOT EXISTS departments (
    id   int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS employees (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name     varchar(150) NOT NULL,
    email         varchar(255) NOT NULL UNIQUE,
    phone         varchar(15),
    department_id int REFERENCES departments(id),
    salary        numeric(12, 2) NOT NULL CHECK (salary >= 0),
    deleted_at    timestamptz
);

CREATE TABLE IF NOT EXISTS staging_employees (
    full_name       text,
    email           text,
    phone           text,
    department_name text,
    salary          numeric(12, 2)
);
```

### 2. Phân biệt `COPY` (phía Server) và `\copy` (phía Client `psql`)

| Tiêu chí | `COPY ... FROM '...'` (Câu lệnh SQL) | `\copy ... FROM '...'` (Lệnh meta của `psql`) |
| :--- | :--- | :--- |
| **Ai đọc tệp?** | Tiến trình **PostgreSQL Server** trực tiếp đọc/ghi tệp trên **máy chủ DB**. | Chương trình khách **`psql`** đọc tệp trên **máy người dùng** rồi truyền luồng qua kết nối tới Server. |
| **Quyền hạn yêu cầu** | Cần quyền `SUPERUSER` hoặc `pg_read_server_files` và đường dẫn phải nằm trong máy chủ / container DB. | Chỉ cần tài khoản DB có quyền `INSERT` vào bảng đích; **không cần quyền đặc biệt trên máy chủ**. |
| **Tình huống thực tế** | Tệp đã được đặt sẵn trên server hoặc bên trong volume Docker. | PostgreSQL chạy trong **Docker** hoặc trên **máy chủ từ xa**, còn tệp `nhan_vien.csv` nằm trên laptop của bạn. |

```sql
-- Ví dụ chạy từ terminal máy người dùng qua psql:
\copy staging_employees (full_name, email, phone, department_name, salary) FROM 'nhan_vien.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
```

### 3. Làm sạch qua bảng tạm (`Staging Table`) và Đồng bộ Sequence
1. **Nạp bảng cha trước hoặc ánh xạ qua `Staging Table`:** Đưa dữ liệu thô từ CSV vào `staging_employees`, làm sạch khoảng trắng (`TRIM`), chuẩn hóa chữ thường (`LOWER`), rồi mới ghép sang `departments` để điền vào `employees`:
   ```sql
   INSERT INTO employees (full_name, email, phone, department_id, salary)
   SELECT
       TRIM(s.full_name),
       LOWER(TRIM(s.email)),
       TRIM(s.phone),
       d.id,
       s.salary
   FROM staging_employees s
   JOIN departments d ON d.name = TRIM(s.department_name)
   ON CONFLICT (email) DO NOTHING;
   ```
2. **Đồng bộ bộ đếm tự tăng (`Sequence`) chính xác cả khi bảng rỗng:**
   Khi chuyển dữ liệu có mang theo sẵn `id` cũ (kèm `OVERRIDING SYSTEM VALUE` nếu cột là `GENERATED ALWAYS AS IDENTITY`), bộ đếm tự tăng có thể tụt lại sau `MAX(id)`. Cần gọi `setval()` kèm **tham số thứ 3 (`is_called`)**:

   ```sql
   SELECT setval(
       pg_get_serial_sequence('public.employees', 'id'),
       COALESCE(MAX(id), 1),
       MAX(id) IS NOT NULL
   )
   FROM public.employees;
   ```

   **Tại sao cần tham số thứ 3 `MAX(id) IS NOT NULL`?**
   - Nếu bảng đã có dữ liệu (ví dụ `MAX(id) = 250`), `is_called` là `true` → lần `nextval()` tiếp theo trả về `251` (chuẩn xác).
   - Nếu bảng đang **rỗng** (`MAX(id)` là `NULL`), `COALESCE` đặt về `1` và `is_called` trở thành **`false`** → lần chèn dòng đầu tiên tiếp theo sẽ nhận đúng **`id = 1`** (thay vì nhảy sang `2` nếu bỏ quên tham số thứ 3).

- **Ghi nhớ:** Dùng **`\copy`** khi đẩy tệp CSV từ máy cá nhân vào PostgreSQL chạy trong Docker/Server từ xa, và luôn truyền đủ **3 tham số** cho `setval()`.

---

## 7.2 Xóa mềm, Lưu lịch sử biến động và Nhật ký kiểm toán

- **Mục tiêu:** Bảo toàn lịch sử nghiệp vụ phục vụ đối soát và kiểm toán thay vì xóa cứng làm gãy liên kết hóa đơn cũ.

- **Xóa mềm (`Soft Delete`):** Thay vì chạy `DELETE FROM employees` làm đứt gãy khóa ngoại tới các phiếu lương/hóa đơn lịch sử, đánh dấu bản ghi đã ngừng hoạt động bằng cột `deleted_at timestamptz` (mặc định `NULL`). Để truy vấn nhân sự đang làm việc luôn nhanh, kết hợp thêm **Partial Index** (mục **5.2**):
  ```sql
  CREATE INDEX idx_employees_active ON employees(department_id) WHERE deleted_at IS NULL;
  ```
- **Lưu trữ lịch sử biến động theo thời gian:** Các thuộc tính đổi theo giai đoạn như lương hay chức vụ nên tách bảng lịch sử (`salary_history`) kèm cặp mốc hiệu lực `effective_from` và `effective_to`.
- **Dấu vết kiểm toán (`Audit Trail`):** Các bảng lõi nên có `created_at`, `updated_at`, `updated_by`; với thao tác nhạy cảm (điều chỉnh lương, phân quyền), ghi nhận vào bảng `audit_logs` lưu giá trị trước và sau thay đổi (thường tự động hóa bằng `Trigger` ở **Phụ lục A.2**).

---

## 7.3 Bảo vệ dữ liệu nhạy cảm, Sao lưu và Quản lý phiên bản lược đồ

1. **Kiểm soát dữ liệu cá nhân (PII) và môi trường thử nghiệm:**
   - Tách dữ liệu nhạy cảm (số căn cước, tài khoản ngân hàng) hoặc áp dụng **Bảo mật mức dòng (`Row-Level Security` — RLS)** để người dùng chỉ đọc được đúng dòng thuộc phạm vi của mình, kết hợp mã hóa **SSL/TLS** trên đường truyền mạng.
   - Tuyệt đối không chép nguyên dữ liệu thật (Production) về máy cá nhân; phải ẩn danh hóa (data masking) hoặc dùng dữ liệu giả lập như `database-demo/` trước khi phát triển và kiểm thử.
2. **Sao lưu định kỳ và Diễn tập khôi phục:**
   - Lập lịch sao lưu tự động bằng **`pg_dump`** (sao lưu logic ra tệp SQL/archive) hoặc **`pg_basebackup`** (sao lưu vật lý toàn cụm kết hợp WAL), lưu bản sao ở hạ tầng độc lập và **định kỳ diễn tập khôi phục (`restore test`)** để chắc chắn tệp sao lưu dùng được khi có sự cố thật.
3. **Quản lý thay đổi bảng bằng Migration:**
   - Không chạy `ALTER TABLE` trực tiếp bằng tay trên hệ thống Production. Đóng gói mọi thay đổi cấu trúc thành tệp **Migration** đánh số phiên bản (bằng Flyway, Liquibase, Alembic, Prisma hoặc Sqitch) và quản lý chung trong Git.

---
# Phụ lục A: Kiến Thức PostgreSQL Nâng Cao

## A.1 View và Materialized View

- **Mục tiêu:** Đóng gói các câu truy vấn `JOIN` / tổng hợp phức tạp để tái sử dụng gọn gàng, và hiểu khi nào cần lưu tạm kết quả báo cáo nặng lên đĩa.

| Tiêu chí | `VIEW` (Khung nhìn ảo) | `MATERIALIZED VIEW` (Khung nhìn vật lý hóa) |
| :--- | :--- | :--- |
| **Cách lưu trữ** | Chỉ lưu **câu lệnh SQL**, không lưu dữ liệu. | Lưu **bảng kết quả thực sự** trên đĩa tại thời điểm tạo/làm mới. |
| **Tốc độ đọc** | Chạy lại câu `SELECT` gốc mỗi lần truy vấn. | Đọc cực nhanh như đọc một bảng nhỏ có sẵn (có thể đánh Index thêm). |
| **Độ tươi dữ liệu** | Luôn mới nhất theo thời gian thực. | Chỉ cập nhật khi chạy `REFRESH MATERIALIZED VIEW`. |

```sql
-- 1. VIEW: Đóng gói danh sách đơn hàng đã hoàn tất
CREATE OR REPLACE VIEW v_completed_orders AS
SELECT
    o.id AS order_id,
    COALESCE(u.name, 'Khách vãng lai') AS customer_name,
    o.amount,
    o.created_at
FROM orders o
LEFT JOIN users u ON u.id = o.user_id
WHERE o.status = 'completed';

SELECT * FROM v_completed_orders ORDER BY order_id;

-- 2. MATERIALIZED VIEW: Lưu sẵn báo cáo doanh thu theo danh mục
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_category_revenue AS
SELECT
    c.name AS category_name,
    COALESCE(SUM(CASE WHEN o.status = 'completed' THEN oi.quantity * oi.unit_price ELSE 0 END), 0) AS revenue
FROM categories c
LEFT JOIN products p ON p.category_id = c.id
LEFT JOIN order_items oi ON oi.product_id = p.id
LEFT JOIN orders o ON o.id = oi.order_id
GROUP BY c.name;

SELECT * FROM mv_category_revenue ORDER BY revenue DESC;

-- Khi dữ liệu đơn hàng thay đổi, chủ động làm mới báo cáo:
REFRESH MATERIALIZED VIEW mv_category_revenue;
```

**Kết quả thực tế của `mv_category_revenue` trên `database-demo/`:**

| category_name | revenue |
| :--- | ---: |
| Laptop | 27990000.00 |
| Màn hình | 8500000.00 |
| Phụ kiện | 1050000.00 |
| Âm thanh | 0 |

---

## A.2 Function, Stored Procedure và Trigger

| Đối tượng | Cách gọi | Có trả về giá trị trong `SELECT`? | Quản lý `COMMIT`/`ROLLBACK` bên trong? | Ngữ cảnh dùng phổ biến |
| :--- | :--- | :---: | :---: | :--- |
| **Function** | `SELECT ten_ham(...);` | Có | Không | Tính toán công thức, chuẩn hóa dữ liệu, hàm phục vụ Trigger. |
| **Procedure** | `CALL ten_thu_tuc(...);` | Không (hoặc qua `INOUT`) | Có (từ PostgreSQL 11+) | Xử lý tác vụ nhiều bước định kỳ (nhập kho, kết sổ cuối ngày). |
| **Trigger** | Tự chạy khi `INSERT`/`UPDATE`/`DELETE` | Không gọi trực tiếp | Không | Tự cập nhật `updated_at`, ghi nhật ký `audit_logs`. |

```sql
-- 1. Function tính chiết khấu 5% cho đơn từ 10 triệu trở lên
CREATE OR REPLACE FUNCTION calc_order_discount(p_amount numeric)
RETURNS numeric LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE WHEN p_amount >= 10000000 THEN ROUND(p_amount * 0.05, 0) ELSE 0 END;
$$;

SELECT id, amount, calc_order_discount(amount) AS giam_gia FROM orders ORDER BY id;

-- 2. Stored Procedure nhập thêm hàng vào kho
CREATE OR REPLACE PROCEDURE sp_restock_product(p_product_id bigint, p_qty int)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE products SET stock = stock + p_qty WHERE id = p_product_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Không tìm thấy sản phẩm id = %', p_product_id;
    END IF;
END;
$$;

BEGIN;
CALL sp_restock_product(3, 5);
SELECT id, name, stock FROM products WHERE id = 3; -- Trả về stock = 6 (1 + 5)
ROLLBACK;

-- 3. Trigger tự động cập nhật cột updated_at mỗi khi bản ghi bị sửa
CREATE TEMP TABLE trig_demo (id int PRIMARY KEY, note text, updated_at timestamptz DEFAULT now());
INSERT INTO trig_demo VALUES (1, 'init', '2026-01-01 00:00:00+07');

CREATE OR REPLACE FUNCTION fn_touch_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_touch_updated_at
BEFORE UPDATE ON trig_demo
FOR EACH ROW EXECUTE FUNCTION fn_touch_updated_at();

UPDATE trig_demo SET note = 'edited' WHERE id = 1;
SELECT id, note, updated_at FROM trig_demo;
```

---

## A.3 Quản lý kết nối với Connection Pooling

Trong kiến trúc nội bộ của PostgreSQL, **mỗi kết nối của Client tương ứng với một tiến trình hệ điều hành riêng biệt** (*backend process*). Nếu một ứng dụng web hoặc dịch vụ nền mở cùng lúc hàng nghìn kết nối mới liên tục:
- Bộ nhớ RAM và CPU bị tiêu tốn nặng cho việc tạo/hủy tiến trình và chuyển ngữ cảnh.
- Khi vượt quá ngưỡng `max_connections` (mặc định thường là `100`), kết nối mới bị từ chối với lỗi `FATAL: sorry, too many clients already`.

**Giải pháp Connection Pooling:**
1. **Pool tại tầng ứng dụng:** Giữ sẵn một nhóm nhỏ kết nối mở (ví dụ 10–30 kết nối) để hàng nghìn yêu cầu luân phiên tái sử dụng thay vì mỗi truy vấn lại mở kết nối mới.
2. **Bộ điều phối trung gian chuyên dụng (như `PgBouncer`):** Đứng giữa hàng trăm máy chủ ứng dụng và PostgreSQL, hỗ trợ chế độ **Transaction Pooling** — mượn kết nối thật trong tích tắc của một Transaction rồi trả lại ngay vào hồ chứa.

---

## A.4 Phân vùng bảng lớn (`Partitioning`)

Khi một bảng nhật ký hoặc bảng đơn hàng phình lên **hàng trăm triệu dòng**, ngay cả B-Tree Index cũng trở nên khổng lồ và việc dọn dữ liệu cũ bằng `DELETE` gây phình *Dead Tuples* rất nặng. **Declarative Partitioning** cho phép chia một bảng logic lớn thành nhiều bảng vật lý nhỏ hơn (theo khoảng thời gian, danh sách hoặc băm):

```sql
CREATE TABLE order_events (
    id         bigint GENERATED ALWAYS AS IDENTITY,
    event_date date NOT NULL,
    payload    text NOT NULL,
    PRIMARY KEY (id, event_date) -- Khóa chính trên bảng phân vùng phải chứa cột phân vùng (event_date)
) PARTITION BY RANGE (event_date);

CREATE TABLE order_events_2026_03 PARTITION OF order_events
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');

CREATE TABLE order_events_2026_04 PARTITION OF order_events
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');

INSERT INTO order_events (event_date, payload)
VALUES ('2026-03-15', 'created'), ('2026-04-02', 'shipped');

-- Kiểm tra mỗi dòng được lưu thực sự vào phân vùng nào:
SELECT tableoid::regclass AS phan_vung, id, event_date, payload
FROM order_events
ORDER BY id;
```

**Kết quả thực tế:**

| phan_vung | id | event_date | payload |
| :--- | :---: | :--- | :--- |
| `order_events_2026_03` | 1 | 2026-03-15 | created |
| `order_events_2026_04` | 2 | 2026-04-02 | shipped |

Hai lợi ích lớn nhất: **Partition Pruning** (truy vấn tháng 4 chỉ quét phân vùng tháng 4) và xóa dữ liệu quá hạn tức thì bằng `DROP TABLE order_events_2026_03;` mà không cần `VACUUM`.

---

## A.5 Nhân bản dữ liệu (`Streaming Replication`)

Để hệ thống vẫn hoạt động khi máy chủ chính gặp sự cố phần cứng và giảm tải cho các truy vấn báo cáo nặng, PostgreSQL sử dụng kiến trúc **Primary – Standby (Streaming Replication)**:
- **Máy chủ chính (`Primary`):** Tiếp nhận toàn bộ lệnh ghi (`INSERT`, `UPDATE`, `DELETE`) và đọc mặc định; liên tục truyền luồng bản ghi **`WAL`** (mục **6.1**) qua mạng sang máy dự phòng.
- **Máy chủ dự phòng (`Standby` / `Read Replica`):** Tự động áp dụng luồng `WAL` để giữ bản sao gần như đồng thời gian thực. Có thể dùng để phục vụ các truy vấn **chỉ đọc (`SELECT`)** cho báo cáo/BI, và sẵn sàng chuyển vai trò lên làm `Primary` mới (*failover*) khi máy chính gặp sự cố.

---

# Phụ lục C: Bảng Tra Cứu Thuật Ngữ Database và PostgreSQL

| Thuật ngữ | Giải thích ngắn gọn | Xem chi tiết |
| :--- | :--- | :--- |
| **ACID** | 4 tính chất bảo đảm giao dịch tin cậy: Atomicity (Nguyên tử), Consistency (Nhất quán), Isolation (Cô lập), Durability (Bền vững). | Mục 4.1 |
| **Autovacuum** | Tiến trình nền tự động đánh dấu tái sử dụng chỗ trống của *Dead Tuples* và cập nhật thống kê bảng (`ANALYZE`). | Mục 5.4 |
| **Cluster** | Tập hợp các Database và Role/Tablespace dùng chung được quản lý bởi **một PostgreSQL server instance**. | Mục 2.1 |
| **Composite Key** | Khóa chính được tạo từ hai cột trở lên (ví dụ `(order_id, product_id)`). | Mục 1.4 |
| **Connection Pool** | Cơ chế giữ sẵn và tái sử dụng nhóm kết nối DB thay vì mở/đóng tiến trình mới liên tục. | Phụ lục A.3 |
| **Constraint** | Ràng buộc bảo vệ dữ liệu ngay tại bảng (`NOT NULL`, `CHECK`, `UNIQUE`, `PRIMARY KEY`, `FOREIGN KEY`). | Mục 1.4 |
| **CTE (`WITH`)** | Biểu thức bảng chung đặt tên bước trung gian giúp câu lệnh SQL phức tạp mạch lạc hơn. | Mục 3.6 |
| **Database Client** | Công cụ dành cho con người kết nối tới DB Server để xem dữ liệu và chạy SQL (`psql`, `pgAdmin 4`). | Mục 0.3 |
| **Database Driver** | Thư viện trong mã nguồn ứng dụng giúp phần mềm giao tiếp với DBMS (`QPSQL` trong Qt, `psycopg` trong Python). | Mục 0.2, 0.3 |
| **Dead Tuples** | Các phiên bản dòng cũ hết hiệu lực sau `UPDATE`/`DELETE` do cơ chế MVCC để lại trên đĩa. | Mục 4.2, 5.4 |
| **DDL / DML** | DDL định nghĩa cấu trúc (`CREATE`, `ALTER`, `DROP`); DML thao tác dữ liệu (`INSERT`, `SELECT`, `UPDATE`, `DELETE`). | Mục 3.1, 3.2 |
| **Dirty Read** | Lỗi đọc nhầm dữ liệu chưa `COMMIT` của giao dịch khác (PostgreSQL luôn ngăn chặn). | Mục 4.3 |
| **ERD** | Sơ đồ thực thể liên kết (thường dùng ký hiệu Crow's Foot) để mô tả bảng, cột và quan hệ `1-1`, `1-N`, `N-N`. | Mục 1.6 |
| **EXPLAIN ANALYZE** | Lệnh thực thi thử truy vấn và in ra kế hoạch thực thi thực tế cùng chi phí, số dòng, thời gian chạy. | Mục 5.1 |
| **Foreign Key (FK)** | Khóa ngoại tham chiếu tới khóa chính bảng cha để bảo toàn liên kết giữa các bảng. | Mục 1.4 |
| **Heap** | Vùng lưu trữ các hàng dữ liệu chính của bảng trên đĩa (tách biệt với cấu trúc Index). | Mục 5.1 |
| **Index** | Cấu trúc phụ (B-Tree, GIN...) giống mục lục sách giúp tìm dòng nhanh mà không quét toàn bộ bảng. | Mục 5.1, 5.2 |
| **Isolation Level** | Mức độ cô lập giữa các giao dịch đồng thời (`READ COMMITTED`, `REPEATABLE READ`, `SERIALIZABLE`). | Mục 4.3 |
| **JSONB** | Kiểu lưu dữ liệu JSON dạng nhị phân đã phân tích sẵn bên trong bảng quan hệ PostgreSQL. | Mục 1.2, 3.7 |
| **MVCC** | Cơ chế kiểm soát đa phiên bản giúp đọc và ghi song song không khóa chéo nhau. | Mục 4.2 |
| **Non-repeatable Read** | Trong cùng giao dịch, đọc lại 1 dòng thấy giá trị thay đổi do giao dịch khác đã `COMMIT`. | Mục 4.3 |
| **NULL** | Trạng thái "chưa biết / chưa có giá trị" (khác `0` và `''`; kiểm tra bằng `IS NULL`). | Mục 1.3 |
| **Partitioning** | Chia một bảng rất lớn thành nhiều phân vùng vật lý nhỏ theo thời gian hoặc miền giá trị. | Phụ lục A.4 |
| **Phantom Read** | Trong cùng giao dịch, đếm lại tập dòng theo cùng điều kiện thấy số lượng dòng đổi do có dòng mới được chèn/xóa và `COMMIT`. | Mục 4.3 |
| **Prepared Statement** | Tách khung câu lệnh SQL và tham số dữ liệu (`prepare` + `bindValue`) để chống SQL Injection. | Mục 6.4 |
| **Primary Key (PK)** | Khóa chính định danh duy nhất mỗi bản ghi trong bảng (không trùng, không `NULL`). | Mục 1.4 |
| **Replication** | Đồng bộ luồng WAL từ máy chủ chính (`Primary`) sang máy dự phòng (`Standby`) để chịu lỗi và chia tải đọc. | Phụ lục A.5 |
| **Role** | Đối tượng quản lý nhóm quyền và tài khoản đăng nhập trong PostgreSQL. | Mục 6.2 |
| **Schema** | Không gian tên phân nhóm bảng bên trong một Database (mặc định là `public`). | Mục 2.1 |
| **Sequence** | Bộ đếm sinh số tự tăng (đứng sau kiểu Identity/`serial`), đồng bộ bằng `setval()`. | Mục 7.1 |
| **Serialization Anomaly** | Sai lệch logic khi hai giao dịch chạy song song cho kết quả không thể xảy ra nếu chạy tuần tự. | Mục 4.3 |
| **Snapshot** | Ảnh chụp trạng thái dữ liệu nhất quán mà một câu lệnh hoặc giao dịch được phép nhìn thấy. | Mục 4.2 |
| **SQL Injection** | Lỗ hổng bảo mật khi nối chuỗi nhập từ người dùng trực tiếp vào câu lệnh SQL. | Mục 6.4 |
| **Transaction** | Khối câu lệnh gộp thành một đơn vị bất khả phân (`BEGIN ... COMMIT / ROLLBACK`). | Mục 4.1 |
| **WAL** | Write-Ahead Logging — nhật ký ghi tuần tự trước khi xác nhận `COMMIT` để bảo vệ dữ liệu khi mất điện. | Mục 6.1 |
