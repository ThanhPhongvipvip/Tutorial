# Cơ Sở Dữ Liệu & PostgreSQL 16

> Ứng dụng demo thực tế Qt + PostgreSQL 16 + Docker: xem tại thư mục [`qt-postgres-login-demo/`](qt-postgres-login-demo/README.md).

---

## Mục lục

- [**Phần 1: Cơ Sở Dữ Liệu & Mô Hình Quan Hệ (RDBMS)**](#phần-1-cơ-sở-dữ-liệu--mô-hình-quan-hệ-rdbms)
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
  - [2.4 Bảng lệnh tắt psql (CLI Cheat Sheet)](#24-bảng-lệnh-tắt-psql-cli-cheat-sheet)
- [**Phần 3: Bảng Tra Cứu Các Câu Lệnh Truy Vấn SQL**](#phần-3-bảng-tra-cứu-các-câu-lệnh-truy-vấn-sql)
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
  - [5.1 Chỉ mục (Index) là gì và tại sao giúp tìm dữ liệu nhanh?](#51-chỉ-mục-index-là-gì-và-tại-sao-giúp-tìm-dữ-liệu-nhanh)
  - [5.2 Các loại Index thường dùng trong PostgreSQL](#52-các-loại-index-thường-dùng-trong-postgresql)
  - [5.3 Cách viết câu lệnh SQL chạy nhanh (Nên làm vs Nên tránh)](#53-cách-viết-câu-lệnh-sql-chạy-nhanh-nên-làm-vs-nên-tránh)
  - [5.4 Dọn rác dữ liệu với VACUUM & Autovacuum](#54-dọn-rác-dữ-liệu-với-vacuum--autovacuum)
- [**Phần 6: Cách PostgreSQL Lưu Dữ Liệu & Bảo Mật Cơ Bản**](#phần-6-cách-postgresql-lưu-dữ-liệu--bảo-mật-cơ-bản)
  - [6.1 Cách PostgreSQL xử lý truy vấn và chống mất dữ liệu (WAL)](#61-cách-postgresql-xử-lý-truy-vấn-và-chống-mất-dữ-liệu-wal)
  - [6.2 Bảo mật cơ bản: Phân quyền, Mật khẩu](#62-bảo-mật-cơ-bản-phân-quyền-mật-khẩu)

---

# Phần 1: Cơ Sở Dữ Liệu & Mô Hình Quan Hệ (RDBMS)

## 1.1 CSDL là gì? Tại sao không dùng Excel / File?

- **Cơ sở dữ liệu (Database - DB):** Là kho lưu trữ dữ liệu có tổ chức, có cấu trúc, cho phép nhiều ứng dụng và người dùng truy cập, tìm kiếm, cập nhật đồng thời mà vẫn đảm bảo tính chính xác và an toàn tuyệt đối.
- **Hệ quản trị CSDL (Database Management System - DBMS):** Là phần mềm chuyên dụng để quản lý, bảo vệ và vận hành cơ sở dữ liệu đó (ví dụ: PostgreSQL, MySQL, Oracle, SQL Server).

### Sơ đồ kiến trúc 3 tầng chuẩn của ứng dụng hiện đại

```mermaid
flowchart LR
    subgraph Client ["1. Tầng Trình Bày (Client)"]
        UI["Web / Mobile App / Desktop"]
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

Hiện nay các hệ quản trị cơ sở dữ liệu được chia làm 2 nhóm chính:

### 1. Bảng phân biệt dễ hiểu: SQL vs NoSQL

| Tiêu chí | CSDL Quan hệ - SQL (PostgreSQL, MySQL) | CSDL Phi quan hệ - NoSQL (MongoDB, Redis) |
| :--- | :--- | :--- |
| **Cách lưu dữ liệu** | Lưu vào các **Bảng (Table)** có hàng và cột được quy định sẵn khuôn mẫu chặt chẽ (giống các bảng tính có liên kết với nhau). | Không ép buộc chia bảng/cột cố định. Lưu linh hoạt dưới dạng tài liệu **JSON** (MongoDB) hoặc cặp **Khóa - Giá trị** trên RAM (Redis). |
| **Kiểm soát dữ liệu** | **chặt chẽ:** Dữ liệu phải đúng kiểu (số, chữ, ngày tháng) và đúng quy tắc liên kết giữa các bảng thì mới cho phép lưu. | **Linh hoạt:** Dòng trước có 3 trường, dòng sau thêm thành 5 trường khác nhau vẫn lưu được ngay mà không cần sửa cấu trúc bảng. |
| **Phù hợp nhất cho** | Hệ thống cần **độ chính xác cao và dữ liệu có mối liên kết rõ ràng**: Tài khoản người dùng, Đơn hàng, Kế toán, Ngân hàng, Quản lý kho. | Hệ thống cần **tốc độ bộ nhớ đệm (Cache)** cực nhanh (Redis), hoặc lưu nhật ký hệ thống (Logs), dữ liệu cảm biến thay đổi cấu trúc liên tục. |

### 2. Sơ đồ chọn nhanh loại CSDL cho dự án

```mermaid
flowchart TD
    Start{"Dữ liệu có cấu trúc rõ ràng\nvà cần đảm bảo chính xác?"}
    Start -- "Có (Người dùng, Đơn hàng, Tiền tệ)" --> SQL["Chọn SQL (PostgreSQL)\n- Quản lý bảng và liên kết chặt chẽ\n- Chuyển tiền / đặt hàng an toàn\n- Có sẵn kiểu JSONB khi cần lưu dữ liệu động"]
    Start -- "Không (Lưu tạm tốc độ cao, Logs tự do)" --> CheckCache{"Mục đích chính của bạn là gì?"}
    CheckCache -- "Lưu bộ nhớ đệm (Cache) nhanh trên RAM" --> Redis["Chọn Redis"]
    CheckCache -- "Lưu tài liệu JSON tự do, ít liên kết" --> Mongo["Chọn MongoDB"]
```

> **Điểm mạnh đặc biệt của PostgreSQL:** Thông thường bạn phải chọn giữa sự chặt chẽ của **SQL** hoặc sự linh hoạt của **NoSQL**. Tuy nhiên, PostgreSQL là hệ CSDL SQL nhưng lại tích hợp sẵn kiểu dữ liệu **`JSONB`** (cho phép lưu và tìm kiếm dữ liệu JSON nhanh tương đương MongoDB). Vì vậy, trong đa số dự án, bạn chỉ cần dùng một mình **PostgreSQL** là đã đáp ứng tốt cả hai nhu cầu.

---

## 1.3 Các khái niệm cốt lõi: Bảng, Cột, Hàng, Giá trị NULL

Hãy hình dung một bảng dữ liệu quan hệ (`Table`) gồm các cột định nghĩa thuộc tính và các hàng chứa từng bản ghi cụ thể:

```text
BẢNG: users (Tập hợp các bản ghi người dùng)
+----+------------+-------------------+-----+------------+
| id | username   | email             | age | is_active  |  <-- CÁC CỘT (Columns / Thuộc tính / Kiểu dữ liệu)
+----+------------+-------------------+-----+------------+
| 1  | phong      | phong@example.com | 22  | true       |  <-- HÀNG 1 (Row / Record / Bản ghi)
| 2  | phonh      | phonh@test.com    | 20  | true       |  <-- HÀNG 2
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

Việc chọn đúng kiểu dữ liệu giúp tiết kiệm dung lượng ổ cứng, bộ tối ưu (Query Planner) hoạt động hiệu quả:

| Nhóm dữ liệu | Tên kiểu dữ liệu | Dung lượng | Khi nào nên dùng? (Lưu ý thực tế) |
| :--- | :--- | :--- | :--- |
| **Số nguyên** | `smallint` | 2 bytes | Giá trị nhỏ: -32,768 đến 32,767 (ví dụ: mã trạng thái, thứ trong tuần). |
| | `integer` (`int`) | 4 bytes | Dải số đến ~2.1 tỷ. Thường dùng làm ID cho các bảng vừa và nhỏ. |
| | `bigint` | 8 bytes | Dải số đến 9 tỷ tỷ. **Chuẩn bắt buộc làm PK cho đơn hàng, giao dịch, logs.** |
| **Số thực / Tiền** | `numeric(p, s)` | Linh hoạt | **Bắt buộc dùng cho tiền tệ, tài chính**. Tính toán chính xác 100%, không bị sai số làm tròn như `float`. |
| | `real` / `double precision` | 4 - 8 bytes | Số thực dấu phẩy động. Chỉ dùng cho tọa độ địa lý, khoa học kỹ thuật chấp nhận sai số nhỏ. |
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

### 1. Chuẩn hóa dữ liệu là gì và tại sao cần chuẩn hóa?

Khi mới học thiết kế CSDL, người mới thường có thói quen **nhồi nhét tất cả thông tin vào chung 1 bảng duy nhất**. Việc này gây ra 2 rắc rối lớn:
- **Dữ liệu bị lặp đi lặp lại gây tốn bộ nhớ** (ví dụ: một phòng ban có 500 nhân viên thì tên phòng và địa chỉ phòng bị chép lại 500 lần).
- **Dễ sai sót khi cập nhật:** Khi phòng ban đó đổi tên, bạn phải tìm và sửa cả 500 dòng; nếu sót vài dòng thì dữ liệu trong bảng sẽ mâu thuẫn nhau.

**Chuẩn hóa dữ liệu** đơn giản là **3 bước kiểm tra để tách một bảng ôm đồm thành các bảng nhỏ gọn, hợp lý** (`1NF -> 2NF -> 3NF`), sao cho mỗi thông tin chỉ cần lưu ở **đúng một nơi duy nhất**.

```mermaid
flowchart TD
    Raw["Bảng thô ban đầu\n(Lưu gộp nhiều giá trị, lặp lại thông tin)"] -->|"Bước 1: Mỗi ô chỉ lưu 1 giá trị đơn"| NF1["Đạt Chuẩn 1 (1NF)"]
    NF1 -->|"Bước 2: Tách thông tin riêng của từng đối tượng ra bảng riêng"| NF2["Đạt Chuẩn 2 (2NF)"]
    NF2 -->|"Bước 3: Không lưu ké thông tin bắc cầu của bảng khác"| NF3["Đạt Chuẩn 3 (3NF) - Thiết kế chuẩn"]
```

---

### 2. Giải thích dễ hiểu 3 bước chuẩn hóa qua ví dụ

#### Bước 1: Chuẩn 1 (`1NF`) — "Mỗi ô chỉ chứa đúng 1 giá trị duy nhất"
- **Cách làm sai (Vi phạm 1NF):** Nhét nhiều số điện thoại vào chung một ô, cách nhau bằng dấu phẩy:
  ```text
  +----+-------+-------------------------+
  | id | ten   | so_dien_thoai           |
  +----+-------+-------------------------+
  | 1  | Phong | 0912345678, 0987654321  |  <-- SAI: Gộp 2 số vào chung 1 ô
  +----+-------+-------------------------+
  ```
  *(Khi lưu thế này, việc tìm kiếm hoặc lập mục lục theo từng số điện thoại sẽ rất khó khăn).*
- **Cách sửa để đạt 1NF:** Đảm bảo mỗi ô chỉ lưu đúng 1 giá trị đơn. Nếu một người có nhiều số điện thoại thì tách sang bảng phụ `user_phones(user_id, so_dien_thoai)`, mỗi số nằm trên 1 dòng riêng.

#### Bước 2: Chuẩn 2 (`2NF`) — "Bảng có Khóa chính ghép từ nhiều cột thì mọi cột phụ phải gắn với cả cặp khóa đó"
*(Quy tắc này chỉ cần xét với những bảng dùng **Khóa kết hợp - Composite Key**, ví dụ bảng `chi_tiet_don_hang` có khóa chính gồm cặp `ma_don + ma_sp`).*
- **Cách làm sai (Vi phạm 2NF):** Lưu luôn cả `ten_sp` và `gia_niem_yet` vào bảng `chi_tiet_don_hang(ma_don, ma_sp, ten_sp, gia_niem_yet, so_luong)`.
  - Bạn thấy rằng: cột `so_luong` (mua mấy cái) thì đúng là phải biết cả **Đơn nào (`ma_don`)** và **Sản phẩm nào (`ma_sp`)** mới xác định được.
  - Nhưng cột `ten_sp` ("Chuột không dây") thì chỉ cần biết **`ma_sp`** là biết tên rồi, không liên quan gì tới `ma_don` cả! Nếu sản phẩm này xuất hiện trong 10.000 đơn hàng thì tên sản phẩm bị lưu lặp lại 10.000 lần.
- **Cách sửa để đạt 2NF:** Đưa `ten_sp` và `gia_niem_yet` về bảng riêng `san_pham(ma_sp, ten_sp, gia_niem_yet)`. Bảng `chi_tiet_don_hang` chỉ giữ lại `(ma_don, ma_sp, so_luong)`.

#### Bước 3: Chuẩn 3 (`3NF`) — "Không lưu ké thông tin của đối tượng khác (Bỏ phụ thuộc bắc cầu)"
- **Cách làm sai (Vi phạm 3NF):** Trong bảng `nhan_vien` có khóa chính là `ma_nv`, nhưng lại lưu kèm luôn cả tên phòng ban và địa chỉ phòng ban:
  ```text
  BẢNG: nhan_vien (Chưa đạt 3NF)
  +-------+--------+----------+---------------+------------------+
  | ma_nv | ten_nv | ma_phong | ten_phong     | dia_chi_phong    |
  +-------+--------+----------+---------------+------------------+
  | 101   | Nam    | P01      | Phòng Kỹ thuật| Tầng 3 - Tòa A   |
  | 102   | Lan    | P01      | Phòng Kỹ thuật| Tầng 3 - Tòa A   |  <-- Lặp lại thông tin phòng P01
  +-------+--------+----------+---------------+------------------+
  ```
  - Ở đây: `ma_nv` cho biết nhân viên thuộc `ma_phong` nào -> rồi từ `ma_phong` mới suy ra `ten_phong` và `dia_chi_phong` (gọi là **suy ra bắc cầu**: `A -> B -> C`).
- **Cách sửa để đạt 3NF:** Tách thông tin phòng ban ra bảng riêng `phong_ban(ma_phong, ten_phong, dia_chi_phong)`. Bảng `nhan_vien` chỉ giữ lại cột khóa ngoại `ma_phong`:
  ```text
  BẢNG: nhan_vien (Đã đạt 3NF)              BẢNG: phong_ban
  +-------+--------+----------+             +----------+---------------+----------------+
  | ma_nv | ten_nv | ma_phong |             | ma_phong | ten_phong     | dia_chi_phong  |
  +-------+--------+----------+             +----------+---------------+----------------+
  | 101   | Nam    | P01      | ----------> | P01      | Phòng Kỹ thuật| Tầng 3 - Tòa A |
  | 102   | Lan    | P01      | ----------> +----------+---------------+----------------+
  +-------+--------+----------+
  ```

> **Khi nào người ta chủ động "Phản chuẩn hóa" (Denormalization)?**
> Tách bảng theo chuẩn `3NF` giúp dữ liệu cực kỳ gọn và dễ sửa, nhưng khi cần xem báo cáo tổng hợp thì câu lệnh SQL lại phải ghép (`JOIN`) nhiều bảng với nhau. Trong thực tế, nếu một thông tin phải đọc đi đọc lại hàng triệu lần, người ta có thể **chấp nhận lưu dư thêm 1 cột đã tính sẵn** để đọc cho nhanh.
> *Ví dụ điển hình:* Lưu sẵn cột `tong_tien` ngay trong bảng `orders` (thay vì mỗi lần hiển thị danh sách đơn hàng lại phải `JOIN` sang bảng `order_items` để cộng tiền từng món).

---

# Phần 2: PostgreSQL 16 & Môi Trường Làm Việc

## 2.1 Cấu trúc phân cấp logic: Cluster -> Database -> Schema -> Table

Người mới làm quen với PostgreSQL rất dễ nhầm lẫn giữa **Database** và **Schema**. Để dễ hình dung nhất, hãy liên tưởng tới mô hình **một tòa nhà văn phòng** gồm 4 cấp từ lớn đến nhỏ:

```mermaid
graph TD
    Cluster["1. Cluster (Cả tòa nhà)\nMáy chủ PostgreSQL chạy ở cổng 5432"]
    Cluster --> DB1["2. Database: appdb\n(Công ty A - Ứng dụng bán hàng)"]
    Cluster --> DB2["2. Database: analytics_db\n(Công ty B - Hệ thống báo cáo)"]
    
    DB1 --> S1["3. Schema: public\n(Thư mục mặc định)"]
    DB1 --> S2["3. Schema: sales\n(Thư mục đơn hàng)"]
    DB1 --> S3["3. Schema: inventory\n(Thư mục kho bãi)"]
    
    S1 --> T1["4. Table: users"]
    S2 --> T2["4. Table: orders"]
    S2 --> T3["4. Table: order_items"]
    S3 --> T4["4. Table: products"]
```

1. **Cluster (Cả tòa nhà — Máy chủ PostgreSQL):**
   - Là phần mềm máy chủ PostgreSQL đang chạy trên máy tính (mặc định lắng nghe ở cổng `5432`). Một Cluster có thể quản lý nhiều Database cùng lúc.
2. **Database (Từng công ty riêng biệt trong tòa nhà):**
   - Mỗi dự án hoặc phần mềm sẽ tạo một Database riêng (ví dụ: `appdb`).
   - **Đặc điểm quan trọng:** Các Database trong PostgreSQL **cách ly hoàn toàn với nhau**. Khi bạn kết nối vào `appdb`, bạn chỉ nhìn thấy dữ liệu của `appdb`, không thể viết câu lệnh `JOIN` trực tiếp sang bảng của `analytics_db`.
3. **Schema (Các phòng ban / Thư mục phân loại bên trong một Database):**
   - Bên trong một Database lớn có thể có tới hàng trăm bảng. Thay vì để tất cả bảng lẫn lộn một chỗ, PostgreSQL cho phép tạo các **Schema** (giống như tạo các **thư mục con**) để gom nhóm bảng theo từng mảng công việc: `sales.orders` (bảng `orders` nằm trong thư mục `sales`), `inventory.products` (bảng `products` nằm trong thư mục `inventory`).
   - **Lưu ý cho người mới:** Mỗi Database khi mới tạo ra đều có sẵn một thư mục mặc định tên là **`public`**. Khi bạn gõ `CREATE TABLE users (...)` mà không ghi tên schema ở trước, bảng `users` sẽ tự động được đặt vào trong schema `public`.
4. **Table (Các bảng dữ liệu cụ thể):**
   - Là nơi thực sự chứa các hàng và cột dữ liệu, nằm bên trong từng Schema.

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

### 1. Chuỗi kết nối (Connection String / URI) là gì?

Khi bạn viết code ứng dụng (bằng Python, Node.js, C++/Qt, Java, Go...), chương trình cần một **"địa chỉ đầy đủ"** để biết phải tìm máy chủ PostgreSQL ở đâu, vào Database nào và đăng nhập bằng tài khoản gì. Toàn bộ thông tin đó thường được gom gọn vào 1 dòng chữ theo chuẩn URI:

```text
postgresql://admin:SecretPassword123!@127.0.0.1:5432/appdb?sslmode=disable
|________|   |___| |________________| |_______| |__| |___| |_____________|
    |          |           |              |       |    |          |
Giao thức   Tài khoản   Mật khẩu       Địa chỉ  Cổng Tên DB   Tùy chọn mã hóa
                                       máy chủ                đường truyền
```

- **`postgresql://`**: Báo cho thư viện lập trình biết đây là kết nối tới hệ CSDL PostgreSQL.
- **`admin:SecretPassword123!`**: Tên đăng nhập và mật khẩu (ngăn cách nhau bởi dấu `:`).
- **`@127.0.0.1:5432`**: Địa chỉ IP của máy chủ chạy PostgreSQL (`127.0.0.1` hoặc `localhost` là ngay trên máy tính hiện tại) và cổng kết nối (`5432` là cổng mặc định của PostgreSQL).
- **`/appdb`**: Tên Database cụ thể muốn mở ra làm việc.
- **`?sslmode=disable`**: Tắt mã hóa đường truyền SSL khi chỉ chạy thử nghiệm trên máy cá nhân. *(Khi triển khai lên máy chủ thật qua mạng Internet, người ta sẽ đổi thành `sslmode=require` để chống nghe lén dữ liệu trên đường truyền).*

### 2. Tại sao nên dùng Biến môi trường (Environment Variables)?

Khi làm dự án thực tế, **không bao giờ nên viết trực tiếp mật khẩu Database vào trong file code** (vì khi chia sẻ code hoặc đẩy lên GitHub người khác sẽ thấy mật khẩu). Thay vào đó, người ta đặt thông tin kết nối vào các **biến môi trường** của hệ thống (hoặc lưu trong file `.env` riêng):

| Tên biến chuẩn của PostgreSQL | Giá trị ví dụ | Ý nghĩa |
| :--- | :--- | :--- |
| **`PGHOST`** | `127.0.0.1` | Địa chỉ máy chủ chạy PostgreSQL |
| **`PGPORT`** | `5432` | Cổng kết nối (mặc định là `5432`) |
| **`PGDATABASE`** | `appdb` | Tên Database cần kết nối vào |
| **`PGUSER`** | `admin` | Tên tài khoản đăng nhập |
| **`PGPASSWORD`** | `SecretPassword123!` | Mật khẩu của tài khoản |

*(Hầu hết các công cụ và thư viện kết nối PostgreSQL đều tự động đọc 5 biến môi trường chuẩn này nếu bạn không truyền chuỗi URI trực tiếp).*

---

## 2.4 Bảng lệnh tắt psql (CLI Cheat Sheet)

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

# Phần 3: Bảng Tra Cứu Các Câu Lệnh Truy Vấn SQL

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

## 4.2 MVCC: Multi-Version Concurrency Control

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

Khi có nhiều người cùng đọc và sửa dữ liệu vào cùng một thời điểm, nếu không có quy tắc kiểm soát thì người đang đọc báo cáo có thể nhìn thấy số liệu bị nhảy loạn xạ.

### 1. Ba tình huống "đọc lệch dữ liệu" khi nhiều người truy cập cùng lúc

1. **Đọc phải dữ liệu chưa chốt (`Dirty Read` - Đọc rác):**
   - *Tình huống:* Giao dịch A vừa sửa số dư tài khoản từ `10 triệu` lên `50 triệu` nhưng **chưa bấm `COMMIT`** (và ngay sau đó A bị lỗi nên `ROLLBACK` hủy bỏ về lại `10 triệu`). Nếu trong lúc A chưa `COMMIT` mà Giao dịch B vào xem lại nhìn thấy con số `50 triệu` ảo kia thì B đã đọc phải dữ liệu sai.
   - *Trong PostgreSQL:* Bạn hoàn toàn yên tâm vì **PostgreSQL chặn 100% lỗi này ở mọi chế độ** — dữ liệu nào chưa `COMMIT` thì không ai bên ngoài được phép nhìn thấy.
2. **Đọc lại cùng 1 dòng nhưng số liệu bị nhảy (`Non-repeatable Read`):**
   - *Tình huống:* Trong cùng một giao dịch `BEGIN ... COMMIT` của bạn, bạn chạy câu lệnh xem giá sản phẩm X lần thứ nhất thấy `100.000đ`. Ngay lúc đó có người khác ở ngoài sửa giá sản phẩm X thành `150.000đ` và `COMMIT` xong. Bạn chạy lại câu lệnh xem giá sản phẩm X lần thứ hai (vẫn trong giao dịch cũ của bạn) thì lại thấy giá nhảy thành `150.000đ`.
3. **Đếm lại số dòng thì thấy thừa/thiếu dòng mới (`Phantom Read` - Dòng ma):**
   - *Tình huống:* Giống như trên, nhưng thay vì người khác sửa 1 dòng cũ (`UPDATE`), họ lại **thêm một dòng mới (`INSERT`)** hoặc xóa dòng (`DELETE`) và `COMMIT`. Kết quả là trong cùng một giao dịch, câu lệnh đếm lần 1 của bạn ra `100 đơn hàng`, nhưng đếm lại lần 2 ở cuối giao dịch lại ra `101 đơn hàng`.

---

### 2. Ba mức cô lập trong PostgreSQL — Khi nào dùng mức nào?

PostgreSQL cho phép bạn chọn mức độ "đóng cửa tách biệt" (gọi là **Isolation Level**) cho giao dịch của mình tùy theo nhu cầu:

| Mức cô lập | Cách hoạt động dễ hiểu | Khi nào nên dùng? |
| :--- | :--- | :--- |
| **`READ COMMITTED`**<br>*(Mặc định)* | Mỗi câu lệnh `SELECT` sẽ nhìn thấy dữ liệu mới nhất đã được người khác `COMMIT` ngay trước lúc câu `SELECT` đó chạy. *(Do đó nếu trong 1 giao dịch bạn chạy 2 câu `SELECT` cách nhau vài giây, kết quả có thể khác nhau nếu ở giữa có người vừa `COMMIT`)*. | Dùng cho **hầu hết các thao tác thông thường (95% trường hợp)** vì tốc độ nhanh nhất và không bị nghẽn. |
| **`REPEATABLE READ`** | Ngay tại câu lệnh đầu tiên của giao dịch, PostgreSQL **chụp lại một bản dữ liệu cố định** cho riêng bạn. Từ đó cho tới khi bạn `COMMIT`, dù bên ngoài có ai sửa giá hay thêm đơn hàng mới, bạn đọc lại bao nhiêu lần vẫn ra kết quả khớp 100% như lúc ban đầu. | Dùng khi cần chạy **báo cáo thống kê, đối soát số liệu** gồm nhiều câu lệnh `SELECT` liên tiếp và cần các con số không bị nhảy giữa chừng. |
| **`SERIALIZABLE`**<br>*(Nghiêm ngặt nhất)* | Kiểm soát chặt đến mức dù nhiều giao dịch chạy song song cùng lúc, kết quả cuối cùng bắt buộc phải giống hệt như khi xếp hàng chạy lần lượt từng giao dịch một. *(Nếu 2 giao dịch làm ảnh hưởng chéo kết quả của nhau, PostgreSQL sẽ hủy 1 bên để ứng dụng tự chạy lại)*. | Chỉ dùng cho các nghiệp vụ tài chính, kế toán đặc biệt khắt khe vì tốc độ chậm hơn và code ứng dụng phải viết thêm phần tự thử lại (retry). |

```sql
-- Khi cần chạy báo cáo đối soát cố định số liệu, bật mức REPEATABLE READ như sau:
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT sum(amount) FROM orders; -- Lần 1: ra 50.000.000
-- (Dù lúc này ở ngoài có người vừa thêm đơn hàng mới và COMMIT...)
SELECT sum(amount) FROM orders; -- Lần 2: vẫn đảm bảo ra đúng 50.000.000!
COMMIT;
```

---

## 4.4 Cơ chế Khóa hàng: FOR UPDATE & FOR UPDATE SKIP LOCKED

### 1. Bài toán thực tế: Tại sao dễ bị "bán âm kho" khi có nhiều người cùng mua?

Giả sử trong kho chỉ còn **đúng 1 chiếc áo cuối cùng** (`stock = 1`). Hai khách hàng **A** và **B** cùng bấm nút "Mua hàng" vào đúng một thời điểm:

```text
Nếu chỉ dùng SELECT bình thường (Không khóa dòng):
- Giây thứ 1: Khách A kiểm tra kho -> SELECT stock thấy bằng 1 (Còn hàng!)
- Giây thứ 1: Khách B cũng kiểm tra kho -> SELECT stock cũng thấy bằng 1 (Còn hàng!)
- Giây thứ 2: Hệ thống trừ kho cho Khách A -> stock giảm từ 1 xuống 0.
- Giây thứ 2: Hệ thống trừ kho tiếp cho Khách B -> stock giảm từ 0 xuống -1 (LỖI: Bán 2 đơn nhưng chỉ có 1 áo!).
```

---

### 2. Giải pháp 1: Khóa giữ chỗ dòng dữ liệu với `FOR UPDATE` (Người đến sau phải chờ)

Khi bạn gắn thêm từ khóa **`FOR UPDATE`** vào cuối câu lệnh `SELECT`, PostgreSQL sẽ **khóa tạm thời dòng dữ liệu đó lại** cho riêng giao dịch của bạn:
- Người nào chạy `SELECT ... FOR UPDATE` trước sẽ giữ quyền sửa dòng đó.
- Người thứ hai cũng chạy `SELECT ... FOR UPDATE` (hoặc `UPDATE`) vào đúng dòng đó sẽ **bị dừng lại đứng chờ** cho tới khi người thứ nhất `COMMIT` (hoặc `ROLLBACK`) xong.

```sql
BEGIN;

-- Bước 1: Đọc số lượng tồn kho VÀ khóa ngay dòng sản phẩm id = 100 lại
-- (Nếu có người thứ 2 cùng mua sản phẩm id = 100 lúc này, người thứ 2 sẽ phải đứng chờ ở dòng lệnh này)
SELECT id, stock FROM products
WHERE id = 100
FOR UPDATE;

-- Bước 2: Sau khi ứng dụng kiểm tra thấy stock >= 1 thì tiến hành trừ kho:
UPDATE products SET stock = stock - 1 WHERE id = 100;

-- Bước 3: Lưu giao dịch và mở khóa dòng id = 100
-- (Lúc này người thứ 2 mới đọc được dòng id = 100 với stock đã về 0 -> Báo hết hàng an toàn!)
COMMIT;
```

---

### 3. Giải pháp 2: Bỏ qua dòng đang bị khóa với `FOR UPDATE SKIP LOCKED` (Không phải chờ)

**Tình huống:** Giả sử bạn có một bảng `task_queue` chứa **100 email đang chờ gửi** (`status = 'pending'`), và bạn chạy **5 tiến trình (workers)** cùng vào bảng này lấy email ra để gửi cho nhanh.
- Nếu dùng `FOR UPDATE` thông thường: Cả 5 tiến trình cùng nhìn vào dòng email số 1 -> Tiến trình 1 khóa được dòng số 1 để gửi, còn 4 tiến trình kia lại phải đứng chờ ở dòng số 1 mà không chịu đi lấy dòng số 2, số 3!
- Khi thêm **`SKIP LOCKED`**: Tiến trình nào thấy dòng số 1 đang bị người khác khóa rồi sẽ **tự động bỏ qua dòng đó ngay lập tức để lấy dòng kế tiếp chưa bị ai khóa** (dòng số 2, số 3...). Nhờ vậy cả 5 tiến trình đều làm việc liên tục mà không bao giờ phải đứng đợi nhau.

```sql
BEGIN;

-- Tìm 1 công việc đang chờ ('pending'), nếu dòng nào đang bị tiến trình khác khóa thì bỏ qua luôn (SKIP LOCKED):
SELECT id, payload FROM task_queue
WHERE status = 'pending'
ORDER BY id ASC
LIMIT 1
FOR UPDATE SKIP LOCKED;

-- Sau khi xử lý xong công việc đó thì cập nhật trạng thái thành 'completed':
UPDATE task_queue SET status = 'completed' WHERE id = :id;

COMMIT;
```

---


# Phần 5: Tối Ưu Hóa Truy Vấn (Query Optimization)

Đọc dữ liệu từ **ổ cứng** luôn chậm hơn rất nhiều so với đọc từ **bộ nhớ RAM**. Vì vậy, mục tiêu chính của việc tối ưu hóa truy vấn là **giúp PostgreSQL tìm đúng dữ liệu cần lấy mà không phải đọc toàn bộ bảng từ ổ cứng**.

---

## 5.1 Chỉ mục (Index) là gì và tại sao giúp tìm dữ liệu nhanh?

### 1. Hình dung đơn giản: Lật từng trang sách vs Tra mục lục

Giả sử bảng `users` của bạn có **10 triệu dòng** và bạn muốn tìm khách hàng có `id = 85`:

- **Khi KHÔNG có Index (`Seq Scan` - Quét tuần tự từ đầu đến cuối):**
  - Giống như bạn cầm một cuốn sách dày không có mục lục, buộc phải **đọc lần lượt từ dòng số 1, số 2, số 3...** cho đến hết 10 triệu dòng để tìm dòng có `id = 85`. Bảng càng nhiều dòng thì tìm càng lâu.
- **Khi CÓ Index (`B-Tree Index` - Cây mục lục đã sắp xếp):**
  - Khi bạn đánh Index lên cột `id`, PostgreSQL sẽ tạo ra một **cây mục lục được sắp xếp sẵn theo thứ tự lớn nhỏ**.
  - Hãy nhìn cách PostgreSQL tìm ra số **`85`** chỉ sau **3 bước rẽ nhánh** trên sơ đồ dưới đây:

```mermaid
graph TD
    Root["Bước 1 - So sánh tại Gốc: [50]\n(Vì 85 > 50 nên rẽ sang nhánh phải)"] --> Left["Nhánh nhỏ hơn 50: [20]"]
    Root --> Right["Bước 2 - So sánh tại Nhánh phải: [80]\n(Vì 85 > 80 nên rẽ tiếp sang phải)"]
    Left --> Leaf1["[10, 15] -> Nằm ở trang 1"]
    Left --> Leaf2["[25, 30] -> Nằm ở trang 4"]
    Right --> Leaf3["[60, 70] -> Nằm ở trang 9"]
    Right --> Leaf4["Bước 3 - Thấy [85]!\n-> Nhảy thẳng tới trang 12 của bảng để lấy dòng"]
```

Nhờ cách chia nhánh lớn/nhỏ như vậy, thay vì phải kiểm tra 10 triệu dòng, PostgreSQL chỉ mất **3 đến 4 bước so sánh** là nhảy thẳng tới đúng vị trí dòng cần lấy!

---

### 2. Ba cách PostgreSQL đọc dữ liệu từ bảng

Khi bạn chạy một câu lệnh `SELECT`, PostgreSQL sẽ tự động tính toán để chọn 1 trong 3 cách đọc sau:

| Tên cách đọc | Hình dung qua việc đọc sách | Khi nào PostgreSQL tự động chọn? | Tốc độ |
| :--- | :--- | :--- | :---: |
| **`Seq Scan`**<br>*(Quét tuần tự)* | Lật đọc từng trang sách từ trang đầu tiên đến trang cuối cùng. | Khi cột tìm kiếm chưa có Index, hoặc khi bảng rất nhỏ (vài trăm dòng), hoặc khi bạn cần lấy phần lớn số dòng trong bảng. | Chậm (khi bảng lớn) |
| **`Index Scan`**<br>*(Quét qua mục lục)* | Xem mục lục ở đầu sách để biết thông tin nằm ở trang 12, sau đó lật thẳng tới trang 12 của cuốn sách để đọc nội dung chi tiết. | Khi cột tìm kiếm đã có Index và bạn chỉ cần lọc ra một số ít dòng trong bảng lớn. | Nhanh |
| **`Index Only Scan`**<br>*(Chỉ đọc mục lục)* | Thông tin bạn cần hỏi đã được in sẵn ngay trên trang mục lục rồi -> Đọc luôn tại mục lục mà **không cần lật vào trang sách chính nữa**. | Khi tất cả các cột trong câu lệnh `SELECT` đều đã nằm sẵn bên trong Index. | Nhanh nhất |

> **Hai điều người mới cần nhớ về Index:**
> 1. Các cột làm **Khóa chính (`PRIMARY KEY`)** và cột **Duy nhất (`UNIQUE`)** đã được PostgreSQL **tự động tạo Index sẵn**, bạn không cần tạo lại.
> 2. **Tại sao không tạo Index cho tất cả mọi cột?** Vì mỗi Index là một bảng mục lục riêng. Tạo quá nhiều Index sẽ làm tốn thêm dung lượng lưu trữ, và mỗi khi bạn thêm/sửa/xóa (`INSERT / UPDATE / DELETE`) dữ liệu ở bảng chính, PostgreSQL phải mất thêm thời gian đi cập nhật lại tất cả các bảng mục lục đó. Chỉ nên tạo Index cho những cột thường xuyên xuất hiện trong điều kiện lọc `WHERE`, nối bảng `JOIN` hoặc sắp xếp `ORDER BY`.

---

## 5.2 Các loại Index thường dùng trong PostgreSQL

Trong hầu hết các trường hợp, bạn chỉ cần dùng **B-Tree Index** (loại mặc định). Dưới đây là các cách tạo Index phổ biến nhất:

| Loại Index | Khi nào nên dùng? | Câu lệnh tạo mẫu |
| :--- | :--- | :--- |
| **B-Tree (Mặc định)** | Dùng cho hầu hết nhu cầu: tìm theo `=`, `<`, `>`, `BETWEEN`, `IN`, sắp xếp `ORDER BY`, hoặc tìm đầu chuỗi `LIKE 'abc%'`. | `CREATE INDEX idx_users_email ON users(email);` |
| **Index nhiều cột (Composite)** | Khi thường xuyên lọc kết hợp 2 cột cùng lúc (ví dụ tìm đơn hàng theo `user_id` và `status`). | `CREATE INDEX idx_orders_user_status ON orders(user_id, status);` |
| **Index một phần (Partial)** | Chỉ tạo mục lục cho một nhóm dòng hay cần tìm (ví dụ chỉ các đơn hàng đang chờ xử lý `pending`), giúp tiết kiệm bộ nhớ. | `CREATE INDEX idx_orders_pending ON orders(created_at) WHERE status = 'pending';` |
| **Index theo biểu thức (Expression)** | Khi thường xuyên tìm kiếm qua hàm, ví dụ tìm tên tài khoản không phân biệt chữ HOA / chữ thường. | `CREATE INDEX idx_users_lower_email ON users(lower(email));`<br>Khi tìm: `WHERE lower(email) = 'abc@gmail.com'` |
| **GIN Index** | Dùng riêng khi cần tìm kiếm bên trong cột dữ liệu dạng **`JSONB`** hoặc cột mảng. | `CREATE INDEX idx_logs_payload ON user_logs USING gin (payload);` |

> **Mẹo:** Hãy nhớ tạo Index cho các cột **Khóa ngoại (`FOREIGN KEY`)** (như `orders.user_id`, `products.category_id`), vì ứng dụng rất hay dùng các cột này để lọc và ghép bảng (`JOIN`).

---

## 5.3 Cách viết câu lệnh SQL chạy nhanh (Nên làm vs Nên tránh)

Dù bảng đã có Index, nếu viết câu lệnh SQL không đúng cách thì PostgreSQL vẫn không dùng được Index hoặc phải làm việc thừa.

| Tình huống | Nên tránh | Nên làm | Giải thích dễ hiểu |
| :--- | :--- | :--- | :--- |
| **Lấy cột dữ liệu** | `SELECT * FROM orders;` | `SELECT id, user_id, amount FROM orders;` | Chỉ lấy đúng cột cần dùng để tránh đọc và truyền dữ liệu thừa qua mạng. |
| **Lọc theo ngày tháng** | `WHERE date_trunc('day', created_at) = '2026-11-01'` | `WHERE created_at >= '2026-11-01' AND created_at < '2026-11-02'` | Đưa cột `created_at` vào trong hàm sẽ làm PostgreSQL không tra được mục lục (Index). Hãy giữ nguyên tên cột ở một vế và lọc theo khoảng thời gian. |
| **Tìm kiếm chuỗi (`LIKE`)** | `WHERE name LIKE '%iphone'` | `WHERE name LIKE 'iphone%'` | Mục lục sắp xếp chữ cái từ trái sang phải, nên nếu đặt dấu `%` ở đầu chuỗi thì không tra mục lục được. |
| **Tìm dữ liệu không tồn tại** | `WHERE u.id NOT IN (SELECT user_id FROM orders)` | `WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id)` | Nếu danh sách bên trong `NOT IN` có chứa dù chỉ 1 giá trị `NULL`, kết quả trả về sẽ bị rỗng. Dùng `NOT EXISTS` vừa tránh được lỗi này vừa chạy nhanh hơn. |
| **Phân trang khi bảng rất lớn** | `SELECT id, amount FROM orders ORDER BY id LIMIT 20 OFFSET 500000;` | `SELECT id, amount FROM orders WHERE id > 500000 ORDER BY id LIMIT 20;` | `OFFSET 500000` bắt DB phải đếm qua 500.000 dòng đầu rồi bỏ đi. Dùng `WHERE id > (id cuối trang trước)` giúp nhảy thẳng đến trang tiếp theo ngay lập tức. |
| **Thêm nhiều dòng cùng lúc** | Chạy vòng lặp gọi 1.000 lệnh `INSERT` rời rạc | `INSERT INTO categories (name) VALUES ('Laptop'), ('Chuột'), ('Bàn phím');` | Gộp nhiều dòng vào chung một câu lệnh `INSERT` giúp giảm thời gian gửi nhận giữa ứng dụng và Database. |

---

## 5.4 Dọn rác dữ liệu với VACUUM & Autovacuum

### 1. Vì sao trong PostgreSQL lại có "dữ liệu rác"?
- Như đã biết ở mục **4.2 (MVCC)**, khi bạn sửa (`UPDATE`) hoặc xóa (`DELETE`) một dòng, PostgreSQL không xóa hẳn dòng cũ ngay lập tức mà chỉ đánh dấu nó là **dòng cũ đã bỏ (Dead Tuple)**.
- Nếu sửa/xóa nhiều lần mà không dọn, bảng sẽ chứa đầy các dòng cũ không còn dùng nữa, làm file dữ liệu phình to và câu lệnh tìm kiếm chạy chậm dần.

### 2. Các lệnh dọn dẹp dữ liệu

| Lệnh | Tác dụng dễ hiểu | Có làm gián đoạn ứng dụng không? |
| :--- | :--- | :--- |
| **`VACUUM ten_bang;`** | Thu hồi chỗ trống của các dòng cũ đã xóa để **dùng lại cho các dòng mới** thêm vào sau này. | **Không** (Ứng dụng vẫn đọc/ghi bình thường). |
| **`ANALYZE ten_bang;`** | Cập nhật lại số liệu thống kê của bảng để PostgreSQL biết cách chọn Index tốt nhất. *(Thường gộp chung: `VACUUM ANALYZE ten_bang;`)*. | **Không** |
| **`VACUUM FULL ten_bang;`** | Viết lại toàn bộ bảng sang một file mới tinh để **giảm dung lượng file trên ổ cứng**. | **Có** (Khóa cứng bảng, ứng dụng không đọc/ghi được trong lúc chạy). |

### 3. Tiến trình tự động Autovacuum
- Bạn **không cần** phải chạy lệnh `VACUUM` thủ công vì PostgreSQL đã bật sẵn chế độ **Autovacuum** chạy ngầm: cứ khi nào bảng có nhiều dòng bị sửa/xóa, nó sẽ tự động vào dọn rác và cập nhật thống kê.
- **Lưu ý quan trọng:** Luôn để Autovacuum bật theo mặc định, không nên tắt.

---

# Phần 6: Cách PostgreSQL Lưu Dữ Liệu & Bảo Mật Cơ Bản

## 6.1 Cách PostgreSQL xử lý truy vấn và chống mất dữ liệu (WAL)

### 1. Vì sao PostgreSQL phải kết hợp cả RAM và Ổ cứng?

Trong máy tính có 2 nơi lưu trữ với đặc tính trái ngược nhau:
- **Bộ nhớ RAM:** Đọc và sửa dữ liệu **cực kỳ nhanh**, nhưng có nhược điểm là **mất điện thì toàn bộ dữ liệu trên RAM sẽ biến mất**.
- **Ổ cứng (SSD/HDD):** Dữ liệu lưu xuống ổ cứng sẽ **còn mãi dù tắt máy hay mất điện**, nhưng tốc độ đọc/ghi lại **chậm hơn RAM rất nhiều**.

Do đó, nếu mỗi lần sửa một dòng dữ liệu mà PostgreSQL đều phải mở các file bảng lớn trên ổ cứng ra tìm đúng chỗ để ghi đè ngay, hệ thống sẽ rất chậm. Để vừa **nhanh như RAM** vừa **an toàn như ổ cứng**, PostgreSQL sử dụng cơ chế **Sổ nhật ký ghi trước (`WAL` - Write-Ahead Logging)**.

```mermaid
flowchart TD
    Client["Ứng dụng"] -->|"Gửi câu lệnh SQL (Cổng 5432)"| BE["Tiến trình xử lý\n(Backend Process)"]

    subgraph RAM ["1. Bộ nhớ RAM (Tốc độ rất nhanh)"]
        SB["Bộ nhớ đệm dữ liệu\n(Shared Buffers)"]
    end

    subgraph Disk ["2. Ổ cứng (Không mất khi tắt máy)"]
        WAL[("Sổ nhật ký WAL\n(Thư mục pg_wal/)")]
        DATA[("File dữ liệu bảng & Index\n(Thư mục base/)")]
    end

    BE <-->|"Bước 1: Đọc & sửa ngay trên RAM"| SB
    BE -->|"Bước 2: Ghi 1 dòng vào cuối sổ WAL khi COMMIT"| WAL
    SB -->|"Bước 3: Lúc rảnh mới gom dữ liệu lưu xuống file bảng"| DATA
```

---

### 2. Hình dung dễ hiểu: Cơ chế "Cuốn sổ nhật ký" (`WAL`) hoạt động ra sao?

Hãy tưởng tượng một kho hàng có **100 kệ hàng lớn ở khắp kho** (tương ứng với **các file bảng dữ liệu & Index trên ổ cứng**) và **1 cuốn sổ nhật ký đặt ngay bàn thu ngân** (tương ứng với **file nhật ký `WAL`**).

Khi ứng dụng chạy lệnh trừ tiền và chốt giao dịch (`COMMIT`):
```sql
UPDATE accounts SET balance = balance - 500 WHERE id = 10;
COMMIT;
```

PostgreSQL thực hiện theo 3 bước rất thông minh:
1. **Bước 1 — Sửa trên RAM trước:** PostgreSQL đưa thông tin tài khoản `id = 10` lên bộ nhớ RAM (`Shared Buffers`) và trừ `500` ngay trên RAM.
2. **Bước 2 — Ghi vào cuối cuốn sổ nhật ký `WAL` trên ổ cứng:** Khi gặp lệnh `COMMIT`, thay vì phải chạy đi tìm các file bảng và file Index trên ổ cứng để sửa từng chỗ, PostgreSQL chỉ cần **ghi nối tiếp 1 dòng ngắn gọn vào cuối file nhật ký `WAL`** trên ổ cứng: *"Tài khoản id=10 vừa giảm 500"*.
   - **Ngay khi dòng nhật ký này được lưu xong xuống ổ cứng, PostgreSQL lập tức báo cho ứng dụng: "COMMIT thành công!"** *(Lúc này file bảng dữ liệu chính trên ổ cứng thực chất vẫn chưa được cập nhật).*
3. **Bước 3 — Định kỳ cập nhật vào file bảng chính sau:** Cứ định kỳ ít phút một lần, tiến trình chạy ngầm của PostgreSQL mới gom nhiều thay đổi đang nằm trên RAM để đi cập nhật một lượt xuống các file bảng chính (`base/`).

> **Tại sao cách làm này giải quyết được cả Tốc độ lẫn Độ an toàn?**
> - **Tại sao NHANH?** Vì ghi nối tiếp một dòng chữ vào cuối cuốn sổ nhật ký (`WAL`) nhanh hơn rất nhiều so với việc phải mở hàng chục file bảng và file Index ở nhiều vị trí khác nhau trên ổ cứng ra sửa trực tiếp.
> - **Tại sao MẤT ĐIỆN KHÔNG MẤT DỮ LIỆU?** Giả sử vừa xong Bước 2 (đã báo `COMMIT` thành công cho khách) thì máy chủ bị mất điện đột ngột: dữ liệu mới trên RAM bị mất sạch và Bước 3 chưa kịp chạy để lưu vào bảng chính. Khi có điện trở lại, PostgreSQL chỉ cần **mở cuốn sổ nhật ký `WAL` trên ổ cứng ra đọc lại những dòng cuối** rồi cập nhật bù vào bảng chính -> **Khôi phục nguyên vẹn 100% những gì đã `COMMIT`!**

---

## 6.2 Bảo mật cơ bản: Phân quyền, Mật khẩu

Khi làm ứng dụng thực tế kết nối với PostgreSQL, có 2 nguyên tắc bảo mật cơ bản nhất mà người mới cần nắm vững:

### 1. Phân quyền tài khoản (Không dùng tài khoản quản trị cao nhất cho ứng dụng)

Khi mới cài PostgreSQL, bạn luôn có một tài khoản quản trị cao nhất (thường là `postgres` hoặc `admin`). Tài khoản này có toàn quyền, kể cả quyền xóa sạch bảng (`DROP TABLE`) hay xóa cả Database.

- **Sai lầm thường gặp của người mới:** Đưa luôn tài khoản `admin` này vào trong code ứng dụng hoặc đưa cho người khác vào xem dữ liệu. Nếu ai đó gõ nhầm lệnh xóa bảng, hoặc kẻ xấu tấn công được vào ứng dụng, toàn bộ Database sẽ bị phá hủy.
- **Cách làm đúng:** Trong PostgreSQL, cả **"nhóm quyền"** và **"tài khoản đăng nhập"** đều được tạo bằng khái niệm **`ROLE`** (lệnh `CREATE USER` thực chất chỉ là tạo một `ROLE` có quyền đăng nhập). Ta sẽ tạo từng nhóm quyền vừa đủ dùng rồi gán cho từng tài khoản:

```mermaid
flowchart LR
    U1["Tài khoản xem báo cáo\n(bi_analyst)"] -->|"Gán vào nhóm"| R1["Nhóm chỉ xem (role_readonly)\nChỉ được chạy lệnh SELECT"]
    U2["Tài khoản của ứng dụng\n(app_backend)"] -->|"Gán vào nhóm"| R2["Nhóm đọc & ghi (role_readwrite)\nĐược SELECT, INSERT, UPDATE, DELETE\n(Không được xóa bảng DROP TABLE)"]
```

Cách viết lệnh SQL để phân quyền (kèm giải thích từng dòng):

```sql
-- =========================================================
-- PHẦN 1: TẠO NHÓM QUYỀN "CHỈ ĐỌC" (role_readonly)
-- =========================================================
CREATE ROLE role_readonly;
-- 1. Cho phép bước qua cổng kết nối vào database 'appdb':
GRANT CONNECT ON DATABASE appdb TO role_readonly;
-- 2. Cho phép mở thư mục (schema) 'public':
GRANT USAGE ON SCHEMA public TO role_readonly;
-- 3. Chỉ cho phép đọc (SELECT) dữ liệu của các bảng trong 'public':
GRANT SELECT ON ALL TABLES IN SCHEMA public TO role_readonly;


-- =========================================================
-- PHẦN 2: TẠO NHÓM QUYỀN "ĐỌC & GHI" CHO ỨNG DỤNG (role_readwrite)
-- =========================================================
CREATE ROLE role_readwrite;
GRANT CONNECT ON DATABASE appdb TO role_readwrite;
GRANT USAGE ON SCHEMA public TO role_readwrite;
-- Cho phép Đọc, Thêm, Sửa, Xóa dòng dữ liệu (nhưng KHÔNG có quyền DROP hay ALTER bảng):
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO role_readwrite;
-- Cho phép dùng bộ đếm số tự động (SEQUENCE) để các cột ID tự tăng hoạt động khi INSERT:
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO role_readwrite;


-- =========================================================
-- PHẦN 3: TẠO TÀI KHOẢN ĐĂNG NHẬP VÀ GÁN VÀO NHÓM
-- =========================================================
CREATE USER bi_analyst WITH PASSWORD 'MatKhauBaoCao_123!';
GRANT role_readonly TO bi_analyst;   -- Tài khoản này chỉ xem được dữ liệu

CREATE USER app_backend WITH PASSWORD 'MatKhauUngDung_123!';
GRANT role_readwrite TO app_backend; -- Tài khoản này dùng để lắp vào code ứng dụng
```

---

### 2. Băm mật khẩu người dùng với `pgcrypto` (`bcrypt`)

Khi làm chức năng Đăng ký / Đăng nhập cho người dùng của ứng dụng, bạn cần lưu mật khẩu của họ vào bảng (ví dụ bảng `accounts`):

- **Nguyên tắc 1 — Không lưu mật khẩu dạng chữ rõ (Plaintext):** Nếu bạn lưu thẳng chuỗi `'MatKhau123'` vào cột, bất kỳ ai xem được bảng dữ liệu đều biết hết mật khẩu của khách hàng.
- **Nguyên tắc 2 — Dùng hàm "Băm một chiều" (`Hash`) có trộn "Muối" (`Salt`):**
  - **Băm một chiều (Hash) là gì?** Là biến mật khẩu gốc `'MatKhau123'` thành một chuỗi ký tự dài không có quy luật (ví dụ `'$2a$10$N9qo8uLOickgx2ZMRZoMye...'`). Điểm cốt lõi là **chỉ có thể biến đổi 1 chiều từ mật khẩu -> chuỗi băm, hoàn toàn không có công thức nào dịch ngược từ chuỗi băm về lại mật khẩu gốc**.
  - **Trộn muối (Salt) là gì?** Nếu hai người dùng cùng đặt mật khẩu dễ đoán là `'123456'` mà băm thông thường (như `MD5` hay `SHA256`) thì sẽ ra 2 chuỗi băm giống hệt nhau (kẻ xấu rất dễ dò ra). Thuật toán **`bcrypt`** sẽ tự động tạo thêm một chuỗi ngẫu nhiên (gọi là **muối - salt**) trộn vào mật khẩu trước khi băm -> nhờ đó 2 người cùng đặt mật khẩu `'123456'` vẫn tạo ra **2 chuỗi băm hoàn toàn khác nhau**!
  - **Vậy khi đăng nhập thì kiểm tra bằng cách nào?** Vì không thể dịch ngược chuỗi băm, nên khi người dùng gõ mật khẩu đăng nhập, hệ thống sẽ **đem mật khẩu người dùng vừa gõ đi băm lại một lần nữa** (với cùng hạt muối đó). Nếu kết quả băm mới **trùng khớp 100%** với chuỗi băm đang lưu trong bảng thì chứng tỏ người dùng nhập đúng mật khẩu!

Trong PostgreSQL, công cụ có sẵn **`pgcrypto`** giúp bạn thực hiện toàn bộ quy trình `bcrypt` này chỉ với 2 hàm `gen_salt()` và `crypt()`:

```sql
-- Bước 0: Bật công cụ pgcrypto (chỉ cần chạy 1 lần trên Database)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Tạo bảng tài khoản người dùng của ứng dụng:
CREATE TABLE accounts (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username varchar(50) NOT NULL UNIQUE,
    password_hash text NOT NULL,
    created_at timestamptz DEFAULT now()
);

-- =========================================================
-- 1. KHI NGƯỜI DÙNG ĐĂNG KÝ TÀI KHOẢN MỚI:
-- =========================================================
-- gen_salt('bf', 10): Tự sinh chuỗi muối (salt) ngẫu nhiên theo chuẩn Blowfish (bcrypt) với độ khó = 10
-- crypt('MatKhau123!@#', ...): Trộn mật khẩu với muối rồi băm thành chuỗi password_hash
INSERT INTO accounts (username, password_hash)
VALUES ('phongvt', crypt('MatKhau123!@#', gen_salt('bf', 10)));


-- =========================================================
-- 2. KHI NGƯỜI DÙNG ĐĂNG NHẬP:
-- =========================================================
-- Truyền mật khẩu người dùng vừa nhập VÀ cột password_hash đang lưu vào hàm crypt().
-- Hàm crypt() sẽ lấy lại đúng hạt muối nằm trong password_hash để băm mật khẩu vừa nhập rồi so sánh:
SELECT id, username
FROM accounts
WHERE username = 'phongvt'
  AND password_hash = crypt('MatKhau123!@#', password_hash);

-- Kết quả:
-- - Nếu nhập ĐÚNG mật khẩu: Điều kiện bằng nhau -> Trả về 1 dòng (id, username) -> Cho phép đăng nhập!
-- - Nếu nhập SAI mật khẩu : Chuỗi băm khác nhau -> Trả về 0 dòng (rỗng)        -> Báo sai mật khẩu!
```

