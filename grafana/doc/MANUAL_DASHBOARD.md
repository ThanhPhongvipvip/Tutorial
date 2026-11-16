# Hướng Dẫn Tạo Thủ Công Dashboard Grafana (Không Dùng File JSON)

Tài liệu này hướng dẫn chi tiết từ đầu cách **tự tạo Dashboard mới hoàn toàn trên giao diện Web UI của Grafana** (thay vì import [`monitoring-dashboard.json`](../Script/May_A/monitoring-dashboard.json)), đồng thời **giải thích sâu cơ chế dữ liệu và từng dòng query (Flux & SQL)** để bạn hiểu bản chất và có thể tự thiết kế thêm các biểu đồ hoặc dashboard mới theo nhu cầu.

---

## Mục Lục

- [1. Điều Kiện Tiên Quyết & Chuẩn Bị Hệ Thống](#1-điều-kiện-tiên-quyết--chuẩn-bị-hệ-thống)
- [2. Tạo Thủ Công Data Sources Trên Grafana](#2-tạo-thủ-công-data-sources-trên-grafana)
- [3. Hiểu Mô Hình Dữ Liệu & Cách Viết Query Trước Khi Tạo Dashboard](#3-hiểu-mô-hình-dữ-liệu--cách-viết-query-trước-khi-tạo-dashboard)
  - [3.1. Dữ liệu từ Telegraf được lưu vào InfluxDB như thế nào?](#31-dữ-liệu-từ-telegraf-được-lưu-vào-influxdb-như-thế-nào)
  - [3.2. Cấu trúc một câu Flux Query chuẩn (tư duy đường ống `|>`)](#32-cấu-trúc-một-câu-flux-query-chuẩn-tư-duy-đường-ống-)
  - [3.3. Cách biến Grafana (`${var}`) hoạt động trong Query](#33-cách-biến-grafana-var-hoạt-động-trong-query)
  - [3.4. Cách tự tra cứu Measurement / Tag / Field bằng Grafana Explore](#34-cách-tự-tra-cứu-measurement--tag--field-bằng-grafana-explore)
  - [3.5. Cấu trúc bảng PostgreSQL Catalog dùng cho ERD](#35-cấu-trúc-bảng-postgresql-catalog-dùng-cho-erd)
- [4. Tạo Dashboard Mới & Cấu Hình Chung](#4-tạo-dashboard-mới--cấu-hình-chung)
- [5. Tạo Các Biến Động (Dashboard Variables)](#5-tạo-các-biến-động-dashboard-variables)
- [6. Tạo Từng Nhóm Panel & Giải Thích Chi Tiết Query](#6-tạo-từng-nhóm-panel--giải-thích-chi-tiết-query)
  - [6.1. Nhóm KPI Tổng Quan](#61-nhóm-kpi-tổng-quan)
  - [6.2. Nhóm Tài Nguyên Hệ Thống (CPU, RAM, Disk, Network)](#62-nhóm-tài-nguyên-hệ-thống-cpu-ram-disk-network)
  - [6.3. Nhóm Card Đồ Họa (NVIDIA GPU)](#63-nhóm-card-đồ-họa-nvidia-gpu)
  - [6.4. Nhóm Dữ Liệu Tập Tin CSV](#64-nhóm-dữ-liệu-tập-tin-csv)
  - [6.5. Nhóm Sơ Đồ Thực Thể Quan Hệ (ERD)](#65-nhóm-sơ-đồ-thực-thể-quan-hệ-erd)
- [7. Mở Rộng: Tự Tạo Thêm Panel Mới Từ Dữ Liệu Có Sẵn](#7-mở-rộng-tự-tạo-thêm-panel-mới-từ-dữ-liệu-có-sẵn)
- [8. Lưu, Kiểm Tra & Tóm Tắt Bố Cục Lưới (Grid 24 Cột)](#8-lưu-kiểm-tra--tóm-tắt-bố-cục-lưới-grid-24-cột)

---

## 1. Điều Kiện Tiên Quyết & Chuẩn Bị Hệ Thống

Việc không dùng [`monitoring-dashboard.json`](../Script/May_A/monitoring-dashboard.json) chỉ thay thế phần **dựng giao diện Dashboard**. Toàn bộ luồng thu thập và lưu trữ dữ liệu phía sau vẫn cần đang chạy sẵn:

### 1.1. Trên Máy Chủ Trung Tâm (Máy A)
- **Grafana** đang chạy ở cổng `3000` (`http://<IP_MAY_A>:3000`, mặc định `admin` / `admin`).
- **InfluxDB 2.x** đang chạy ở cổng `8086`:
  - Organization: `monitoring`
  - Buckets: `system_metrics`, `device_csv`, `device_database`
  - Có API Token (xem trong [`configs/config.json`](../Script/May_A/configs/config.json)).
- **PostgreSQL Central Catalog** đang chạy ở cổng `5432`:
  - Database `monitoring_catalog` đã khởi tạo từ [`sql/init_central_catalog.sql`](../Script/May_A/sql/init_central_catalog.sql).
  - User đọc dữ liệu: `grafana_reader` (mật khẩu mặc định `1`).
- **ERD Viewer Microservice** đang chạy ở cổng `8088`:
  ```bash
  sudo systemctl status erd-viewer
  # Nếu chưa chạy:
  cd Script/May_A && ./setup.sh --start-erd
  ```
- **Plugin Business Charts** (`volkovlabs-echarts-panel`) *(dùng cho Panel ERD)*:
  ```bash
  sudo grafana-cli plugins install volkovlabs-echarts-panel
  sudo systemctl restart grafana-server
  ```
  *(Hoặc cài trên Web UI: **Administration → Plugins and data → Plugins** → tìm `Business Charts` → **Install**).*

### 1.2. Trên Các Máy Cần Giám Sát (Máy Con / Máy A)
- Đã cài **Telegraf Agent** theo [`SETUP.md`](SETUP.md) (`install-agent-v2.sh --config device.yaml`) để đẩy metrics hệ thống/GPU vào bucket `system_metrics` và file CSV vào bucket `device_csv`.
- Đã đồng bộ metadata PostgreSQL về Máy A bằng `python3 manage.py collect device.yaml` (hoặc cronjob `/etc/cron.d/erd-metadata-sync`).

---

## 2. Tạo Thủ Công Data Sources Trên Grafana

Đăng nhập Grafana, vào menu bên trái: **Connections → Data sources → Add data source**. Tạo lần lượt 2 nguồn dữ liệu sau:

### 2.1. Data Source 1: `InfluxDB-Monitoring`
1. Chọn loại: **InfluxDB**.
2. Cấu hình:
   - **Name**: `InfluxDB-Monitoring`
   - **Query Language**: **`Flux`** *(bắt buộc chọn **Flux**, vì mọi query phía dưới viết bằng Flux — không chọn InfluxQL)*
   - **HTTP → URL**: `http://localhost:8086` *(hoặc `http://<IP_MAY_A>:8086` nếu Grafana chạy khác máy InfluxDB)*
   - **InfluxDB Details**:
     - **Organization**: `monitoring`
     - **Token**: Token InfluxDB (tham khảo [`configs/config.json`](../Script/May_A/configs/config.json))
     - **Default Bucket**: `system_metrics`
3. Nhấn **Save & test** → hiện thông báo xanh là thành công.

### 2.2. Data Source 2: `PostgreSQL-Catalog`
1. Quay lại **Add data source** → chọn **PostgreSQL**.
2. Cấu hình:
   - **Name**: `PostgreSQL-Catalog`
   - **Connection → Host URL**: `localhost:5432`
   - **Database name**: `monitoring_catalog`
   - **Authentication → Username**: `grafana_reader`
   - **Password**: `1`
   - **TLS/SSL Mode**: `disable`
   - **PostgreSQL details → Version**: `14` *(hoặc khớp phiên bản PostgreSQL đang cài)*
3. Nhấn **Save & test** → hiện `Database Connection OK`.

---

## 3. Hiểu Mô Hình Dữ Liệu & Cách Viết Query Trước Khi Tạo Dashboard

Nếu hiểu phần này, bạn sẽ **tự đọc và tự viết lại được mọi query** thay vì chỉ chép máy móc.

### 3.1. Dữ liệu từ Telegraf được lưu vào InfluxDB như thế nào?

InfluxDB 2.x là cơ sở dữ liệu chuỗi thời gian (Time-series DB). Để dễ hình dung khi quy đổi từ SQL truyền thống:

| Khái niệm InfluxDB | Tương đương trong SQL | Trong hệ thống này là gì? |
| :--- | :--- | :--- |
| **Bucket** | Database | `system_metrics` (chứa CPU, RAM, Disk, Net, GPU, PostgreSQL...) và `device_csv` (chứa dữ liệu CSV) |
| **`_measurement`** | Tên bảng | `cpu`, `mem`, `disk`, `net`, `nvidia_smi`, `file`, `diskio`, `system`, `postgresql`... |
| **Tag** | Cột đánh chỉ mục (`WHERE`, `GROUP BY`) | `device`, `device_name`, `host`, `location`, `cpu`, `path`, `interface`, `index`, `name`, `csv_name`, `row_id`... |
| **`_field`** | Tên cột giá trị | Ví dụ trong `cpu` có `usage_user`, `usage_system`, `usage_idle`; trong `mem` có `used_percent` |
| **`_value`** | Giá trị số liệu của field đó | Ví dụ `12.5` (%), `1048576` (bytes)... |
| **`_time`** | Cột thời gian (`TIMESTAMP`) | Thời điểm Telegraf thu thập mẫu (mặc định mỗi `10s`, CSV mỗi `1m`) |

Khi `install-agent-v2.sh` cấu hình Telegraf trên máy con, nó gắn sẵn khối `[[processors.override]]` để **mọi bản ghi gửi về đều có các tag chung**:
- `device`: tên định danh máy (lấy từ `device.id` trong `device.yaml`)
- `device_name`, `location`, `host`

Và chia làm **2 luồng đầu ra (`[[outputs.influxdb_v2]]`)**:
1. Mọi measurement **khác `file`** → ghi vào bucket **`system_metrics`**.
2. Riêng measurement **`file`** (từ file CSV, đã qua Starlark processor gắn tag `csv_name` và `row_id`) → ghi vào bucket **`device_csv`**.

---

### 3.2. Cấu trúc một câu Flux Query chuẩn (tư duy đường ống `|>`)

Ngôn ngữ **Flux** xử lý dữ liệu theo từng bước nối tiếp nhau bằng toán tử ống **`|>`** (pipe — kết quả bước trước là đầu vào bước sau), tương tự lệnh pipe `|` trong Linux:

```flux
from(bucket: "system_metrics")                                     // 1. Chọn kho dữ liệu
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)         // 2. Cắt theo khung thời gian trên góc phải Grafana
  |> filter(fn: (r) => r._measurement == "mem" and r._field == "used_percent") // 3. Chọn bảng & chỉ số cần vẽ
  |> filter(fn: (r) => r.device =~ /^${device:regex}$/)            // 4. Lọc theo máy đang chọn ở dropdown
  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)      // 5. Gom mẫu theo độ rộng màn hình
  |> drop(columns: ["device", "device_name", "host", "location", "_measurement", "_start", "_stop"]) // 6. Bỏ tag thừa
  |> yield(name: "RAM")                                            // 7. Xuất kết quả đặt tên là "RAM"
```

**Ý nghĩa từng hàm quan trọng hay gặp:**
- **`v.timeRangeStart`, `v.timeRangeStop`, `v.windowPeriod`**: là **biến có sẵn của Grafana** tự truyền vào Flux theo khung thời gian người dùng chọn trên thanh Time Picker (ví dụ `Last 6 hours`). Khi khung thời gian lớn (7 ngày), `v.windowPeriod` tự giãn ra để biểu đồ không bị quá tải hàng triệu điểm.
- **`aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)`**: chia trục thời gian thành các cửa sổ bằng `v.windowPeriod` và tính trung bình (`mean`). Đặt `createEmpty: false` để không tạo các điểm `null` gây đứt đoạn biểu đồ.
- **`group(columns: [...])`**: gom các dòng có cùng tập cột lại thành 1 bảng (table).
  - `group()` (không truyền tham số): **gộp tất cả các bảng nhỏ thành 1 bảng duy nhất** (thường dùng trước `count()` hoặc `sum()` để tính tổng toàn hệ thống).
- **`last()`**: chỉ giữ bản ghi mới nhất trong mỗi bảng (dùng cho Stat, Pie chart, Gauge, hoặc lấy phiên bản mới nhất của từng dòng CSV).
- **`drop(columns: [...])`**: xóa bớt các cột tag không cần phân biệt trên biểu đồ. *Tại sao cần?* Vì InfluxDB tự tách mỗi tổ hợp tag khác nhau thành 1 chuỗi (series) riêng, khiến tên chú thích (Legend) trên Grafana rất dài như `used_percent {device="cuonglq", host="...", location="..."}`. Xóa các tag đó đi thì biểu đồ gọn hẳn.
- **`yield(name: "...")`**: xuất luồng dữ liệu ra cho Grafana vẽ và gắn tên cho Frame kết quả. Nếu một panel có nhiều query (ví dụ Query `System` và Query `User` trên biểu đồ CPU), đặt `yield(name: ...)` khác nhau giúp phân biệt rõ từng đường.

---

### 3.3. Cách biến Grafana (`${var}`) hoạt động trong Query

Khi bạn tạo các biến trên dashboard (như `device`, `db_name`, `csv_file`), Grafana hỗ trợ nhiều định dạng chèn biến vào câu query:

1. **Trong Flux Query (lọc tag InfluxDB): dùng Regex `r.device =~ /^${device:regex}$/`**
   - Toán tử `=~` là so khớp biểu thức chính quy (Regex), `/^...$/` nghĩa là khớp **chính xác từ đầu đến cuối chuỗi** (tránh chọn máy `node1` lại dính nhầm dữ liệu của `node10`).
   - Đuôi **`:regex`** tự động escape ký tự đặc biệt (như dấu `.`, `-` trong tên máy) và nếu biến có chọn nhiều giá trị/All, Grafana sẽ ghép thành `(may1|may2)`.
2. **Trong Flux Query (so sánh chuỗi trực tiếp): `"${csv_file}"`**
   - Dùng khi muốn kiểm tra điều kiện `if "${csv_file}" == ".*" ...` (lọc hay bỏ qua bộ lọc khi người dùng chọn `All`).
3. **Trong PostgreSQL SQL: `'${device}'` và `'${db_name}'`**
   - Chèn trực tiếp giá trị chuỗi vào `WHERE device = '${device}'`.
4. **Trong Tiêu đề Panel & Display Name**:
   - `${device}`, `${csv_file}`, `${db_name}`: tự thay bằng giá trị biến đang chọn trên thanh dropdown.
   - `${__field.name}`: tên gốc của field/cột.
   - `${__field.labels.index}`, `${__field.labels.name}`: lấy giá trị **tag** gắn trên chuỗi dữ liệu đó (ví dụ với GPU, Telegraf gắn tag `index="0"` và `name="NVIDIA RTX A2000 12GB"`).

---

### 3.4. Cách tự tra cứu Measurement / Tag / Field bằng Grafana Explore

Khi muốn tạo một dashboard hoàn toàn mới mà **không nhớ tên measurement hay tên field**, bạn vào menu bên trái Grafana → **Explore** → chọn Data Source **`InfluxDB-Monitoring`** → chuyển sang chế độ Code rồi chạy 3 câu Flux sau để tự khám phá dữ liệu thật đang có trên máy:

1. **Xem tất cả các `_measurement` (bảng) đang có trong bucket `system_metrics`:**
   ```flux
   import "influxdata/influxdb/schema"
   schema.measurements(bucket: "system_metrics")
   ```
2. **Xem một measurement cụ thể có những `_field` (chỉ số) nào** *(ví dụ xem của `nvidia_smi` hoặc `mem`)*:
   ```flux
   import "influxdata/influxdb/schema"
   schema.measurementFieldKeys(
     bucket: "system_metrics",
     measurement: "nvidia_smi"
   )
   ```
3. **Xem một measurement có những Tag nào và giá trị của Tag đó** *(ví dụ xem `disk` có những `path` nào, hay `net` có những `interface` nào)*:
   ```flux
   import "influxdata/influxdb/schema"
   schema.measurementTagKeys(bucket: "system_metrics", measurement: "disk")
   ```
   ```flux
   import "influxdata/influxdb/schema"
   schema.tagValues(bucket: "system_metrics", tag: "path")
   ```

> [!TIP]
> Trong **Explore**, bạn thử chạy query trước; khi thấy bảng/đồ thị trả về đúng số liệu mình muốn, chỉ cần bấm nút **Add to dashboard** là đưa thẳng vào dashboard mới mà không sợ sai cú pháp.

---

### 3.5. Cấu trúc bảng PostgreSQL Catalog dùng cho ERD

Database `monitoring_catalog` trên Máy A (được [`init_central_catalog.sql`](../Script/May_A/sql/init_central_catalog.sql) tạo và `manage.py collect` đổ dữ liệu vào) gồm 2 bảng:

1. **`db_metadata_tables`** — mỗi dòng là **1 bảng** của một database trên một thiết bị:
   - Các cột chính: `device`, `database_name`, `schema_name`, `table_name`, `column_count`, `columns_detail`, `updated_at`.
   - `columns_detail` là chuỗi gộp các cột theo định dạng `KEY^tên_cột^kiểu_dữ_liệu^NULL/NOT NULL` nối với nhau bằng `|||`.
2. **`db_metadata_relations`** — mỗi dòng là **1 khóa ngoại (FK)** nối 2 bảng:
   - Các cột chính: `device`, `database_name`, `schema_name`, `constraint_name`, `from_table`, `from_column`, `to_table`, `to_column`, `cardinality`.

---

## 4. Tạo Dashboard Mới & Cấu Hình Chung

1. Vào menu **Dashboards → New → New dashboard**.
2. Nhấn biểu tượng bánh răng **Dashboard settings** ở góc trên bên phải:
   - Tab **General**:
     - **Name**: `System Monitoring & Central ERD Dashboard` *(hoặc tên dashboard mới của bạn)*
     - **Tags**: `monitoring`, `gpu`, `erd`, `business-charts`
     - **Timezone**: `Browser Time`
     - **Graph tooltip**: `Shared crosshair` *(di chuột trên 1 biểu đồ sẽ đồng bộ vạch thời gian ở các biểu đồ khác)*
     - **Editable**: `ON`
   - Tab **Time options**:
     - **Auto refresh**: `5s, 10s, 30s, 1m, 5m, 15m, 1h`
3. Quay lại màn hình Dashboard, ở góc trên bên phải đặt:
   - Khoảng thời gian mặc định: **Last 6 hours**
   - Chu kỳ làm mới (Refresh): **10s**

---

## 5. Tạo Các Biến Động (Dashboard Variables)

Vào **Dashboard settings → Variables → Add variable**. Tạo **đúng thứ tự 4 biến** dưới đây *(tạo `device` trước `db_name` vì câu SQL của `db_name` phụ thuộc `${device}`)*.

### Biến 1: `ds_postgres` *(Chọn Data Source Catalog)*
- **Variable type**: `Data source`
- **Name**: `ds_postgres`
- **Label**: `Kho Metadata Catalog`
- **Data source type**: `PostgreSQL` (`grafana-postgresql-datasource`)
- **Refresh**: `On dashboard load`
- **Show on dashboard**: `Label and value`
- Nhấn **Apply**.

### Biến 2: `device` *(Danh sách thiết bị)*
- **Variable type**: `Query`
- **Name**: `device`
- **Label**: `Thiết Bị (Device)`
- **Data source**: `InfluxDB-Monitoring`
- **Refresh**: `On time range change`
- **Query**:
  ```flux
  import "influxdata/influxdb/schema"
  schema.tagValues(bucket: "system_metrics", tag: "device")
    |> filter(fn: (r) => r._value != "THAY_THANH_TEN_MAY_CUA_BAN" and r._value != "")
  ```
  - **Giải thích query**:
    - `schema.tagValues(...)` trả về một bảng gồm cột `_value` chứa tất cả giá trị duy nhất của tag `device` trong bucket `system_metrics`.
    - `filter(...)` loại bỏ giá trị rỗng hoặc tên mẫu mặc định `THAY_THANH_TEN_MAY_CUA_BAN` trong trường hợp có agent chạy nhầm config mẫu.
- **Regex**: `/^(?!THAY_THANH_TEN_MAY_CUA_BAN$).*/` *(lọc thêm một lớp ở phía Grafana UI)*
- **Sort**: `Alphabetical (asc)`
- **Selection options**: Multi-value `OFF`, Include All option `OFF`
- Nhấn **Run query** kiểm tra thấy tên máy ở phần Preview rồi nhấn **Apply**.

### Biến 3: `db_name` *(Danh sách Database của thiết bị)*
- **Variable type**: `Query`
- **Name**: `db_name`
- **Label**: `Cơ Sở Dữ Liệu`
- **Data source**: `PostgreSQL-Catalog`
- **Refresh**: `On time range change`
- **Query**:
  ```sql
  SELECT DISTINCT database_name
  FROM db_metadata_tables
  WHERE device = '${device}'
  ORDER BY database_name;
  ```
  - **Giải thích query**: Lấy danh sách tên database không trùng (`DISTINCT`) thuộc về thiết bị đang chọn ở `${device}` trong bảng `db_metadata_tables` để đổ vào dropdown.
- **Selection options**: Multi-value `OFF`, Include All option `OFF` *(nếu muốn có tùy chọn xem gộp tất cả DB cùng lúc, bật `Include All option: ON` và đặt `Custom all value` là `All`)*.
- Nhấn **Apply**.

### Biến 4: `csv_file` *(Danh sách file CSV)*
- **Variable type**: `Query`
- **Name**: `csv_file`
- **Label**: `Tập Tin CSV`
- **Data source**: `InfluxDB-Monitoring`
- **Refresh**: `On time range change`
- **Query**:
  ```flux
  import "influxdata/influxdb/schema"
  schema.tagValues(bucket: "device_csv", tag: "csv_name")
  ```
  - **Giải thích query**: Lấy mọi giá trị duy nhất của tag `csv_name` trong bucket `device_csv` (tag `csv_name` được `install-agent-v2.sh` tự đặt bằng tên file CSV không gồm đuôi `.csv`).
- **Sort**: `Alphabetical (asc)`
- **Selection options**:
  - Multi-value: `OFF`
  - **Include All option**: **`ON`**
  - **Custom all value**: **`.*`** *(quan trọng: câu query ở Panel CSV kiểm tra `if "${csv_file}" == ".*"` để hiển thị tất cả file khi chọn `All`)*.
- Nhấn **Apply**.

---

## 6. Tạo Từng Nhóm Panel & Giải Thích Chi Tiết Query

Khi đang ở chế độ **Edit**, nhấn **Add → Visualization** để thêm biểu đồ/bảng, và **Add → Row** để thêm thanh tiêu đề phân nhóm.

---

### 6.1. Nhóm KPI Tổng Quan

#### Panel 1: `Tổng Số Thiết Bị`
- **Visualization**: `Stat` | **Data source**: `InfluxDB-Monitoring`
- **Title**: `Tổng Số Thiết Bị`
- **Query (Flux)**:
  ```flux
  from(bucket: "system_metrics")
    |> range(start: -5m)
    |> filter(fn: (r) => r._measurement == "cpu" and r._field == "usage_idle")
    |> filter(fn: (r) => r.device != "THAY_THANH_TEN_MAY_CUA_BAN")
    |> group(columns: ["device"])
    |> last()
    |> group()
    |> count()
  ```
- **Giải thích từng bước Query**:
  1. `range(start: -5m)`: xét tất cả các máy có gửi dữ liệu trong **5 phút gần nhất**.
  2. `filter(... cpu & usage_idle)`: chọn 1 chỉ số chắc chắn máy nào cũng có là `cpu.usage_idle` làm dấu hiệu nhận biết máy tồn tại.
  3. `group(columns: ["device"]) |> last()`: trong 5 phút, một máy gửi nhiều bản ghi (cứ 10s gửi 1 lần). Gom theo `device` rồi lấy `last()` để **mỗi máy chỉ còn đúng 1 dòng đại diện**.
  4. `group() |> count()`: `group()` không tham số sẽ gộp toàn bộ các máy về chung 1 bảng duy nhất, sau đó `count()` đếm số dòng → chính là **tổng số thiết bị**.
- **Cấu hình bên phải**:
  - **Value options**: Calculation `Last*` (`lastNotNull`)
  - **Stat styles**: Text mode `Value`, Color mode `Background`, Graph mode `None`, Alignment `Center`
  - **Standard options**: Unit `Short`, No value `0`, Color scheme `Single color` (`blue`), Threshold base `blue`.

#### Panel 2: `Thiết Bị Online`
- Duplicate từ Panel 1, đổi **Title** thành `Thiết Bị Online`, **Color scheme / Threshold** thành `green`, và thu hẹp cửa sổ thời gian từ `-5m` xuống **`-2m`**:
  ```flux
  from(bucket: "system_metrics")
    |> range(start: -2m)
    |> filter(fn: (r) => r._measurement == "cpu" and r._field == "usage_idle")
    |> filter(fn: (r) => r.device != "THAY_THANH_TEN_MAY_CUA_BAN")
    |> group(columns: ["device"])
    |> last()
    |> group()
    |> count()
  ```
- **Giải thích**: Do Telegraf gửi dữ liệu mỗi `10s`, máy nào không gửi bất kỳ bản ghi nào trong **2 phút gần nhất** được coi là offline và tự động bị loại khỏi kết quả đếm.

---

### 6.2. Nhóm Tài Nguyên Hệ Thống (CPU, RAM, Disk, Network)

Tạo **Row**: **Add → Row** → đặt tên `TÀI NGUYÊN HỆ THỐNG: $device`.

#### Panel 3: `CPU Usage (%) - ${device}`
- **Visualization**: `Time series` | **Data source**: `InfluxDB-Monitoring`
- **Title**: `CPU Usage (%) - ${device}`
- **Description**: `• CPU Hệ Thống (Kernel)\n• CPU Ứng Dụng (User)`
- **Query A** *(đổi tên RefID `A` thành `System`)*:
  ```flux
  from(bucket: "system_metrics")
    |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
    |> filter(fn: (r) => r._measurement == "cpu" and r.cpu == "cpu-total" and r._field == "usage_system")
    |> filter(fn: (r) => r.device =~ /^${device:regex}$/)
    |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)
    |> drop(columns: ["cpu", "device", "device_name", "host", "location", "_measurement", "_start", "_stop"])
    |> yield(name: "System")
  ```
- **Query B** *(bấm **+ Add query**, đổi RefID thành `User`)*:
  ```flux
  from(bucket: "system_metrics")
    |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
    |> filter(fn: (r) => r._measurement == "cpu" and r.cpu == "cpu-total" and r._field == "usage_user")
    |> filter(fn: (r) => r.device =~ /^${device:regex}$/)
    |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)
    |> drop(columns: ["cpu", "device", "device_name", "host", "location", "_measurement", "_start", "_stop"])
    |> yield(name: "User")
  ```
- **Giải thích Query**:
  - `r.cpu == "cpu-total"`: lấy giá trị tổng hợp toàn bộ CPU thay vì từng nhân riêng lẻ (`cpu0`, `cpu1`...).
  - `usage_system` = % CPU dành cho nhân hệ điều hành (Kernel); `usage_user` = % CPU dành cho ứng dụng người dùng.
  - `drop(...)`: xóa các cột tag phụ để Legend không bị nối chuỗi dài.
  - `yield(name: "System")` / `yield(name: "User")`: đặt tên riêng cho 2 luồng dữ liệu để gắn Override màu và tên tiếng Việt bên dưới.
- **Cấu hình bên phải**:
  - **Legend**: `List`, `Bottom` | **Tooltip**: `All`, Sort `Descending`
  - **Graph styles**: Line interpolation `Smooth`, Fill opacity `15`, Connect null values `Always`
  - **Standard options → Unit**: `Percent (0-100)`
  - **Overrides**:
    1. `Fields returned by query` → `System`: Display name `CPU Hệ Thống (Kernel)`, Color `blue`
    2. `Fields returned by query` → `User`: Display name `CPU Ứng Dụng (User)`, Color `orange`

#### Panel 4: `RAM Usage (%) - ${device}`
- **Visualization**: `Time series` | **Data source**: `InfluxDB-Monitoring`
- **Title**: `RAM Usage (%) - ${device}`
- **Query** *(RefID `RAM`)*:
  ```flux
  from(bucket: "system_metrics")
    |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
    |> filter(fn: (r) => r._measurement == "mem" and r._field == "used_percent")
    |> filter(fn: (r) => r.device =~ /^${device:regex}$/)
    |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)
    |> drop(columns: ["device", "device_name", "host", "location", "_measurement", "_start", "_stop"])
    |> yield(name: "RAM")
  ```
- **Giải thích Query**: Lấy phần trăm RAM đã dùng (`mem.used_percent`) của thiết bị `${device}`, tính trung bình theo cửa sổ `v.windowPeriod`. *(Nếu muốn xem theo GB thay vì %, bạn có thể đổi `_field == "used"` hoặc `"available"` và đặt Unit là `bytes (IEC)`).*
- **Cấu hình bên phải**:
  - **Legend**: `Table`, `Bottom`, Values: `Last*`, `Max`
  - **Graph styles**: Smooth, Fill opacity `25`, Connect null values `Always`
  - **Standard options**: Unit `Percent (0-100)`, Color `Single color` (`green`)
  - **Overrides**: `Fields returned by query` (`RAM`) → Display name `RAM Đã Dùng (%)`

#### Panel 5: `Disk Usage (Root /) - ${device}`
- **Visualization**: `Pie chart` | **Data source**: `InfluxDB-Monitoring`
- **Title**: `Disk Usage (Root /) - ${device}`
- **Query**:
  ```flux
  from(bucket: "system_metrics")
    |> range(start: -5m)
    |> filter(fn: (r) => r._measurement == "disk" and r.path == "/" and (r._field == "used" or r._field == "free"))
    |> filter(fn: (r) => r.device =~ /^${device:regex}$/)
    |> group(columns: ["_field"])
    |> last()
    |> map(fn: (r) => ({
        _time: r._time,
        _field: if r._field == "used" then "Đã dùng" else "Còn trống",
        _value: r._value
    }))
  ```
- **Giải thích từng bước Query**:
  1. `r._measurement == "disk" and r.path == "/"`: lọc đúng phân vùng gốc `/` *(muốn theo dõi phân vùng khác như `/data` hoặc `/home`, chỉ cần đổi `r.path == "/data"`)*.
  2. `r._field == "used" or r._field == "free"`: lấy đồng thời 2 field là dung lượng đã dùng và còn trống (đơn vị byte).
  3. `group(columns: ["_field"]) |> last()`: gom thành 2 nhóm (`used` và `free`), mỗi nhóm chỉ lấy bản ghi mới nhất trong 5 phút qua để vẽ biểu đồ tròn.
  4. `map(...)`: đổi tên giá trị cột `_field` sang tiếng Việt `"Đã dùng"` và `"Còn trống"` ngay trong query để hiển thị trực tiếp lên nhãn biểu đồ & khớp với rule đổi màu bên dưới.
- **Cấu hình bên phải**:
  - **Value options**: Calculation `Last*`
  - **Pie chart**: Type `Donut`, Labels `Name`, `Percent`
  - **Legend**: `Table`, `Bottom`, Values: `Value`, `Percent`
  - **Standard options → Unit**: `Data -> bytes (IEC)`
  - **Overrides**: `Fields with name` → `Đã dùng` (`orange`), `Còn trống` (`green`)

#### Panel 6 & Panel 7: `Network Download` & `Network Upload`
- **Visualization**: `Gauge` | **Data source**: `InfluxDB-Monitoring`
- **Query Panel 6 (`Network Download - ${device}`, RefID `Download`)**:
  ```flux
  from(bucket: "system_metrics")
    |> range(start: -15m)
    |> filter(fn: (r) => r._measurement == "net" and r._field == "bytes_recv")
    |> filter(fn: (r) => r.device =~ /^${device:regex}$/)
    |> derivative(unit: 1s, nonNegative: true)
    |> last()
    |> group()
    |> sum(column: "_value")
    |> map(fn: (r) => ({_value: if exists r._value and r._value > 0.0 then r._value else 0.0}))
  ```
- **Query Panel 7 (`Network Upload - ${device}`, RefID `Upload`)**: giống hệt Panel 6, chỉ thay `bytes_recv` bằng **`bytes_sent`**.
- **Giải thích từng bước Query (rất quan trọng cho các chỉ số Counter)**:
  1. `bytes_recv` (nhận vào) và `bytes_sent` (gửi đi) do Telegraf ghi nhận là **bộ đếm cộng dồn (cumulative counter)** tính từ lúc khởi động máy (luôn tăng dần, ví dụ: 100GB → 100.1GB...).
  2. `derivative(unit: 1s, nonNegative: true)`: tính **tốc độ thay đổi mỗi 1 giây** ($\Delta\text{bytes} / \Delta t$) để chuyển từ "tổng bytes" sang **"bytes/giây"**. Tham số `nonNegative: true` giúp bỏ qua giá trị âm nếu máy vừa reboot làm counter reset về 0.
  3. `last()`: lấy tốc độ mới nhất của **từng card mạng (`interface`)** trên máy (vì máy thường có nhiều interface như `eth0`, `ens33`, `wlan0`, `docker0`...). *(Nếu chỉ muốn đo 1 card mạng cụ thể, thêm `and r.interface == "eth0"` ở bước `filter`).*
  4. `group() |> sum(column: "_value")`: gộp tất cả interface về 1 bảng rồi cộng tổng tốc độ lại thành tổng băng thông máy.
  5. `map(...)`: bảo đảm nếu không có lưu lượng thì giá trị tối thiểu là `0.0` để kim Gauge không bị lỗi hoặc âm.
- **Cấu hình bên phải (cho cả 2 panel)**:
  - **Value options**: Calculation `Last*`
  - **Gauge**: Show threshold markers `ON`, Show threshold labels `OFF`
  - **Standard options**: Unit `Data rate -> bytes/sec (IEC)` (`binBps`), Min `0`, No value `0 B/s`, Color scheme `From thresholds`
  - **Thresholds** (`Absolute`): Base `green`, `5242880` *(5 MiB/s)* `#EAB839` (vàng), `20971520` *(20 MiB/s)* `#E24D42` (đỏ).

---

### 6.3. Nhóm Card Đồ Họa (NVIDIA GPU)

Tạo **Row**: **Add → Row** → đặt tên `GIÁM SÁT CARD ĐỒ HỌA (NVIDIA GPU): $device`.

> [!NOTE]
> **Cơ chế tách đa GPU tự động trong Query:**
> Telegraf `[[inputs.nvidia_smi]]` gắn rất nhiều tag vào mỗi điểm dữ liệu (`index`, `name`, `uuid`, `pstate`, `arch`, `compute_mode`...). Trong câu `drop(...)` bên dưới, ta cố tình **giữ lại 2 tag `index` (số thứ tự card: 0, 1...) và `name` (tên card: NVIDIA RTX A2000 12GB)**. Nhờ vậy Grafana đọc được `${__field.labels.index}` và `${__field.labels.name}` để hiển thị từng card thành từng đường riêng biệt (`GPU #0: ...`, `GPU #1: ...`).

#### Panel 8: `GPU Core Utilization (%) - ${device}`
- **Visualization**: `Time series` | **Data source**: `InfluxDB-Monitoring`
- **Title**: `GPU Core Utilization (%) - ${device}`
- **Query**:
  ```flux
  from(bucket: "system_metrics")
    |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
    |> filter(fn: (r) => r._measurement == "nvidia_smi" and r._field == "utilization_gpu")
    |> filter(fn: (r) => r.device =~ /^${device:regex}$/)
    |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)
    |> drop(columns: ["arch", "compute_mode", "pstate", "uuid", "device", "device_name", "host", "location", "_measurement", "_start", "_stop"])
    |> yield(name: "GPU Core")
  ```
- **Cấu hình**: Legend `Table` (`Last*`, `Max`, `Mean`), Tooltip `All` (`Desc`), Unit `Percent (0-100)`, Min `0`, Max `100`, No value `0%`, Display name `GPU #${__field.labels.index}: ${__field.labels.name}`, Color `Classic palette`, Smooth, Width `2`, Fill `15`, Span nulls `Always`.

#### Panel 9: `GPU VRAM Memory Usage (MiB) - ${device}`
- **Visualization**: `Time series` | **Data source**: `InfluxDB-Monitoring`
- **Title**: `GPU VRAM Memory Usage (MiB) - ${device}`
- **Query A** *(RefID `Used`)* — thay `_field == "memory_used"` và `yield(name: "Used")`
- **Query B** *(RefID `Total`)* — thay `_field == "memory_total"` và `yield(name: "Total")`
  ```flux
  // Query A (Used)
  from(bucket: "system_metrics")
    |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
    |> filter(fn: (r) => r._measurement == "nvidia_smi" and r._field == "memory_used")
    |> filter(fn: (r) => r.device =~ /^${device:regex}$/)
    |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)
    |> drop(columns: ["arch", "compute_mode", "pstate", "uuid", "device", "device_name", "host", "location", "_measurement", "_start", "_stop"])
    |> yield(name: "Used")
  ```
  ```flux
  // Query B (Total)
  from(bucket: "system_metrics")
    |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
    |> filter(fn: (r) => r._measurement == "nvidia_smi" and r._field == "memory_total")
    |> filter(fn: (r) => r.device =~ /^${device:regex}$/)
    |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)
    |> drop(columns: ["arch", "compute_mode", "pstate", "uuid", "device", "device_name", "host", "location", "_measurement", "_start", "_stop"])
    |> yield(name: "Total")
  ```
- **Giải thích**: `nvidia-smi` trả về VRAM tính bằng **MiB**, nên chọn Unit `Data -> megabytes (mbytes)` để Grafana tự hiển thị `15 MiB` hoặc `1.37 GiB`, `12 GiB`. Vẽ thêm đường `Total` dạng nét đứt (`Dash`) để nhìn trực quan VRAM đã dùng đang chiếm bao nhiêu so với tổng dung lượng card.
- **Cấu hình**:
  - **Legend**: `Table`, `Bottom`, Values: `Last*`, `Max`
  - **Standard options**: Unit `Data -> megabytes (mbytes)`, No value `Thiết bị không có GPU`
  - **Overrides**:
    1. Query `Used`: Display name `GPU #${__field.labels.index} (${__field.labels.name}) — Đã dùng`, Fill opacity `20`
    2. Query `Total`: Display name `GPU #${__field.labels.index} (${__field.labels.name}) — Tổng`, Line style `Dash` (`6`, `4`), Fill opacity `0`, Line width `1`

#### Panel 10: `GPU Nhiệt Độ (°C) - ${device}`
- **Visualization**: `Time series` | **Data source**: `InfluxDB-Monitoring`
- **Query**: giống Panel 8 nhưng dùng `_field == "temperature_gpu"` và `yield(name: "Nhiệt Độ")`.
- **Cấu hình**: Legend `Table` (`Last*`, `Max`, `Mean`), Unit `Celsius (°C)`, Display name `GPU #${__field.labels.index}: ${__field.labels.name}`, Smooth, Fill `20`, Span nulls `Always`.

#### Panel 11: `GPU Công Suất (W) - ${device}`
- **Visualization**: `Time series` | **Data source**: `InfluxDB-Monitoring`
- **Query**:
  ```flux
  from(bucket: "system_metrics")
    |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
    |> filter(fn: (r) => r._measurement == "nvidia_smi" and r._field == "power_draw")
    |> filter(fn: (r) => r.device =~ /^${device:regex}$/)
    |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)
    |> drop(columns: ["arch", "compute_mode", "pstate", "uuid", "device", "device_name", "host", "location", "_measurement", "_start", "_stop"])
    |> yield(name: "Công Suất")
  ```
- **Giải thích khác biệt nhỏ**: dùng `every: 1m` thay vì `v.windowPeriod` để làm mượt bớt các xung tăng/giảm công suất tức thời trong vài giây.
- **Cấu hình**: Legend `Table` (`Last*`, `Max`, `Mean`), Unit `Watt (W)`, Display name `GPU #${__field.labels.index}: ${__field.labels.name}`, Line interpolation `Linear`, Line width `1`, Fill `0`, Span nulls `Always`.

---

### 6.4. Nhóm Dữ Liệu Tập Tin CSV

Tạo **Row**: **Add → Row** → đặt tên `DỮ LIỆU TẬP TIN CSV: $device`.

#### Panel 12: `Bảng Dữ Liệu CSV Chi Tiết: ${device} (Tập tin: ${csv_file})`
- **Visualization**: `Table` | **Data source**: `InfluxDB-Monitoring`
- **Title**: `Bảng Dữ Liệu CSV Chi Tiết: ${device} (Tập tin: ${csv_file})`
- **Query (Flux)**:
  ```flux
  from(bucket: "device_csv")
    |> range(start: -30d)
    |> filter(fn: (r) => r._measurement == "file")
    |> filter(fn: (r) => r.device =~ /^${device:regex}$/)
    |> filter(fn: (r) => if "${csv_file}" == ".*" or "${csv_file}" == "All" then true else r.csv_name =~ /^${csv_file:regex}$/ or r.file =~ /^${csv_file:regex}$/)
    |> map(fn: (r) => ({ r with row_id: if exists r.row_id then r.row_id else "1" }))
    |> group(columns: ["device", "csv_name", "row_id", "_field"])
    |> last()
    |> toString()
    |> group(columns: ["device", "csv_name"])
    |> pivot(rowKey: ["row_id"], columnKey: ["_field"], valueColumn: "_value")
    |> drop(columns: ["_start", "_stop", "_measurement", "host", "device_name", "location", "source_file", "row_id", "device", "csv_name"])
    |> group()
    |> limit(n: 500)
  ```
- **Giải thích chi tiết từng dòng (Query quan trọng nhất cho CSV tổng quát)**:
  1. `from(bucket: "device_csv") |> range(start: -30d)`: lấy trong 30 ngày gần nhất (vì các file CSV ít thay đổi có thể đã được đẩy lên từ nhiều ngày trước, không phụ thuộc Time Picker `Last 6 hours`).
  2. `filter(r._measurement == "file")`: toàn bộ file CSV đều ghi dưới measurement tên `"file"`.
  3. `filter(if "${csv_file}" == ".*" ...)`: nếu biến đang chọn `All` (`.*`), lấy hết; nếu chọn 1 file cụ thể, chỉ giữ file có tag `csv_name` khớp với `${csv_file}`.
  4. `map(... row_id ...)`: đảm bảo mọi bản ghi đều có `row_id` (tag do Starlark đánh số `1, 2, 3...` cho từng dòng của CSV).
  5. `group(columns: ["device", "csv_name", "row_id", "_field"]) |> last()`: vì Telegraf đọc lại file CSV mỗi 1 phút nên một dòng CSV có thể có hàng chục bản sao theo thời gian. Gom theo `(device, csv_name, row_id, _field)` và gọi `last()` giúp **chỉ lấy bản mới nhất của từng ô dữ liệu, chống lặp dòng**.
  6. `|> toString()`: ép toàn bộ cột `_value` về chuỗi (String). *Tại sao?* Khi xem `All` hoặc nhiều file CSV khác cấu trúc, hoặc 1 cột có kiểu dữ liệu lẫn lộn, InfluxDB sẽ báo lỗi xung đột schema nếu không ép kiểu đồng nhất trước khi `pivot`.
  7. `group(columns: ["device", "csv_name"]) |> pivot(...)`: InfluxDB lưu mỗi cột của CSV thành 1 dòng dữ liệu riêng lẻ theo `_field`. Hàm `pivot(rowKey: ["row_id"], columnKey: ["_field"], valueColumn: "_value")` sẽ **xoay dọc thành ngang**, biến các `_field` thành các cột giống hệt file CSV gốc, mỗi `row_id` là 1 dòng.
  8. `drop(...)`: loại bỏ các cột kỹ thuật nội bộ (`_start`, `_stop`, `host`, `row_id`, `source_file`...) để bảng chỉ hiện đúng các cột dữ liệu của file CSV.
  9. `group() |> limit(n: 500)`: gộp kết quả và giới hạn tối đa 500 dòng để trình duyệt render mượt.
- **Cấu hình bên phải**:
  - **Table**: Show table header `ON`, Enable pagination `ON` (`20` dòng/trang)
  - **Standard options → Display name**: `${__field.name}`

> [!TIP]
> **Muốn vẽ Bar Chart từ CSV?**
> Duplicate panel Table này → đổi Visualization sang **Bar chart** → vào tab **Transformations → Add transformation → Convert field type** → chọn cột số (ví dụ `So_don_hang`) chuyển sang **`Numeric`** (vì bước `toString()` ở trên đã biến mọi cột thành String). Xem hướng dẫn chi tiết tại [`USAGE.md`](USAGE.md#12-hướng-dẫn-chi-tiết-từng-bước-chuyển-từ-table-sang-bar-chart-biểu-đồ-cột).

---

### 6.5. Nhóm Sơ Đồ Thực Thể Quan Hệ (ERD)

Tạo **Row**: **Add → Row** → đặt tên `SƠ ĐỒ THỰC THỂ QUAN HỆ (ERD) - THIẾT BỊ: $device`.

#### Panel 13: `Sơ Đồ Thực Thể Quan Hệ (ERD) — Thiết Bị: ${device} | DB: ${db_name}`
- **Visualization**: **`Business Charts`** *(plugin `volkovlabs-echarts-panel`)*
- **Data source**: `PostgreSQL-Catalog`
- **Title**: `Sơ Đồ Thực Thể Quan Hệ (ERD) — Thiết Bị: ${device} | DB: ${db_name}`
- **Query (SQL)**: Chuyển SQL Editor sang chế độ **`Code`** và đặt **Format** là **`Table`**, dán câu SQL sau:
  ```sql
  WITH nodes AS (
      SELECT 
          'node' AS type,
          device || '.' || database_name || '.' || schema_name || '.' || table_name AS id,
          schema_name || '.' || table_name AS label,
          columns_detail AS columns,
          NULL::text AS source,
          NULL::text AS target,
          database_name AS db,
          schema_name AS schema
      FROM db_metadata_tables
      WHERE device = '${device}'
        AND ('${db_name}' = 'All' OR '${db_name}' = '' OR database_name = '${db_name}')
  ),
  edges AS (
      SELECT 
          'edge' AS type,
          constraint_name AS id,
          from_table || ' → ' || to_table AS label,
          COALESCE(cardinality, '1 : 0..N') AS columns,
          device || '.' || database_name || '.' || schema_name || '.' || to_table AS source,
          device || '.' || database_name || '.' || schema_name || '.' || from_table AS target,
          database_name AS db,
          schema_name AS schema
      FROM db_metadata_relations
      WHERE device = '${device}'
        AND ('${db_name}' = 'All' OR '${db_name}' = '' OR database_name = '${db_name}')
  )
  SELECT * FROM nodes
  UNION ALL
  SELECT * FROM edges;
  ```
- **Giải thích SQL Query**:
  - CTE **`nodes`**: đọc từ `db_metadata_tables`, mỗi bảng trở thành một thực thể (`type = 'node'`), mang theo `columns_detail` và mã định danh duy nhất `device.db.schema.table`.
  - CTE **`edges`**: đọc từ `db_metadata_relations`, mỗi khóa ngoại trở thành một cạnh nối (`type = 'edge'`) từ bảng cha (`to_table`) tới bảng con (`from_table`) kèm nhãn quan hệ `cardinality` (`1 : 0..N` hoặc `0..1 : 0..N`).
  - Mệnh đề `WHERE device = '${device}' AND ('${db_name}' = 'All' OR ...)`: giúp câu query tương thích cả khi chọn 1 DB lẫn khi bật tùy chọn `All`.
- **Cấu hình Charts Function (`getOption`) ở thanh bên phải**:
  Tìm phần **Chart Editor / Charts Function (`getOption`)**, xóa code mặc định và dán đoạn JavaScript sau:
  ```javascript
  // Business Charts (Volkov Labs) - ERD Viewer Chuyên Dụng (Cytoscape.js + ELK.js Chuẩn pgAdmin 4)
  let chart = (typeof echartsInstance !== 'undefined') ? echartsInstance : (typeof context !== 'undefined' && context.panel ? context.panel.chart : null);

  let dom = null;
  if (chart && typeof chart.getDom === 'function') {
    dom = chart.getDom();
  } else if (typeof context !== 'undefined' && context.element) {
    dom = context.element;
  } else if (typeof context !== 'undefined' && context.container) {
    dom = context.container;
  }

  let deviceName = '';
  let dbName = '';

  try {
    if (typeof replaceVariables === 'function') {
      deviceName = replaceVariables('${device}') || '';
      dbName = replaceVariables('${db_name}') || '';
    } else if (typeof context !== 'undefined' && context.grafana && typeof context.grafana.replaceVariables === 'function') {
      deviceName = context.grafana.replaceVariables('${device}') || '';
      dbName = context.grafana.replaceVariables('${db_name}') || '';
    } else if (typeof context !== 'undefined' && context.panel && context.panel.scopedVars) {
      deviceName = context.panel.scopedVars.device?.value || '';
      dbName = context.panel.scopedVars.db_name?.value || '';
    }
  } catch (e) {
    console.warn('Error reading Grafana variables:', e);
  }

  const host = window.location.hostname || 'localhost';
  const iframeUrl = 'http://' + host + ':8088/?device=' + encodeURIComponent(deviceName) + '&db=' + encodeURIComponent(dbName);

  if (dom) {
    dom.style.position = 'relative';
    dom.style.overflow = 'hidden';
    dom.style.width = '100%';
    dom.style.height = '100%';

    let iframe = dom.querySelector('iframe.erd-iframe');
    if (!iframe) {
      iframe = document.createElement('iframe');
      iframe.className = 'erd-iframe';
      iframe.src = iframeUrl;
      iframe.setAttribute('data-url', iframeUrl);
      iframe.style.position = 'absolute';
      iframe.style.top = '0';
      iframe.style.left = '0';
      iframe.style.width = '100%';
      iframe.style.height = '100%';
      iframe.style.border = 'none';
      iframe.style.zIndex = '100';
      iframe.style.background = '#f8fafc';
      iframe.style.borderRadius = '6px';
      dom.appendChild(iframe);
    } else if (iframe.getAttribute('data-url') !== iframeUrl) {
      iframe.src = iframeUrl;
      iframe.setAttribute('data-url', iframeUrl);
    }
  }

  return {};
  ```
- **Giải thích cơ chế kết hợp SQL + JavaScript**:
  1. SQL Query đóng vai trò liên kết panel với `PostgreSQL-Catalog` và buộc Grafana gọi lại `getOption()` mỗi khi bạn đổi `${device}` hoặc `${db_name}`.
  2. `replaceVariables('${device}')` và `replaceVariables('${db_name}')` lấy tên máy và DB hiện tại ghép thành URL `http://<host>:8088/?device=...&db=...`.
  3. Đoạn code gắn thuộc tính `data-url` để **chỉ tải lại `<iframe>` khi bạn thực sự đổi máy hoặc đổi DB** — nhờ đó khi dashboard auto-refresh mỗi `10s`, sơ đồ ERD bạn đang kéo thả sẽ không bị reload mất vị trí.
  4. Giao diện bên trong `<iframe>` được phục vụ bởi [`erd_service/server.py`](../Script/May_A/erd_service/server.py) (gọi API `/api/erd` truy vấn `monitoring_catalog` và vẽ bằng Cytoscape.js + ELK.js).

---

## 7. Mở Rộng: Tự Tạo Thêm Panel Mới Từ Dữ Liệu Có Sẵn

Ngoài 13 panel chuẩn ở trên, script [`install-agent-v2.sh`](../Script/May_Khac/install-agent-v2.sh) đã cấu hình Telegraf thu thập sẵn nhiều chỉ số khác vào bucket `system_metrics`. Khi tự tạo dashboard mới, bạn có thể áp dụng đúng mẫu Flux ở Mục 3 để vẽ thêm:

### 7.1. Tốc độ Đọc/Ghi Ổ Đĩa (`diskio` — Counter dùng `derivative`)
```flux
from(bucket: "system_metrics")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "diskio" and (r._field == "read_bytes" or r._field == "write_bytes"))
  |> filter(fn: (r) => r.device =~ /^${device:regex}$/)
  |> derivative(unit: 1s, nonNegative: true)
  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)
  |> drop(columns: ["device", "device_name", "host", "location", "_measurement", "_start", "_stop"])
```
*(Gợi ý: chọn Visualization `Time series`, Unit `Data rate -> bytes/sec (IEC)`).*

### 7.2. Thời gian hoạt động (Uptime) & Tải hệ thống (`system`)
```flux
from(bucket: "system_metrics")
  |> range(start: -5m)
  |> filter(fn: (r) => r._measurement == "system" and r._field == "uptime")
  |> filter(fn: (r) => r.device =~ /^${device:regex}$/)
  |> last()
```
*(Gợi ý: chọn Visualization `Stat`, Unit `Time -> seconds (s)` — Grafana tự đổi sang ngày/giờ; hoặc đổi `_field == "load1"` để xem Load Average 1 phút trên `Time series`).*

### 7.3. Số lượng kết nối PostgreSQL đang mở (`postgresql`)
```flux
from(bucket: "system_metrics")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "postgresql" and r._field == "numbackends")
  |> filter(fn: (r) => r.device =~ /^${device:regex}$/)
  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)
  |> drop(columns: ["device", "device_name", "host", "location", "server", "_measurement", "_start", "_stop"])
```
*(Tag `db` được giữ lại nên mỗi database trên máy sẽ vẽ thành một đường riêng).*

---

## 8. Lưu, Kiểm Tra & Tóm Tắt Bố Cục Lưới (Grid 24 Cột)

### 8.1. Lưu & Kiểm Tra
1. Nhấn **Save dashboard** (hoặc `Ctrl + S`) → đặt tên và nhấn **Save**.
2. Kiểm tra lần lượt các tương tác:
   - Đổi `Thiết Bị (Device)` → toàn bộ phần Hệ thống, GPU, CSV và ERD cập nhật theo máy mới.
   - Đổi `Tập Tin CSV` → bảng CSV hiển thị đúng các cột và phân trang 20 dòng/trang.
   - Đổi `Cơ Sở Dữ Liệu` → khung ERD tự tải lại đúng sơ đồ của database đó.

### 8.2. Bảng Căn Kích Thước Chuẩn (Lưới 24 Cột của Grafana)
Khi kéo góc dưới-phải để sắp xếp giao diện cân đối như bản [`monitoring-dashboard.json`](../Script/May_A/monitoring-dashboard.json):

| Hàng | Nội dung | Rộng (`w` / 24) | Cao (`h`) | Bố trí trên hàng |
| :---: | :--- | :---: | :---: | :--- |
| **0** | `Tổng Số Thiết Bị` / `Thiết Bị Online` | `6` / `6` | `3` | 2 thẻ Stat nằm cạnh nhau ở nửa trái |
| **1** | Row `TÀI NGUYÊN HỆ THỐNG` | `24` | `1` | Thanh tiêu đề ngăn nhóm |
| **2** | `CPU Usage` / `RAM Usage` / `Disk Usage` | `8` / `8` / `8` | `7` | Chia đều 3 cột |
| **3** | `Network Download` / `Network Upload` | `12` / `12` | `6` | Chia đôi 2 cột |
| **4** | Row `GIÁM SÁT CARD ĐỒ HỌA (NVIDIA GPU)` | `24` | `1` | Thanh tiêu đề ngăn nhóm |
| **5** | `GPU Core Utilization` / `GPU VRAM` | `12` / `12` | `7` | Chia đôi 2 cột |
| **6** | `GPU Nhiệt Độ` / `GPU Công Suất` | `12` / `12` | `7` | Chia đôi 2 cột |
| **7** | Row `DỮ LIỆU TẬP TIN CSV` | `24` | `1` | Thanh tiêu đề ngăn nhóm |
| **8** | `Bảng Dữ Liệu CSV Chi Tiết` | `24` | `9` | Tràn toàn bộ chiều ngang |
| **9** | Row `SƠ ĐỒ THỰC THỂ QUAN HỆ (ERD)` | `24` | `1` | Thanh tiêu đề ngăn nhóm |
| **10** | `Sơ Đồ Thực Thể Quan Hệ (ERD)` | `24` | `22` | Tràn toàn bộ chiều ngang, đủ cao để kéo thả ERD |
