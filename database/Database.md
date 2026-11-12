#  Cơ Sở Dữ Liệu & PostgreSQL 16

> Ứng dụng demo thực tế Qt + PostgreSQL 16 + Docker: xem tại thư mục [`qt-postgres-login-demo/`](qt-postgres-login-demo/README.md).

---

## Mục lục

- [**Phần 1: Nhập Môn Cơ Sở Dữ Liệu & Mô Hình Quan Hệ (RDBMS)**](#phần-1-nhập-môn-cơ-sở-dữ-liệu--mô-hình-quan-hệ-rdbms)
  - [1.1 CSDL là gì? Tại sao không dùng Excel / File?](#11-csdl-là-gì-tại-sao-không-dùng-excel--file)
  - [1.2 Phân loại: SQL (RDBMS) vs NoSQL - Khi nào dùng gì?](#12-phân-loại-sql-rdbms-vs-nosql---khi-nào-dùng-gì)
  - [1.3 Các khái niệm cốt lõi: Bảng, Cột, Hàng, Giá trị NULL](#13-các-khái-niệm-cốt-lõi-bảng-cột-hàng-giá-trị-null)
  - [1.4 Các loại Khóa trong CSDL (PK, FK, Unique, Composite Key)](#14-các-loại-khóa-trong-csdl-pk-fk-unique-composite-key)
  - [1.5 Bảng các kiểu dữ liệu quan trọng nhất trong PostgreSQL](#15-bảng-các-kiểu-dữ-liệu-quan-trọng-nhất-trong-postgresql)
  - [1.6 Các mối quan hệ trong CSDL (1-1, 1-N, N-N)](#16-các-mối-quan-hệ-trong-csdl-1-1-1-n-n-n)
  - [1.7 Chuẩn hóa dữ liệu (1NF -> 2NF -> 3NF) & Hiện tượng phản chuẩn hóa](#17-chuẩn-hóa-dữ-liệu-1nf---2nf---3nf--hiện-tượng-phản-chuẩn-hóa)
- [**Phần 2: PostgreSQL 16 & Môi Trường Làm Việc**](#phần-2-postgresql-16--môi-trường-làm-việc)
  - [2.1 Cấu trúc phân cấp logic: Cluster -> Database -> Schema -> Table](#21-cấu-trúc-phân-cấp-logic-cluster---database---schema---table)
  - [2.2 Cài đặt & Khởi chạy PostgreSQL 16 + pgAdmin 4 bằng Docker Compose](#22-cài-đặt--khởi-chạy-postgresql-16--pgadmin-4-bằng-docker-compose)
  - [2.3 Chuỗi kết nối chuẩn (Connection String / URI) & Biến môi trường](#23-chuỗi-kết-nối-chuẩn-connection-string--uri--biến-môi-trường)
  - [2.4 Bảng lệnh tắt psql bỏ túi (CLI Cheat Sheet)](#24-bảng-lệnh-tắt-psql-bỏ-túi-cli-cheat-sheet)
- [**Phần 3: Bảng Tra Cứu Toàn Diện Các Câu Lệnh Truy Vấn SQL**](#phần-3-bảng-tra-cứu-toàn-diện-các-câu-lệnh-truy-vấn-sql)
  - [3.1 Bảng lệnh tạo và sửa cấu trúc (DDL)](#31-bảng-lệnh-tạo-và-sửa-cấu-trúc-ddl)
  - [3.2 Bảng lệnh thao tác dữ liệu cơ bản (DML)](#32-bảng-lệnh-thao-tác-dữ-liệu-cơ-bản-dml)
  - [3.3 Bảng điều kiện lọc & Tìm kiếm (WHERE, LIKE, ILIKE, IN, BETWEEN, IS NULL)](#33-bảng-điều-kiện-lọc--tìm-kiếm-where-like-ilike-in-between-is-null)
  - [3.4 Hàm tổng hợp, Gom nhóm & Vòng đời câu truy vấn (GROUP BY, HAVING)](#34-hàm-tổng-hợp-gom-nhóm--vòng-đời-câu-truy-vấn-group-by-having)
  - [3.5 Các Phép JOIN](#35-các-phép-join)
  - [3.6 Truy vấn Subquery, CTE, UPSERT, Set Operations](#36-truy-vấn-subquery-cte-upsert-set-operations)
  - [3.7 Window Functions & Thao tác JSONB](#37-window-functions--thao-tác-jsonb)
- [**Phần 4: Giao Dịch (Transaction), Kiểm Soát Đồng Thời & MVCC**](#phần-4-giao-dịch-transaction-kiểm-soát-đồng-thời--mvcc)
  - [4.1 Tính chất ACID của Transaction](#41-tính-chất-acid-của-transaction)
  - [4.2 MVCC: Multi-Version Concurrency Control](#42-mvcc-multi-version-concurrency-control)
  - [4.3 Các mức cô lập (Isolation Levels) & Hiện tượng đọc sai](#43-các-mức-cô-lập-isolation-levels--hiện-tượng-đọc-sai)
  - [4.4 Cơ chế Khóa hàng: FOR UPDATE & FOR UPDATE SKIP LOCKED](#44-cơ-chế-khóa-hàng-for-update--for-update-skip-locked)
- [**Phần 5: Tối Ưu Hóa Truy Vấn (Query Optimization)**](#phần-5-tối-ưu-hóa-truy-vấn-query-optimization)
  - [5.1 Bản chất Chỉ mục (Index) & Cơ chế hoạt động (B-Tree vs Sequential Scan)](#51-bản-chất-chỉ-mục-index--cơ-chế-hoạt-động-b-tree-vs-sequential-scan)
  - [5.2 Bảng tra cứu các loại Index trong PostgreSQL](#52-bảng-tra-cứu-các-loại-index-trong-postgresql)
  - [5.4 Bảng so sánh "NÊN LÀM vs NÊN TRÁNH" khi viết SQL](#54-bảng-so-sánh-nên-làm-vs-nên-tránh-khi-viết-sql)
  - [5.5 Dọn rác với VACUUM, Autovacuum & Chống phình dữ liệu (Bloat)](#55-dọn-rác-với-vacuum-autovacuum--chống-phình-dữ-liệu-bloat)
  - [5.6 Tối ưu cấu hình phần cứng & Connection Pooling (PgBouncer)](#56-tối-ưu-cấu-hình-phần-cứng--connection-pooling-pgbouncer)
- [**Phần 6: Kiến Trúc Nội Bộ, Bảo Mật & Vận Hành**](#phần-6-kiến-trúc-nội-bộ-bảo-mật--vận-hành)
  - [6.1 Sơ đồ kiến trúc các tiến trình & Cơ chế WAL (Write-Ahead Logging)](#61-sơ-đồ-kiến-trúc-các-tiến-trình--cơ-chế-wal-write-ahead-logging)
  - [6.2 Phân quyền Role & Bảo mật mật khẩu với pgcrypto (bcrypt)](#62-phân-quyền-role--bảo-mật-mật-khẩu-với-pgcrypto-bcrypt)


---

# Phần 1: Nhập Môn Cơ Sở Dữ Liệu & Mô Hình Quan Hệ (RDBMS)

## 1.1 CSDL là gì? Tại sao không dùng Excel / File?

- **Cơ sở dữ liệu (Database - DB):** Là kho lưu trữ dữ liệu có tổ chức, có cấu trúc, cho phép nhiều ứng dụng và người dùng truy cập, tìm kiếm, cập nhật đồng thời mà vẫn đảm bảo tính chính xác và an toàn tuyệt đối.
- **Hệ quản trị CSDL (Database Management System - DBMS):** Là phần mềm chuyên dụng để quản lý, bảo vệ và vận hành cơ sở dữ liệu đó (ví dụ: PostgreSQL, MySQL, Oracle, SQL Server).

### Sơ đồ kiến trúc 3 tầng chuẩn của ứng dụng hiện đại

```mermaid
flowchart LR
    subgraph Client ["1. Tầng Trình Bày (Client)"]
        UI["Web / Mobile App / Desktop (Qt)"]
    end

    subgraph App ["2. Tầng Nghiệp Vụ (Backend)"]
        API["Backend API / Business Logic"]
    end

    subgraph Data ["3. Tầng Dữ Liệu (Database)"]
        PG[("PostgreSQL 16 (DBMS)")]
    end

    UI <-->|"HTTP / REST / gRPC"| API
    API <-->|"SQL Connection / TCP 5432"| PG
```

### So sánh lưu trữ bằng File (Excel / CSV / JSON) vs Hệ quản trị CSDL (DBMS)

| Tiêu chí | Lưu bằng File (Excel, CSV, JSON) | Dùng DBMS (PostgreSQL) |
| :--- | :--- | :--- |
| **Xử lý đồng thời (Concurrency)** | Khi 2 người cùng sửa 1 file, người lưu sau sẽ ghi đè và làm mất dữ liệu của người trước. | Hàng nghìn kết nối có thể đọc và ghi đồng thời mà không bị xung đột nhờ cơ chế khóa và MVCC. |
| **Tính toàn vẹn (Data Integrity)** | Người dùng có thể nhập chữ vào cột "Tuổi", để trống ô bắt buộc, hoặc nhập trùng lặp mã đơn. | Ràng buộc dữ liệu nghiêm ngặt (`NOT NULL`, `CHECK`, `UNIQUE`, `FOREIGN KEY`) ngăn chặn lỗi từ tầng gốc. |
| **Tốc độ tìm kiếm** | Phải duyệt tuần tự từ dòng đầu đến dòng cuối (rất chậm, tốn RAM khi dữ liệu lớn). | Sử dụng **Chỉ mục (Index - B-Tree)** để tìm kiếm tức thì trong vài mili-giây trên hàng chục triệu dòng. |
| **Phân quyền & Bảo mật** | Hoặc là thấy toàn bộ file, hoặc không thấy gì; không kiểm soát được ai sửa gì. | Phân quyền chi tiết tới từng bảng, từng cột, từng dòng (Row-Level Security) theo từng vai trò (Role). |
| **Khôi phục khi gặp sự cố** | Nếu máy tính mất điện hoặc sập nguồn khi đang lưu file, file rất dễ bị hỏng hoàn toàn. | Nhật ký ghi trước **WAL (Write-Ahead Logging)** đảm bảo 100% dữ liệu đã commit không bao giờ bị mất. |

---

## 1.2 Phân loại: SQL (RDBMS) vs NoSQL - Khi nào dùng gì?

```mermaid
flowchart TD
    Start{"Dữ liệu của bạn có cấu trúc rõ ràng\nvà yêu cầu giao dịch ACID tuyệt đối?"}
    Start -- "Có (Tài chính, Đơn hàng, Người dùng)" --> SQL["Dùng SQL / RDBMS (PostgreSQL)\n- Ràng buộc quan hệ chặt chẽ\n- Transaction ACID an toàn tuyệt đối\n- Hỗ trợ JSONB khi cần dữ liệu động"]
    Start -- "Không (Dữ liệu phi cấu trúc, Logs, Cache)" --> CheckCache{"Cần tốc độ đọc siêu cao\nhoặc mở rộng phân tán cực lớn?"}
    CheckCache -- "Caching / Key-Value" --> Redis["Redis / Memcached"]
    CheckCache -- "Tài liệu JSON biến đổi liên tục" --> Mongo["MongoDB / Document Store"]
```

> **Vị thế đặc biệt của PostgreSQL:** PostgreSQL là một **ORDBMS** (Hệ quản trị CSDL quan hệ - hướng đối tượng). Điểm mạnh vượt trội của PostgreSQL là vừa hỗ trợ đầy đủ chuẩn SQL quan hệ và giao dịch ACID, vừa hỗ trợ kiểu dữ liệu nhị phân `JSONB` với hiệu năng tìm kiếm và đánh index tương đương MongoDB. Vì vậy, PostgreSQL có thể giải quyết tốt hơn nhiều nhu cầu thực tế của dự án mà không cần cài thêm CSDL NoSQL riêng.

---

## 1.3 Các khái niệm cốt lõi: Bảng, Cột, Hàng, Giá trị NULL

Hãy hình dung một bảng dữ liệu quan hệ (`Table`) gồm các cột định nghĩa thuộc tính và các hàng chứa từng bản ghi cụ thể:

```text
BẢNG: users (Tập hợp các bản ghi người dùng)
+----+------------+-------------------+-----+------------+
| id | username   | email             | age | is_active  |  <-- CÁC CỘT (Columns / Thuộc tính / Kiểu dữ liệu)
+----+------------+-------------------+-----+------------+
| 1  | phong      | phong@example.com | 22  | true       |  <-- HÀNG 1 (Row / Record / Bản ghi)
| 2  | phanh      | phanh@test.com    | 20  | true       |  <-- HÀNG 2
| 3  | guest      | NULL              | 0   | false      |  <-- HÀNG 3: Cột email có giá trị NULL
+----+------------+-------------------+-----+------------+
  ^
  |-- id là PRIMARY KEY (Khóa chính: duy nhất, không trùng lặp, không bao giờ nhận NULL)
```

- **Bảng (Table):** Tập hợp các dữ liệu cùng một chủ đề (như người dùng, sản phẩm, đơn hàng).
- **Cột (Column / Attribute):** Một trường thông tin cụ thể, có tên cột và kiểu dữ liệu cố định (ví dụ: `age` kiểu số nguyên, `username` kiểu chuỗi ký tự).
- **Hàng (Row / Record / Tuple):** Một thực thể dữ liệu hoàn chỉnh tương ứng với một đối tượng.
- **Giá trị `NULL`:** Đại diện cho trạng thái **"chưa có thông tin"** hoặc **"không xác định"**, hoàn toàn khác với số `0` hoặc chuỗi rỗng `""`.
  > **Quy tắc sống còn về `NULL`:** Trong chuẩn SQL, `NULL` không bằng bất kỳ thứ gì, kể cả chính nó (`NULL = NULL` trả về `UNKNOWN`, không phải `TRUE`). Do đó, để lọc giá trị `NULL`, bắt buộc phải dùng cú pháp `IS NULL` hoặc `IS NOT NULL`, không được dùng dấu `= NULL`.

---

## 1.4 Các loại Khóa trong CSDL (PK, FK, Unique, Composite Key)

Khóa là công cụ cốt lõi để đảm bảo dữ liệu không bị trùng lặp và liên kết chính xác giữa các bảng:

| Loại khóa | Tên tiếng Anh | Ý nghĩa & Quy tắc | Ví dụ thực tế |
| :--- | :--- | :--- | :--- |
| **Khóa chính** | Primary Key (PK) | Cột định danh duy nhất cho mỗi dòng trong bảng. **Bắt buộc không được trùng lặp và không được phép mang giá trị `NULL`.** | `users.id` (1, 2, 3...) hoặc `UUID` |
| **Khóa ngoại** | Foreign Key (FK) | Cột ở bảng này trỏ trực tiếp đến Khóa chính của bảng khác để ràng buộc mối quan hệ cha - con. | `orders.user_id` tham chiếu tới `users.id` |
| **Khóa duy nhất** | Unique Key | Đảm bảo giá trị trong cột không bị trùng lặp trên toàn bảng, nhưng **cho phép nhận giá trị `NULL`**. | Cột `email`, `so_cmnd`, `so_dien_thoai` |
| **Khóa kết hợp** | Composite Key | Khóa chính được ghép từ hai hoặc nhiều cột lại với nhau để tạo thành một định danh duy nhất. | Bảng chi tiết đơn hàng: cặp `(order_id, product_id)` |

---

## 1.5 Bảng các kiểu dữ liệu quan trọng nhất trong PostgreSQL

Việc chọn đúng kiểu dữ liệu giúp tiết kiệm dung lượng ổ cứng, tăng tốc độ RAM và giúp bộ tối ưu (Query Planner) hoạt động hiệu quả:

| Nhóm dữ liệu | Tên kiểu dữ liệu | Dung lượng | Khi nào nên dùng? (Lưu ý thực tế) |
| :--- | :--- | :--- | :--- |
| **Số nguyên** | `smallint` | 2 bytes | Giá trị nhỏ: -32,768 đến 32,767 (ví dụ: mã trạng thái, thứ trong tuần). |
| | `integer` (`int`) | 4 bytes | Dải số đến ~2.1 tỷ. Thường dùng làm ID cho các bảng vừa và nhỏ. |
| | `bigint` | 8 bytes | Dải số đến 9 tỷ tỷ. **Chuẩn bắt buộc làm PK cho đơn hàng, giao dịch, logs.** |
| **Số thực / Tiền** | `numeric(p, s)` | Linh hoạt | **Bắt buộc dùng cho tiền tệ, tài chính**. Tính toán chính xác 100%, không bị sai số làm tròn như `float`. |
| | `real` / `double` | 4 - 8 bytes | Số thực dấu phẩy động. Chỉ dùng cho tọa độ địa lý, khoa học kỹ thuật chấp nhận sai số nhỏ. |
| **Chuỗi ký tự** | `varchar(n)` | Linh hoạt | Chuỗi có giới hạn độ dài tối đa (ví dụ: mã bưu điện, mã vạch). |
| | `text` | Linh hoạt | Chuỗi độ dài bất kỳ. Trong PostgreSQL, `text` và `varchar` có hiệu năng tương đương, nên ưu tiên dùng `text` khi không cần giới hạn cứng. |
| **Ngày & Giờ** | `timestamptz` | 8 bytes | **Timestamp with time zone - Chuẩn quốc tế bắt buộc dùng**. Tự động chuẩn hóa về UTC khi lưu, hiển thị theo timezone client. |
| | `date` | 4 bytes | Chỉ lưu ngày tháng năm (`YYYY-MM-DD`), ví dụ: ngày sinh, ngày lễ. |
| **Logic** | `boolean` | 1 byte | Chỉ nhận `true`, `false`, hoặc `null`. |
| **Định danh UUID** | `uuid` | 16 bytes | Định danh ngẫu nhiên toàn cầu (dùng `gen_random_uuid()`). Rất tốt khi làm hệ thống phân tán, tránh lộ ID tự tăng. |
| **Bán cấu trúc** | `jsonb` | Linh hoạt | Dữ liệu JSON dạng nhị phân đã phân tích cú pháp. Hỗ trợ index GIN, truy vấn siêu nhanh. |

---

## 1.6 Các mối quan hệ trong CSDL (1-1, 1-N, N-N)

```mermaid
erDiagram
    USERS ||--o{ ORDERS : "1 người có THỂ ĐẶT nhiều (1-N) đơn hàng"
    ORDERS ||--|{ ORDER_ITEMS : "1 đơn CHỨA một hoặc nhiều (1-N) chi tiết"
    PRODUCTS ||--o{ ORDER_ITEMS : "1 sản phẩm XUẤT HIỆN trong nhiều chi tiết"
    USERS ||--|| USER_PROFILES : "1 người SỞ HỮU duy nhất (1-1) hồ sơ"
```

1. **Quan hệ 1 - 1 (Một - Một):**
   - *Bản chất:* Mỗi bản ghi bảng A chỉ liên kết với duy nhất 1 bản ghi bảng B.
   - *Ví dụ:* 1 Người dùng (`users`) chỉ có 1 Hồ sơ cá nhân (`user_profiles`).
   - *Cách thiết kế:* Đặt cột `user_id` ở bảng `user_profiles` vừa làm Khóa ngoại (FK), vừa gắn ràng buộc `UNIQUE`.
2. **Quan hệ 1 - N (Một - Nhiều):**
   - *Bản chất:* 1 bản ghi bảng A liên kết với nhiều bản ghi bảng B, nhưng mỗi bản ghi bảng B chỉ thuộc về đúng 1 bản ghi bảng A.
   - *Ví dụ:* 1 Khách hàng (`users`) có thể tạo ra nhiều Đơn hàng (`orders`).
   - *Cách thiết kế:* Đặt cột Khóa ngoại `user_id` nằm ở bảng phía "Nhiều" (bảng `orders`).
3. **Quan hệ N - N (Nhiều - Nhiều):**
   - *Bản chất:* 1 bản ghi bảng A liên kết với nhiều bản ghi bảng B, và ngược lại.
   - *Ví dụ:* 1 Đơn hàng (`orders`) có nhiều Sản phẩm (`products`), và 1 Sản phẩm nằm trong nhiều Đơn hàng khác nhau.
   - *Cách thiết kế:* **Bắt buộc tạo một Bảng trung gian (Bảng nối - Junction Table)** tên là `order_items`. Bảng này chứa ít nhất 2 khóa ngoại: `order_id` và `product_id`.

---

## 1.7 Chuẩn hóa dữ liệu (1NF -> 2NF -> 3NF) & Hiện tượng phản chuẩn hóa

Mục đích của chuẩn hóa: **Loại bỏ dữ liệu dư thừa** và ngăn chặn các dị thường khi thêm, sửa, xóa (Anomaly).

```mermaid
flowchart TD
    Raw["Dữ liệu thô ban đầu\n(Ô gộp nhiều giá trị, dữ liệu lặp lại)"] -->|"Tách dữ liệu nguyên tử\n(1 ô = đúng 1 giá trị đơn)"| NF1["Chuẩn 1 (1NF)"]
    NF1 -->|"Tách bảng để mọi cột\nphụ thuộc toàn phần vào Khóa chính"| NF2["Chuẩn 2 (2NF)"]
    NF2 -->|"Loại bỏ phụ thuộc bắc cầu\n(Cột A -> Cột B -> Cột C)"| NF3["Chuẩn 3 (3NF) - Chuẩn thiết kế tối ưu"]
```

### Ví dụ từng bước:

#### Bước 1: Chuẩn 1 (1NF) - "Mỗi ô chỉ chứa một giá trị nguyên tử (Atomic)"
- **Vi phạm 1NF:** Cột `dien_thoai` lưu chuỗi `'0912345678, 0987654321'`. Khi cần tìm người có số `'0987654321'`, máy tính phải quét chuỗi rất chậm và không thể lập index.
- **Đạt 1NF:** Mỗi ô chỉ lưu đúng 1 số điện thoại; nếu có nhiều số thì tách thành nhiều dòng hoặc chuyển sang bảng phụ `user_phones`.

#### Bước 2: Chuẩn 2 (2NF) - "Mọi cột phải phụ thuộc vào TOÀN BỘ Khóa chính (Không phụ thuộc một phần)"
- **Vi phạm 2NF:** Bảng `chi_tiet_don(ma_don, ma_sp, ten_sp, so_luong)`. Khóa chính gồm cặp `(ma_don, ma_sp)`. Nhưng `ten_sp` chỉ cần biết `ma_sp` là xác định được, không cần tới `ma_don`. Khi sửa tên một sản phẩm, hệ thống phải cập nhật hàng triệu dòng đơn hàng cũ!
- **Đạt 2NF:** Tách riêng bảng `san_pham(ma_sp, ten_sp)`. Bảng `chi_tiet_don` chỉ còn lại `(ma_don, ma_sp, so_luong)`.

#### Bước 3: Chuẩn 3 (3NF) - "Không phụ thuộc bắc cầu (A xác định B, B lại xác định C)"
- **Vi phạm 3NF:** Bảng `nhan_vien(ma_nv, ten_nv, ma_phong, ten_phong)`. Ta có: `ma_nv -> ma_phong` và `ma_phong -> ten_phong`. Khi đổi tên phòng ban, ta phải cập nhật trên tất cả nhân viên thuộc phòng đó.
- **Đạt 3NF:** Tách riêng bảng `phong_ban(ma_phong, ten_phong)`. Bảng `nhan_vien` chỉ lưu Khóa ngoại `ma_phong`.

> **Khi nào nên Phản chuẩn hóa (Denormalization)?**
> Trong các hệ thống báo cáo (Data Warehouse / OLAP) hoặc hệ thống thương mại điện tử đọc cực lớn: Việc tuân thủ 100% 3NF bắt buộc câu truy vấn phải `JOIN` qua 7-10 bảng, làm giảm tốc độ đọc. Lúc này, người ta chủ động chấp nhận lưu dư thừa (ví dụ: lưu sẵn `tong_tien` ở bảng `orders`, hoặc lưu `ten_san_pham_luc_mua` để làm lịch sử) nhằm đạt tốc độ đọc cao nhất.

---

# Phần 2: PostgreSQL 16 & Môi Trường Làm Việc

## 2.1 Cấu trúc phân cấp logic: Cluster -> Database -> Schema -> Table

Trước khi bắt đầu cài đặt, cần nắm vững cấu trúc tổ chức 4 tầng bên trong PostgreSQL:

```mermaid
graph TD
    Cluster["PostgreSQL Instance / Cluster (Chạy trên cổng TCP 5432)"]
    Cluster --> DB1["Database: appdb (Ứng dụng chính)"]
    Cluster --> DB2["Database: analytics_db (Phân tích dữ liệu)"]
    
    DB1 --> S1["Schema: public (Mặc định khi tạo bảng)"]
    DB1 --> S2["Schema: sales (Nghiệp vụ bán hàng)"]
    DB1 --> S3["Schema: inventory (Quản lý kho)"]
    
    S1 --> T1["Table: users"]
    S2 --> T2["Table: orders"]
    S2 --> T3["Table: order_items"]
    S3 --> T4["Table: products"]
```

- **Cluster:** Một tiến trình máy chủ PostgreSQL quản lý tập hợp các Database trên cùng một thư mục dữ liệu (`PGDATA`).
- **Database:** Không gian lưu trữ độc lập hoàn toàn. Một phiên kết nối thông thường không thể chạy lệnh `JOIN` trực tiếp giữa hai Database khác nhau.
- **Schema:** Tương tự như các "thư mục phân loại" nằm bên trong một Database. Giúp gom nhóm các bảng theo nghiệp vụ (`sales.orders`, `inventory.products`) và phân quyền độc lập. Mặc định PostgreSQL dùng schema có tên `public`.
- **Table / View / Function:** Các đối tượng dữ liệu cụ thể nằm trong từng schema.

---

## 2.2 Cài đặt & Khởi chạy PostgreSQL 16 + pgAdmin 4 bằng Docker Compose

Tạo file `docker-compose.yml`:

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

### Các lệnh điều khiển hệ thống Docker:

```bash
# 1. Khởi động PostgreSQL và pgAdmin chạy ngầm:
docker compose up -d

# 2. Xem logs thời gian thực của PostgreSQL:
docker compose logs -f postgres

# 3. Mở giao diện Web quản trị pgAdmin 4:
# Mở trình duyệt truy cập: http://localhost:5050
# Đăng nhập bằng Email: admin@example.com / Mật khẩu: SecretPassword123!
# Khi tạo New Server trong pgAdmin:
# - Tab 'General' -> Name: Postgres-Local
# - Tab 'Connection' -> Host name/address: postgres (tên service trong docker-compose)
#                      Port: 5432 | Username: admin | Password: SecretPassword123!

# 4. Dừng container (dữ liệu vẫn an toàn tuyệt đối trong volume pgdata):
docker compose down
```

---

## 2.3 Chuỗi kết nối chuẩn (Connection String / URI) & Biến môi trường

Khi kết nối từ Backend (Node.js, Python, Go, Java, C++/Qt), cấu trúc chuỗi kết nối URI chuẩn có dạng:

```text
postgresql://[username]:[password]@[host]:[port]/[database_name]?sslmode=[disable|prefer|require]
```

*Ví dụ thực tế:*
```text
postgresql://admin:SecretPassword123!@127.0.0.1:5432/appdb?sslmode=disable
```

### Các biến môi trường chuẩn của PostgreSQL (`libpq`):

Hầu hết các thư viện lập trình đều tự động nhận các biến môi trường này nếu không truyền trực tiếp chuỗi kết nối:
- `PGHOST=127.0.0.1`
- `PGPORT=5432`
- `PGDATABASE=appdb`
- `PGUSER=admin`
- `PGPASSWORD=SecretPassword123!`

---

## 2.4 Bảng lệnh tắt psql bỏ túi (CLI Cheat Sheet)

Truy cập dòng lệnh `psql` bên trong container:
```bash
docker exec -it postgres_pg16 psql -U admin -d appdb
```

| Lệnh tắt | Ý nghĩa & Tác dụng | Ví dụ mẫu |
| :--- | :--- | :--- |
| `\l` | Liệt kê tất cả các Database có trên cluster | `\l` |
| `\c <tên_db>` | Chuyển (kết nối) sang database khác | `\c appdb` |
| `\dt` | Xem danh sách các bảng trong schema hiện tại | `\dt` |
| `\dt+` | Xem danh sách bảng kèm kích thước lưu trữ trên đĩa | `\dt+` |
| `\d <tên_bảng>` | Xem chi tiết cấu trúc cột, kiểu dữ liệu, ràng buộc, index của bảng | `\d users` |
| `\dn` | Liệt kê danh sách các schema | `\dn` |
| `\du` | Liệt kê danh sách người dùng và vai trò phân quyền (roles) | `\du` |
| `\x` | Bật/tắt hiển thị kết quả theo chiều dọc (cực kỳ hữu ích khi bảng có nhiều cột) | `\x` |
| `\timing` | Bật/tắt hiển thị thời gian chạy chính xác của từng câu truy vấn (ms) | `\timing` |
| `\i <file.sql>` | Đọc và thực thi toàn bộ câu lệnh trong một file script SQL | `\i /db/init.sql` |
| `\q` | Thoát khỏi môi trường dòng lệnh psql | `\q` |

---

# Phần 3: Bảng Tra Cứu Toàn Diện Các Câu Lệnh Truy Vấn SQL

Lược đồ mẫu dùng xuyên suốt cho các ví dụ trong phần này:
- Bảng `categories`: Danh mục sản phẩm (`id`, `name`)
- Bảng `products`: Sản phẩm (`id`, `name`, `price`, `stock`, `category_id`)
- Bảng `users`: Khách hàng (`id`, `name`, `email`, `is_active`)
- Bảng `orders`: Đơn hàng (`id`, `user_id`, `amount`, `status`, `created_at`)

---

## 3.1 Bảng lệnh tạo và sửa cấu trúc (DDL)

| Thao tác | Cú pháp mẫu | Mục đích & Lưu ý thực tế |
| :--- | :--- | :--- |
| **Tạo Database** | `CREATE DATABASE shop_db;` | Khởi tạo cơ sở dữ liệu độc lập mới. |
| **Tạo Bảng chuẩn** | Xem mã nguồn chi tiết bên dưới | Dùng `GENERATED ALWAYS AS IDENTITY` thay thế `SERIAL` cũ. Cột tiền tệ bắt buộc dùng `numeric`. |
| **Thêm cột mới** | `ALTER TABLE products ADD COLUMN stock int DEFAULT 0;` | Thêm cột an toàn; giá trị mặc định cho dữ liệu cũ là 0. |
| **Đổi tên cột** | `ALTER TABLE products RENAME COLUMN stock TO quantity;` | Đổi tên cột mà không làm mất dữ liệu bên trong. |
| **Thêm ràng buộc** | `ALTER TABLE products ADD CONSTRAINT chk_price CHECK (price >= 0);` | Ngăn chặn lỗi từ tầng ứng dụng ghi giá trị tiền âm vào DB. |
| **Xóa bảng an toàn** | `DROP TABLE IF EXISTS products CASCADE;` | Có `IF EXISTS` để không báo lỗi nếu bảng chưa có; `CASCADE` để xóa ràng buộc phụ thuộc. |

### Cú pháp tạo bảng chuẩn sản xuất (Production-Ready Schema):

```sql
-- 1. Bảng danh mục
CREATE TABLE categories (
    id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(100) NOT NULL UNIQUE
);

-- 2. Bảng sản phẩm có khóa ngoại và ràng buộc kiểm tra
CREATE TABLE products (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(255) NOT NULL,
    price numeric(12, 2) NOT NULL CHECK (price >= 0),
    stock int NOT NULL DEFAULT 0 CHECK (stock >= 0),
    category_id int REFERENCES categories(id) ON DELETE SET NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);
```

---

## 3.2 Bảng lệnh thao tác dữ liệu cơ bản (DML)

| Thao tác | Cú pháp chuẩn | Lưu ý quan trọng & Mẹo thực chiến |
| :--- | :--- | :--- |
| **INSERT (Thêm)** | `INSERT INTO products (name, price, stock) VALUES ('Chuột không dây', 350000, 50) RETURNING id;` | **Mẹo PG:** Dùng `RETURNING id` để lấy ngay ID vừa tạo mà không cần chạy thêm câu lệnh `SELECT`. |
| **INSERT nhiều dòng (Batch)** | `INSERT INTO categories (name) VALUES ('Laptop'), ('Bàn phím'), ('Màn hình');` | Thêm hàng loạt bản ghi trong một câu lệnh, nhanh gấp 10-50 lần chạy từng câu `INSERT` đơn lẻ. |
| **SELECT (Đọc)** | `SELECT id, name, price FROM products ORDER BY price DESC LIMIT 10 OFFSET 0;` | Luôn liệt kê rõ tên cột cần lấy. **Tuyệt đối tránh dùng `SELECT *` trong ứng dụng sản xuất.** |
| **UPDATE (Sửa)** | `UPDATE products SET price = price * 0.9, stock = stock - 1 WHERE id = 1 RETURNING id, price;` | **Cực kỳ quan trọng:** Luôn phải có mệnh đề `WHERE`, nếu không sẽ cập nhật toàn bộ bảng! |
| **DELETE (Xóa)** | `DELETE FROM products WHERE stock = 0 RETURNING id, name;` | Xóa các dòng thỏa mãn điều kiện và trả về danh sách các bản ghi vừa bị xóa. |
| **TRUNCATE (Xóa sạch)** | `TRUNCATE TABLE logs RESTART IDENTITY;` | Xóa toàn bộ dữ liệu bảng ngay lập tức, reset ID về 1. Nhanh hơn `DELETE` hàng trăm lần vì không sinh log từng dòng. |

---

## 3.3 Bảng điều kiện lọc & Tìm kiếm (WHERE, LIKE, ILIKE, IN, BETWEEN, IS NULL)

| Điều kiện lọc | Cú pháp ví dụ | Ý nghĩa & Cách ứng dụng |
| :--- | :--- | :--- |
| **So sánh bằng / khác** | `WHERE is_active = true`<br>`WHERE status <> 'cancelled'` | So sánh bằng `=`; khác dùng `<>` hoặc `!=`. |
| **Khoảng giá trị (BETWEEN)** | `WHERE price BETWEEN 100000 AND 500000` | Lọc trong khoảng `[100000, 500000]` (bao gồm cả 2 giá trị đầu mút). |
| **Tập hợp giá trị (IN)** | `WHERE category_id IN (1, 3, 5)` | Khớp nếu giá trị nằm trong danh sách chỉ định. |
| **Khớp chuỗi (LIKE / ILIKE)** | `WHERE email LIKE '%@gmail.com'`<br>`WHERE name ILIKE 'macbook%'` | - `LIKE`: Có phân biệt chữ HOA / chữ thường.<br>- `ILIKE`: **Không phân biệt HOA / thường** (đặc trưng rất hay của PostgreSQL).<br>- `%`: Chuỗi ký tự bất kỳ; `_`: Đúng 1 ký tự đơn. |
| **Kiểm tra NULL** | `WHERE email IS NULL`<br>`WHERE email IS NOT NULL` | **Sai:** `WHERE email = NULL` (luôn trả về rỗng).<br>**Đúng:** Luôn luôn dùng `IS NULL` hoặc `IS NOT NULL`. |
| **Hàm COALESCE** | `SELECT name, COALESCE(phone, 'Chưa có SĐT') FROM users;` | Trả về giá trị đầu tiên khác `NULL` trong danh sách đối số. Thường dùng đặt giá trị mặc định. |

---

## 3.4 Hàm tổng hợp, Gom nhóm & Vòng đời câu truy vấn (GROUP BY, HAVING)

### Sơ đồ thứ tự thực thi logic của câu truy vấn SQL

Một trong những sai lầm phổ biến nhất của người mới học là nghĩ rằng máy tính thực thi câu lệnh SQL từ trên xuống dưới (từ `SELECT` đến `LIMIT`). Thực tế, PostgreSQL thực thi theo thứ tự logic sau:

```mermaid
flowchart TD
    S1["1. FROM & JOIN (Xác định nguồn bảng)"] --> S2["2. WHERE (Lọc các dòng đơn lẻ)"]
    S2 --> S3["3. GROUP BY (Gom nhóm các dòng)"]
    S3 --> S4["4. HAVING (Lọc trên từng nhóm đã gom)"]
    S4 --> S5["5. SELECT (Chiết xuất cột & tính toán hàm)"]
    S5 --> S6["6. DISTINCT (Khử trùng lặp)"]
    S6 --> S7["7. ORDER BY (Sắp xếp kết quả)"]
    S7 --> S8["8. LIMIT / OFFSET (Cắt số dòng trả về)"]
```

> **Hệ quả logic:**
> 1. Bạn **không thể** dùng bí danh (Alias) vừa đặt trong mệnh đề `SELECT` để lọc ở mệnh đề `WHERE`, vì `WHERE` chạy trước `SELECT`.
> 2. Mệnh đề `WHERE` dùng để lọc từng dòng dữ liệu **trước khi gom nhóm**.
> 3. Mệnh đề `HAVING` dùng để lọc các nhóm **sau khi đã gom nhóm**.

### Bảng hàm tổng hợp thường dùng:

| Hàm tổng hợp | Cú pháp ví dụ | Mô tả & Lưu ý |
| :--- | :--- | :--- |
| `COUNT(*)` | `SELECT count(*) FROM users WHERE is_active = true;` | Đếm tổng số dòng thỏa mãn điều kiện. |
| `COUNT(cột)` | `SELECT count(email) FROM users;` | Chỉ đếm các dòng có cột `email` mang giá trị khác `NULL`. |
| `SUM` / `AVG` | `SELECT sum(price), round(avg(price), 2) FROM products;` | Tính tổng giá trị và trung bình cộng. Tự động bỏ qua các dòng `NULL`. |
| `MIN` / `MAX` | `SELECT min(price), max(price) FROM products;` | Tìm giá trị nhỏ nhất và lớn nhất trong cột. |

### Ví dụ kết hợp GROUP BY và HAVING:

```sql
-- Thống kê danh mục có từ 3 sản phẩm trở lên, tính giá trung bình:
SELECT 
    category_id,
    count(*) AS so_luong_sp,
    round(avg(price), 0) AS gia_trung_binh
FROM products
WHERE price > 50000                     -- BƯỚC 1: Lọc bỏ sản phẩm giá quá rẻ
GROUP BY category_id                    -- BƯỚC 2: Gom nhóm theo từng danh mục
HAVING count(*) >= 3                    -- BƯỚC 3: Chỉ giữ lại danh mục có từ 3 sản phẩm
ORDER BY gia_trung_binh DESC;           -- BƯỚC 4: Sắp xếp danh mục theo giá giảm dần
```

---

## 3.5 Các Phép JOIN

Phép `JOIN` dùng để ghép các cột từ hai hay nhiều bảng lại với nhau dựa trên mối liên kết logic giữa các cột chung (thường là Khóa chính trỏ tới Khóa ngoại).

### Dữ liệu mẫu minh họa:

Ta có 2 bảng dữ liệu đơn giản:
- **Bảng `users` (Khách hàng):** Gồm 3 người (Phong, Linh, Tuấn).
- **Bảng `orders` (Đơn hàng):** Gồm 4 đơn (101, 102, 103, 104). Đơn 104 có `user_id = 99` không tồn tại trong bảng `users`.

```text
       BẢNG A (users)                             BẢNG B (orders)
+----+-------+-------------------+        +-----+---------+--------+
| id | name  | email             |        | id  | user_id | amount |
+----+-------+-------------------+        +-----+---------+--------+
| 1  | Phong | phong@example.com |        | 101 | 1       | 500    |
| 2  | Linh  | linh@example.com  |        | 102 | 1       | 200    |
| 3  | Tuấn  | tuan@example.com  |        | 103 | 2       | 300    |
+----+-------+-------------------+        | 104 | 99      | 150    |
                                          +-----+---------+--------+
```

---

### Bảng so sánh tổng hợp các phép JOIN (Cheat Sheet)

| Loại JOIN | Bản chất & Biểu đồ Venn | Cú pháp tóm tắt | Ý nghĩa kết quả trả về | Trường hợp ứng dụng |
| :--- | :--- | :--- | :--- | :--- |
| **INNER JOIN** | `A ∩ B` (Phần giao)<br>Chỉ lấy dòng có mặt ở cả 2 bảng | `FROM users u`<br>`INNER JOIN orders o`<br>`ON u.id = o.user_id` | Chỉ lấy khách hàng **đã từng mua hàng** và đơn hàng **có khách xác định**. | Lập danh sách đơn hàng hợp lệ cần đóng gói và giao hàng. |
| **LEFT JOIN** | `A` trọn vẹn + `(A ∩ B)`<br>Giữ hết bảng trái, bên phải thiếu điền `NULL` | `FROM users u`<br>`LEFT JOIN orders o`<br>`ON u.id = o.user_id` | Giữ **tất cả khách hàng**, ai chưa mua thì thông tin đơn hàng điền `NULL`. | Thống kê danh sách toàn bộ khách hàng kèm doanh số (nếu có). |
| **ANTI-JOIN** | `A - B` (Chỉ riêng A)<br>Dùng LEFT JOIN + lọc `WHERE B.id IS NULL` | `FROM users u`<br>`LEFT JOIN orders o`<br>`ON u.id = o.user_id`<br>`WHERE o.id IS NULL` | Chỉ lấy những khách hàng **chưa từng mua bất kỳ đơn hàng nào**. | Gửi email khuyến mãi kích cầu cho người dùng đăng ký mà chưa mua. |
| **RIGHT JOIN** | `(A ∩ B)` + `B` trọn vẹn<br>Giữ hết bảng phải, bên trái thiếu điền `NULL` | `FROM users u`<br>`RIGHT JOIN orders o`<br>`ON u.id = o.user_id` | Giữ **tất cả đơn hàng**, đơn nào không gắn với user thì tên khách là `NULL`. | Kiểm tra các đơn hàng vãng lai hoặc đơn hàng mồ côi lỗi dữ liệu. |
| **FULL OUTER JOIN** | `A ∪ B` (Toàn bộ A và B)<br>Không bỏ sót bất kỳ dòng nào của cả 2 bên | `FROM users u`<br>`FULL OUTER JOIN orders o`<br>`ON u.id = o.user_id` | Lấy tất cả khách hàng và tất cả đơn hàng, thiếu bên nào điền `NULL` bên đó. | Đối soát dữ liệu toàn diện giữa hai hệ thống độc lập. |
| **CROSS JOIN** | `A × B` (Tích Descartes)<br>Ghép mỗi dòng của A với mọi dòng của B | `FROM sizes`<br>`CROSS JOIN colors` | Số dòng kết quả = `(số dòng A) × (số dòng B)`. Không cần điều kiện `ON`. | Tự động sinh danh mục biến thể sản phẩm (Size S/M/L ghép Màu Đỏ/Xanh). |
| **SELF JOIN** | Bảng tự kết nối với chính nó<br>Dùng bí danh (Alias) để phân biệt | `FROM employees e`<br>`LEFT JOIN employees m`<br>`ON e.manager_id = m.id` | Ghép từng nhân viên với người quản lý trực tiếp của họ trên cùng 1 bảng. | Quản lý cây phân cấp nhân sự, danh mục cha - con đa cấp. |

---

### Phân tích trực quan chi tiết từng phép JOIN

#### 1. INNER JOIN (Chỉ lấy phần giao nhau giữa 2 bảng)

- **Sơ đồ ghép dòng:**
  ```text
  users (u)               Điều kiện: u.id = o.user_id              orders (o)
  +---+-------+                                                   +-----+---------+--------+
  | 1 | Phong | -------- Khớp với 2 đơn: 101, 102 --------->      | 101 | 1       | 500    |
  |   |       |                                                   | 102 | 1       | 200    |
  | 2 | Linh  | -------- Khớp với 1 đơn: 103 -------------->      | 103 | 2       | 300    |
  | 3 | Tuấn  | -------- (Chưa mua đơn nào) ------------------->  [ BỊ LOẠI KHỎI KẾT QUẢ]
  |   |       | <------- [ BỊ LOẠI KHỎI KẾT QUẢ] -------------    | 104 | 99      | 150    |
  +---+-------+                                                   +-----+---------+--------+
  ```

- **Câu lệnh truy vấn:**
  ```sql
  SELECT 
      u.name, 
      o.id AS order_id, 
      o.amount
  FROM users u
  INNER JOIN orders o ON u.id = o.user_id;
  ```

- **Bảng kết quả thực tế:**

  | name | order_id | amount |
  | :--- | :---: | :---: |
  | Phong | 101 | 500 |
  | Phong | 102 | 200 |
  | Linh | 103 | 300 |

- **Giải thích:**
  - `Tuấn` bị loại vì không có bản ghi nào khớp trong bảng `orders`.
  - Đơn `104` bị loại vì `user_id = 99` không tồn tại trong bảng `users`.
  - `Phong` mua 2 đơn nên xuất hiện 2 dòng trong kết quả.

---

#### 2. LEFT JOIN (Giữ trọn vẹn bảng bên trái)

- **Sơ đồ ghép dòng:**
  ```text
  users (u - Trái)        Điều kiện: u.id = o.user_id              orders (o - Phải)
  +---+-------+                                                   +-----+---------+--------+
  | 1 | Phong | -------- Khớp 101, 102 -------------------->      | 101 | 1       | 500    |
  |   |       |                                                   | 102 | 1       | 200    |
  | 2 | Linh  | -------- Khớp 103 ------------------------->      | 103 | 2       | 300    |
  | 3 | Tuấn  | -------- Không có đơn -> Điền NULL -------->      | NULL| NULL    | NULL   |
  +---+-------+                                                   +-----+---------+--------+
  ```

- **Câu lệnh truy vấn:**
  ```sql
  SELECT 
      u.name, 
      o.id AS order_id, 
      o.amount
  FROM users u
  LEFT JOIN orders o ON u.id = o.user_id;
  ```

- **Bảng kết quả thực tế:**

  | name | order_id | amount |
  | :--- | :---: | :---: |
  | Phong | 101 | 500 |
  | Phong | 102 | 200 |
  | Linh | 103 | 300 |
  | Tuấn | *NULL* | *NULL* |

- **Giải thích:**
  - Mọi người dùng ở bảng bên trái (`users`) đều được giữ lại 100%.
  - `Tuấn` chưa mua hàng nên các cột lấy từ bảng `orders` nhận giá trị `NULL`.

---

#### 3. ANTI-JOIN (Tìm phần tử chỉ có ở bảng trái mà KHÔNG có ở bảng phải)

- **Bản chất:** Sử dụng `LEFT JOIN` kết hợp điều kiện `WHERE o.id IS NULL`. Đây là kỹ thuật kinh điển để tìm các bản ghi mồ côi hoặc đối tượng chưa từng phát sinh hành động.

- **Câu lệnh truy vấn:**
  ```sql
  SELECT 
      u.id, 
      u.name, 
      u.email
  FROM users u
  LEFT JOIN orders o ON u.id = o.user_id
  WHERE o.id IS NULL;
  ```

- **Bảng kết quả thực tế:**

  | id | name | email |
  | :---: | :--- | :--- |
  | 3 | Tuấn | tuan@example.com |

- **Ứng dụng thực tế:**
  - Tìm khách hàng đăng ký tài khoản nhưng chưa từng mua hàng.
  - Tìm sản phẩm tồn kho chưa từng bán được cái nào.
  - Tìm bài viết không có bất kỳ lượt bình luận nào.

---

#### 4. RIGHT JOIN (Giữ trọn vẹn bảng bên phải)

- **Câu lệnh truy vấn:**
  ```sql
  SELECT 
      u.name, 
      o.id AS order_id, 
      o.amount
  FROM users u
  RIGHT JOIN orders o ON u.id = o.user_id;
  ```

- **Bảng kết quả thực tế:**

  | name | order_id | amount |
  | :--- | :---: | :---: |
  | Phong | 101 | 500 |
  | Phong | 102 | 200 |
  | Linh | 103 | 300 |
  | *NULL* | 104 | 150 |

- **Giải thích:**
  - Giữ lại toàn bộ các đơn hàng ở bảng bên phải (`orders`).
  - Đơn `104` có `user_id = 99` không có trong bảng `users`, nên cột `name` hiển thị giá trị `NULL`.
  > **Kinh nghiệm thực tế:** Trong các dự án phần mềm, lập trình viên thường dùng `LEFT JOIN` và đảo thứ tự bảng thay vì dùng `RIGHT JOIN` để câu lệnh dễ đọc theo chiều tự nhiên từ trái sang phải.

---

#### 5. FULL OUTER JOIN (Lấy tất cả của cả hai bên)

- **Câu lệnh truy vấn:**
  ```sql
  SELECT 
      u.name, 
      o.id AS order_id, 
      o.amount
  FROM users u
  FULL OUTER JOIN orders o ON u.id = o.user_id;
  ```

- **Bảng kết quả thực tế:**

  | name | order_id | amount |
  | :--- | :---: | :---: |
  | Phong | 101 | 500 |
  | Phong | 102 | 200 |
  | Linh | 103 | 300 |
  | Tuấn | *NULL* | *NULL* |
  | *NULL* | 104 | 150 |

- **Giải thích:** Kết hợp toàn bộ: `Tuấn` vẫn có mặt (kèm `NULL` đơn hàng) và Đơn `104` vẫn có mặt (kèm `NULL` người mua).

---

#### 6. CROSS JOIN (Tích Descartes - Ghép cặp toàn bộ)

- **Bản chất:** Giả sử bạn có bảng `sizes` gồm 3 size (`S`, `M`, `L`) và bảng `colors` gồm 2 màu (`Đỏ`, `Xanh`). Phép `CROSS JOIN` sẽ tạo ra `3 × 2 = 6` dòng kết hợp.

- **Câu lệnh truy vấn:**
  ```sql
  SELECT s.size_name, c.color_name
  FROM sizes s
  CROSS JOIN colors c;
  ```

- **Bảng kết quả thực tế:**

  | size_name | color_name |
  | :--- | :--- |
  | S | Đỏ |
  | S | Xanh |
  | M | Đỏ |
  | M | Xanh |
  | L | Đỏ |
  | L | Xanh |

---

#### 7. SELF JOIN (Bảng tự kết nối với chính nó)

- **Bản chất:** Dùng khi dữ liệu có cấu trúc cây hoặc phân cấp (nhân viên có cột `manager_id` trỏ tới chính `id` của nhân viên quản lý trong cùng một bảng `employees`).

```text
BẢNG: employees
+----+-----------+------------+
| id | name      | manager_id |
+----+-----------+------------+
| 1  | Sếp Hùng  | NULL       |  <-- Giám đốc (không có sếp trên)
| 2  | Nam       | 1          |  <-- Nhân viên dưới quyền sếp Hùng
| 3  | Lan       | 1          |  <-- Nhân viên dưới quyền sếp Hùng
+----+-----------+------------+
```

- **Câu lệnh truy vấn:**
  ```sql
  SELECT 
      e.name AS nhan_vien, 
      COALESCE(m.name, 'Cấp cao nhất') AS quan_ly
  FROM employees e
  LEFT JOIN employees m ON e.manager_id = m.id;
  ```

- **Bảng kết quả thực tế:**

  | nhan_vien | quan_ly |
  | :--- | :--- |
  | Sếp Hùng | Cấp cao nhất |
  | Nam | Sếp Hùng |
  | Lan | Sếp Hùng |

---

## 3.6 Truy vấn Subquery, CTE, UPSERT, Set Operations

| Kỹ thuật | Cú pháp mẫu | Mục đích & Ứng dụng thực tế |
| :--- | :--- | :--- |
| **Subquery (Truy vấn con)** | `SELECT * FROM products WHERE price > (SELECT avg(price) FROM products);` | Lấy các sản phẩm có giá cao hơn mức giá trung bình của toàn bộ cửa hàng. |
| **EXISTS vs IN** | `SELECT * FROM users u WHERE EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id);` | **Tối ưu hơn `IN`:** `EXISTS` dừng quét ngay lập tức khi tìm thấy 1 bản ghi khớp đầu tiên; xử lý giá trị `NULL` an toàn tuyệt đối. |
| **CTE (Mệnh đề WITH)** | Xem mã nguồn chi tiết bên dưới | Tách truy vấn phức tạp thành các bảng tạm logic dễ đọc, dễ kiểm thử và bảo trì. |
| **UPSERT (Thêm, nếu trùng thì Sửa)** | Xem mã nguồn chi tiết bên dưới | Xử lý bài toán: Nếu bản ghi chưa có thì `INSERT`, nếu đã tồn tại khóa thì chuyển sang `UPDATE`. |
| **UNION vs UNION ALL** | `SELECT phone FROM users UNION ALL SELECT phone FROM suppliers;` | Ghép kết quả 2 câu truy vấn.<br>- `UNION`: Khử trùng lặp (tốn chi phí sắp xếp RAM/Disk).<br>- `UNION ALL`: Giữ nguyên toàn bộ (rất nhanh, nên ưu tiên dùng). |

### 1. Kỹ thuật CTE (Common Table Expression - Mệnh đề WITH):

```sql
-- Tìm những khách hàng VIP đã chi tiêu tổng cộng trên 10 triệu đồng:
WITH vip_spending AS (
    SELECT 
        user_id, 
        sum(amount) AS tong_chi_tieu
    FROM orders
    WHERE status = 'completed'
    GROUP BY user_id
    HAVING sum(amount) >= 10000000
)
SELECT 
    u.id,
    u.name,
    u.email,
    v.tong_chi_tieu
FROM users u
INNER JOIN vip_spending v ON u.id = v.user_id
ORDER BY v.tong_chi_tieu DESC;
```

### 2. Kỹ thuật UPSERT (`INSERT ... ON CONFLICT`):

```sql
-- Lưu thông tin tài khoản: nếu id=1 chưa có thì tạo mới, nếu đã có thì cập nhật email:
INSERT INTO users (id, name, email)
VALUES (1, 'phong', 'phong_new@example.com')
ON CONFLICT (id) 
DO UPDATE SET 
    email = EXCLUDED.email,
    name = EXCLUDED.name;
```

---

## 3.7 Window Functions & Thao tác JSONB

### Window Functions (Hàm cửa sổ - Tính toán mà không làm gộp dòng)

Điểm khác biệt cốt lõi so với `GROUP BY`: 

`GROUP BY` gom nhiều dòng thành 1 dòng duy nhất; còn **Window Function giữ nguyên số lượng dòng ban đầu**, chỉ gắn thêm cột kết quả tính toán bên cạnh mỗi dòng.

| Nhu cầu nghiệp vụ | Câu lệnh SQL mẫu | Kết quả trả về |
| :--- | :--- | :--- |
| **Đánh số thứ tự từng dòng** | `SELECT name, row_number() OVER (ORDER BY created_at) FROM users;` | `1 \| An`, `2 \| Bình`, `3 \| Cường` |
| **Xếp hạng theo từng nhóm (Rank)** | `SELECT name, category_id, price, rank() OVER (PARTITION BY category_id ORDER BY price DESC) AS hang FROM products;` | Xếp hạng sản phẩm đắt nhất đến rẻ nhất **trong từng danh mục riêng biệt**. |
| **Lấy giá trị dòng trước (LAG)** | `SELECT thang, doanh_so, lag(doanh_so) OVER (ORDER BY thang) AS thang_truoc FROM bao_cao;` | So sánh doanh số tháng này với tháng liền trước để tính tỷ lệ tăng trưởng. |

### Thao tác với JSONB trong PostgreSQL 16:

PostgreSQL lưu trữ JSON dưới dạng nhị phân đã phân tích cú pháp (`jsonb`), hỗ trợ đánh chỉ mục GIN và truy vấn cực nhanh:

```sql
-- Tạo bảng chứa trường dữ liệu động JSONB:
CREATE TABLE user_logs (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id int,
    payload jsonb,
    created_at timestamptz DEFAULT now()
);

-- Thêm dữ liệu JSON:
INSERT INTO user_logs (user_id, payload) VALUES
(1, '{"action": "login", "device": "mobile", "ip": "192.168.1.10", "tags": ["ios", "wifi"]}');

-- 1. Trích xuất giá trị trường text bằng toán tử ->>
SELECT payload->>'action' AS action, payload->>'device' AS device FROM user_logs;

-- 2. Tìm kiếm bản ghi có chứa JSON con bằng toán tử @> (RẤT NHANH với GIN Index):
SELECT * FROM user_logs WHERE payload @> '{"device": "mobile"}';

-- 3. Tạo GIN Index để tối ưu hóa tìm kiếm JSONB hàng triệu dòng:
CREATE INDEX idx_user_logs_payload ON user_logs USING gin (payload);
```

---

# Phần 4: Giao Dịch (Transaction), Kiểm Soát Đồng Thời & MVCC

## 4.1 Tính chất ACID của Transaction

Một **Transaction (Giao dịch)** là tập hợp gồm một hoặc nhiều thao tác SQL được thực thi như một đơn vị công việc thống nhất: **"Hoặc tất cả thành công, hoặc không có gì thay đổi cả"**.

```mermaid
sequenceDiagram
    autonumber
    actor App as Ứng dụng Backend
    participant DB as PostgreSQL 16
    App->>DB: BEGIN TRANSACTION (Khởi đầu giao dịch)
    App->>DB: UPDATE accounts SET balance = balance - 1000000 WHERE id = 'A'
    alt Lỗi phần cứng hoặc Mất điện đột ngột
        DB-->>App: Tự động ROLLBACK (Hoàn tác 100%, tài khoản A không bị trừ tiền)
    else Mọi thao tác đều hợp lệ
        App->>DB: UPDATE accounts SET balance = balance + 1000000 WHERE id = 'B'
        App->>DB: COMMIT (Ghi nhận vĩnh viễn dữ liệu xuống đĩa)
        DB-->>App: Xác nhận thành công (Success)
    end
```

- **A - Atomicity (Tính nguyên tử):** Không bao giờ có trạng thái lấp lửng (tiền đã trừ ở A nhưng chưa cộng cho B). Nếu xảy ra bất kỳ lỗi nào, toàn bộ giao dịch sẽ bị hoàn tác (`ROLLBACK`).
- **C - Consistency (Tính nhất quán):** Dữ liệu luôn chuyển từ trạng thái hợp lệ này sang trạng thái hợp lệ khác, không vi phạm bất kỳ ràng buộc nào (`CHECK`, `FOREIGN KEY`).
- **I - Isolation (Tính cô lập):** Các giao dịch diễn ra đồng thời không nhìn thấy trạng thái trung gian dở dang của nhau và không làm sai lệch kết quả của nhau.
- **D - Durability (Tính bền vững):** Khi hệ thống đã trả về thông báo `COMMIT` thành công, dữ liệu chắc chắn đã được lưu an toàn xuống nhật ký WAL trên ổ cứng, dù máy chủ bị rút nguồn điện ngay sau đó.

---

## 4.2 MVCC:

PostgreSQL kiểm soát truy cập đồng thời bằng cơ chế **MVCC (Multi-Version Concurrency Control)**. Khi một câu lệnh `UPDATE` hoặc `DELETE` diễn ra, PostgreSQL **không bao giờ ghi đè trực tiếp** lên ô nhớ của bản ghi cũ, mà thực hiện:
1. Đánh dấu bản ghi cũ là đã hết hiệu lực (Dead Tuple).
2. Tạo ra một **phiên bản bản ghi mới (Tuple mới)** chứa dữ liệu vừa cập nhật.

```text
CẤU TRÚC BẢNG LƯU DƯỚI Ổ CỨNG (HEAP PAGE):
+-------------------------------------------------------------------------------+
| [Tuple 1: id=1, name='Phong', xmin=100, xmax=105]  <-- Hàng cũ (Dead Tuple)    |
| [Tuple 2: id=1, name='Phong VIP', xmin=105, xmax=0] <-- Hàng mới (Live Tuple)  |
+-------------------------------------------------------------------------------+
```

- **Ưu điểm vượt trội:** Khi User 1 đang chạy câu lệnh `SELECT` xuất báo cáo tài chính mất 3 phút, User 2 đồng thời chạy `UPDATE` sửa dữ liệu thì cả hai **không hề phải đứng chờ nhau**. User 1 vẫn nhìn thấy "bức ảnh chụp" (Snapshot) dữ liệu tại thời điểm bắt đầu truy vấn.
- **Hệ quả (Bản ghi rác - Dead Tuples):** Bản ghi cũ bị xóa hoặc sửa sẽ trở thành rác. Nếu không được dọn dẹp định kỳ, dung lượng file bảng sẽ ngày càng phình to (gọi là **Table Bloat**). Vì vậy PostgreSQL cần tiến trình **VACUUM** chạy ngầm để thu hồi không gian bộ nhớ này.

---

## 4.3 Các mức cô lập (Isolation Levels) & Hiện tượng đọc sai

Chuẩn SQL định nghĩa 3 hiện tượng dị thường khi nhiều giao dịch chạy đồng thời:
1. **Dirty Read (Đọc rác):** Giao dịch 1 đọc phải dữ liệu dở dang mà Giao dịch 2 vừa sửa nhưng chưa `COMMIT` (nếu Giao dịch 2 `ROLLBACK` thì dữ liệu Giao dịch 1 đọc là hoàn toàn sai).
2. **Non-repeatable Read (Đọc không lặp lại):** Trong cùng 1 giao dịch, đọc dòng X lần 1 được 10 triệu; đọc dòng X lần 2 lại ra 15 triệu vì ai đó vừa `UPDATE` và `COMMIT` ở giữa 2 lần đọc.
3. **Phantom Read (Đọc bóng ma):** Trong cùng 1 giao dịch, câu lệnh đếm tổng đơn hàng lần 1 được 100 đơn; câu lệnh đếm lần 2 lại ra 101 đơn vì ai đó vừa `INSERT` thêm đơn mới và `COMMIT`.

### Bảng ma trận mức cô lập trong PostgreSQL:

| Mức cô lập | Dirty Read | Non-repeatable Read | Phantom Read | Đánh giá & Khuyên dùng |
| :--- | :---: | :---: | :---: | :--- |
| **`READ COMMITTED`** *(Mặc định)* | **Không bị** | Có thể gặp | Có thể gặp | Mặc định của PostgreSQL. Đạt tốc độ cao nhất, phù hợp với 95% tác vụ thông thường. |
| **`REPEATABLE READ`** | **Không bị** | **Ngăn chặn được** | **Ngăn chặn được** *(Đặc trưng của PG)* | Chụp snapshot ổn định cho toàn bộ transaction. Dùng khi làm báo cáo tài chính phức tạp. |
| **`SERIALIZABLE`** *(Cao nhất)* | **Không bị** | **Ngăn chặn được** | **Ngăn chặn được** | Đảm bảo kết quả giống như các transaction chạy lần lượt từng cái một. Chi phí cao, dễ bị lỗi `serialization_failure` cần retry. |

```sql
-- Cách đổi mức cô lập cho phiên làm việc hiện tại:
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- Các thao tác truy vấn...
COMMIT;
```

---

## 4.4 Cơ chế Khóa hàng: FOR UPDATE & FOR UPDATE SKIP LOCKED

Khi xây dựng các hệ thống nhạy cảm như bán vé xem phim, flash sale hoặc trừ tiền tài khoản: Nếu 2 khách hàng cùng bấm nút mua một món hàng cuối cùng (`quantity = 1`), cả 2 tiến trình đều đọc thấy `1` và cùng cho phép mua -> **Dẫn đến bán âm kho!**

### Giải pháp 1: Khóa hàng độc quyền với `FOR UPDATE`

```sql
BEGIN;
-- Khóa cứng dòng sản phẩm này lại:
SELECT id, stock FROM products 
WHERE id = 100 
FOR UPDATE;

-- Tiến trình khác muốn SELECT ... FOR UPDATE hoặc UPDATE dòng này phải chờ đợi!
UPDATE products SET stock = stock - 1 WHERE id = 100;
COMMIT; -- Nhả khóa an toàn
```

### Giải pháp 2: Xử lý hàng đợi tác vụ không nghẽn với `FOR UPDATE SKIP LOCKED`

Khi bạn có 10 worker backend cùng lấy công việc từ bảng `task_queue`: Nếu dùng `FOR UPDATE` thông thường, các worker sẽ bị nghẽn đợi nhau. Dùng `SKIP LOCKED` giúp worker tự động **bỏ qua những dòng đang bị worker khác khóa** để lấy ngay dòng tiếp theo!

```sql
-- Lấy 1 công việc chưa xử lý mà không bị kẹt khóa:
BEGIN;
SELECT id, payload FROM task_queue
WHERE status = 'pending'
ORDER BY id ASC
LIMIT 1
FOR UPDATE SKIP LOCKED;

-- Xử lý xong thì cập nhật trạng thái:
UPDATE task_queue SET status = 'completed' WHERE id = :id;
COMMIT;
```

---


# Phần 5: Tối Ưu Hóa Truy Vấn (Query Optimization)

Tối ưu hóa truy vấn thực chất là **giảm thiểu số lần đọc ổ cứng (I/O)** và tận dụng tối đa bộ nhớ đệm (RAM). Dưới đây là các kiến thức cốt lõi được đúc kết cô đọng, dễ hiểu nhất.

---

## 5.1 Bản chất Chỉ mục (Index) & Cơ chế hoạt động (B-Tree vs Sequential Scan)

### 1. Hình dung trực quan: Mục lục sách vs Lật từng trang
- **Sequential Scan (`Seq Scan`):** Đọc tuần tự từ trang 1 đến trang cuối cùng của bảng. Nếu bảng có 10 triệu dòng, máy tính phải nạp cả 10 triệu dòng lên RAM để kiểm tra -> **Cực kỳ chậm khi dữ liệu lớn**.
- **B-Tree Index (`Index Scan`):** Tương tự như **Mục lục ở đầu cuốn sách**. Mục lục lưu các cặp `(Giá trị tìm kiếm -> Vị trí trang trên đĩa ctid)`. 
  - Thay vì lật 10 triệu trang, cây B-Tree chỉ mất **3 - 4 bước so sánh** trên RAM là nhảy thẳng tới đúng dòng cần đọc!

```mermaid
graph TD
    Root["Gốc B-Tree: [Mã 50]"] --> Left["Nhánh Trái: [Mã 20]"]
    Root --> Right["Nhánh Phải: [Mã 80]"]
    Left --> Leaf1["Lá: [Mã 10, 15] -> Trang 1"]
    Left --> Leaf2["Lá: [Mã 25, 30] -> Trang 4"]
    Right --> Leaf3["Lá: [Mã 60, 70] -> Trang 9"]
    Right --> Leaf4["Lá: [Mã 85, 95] -> Trang 12"]
```

---

### 2. So sánh 3 chiến lược quét dữ liệu phổ biến nhất

| Kiểu quét | Bản chất dễ hiểu | Khi nào DB chọn? | Tốc độ |
| :--- | :--- | :--- | :---: |
| **`Seq Scan`** | Quét tuần tự toàn bộ bảng từ đầu đến cuối. | Bảng nhỏ (< vài trăm dòng) hoặc khi câu truy vấn lấy > 25% số dòng của bảng. | 🐢 Chậm nhất |
| **`Index Scan`** | Tra cây B-Tree để lấy vị trí `ctid`, sau đó lật đến trang bảng để đọc dữ liệu. | Điều kiện lọc tìm kiếm ít dòng (< 5% số dòng). | 🚗 Rất nhanh |
| **`Index Only Scan`** | **Đỉnh cao tốc độ:** Mọi cột cần lấy (`SELECT`, `WHERE`) đều nằm sẵn trong Index. DB **không cần chạm vào bảng chính**, chỉ đọc trên RAM. | Khi dùng Covering Index (`INCLUDE`) hoặc chỉ `SELECT` cột đã được đánh index. | 🚀 Siêu tốc |

> **Nguyên tắc chi phí:** Bảng nhỏ (< 500 dòng) thì quét toàn bảng (`Seq Scan`) lại nhanh hơn dùng Index vì không mất công nạp thêm cây B-Tree. Nhưng với bảng hàng triệu dòng, Index giúp giảm thời gian từ **vài chục giây xuống dưới 1 mili-giây**!

---

## 5.2 Bảng tra cứu các loại Index trong PostgreSQL

| Loại Index | Khi nào nên dùng? (Bản chất dễ hiểu) | Cú pháp mẫu |
| :--- | :--- | :--- |
| **B-Tree** *(Mặc định)* | Tìm kiếm `=`, `<`, `>`, `BETWEEN`, `IN`, sắp xếp `ORDER BY`, tìm tiền tố `LIKE abc%`. | `CREATE INDEX idx_users_email ON users(email);` |
| **Composite** *(Nhiều cột)* | Thường xuyên lọc đồng thời: `WHERE user_id = ? AND status = ?`.<br>*(Quy tắc: Cột so sánh bằng đặt trước, cột khoảng/sắp xếp đặt sau).* | `CREATE INDEX idx_orders_u_s ON orders(user_id, status);` |
| **Covering (`INCLUDE`)** | Đính kèm thêm cột phụ vào lá của Index để đạt **`Index Only Scan`** mà không làm nặng cây B-Tree. | `CREATE INDEX idx_orders_covering ON orders(user_id) INCLUDE (total_amount);` |
| **Partial Index** *(Một phần)* | Chỉ đánh index cho tập dữ liệu con thường xuyên truy vấn (ví dụ: chỉ 5% đơn `pending`). Tiết kiệm 95% RAM! | `CREATE INDEX idx_orders_pending ON orders(created_at) WHERE status = pending;` |
| **Expression Index** | Đánh index trên kết quả của hàm khi thường xuyên tìm kiếm không phân biệt hoa thường. | `CREATE INDEX idx_users_lower_email ON users(lower(email));`<br>Truy vấn: `WHERE lower(email) = abc@gmail.com` |
| **GIN Index** | Tìm kiếm trong cột mảng (`text[]`), dữ liệu JSONB (`@>`), hoặc tìm kiếm toàn văn Full-Text Search. | `CREATE INDEX idx_events_json ON events USING gin (payload);` |
| **BRIN Index** | Bảng Log, Time-series khổng lồ (hàng trăm triệu dòng) ghi liên tục theo thời gian. Dung lượng cực nhỏ (< 5MB). | `CREATE INDEX idx_logs_brin ON logs USING brin (created_at);` |

### 2 câu lệnh SQL bỏ túi kiểm tra Index của DBA:

```sql
-- 1. Tìm các Index thừa KHÔNG BAO GIỜ được dùng (để xóa bớt, tăng tốc ghi INSERT/UPDATE):
SELECT relname AS ten_bang, indexrelname AS ten_index, idx_scan AS so_lan_dung
FROM pg_stat_user_indexes
WHERE idx_scan = 0 AND indisunique = false;

-- 2. Tìm các Khóa ngoại (Foreign Key) bị quên đánh Index (nguyên nhân gây treo Deadlock):
SELECT conrelid::regclass AS bang_con, conname AS ten_khoa_ngoai
FROM pg_constraint c
WHERE contype = f AND NOT EXISTS (
    SELECT 1 FROM pg_index i WHERE i.indrelid = c.conrelid AND (i.indkey::int2[])[0] = (c.conkey)[1]
);
```

---

## 5.4 Bảng so sánh "NÊN LÀM vs NÊN TRÁNH" khi viết SQL

| Tình huống | NÊN TRÁNH (Chậm, vô hiệu hóa Index) |  NÊN LÀM (Tối ưu, tận dụng tối đa Index) | Bản chất kỹ thuật |
| :--- | :--- | :--- | :--- |
| **Chọn cột** | `SELECT * FROM orders;` | `SELECT id, code, amount FROM orders;` | Tiết kiệm băng thông, RAM và giúp kích hoạt **`Index Only Scan`**. |
| **Lọc thời gian** | `WHERE date_trunc(day, created_at) = 2026-11-01` | `WHERE created_at >= 2026-11-01 AND created_at < 2026-11-02` | Bọc cột trong hàm làm B-Tree bị vô hiệu hóa (phải quét toàn bảng). Dùng khoảng so sánh để giữ tính Sargable. |
| **Tìm chuỗi** | `WHERE name LIKE %iphone` | `WHERE name LIKE iphone%` | Dấu `%` ở đầu làm B-Tree không tìm được nhánh; dấu `%` ở cuối thì B-Tree tìm cực nhanh. *(Nếu cần tìm ở giữa, dùng extension `pg_trgm`)*. |
| **Subquery** | `WHERE id IN (SELECT user_id FROM orders)` | `WHERE EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id)` | `EXISTS` dừng lại ngay khi thấy bản ghi khớp đầu tiên; xử lý an toàn khi bảng con có giá trị `NULL`. |
| **Phân trang** | `SELECT * FROM logs ORDER BY id LIMIT 20 OFFSET 500000;` | `SELECT * FROM logs WHERE id > 500000 ORDER BY id LIMIT 20;` | `OFFSET 500,000` bắt DB đọc nạp 500,000 dòng rồi vứt đi. Dùng **Keyset Pagination** (`WHERE id > ?`) nhảy tức thì 0.05ms! |
| **Ghi dữ liệu** | Chạy vòng lặp gọi 1,000 lần lệnh `INSERT` đơn lẻ | `INSERT INTO logs (m) VALUES (a), (b), (c);` (Batch) | Giảm 1,000 round-trip mạng và chi phí mở/đóng transaction. |

---

## 5.5 Dọn rác với VACUUM, Autovacuum & Chống phình dữ liệu (Bloat)

### 1. Tại sao file dữ liệu không tự nhỏ lại khi DELETE?
- Theo cơ chế **MVCC**, khi bạn `DELETE` hoặc `UPDATE`, dòng cũ không bị xóa mất mà trở thành **Dead Tuple (bản ghi rác)**.
- **Kích thước file trên đĩa cứng KHÔNG BAO GIỜ tự thu nhỏ lại**. Không gian của các dòng rác chỉ được tái sử dụng nội bộ cho các lệnh `INSERT/UPDATE` tương lai.

### 2. Phân biệt 3 công cụ dọn rác:
- **`VACUUM (ANALYZE)`:** Dọn dẹp rác, tái sử dụng ô trống. **Hoàn toàn KHÔNG khóa bảng**, ứng dụng vẫn đọc/ghi bình thường.
- **`VACUUM FULL`:** Viết lại toàn bộ bảng sang file mới để trả dung lượng đĩa về cho Hệ điều hành. **Cực kỳ nguy hiểm vì KHÓA CỨNG TOÀN BẢNG**, ứng dụng bị treo toàn bộ!
- **`pg_repack` (Extension):** Giải pháp chuẩn cho Production: Thu hồi đĩa 100% như `VACUUM FULL` nhưng **hoàn toàn Online, không khóa đọc/ghi**.

### 3. Quy tắc vàng với Autovacuum:
- **Tuyệt đối không bao giờ tắt Autovacuum!** Tắt Autovacuum sẽ dẫn đến thảm họa cạn kiệt Transaction ID (**Wraparound**), khiến PostgreSQL tự động ngắt kết nối và ép chuyển sang chế độ Read-Only để chống hỏng dữ liệu.
- Với bảng lớn (> 10 triệu dòng), hãy giảm tham số `scale_factor` để Autovacuum dọn rác sớm hơn:
  ```sql
  ALTER TABLE orders SET (autovacuum_vacuum_scale_factor = 0.02); -- 2% rác là dọn ngay
  ```

---

## 5.6 Tối ưu cấu hình phần cứng & Connection Pooling (PgBouncer)

### 1. Tại sao bắt buộc dùng PgBouncer?
PostgreSQL dùng mô hình **đa tiến trình (Multi-process)**: mỗi kết nối từ ứng dụng tạo ra 1 process Linux riêng (tiêu tốn ~10MB RAM). Nếu mở 1,000 kết nối trực tiếp, máy chủ sẽ sập RAM và tê liệt CPU vì chuyển ngữ cảnh (Context Switching).

```mermaid
flowchart LR
    App["1000 Kết nối từ Backend"] --> PB["PgBouncer
(Connection Pooler)"]
    PB -->|"Chỉ duy trì 20 - 30 kết nối thực tế"| PG[("PostgreSQL Server
(CPU & RAM ổn định)")]
```

> **Chế độ khuyên dùng:** Thiết lập PgBouncer ở chế độ **`pool_mode = transaction`** (mượn kết nối khi chạy transaction, xong trả ngay cho người khác). Giúp hàng ngàn người dùng chia sẻ mượt mà chỉ 30 kết nối thực tế!

### 2. Bảng cấu hình `postgresql.conf` bỏ túi (cho máy chủ chạy ổ cứng SSD/NVMe):

| Tham số | Giá trị khuyên dùng | Bản chất dễ nhớ |
| :--- | :--- | :--- |
| **`shared_buffers`** | **25% tổng RAM** của server | Bộ nhớ đệm RAM chính để giữ các trang dữ liệu hay đọc. (Ví dụ: Server 16GB RAM -> đặt 4GB). |
| **`effective_cache_size`** | **50% - 75% tổng RAM** | Ước tính tổng bộ nhớ cache (của cả PostgreSQL và Linux) để Query Planner tính toán chọn Index. |
| **`work_mem`** | **16MB - 64MB** | RAM cấp cho **mỗi phép sắp xếp hoặc băm** của câu truy vấn. Không đặt quá lớn kẻo tràn RAM khi nhiều người truy vấn cùng lúc. |
| **`maintenance_work_mem`**| **256MB - 1GB** | RAM dành riêng cho việc bảo trì: tạo Index (`CREATE INDEX`) và dọn rác (`VACUUM`). |
| **`random_page_cost`** | **`1.1`** *(Mặc định là 4.0)* | **Bắt buộc đổi thành 1.1 khi dùng ổ SSD/NVMe** để báo cho DB biết ổ đĩa đọc ngẫu nhiên rất nhanh, khuyến khích dùng Index! |
| **`max_connections`** | **100 - 200** | Giữ ở mức vừa phải kết hợp với PgBouncer, không mở trực tiếp hàng ngàn kết nối. |

---

# Phần 6: Kiến Trúc Nội Bộ, Bảo Mật & Vận Hành

## 6.1 Sơ đồ kiến trúc các tiến trình & Cơ chế WAL (Write-Ahead Logging)

### Sơ đồ kiến trúc toàn diện của PostgreSQL Instance

```mermaid
flowchart TD
    subgraph Clients ["Các ứng dụng kết nối (Client Layer)"]
        C1["Web App"]
        C2["Mobile Backend"]
        C3["Worker Service"]
    end

    subgraph Master ["Tiến trình Quản lý chính (Postmaster)"]
        PM["Postmaster Daemon (Cổng TCP 5432)"]
    end

    subgraph Shared_Memory ["Vùng Bộ Nhớ Chung (Shared Memory / RAM)"]
        SB[("Shared Buffers
(Các trang dữ liệu bảng 8KB)")]
        WB["WAL Buffers
(Nhật ký thay đổi chờ ghi)"]
        LM["Lock Manager
(Quản lý khóa hàng & khóa bảng)"]
    end

    subgraph Backends ["Các tiến trình phục vụ độc lập"]
        B1["Backend Process 1"]
        B2["Backend Process 2"]
        B3["Backend Process 3"]
    end

    subgraph Bg_Workers ["Các tiến trình nền ngầm (Background Workers)"]
        CP["Checkpointer
(Đẩy trang bẩn từ RAM xuống đĩa)"]
        BGW["Background Writer (bgwriter)
(Làm sạch Shared Buffers)"]
        WW["WAL Writer
(Ghi WAL Buffers xuống đĩa liên tục)"]
        AV["Autovacuum Launcher & Workers
(Dọn dẹp Dead Tuples)"]
        ARCH["Archiver
(Lưu trữ WAL phục vụ backup PITR)"]
    end

    subgraph Storage ["Hệ thống Lưu Trữ Ổ Cứng (Disk Storage)"]
        WAL_DISK[("pg_wal/
(Tệp nhật ký ghi trước 16MB)")]
        DATA_DISK[("base/ & global/
(Tệp dữ liệu bảng và Index)")]
    end

    Clients -->|"Gửi yêu cầu kết nối"| PM
    PM -->|"Fork tiến trình mới"| Backends
    Backends <-->|"Đọc / Sửa trang dữ liệu"| SB
    Backends -->|"Ghi chép lịch sử giao dịch"| WB
    Backends <-->|"Xin cấp phép khóa"| LM

    WB -->|"fsync định kỳ"| WW --> WAL_DISK
    SB -->|"Checkpoint định kỳ"| CP --> DATA_DISK
    SB -->|"Dọn chỗ trống RAM"| BGW --> DATA_DISK
    AV <-->|"Quét dọn rác"| SB & DATA_DISK
    WAL_DISK -->|"Đẩy file sang kho lưu trữ"| ARCH
```

---

### Vòng đời chi tiết của một câu lệnh ghi (`INSERT / UPDATE`):

Khi ứng dụng chạy lệnh:
```sql
UPDATE accounts SET balance = balance - 500 WHERE id = 10;
COMMIT;
```

Cơ chế diễn ra bên dưới gồm 5 bước nghiêm ngặt:
1. **Truy vấn trang dữ liệu vào RAM:** Tiến trình Backend tìm kiếm xem trang chứa dòng `id = 10` đã có trong `Shared Buffers` (RAM) chưa. Nếu chưa có, nó phát lệnh đọc khối 8KB tương ứng từ đĩa cứng `base/` nạp vào RAM.
2. **Sửa đổi trên RAM (Tạo Dirty Page):** Backend tạo một bản ghi mới với số dư trừ 500, đánh dấu bản ghi cũ là Dead Tuple. Trang dữ liệu trên RAM bị thay đổi gọi là **Dirty Page (Trang bẩn)** vì nội dung trên RAM lúc này đã khác với nội dung đang lưu dưới đĩa.
3. **Ghi nhật ký WAL (Write-Ahead Logging):** Ngay lập tức, một bản ghi nhật ký mô tả sự thay đổi ("Dòng 10 đổi số dư thành X") được tạo ra và đưa vào `WAL Buffers` trên RAM.
4. **Lệnh `COMMIT` và `fsync` xuống đĩa:** Khi gặp lệnh `COMMIT`, tiến trình gọi lệnh hệ thống `fsync()` để ép ghi bản ghi WAL từ RAM xuống tệp vật lý trong thư mục `pg_wal/` trên ổ cứng. **Ngay khi file WAL được ghi an toàn xuống đĩa, PostgreSQL lập tức phản hồi về cho ứng dụng: "Giao dịch thành công!"**
   > **Bí mật tốc độ của PostgreSQL:** Lưu ý rằng lúc này **dữ liệu trong tệp bảng chính `base/` vẫn CHƯA ĐƯỢC CẬP NHẬT DƯỚI ĐĨA**! Việc ghi nhật ký WAL tuần tự (Sequential I/O) nhanh hơn gấp hàng trăm lần so với việc nhảy vào sửa file bảng chính (Random I/O).
5. **Đồng bộ về sau qua Checkpointer:** Một lúc sau, tiến trình nền `Checkpointer` thức dậy định kỳ, gom tất cả các Dirty Pages trên RAM ghi một lượt xuống tệp bảng chính trên ổ đĩa và đánh dấu một "Điểm kiểm tra" (Checkpoint).

---

### Nguyên lý phục hồi khi gặp thảm họa (Crash Recovery):

Nếu máy chủ bị rút phích cắm điện đột ngột ngay sau bước 4:
- Dữ liệu mới trong RAM `Shared Buffers` bị mất sạch 100%.
- Dữ liệu trong file bảng chính `base/` vẫn là dữ liệu cũ.
- **Cách khôi phục khi bật máy lại:** PostgreSQL khởi động, đọc điểm Checkpoint gần nhất và đọc lại toàn bộ nhật ký `pg_wal/` từ mốc đó trở đi (**REDO Phase**). Nó thực hiện lại toàn bộ các thao tác đã commit ghi vào tệp bảng, đảm bảo **không mất một byte dữ liệu nào**!

---

## 6.2 Phân quyền Role & Bảo mật mật khẩu với pgcrypto (bcrypt)

### 1. Mô hình Phân quyền Phân tầng chuẩn Doanh nghiệp (RBAC Model)

Trong PostgreSQL, không có sự phân biệt giữa "User" và "Group", cả hai đều là **`ROLE`**. Một User thực chất chỉ là một Role có cờ `LOGIN`.

```mermaid
flowchart TD
    subgraph Roles ["Tầng Phân Nhóm Quyền (Không thể đăng nhập)"]
        R_Read["Role: read_only
(Chỉ xem SELECT dữ liệu)"]
        R_App["Role: app_read_write
(Xem, Thêm, Sửa, Xóa DML)"]
        R_Admin["Role: dba_admin
(Tạo bảng, sửa schema DDL)"]
    end

    subgraph Logins ["Tầng Tài Khoản Đăng Nhập Thực Tế (LOGIN)"]
        U_Analyst["User: analyst_linh
(Nhân viên phân tích dữ liệu)"]
        U_Backend["User: backend_api_service
(Mã nguồn ứng dụng chạy thật)"]
        U_DevOps["User: devops_deployer
(Tài khoản CI/CD chạy migration)"]
    end

    U_Analyst -->|"Kế thừa quyền"| R_Read
    U_Backend -->|"Kế thừa quyền"| R_App
    U_DevOps -->|"Kế thừa quyền"| R_Admin
```

#### Mã nguồn SQL thiết lập phân quyền chuẩn sản xuất:

```sql
-- BƯỚC 1: Tạo các Role chức năng (Không cho phép đăng nhập trực tiếp)
CREATE ROLE role_readonly;
GRANT CONNECT ON DATABASE appdb TO role_readonly;
GRANT USAGE ON SCHEMA public TO role_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO role_readonly;
-- Đảm bảo các bảng tạo trong tương lai cũng tự động cấp quyền SELECT:
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO role_readonly;

CREATE ROLE role_readwrite;
GRANT CONNECT ON DATABASE appdb TO role_readwrite;
GRANT USAGE ON SCHEMA public TO role_readwrite;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO role_readwrite;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO role_readwrite;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO role_readwrite;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO role_readwrite;

-- BƯỚC 2: Tạo các tài khoản đăng nhập chuyên biệt cho từng dịch vụ
CREATE USER api_backend_user WITH PASSWORD 'MatKhauSieuManh_2026_@XYZ';
GRANT role_readwrite TO api_backend_user; -- Kế thừa toàn bộ quyền Đọc/Ghi

CREATE USER bi_analyst_user WITH PASSWORD 'AnalystPass_2026_Safe!';
GRANT role_readonly TO bi_analyst_user;   -- Chỉ được phép đọc dữ liệu
```

---

### 2. Bảo mật cấp hàng (Row-Level Security - RLS)

**Bài toán:** Trong hệ thống SaaS đa khách hàng (Multi-tenant), bảng `documents` chứa tài liệu của hàng trăm công ty khác nhau. Nếu một lập trình viên backend viết thiếu mệnh đề `WHERE company_id = ?`, dữ liệu của công ty này sẽ bị lộ cho công ty khác xem (lỗ hổng IDOR nguy hiểm).

**Giải pháp RLS: Ràng buộc an toàn ngay tại tầng CSDL:**
```sql
-- 1. Bật tính năng RLS trên bảng:
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- 2. Tạo chính sách bảo mật: Người dùng chỉ được thấy dòng có company_id trùng với phiên làm việc của họ:
CREATE POLICY tenant_isolation_policy ON documents
FOR ALL
TO role_readwrite
USING (company_id = current_setting('app.current_company_id')::int);

-- 3. Khi Backend kết nối vào và xử lý yêu cầu của Công ty A (id=5):
BEGIN;
SET LOCAL app.current_company_id = '5';
SELECT * FROM documents; -- Tự động chỉ trả về tài liệu của công ty 5, không cần nhớ viết WHERE!
COMMIT;
```

---

### 3. Mã hóa và xác thực mật khẩu an toàn với `pgcrypto` (bcrypt)

Tuyệt đối không sử dụng MD5 hay SHA256 để lưu mật khẩu người dùng vì hacker có thể dùng kỹ thuật bảng Rainbow (Rainbow Tables) để giải mã hàng triệu mật khẩu trong vài phút. Bắt buộc sử dụng thuật toán thích ứng **bcrypt**.

```sql
-- Bật extension mã hóa chuẩn của PostgreSQL:
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Tạo bảng lưu người dùng:
CREATE TABLE accounts (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username varchar(50) NOT NULL UNIQUE,
    password_hash text NOT NULL,
    created_at timestamptz DEFAULT now()
);

-- 2. Đăng ký tài khoản: Mã hóa mật khẩu với thuật toán Blowfish (bcrypt) với độ phức tạp cost=10:
INSERT INTO accounts (username, password_hash)
VALUES ('phongvt', crypt('MatKhauKhoDoan123!@#', gen_salt('bf', 10)));

-- 3. Xác thực khi người dùng đăng nhập:
SELECT id, username 
FROM accounts 
WHERE username = 'phongvt'
  AND password_hash = crypt('MatKhauKhoDoan123!@#', password_hash);
-- Nếu mật khẩu khớp: Trả về dòng dữ liệu của user phongvt.
-- Nếu mật khẩu sai: Trả về rỗng (0 dòng). Toàn bộ quá trình kiểm tra diễn ra an toàn trong CSDL.
```

