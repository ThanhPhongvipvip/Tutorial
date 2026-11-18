# Hướng Dẫn Tự Tạo Dashboard Grafana (Đơn Giản, Dễ Làm)

Tài liệu này hướng dẫn bạn **tự tay tạo mới hoàn toàn một Dashboard trên Grafana** (không cần import file [`monitoring-dashboard.json`](../Script/May_A/monitoring-dashboard.json)), đồng thời giải thích dễ hiểu cách viết Query để bạn tự tùy biến hoặc tạo thêm Dashboard mới.

Dashboard hoàn chỉnh gồm 4 phần:
1. **Tổng quan & Máy tính:** Số máy online, CPU, RAM, Ổ đĩa `/`, Mạng Download/Upload.
2. **Card đồ họa (GPU):** % tải GPU, VRAM, Nhiệt độ, Công suất.
3. **File CSV:** Bảng xem toàn bộ dữ liệu CSV bất kỳ.
4. **Sơ đồ ERD:** Xem cấu trúc bảng và khóa ngoại PostgreSQL.

---

## Chuẩn Bị Trước Khi Làm

> Bỏ file JSON chỉ là tự vẽ giao diện, còn hệ thống thu thập dữ liệu vẫn phải chạy sẵn:

- **Máy A (Server):** Đang chạy Grafana (`:3000`), InfluxDB (`:8086`), PostgreSQL `monitoring_catalog` (`:5432`) và dịch vụ vẽ ERD (`:8088` — kiểm tra bằng `sudo systemctl status erd-viewer`).
- **Cài plugin vẽ ERD cho Grafana:** Chạy lệnh sau trên Máy A (hoặc cài trong mục **Plugins** trên web):
  ```bash
  sudo grafana-cli plugins install volkovlabs-echarts-panel
  sudo systemctl restart grafana-server
  ```
- **Máy con:** Đã chạy Telegraf Agent (đẩy dữ liệu vào InfluxDB) và `manage.py collect` (đẩy cấu trúc DB về PostgreSQL).

---

## Bước 1: Kết Nối 2 Nguồn Dữ Liệu (Data Sources)

Vào Grafana (`http://<IP_MAY_A>:3000`) → menu trái chọn **Connections → Data sources → Add data source**:

1. **Tạo nguồn InfluxDB:**
   - Chọn **InfluxDB** → Đặt tên: `InfluxDB-Monitoring`
   - **Query Language:** Chọn **`Flux`** *(rất quan trọng, không chọn InfluxQL)*
   - **URL:** `http://localhost:8086`
   - **Organization:** `monitoring` | **Default Bucket:** `system_metrics`
   - **Token:** Lấy trong [`configs/config.json`](../Script/May_A/configs/config.json)
   - Bấm **Save & test**.

2. **Tạo nguồn PostgreSQL:**
   - Chọn **PostgreSQL** → Đặt tên: `PostgreSQL-Catalog`
   - **Host URL:** `localhost:5432` | **Database:** `monitoring_catalog`
   - **Username:** `grafana_reader` | **Password:** `1` | **TLS/SSL Mode:** `disable`
   - Bấm **Save & test**.

---

## Bước 2: Hiểu Nhanh Cách Viết Query (Đọc 2 Phút Là Tự Làm Được)

### 2.1. Dữ liệu được cất ở đâu?

| Thuật ngữ trong InfluxDB | Hiểu đơn giản giống SQL | Có trong hệ thống này |
| :--- | :--- | :--- |
| **`bucket`** | Tên Database | `system_metrics` (chứa thông số máy, GPU) và `device_csv` (chứa file CSV) |
| **`_measurement`** | Tên Bảng | `cpu`, `mem`, `disk`, `net`, `nvidia_smi`, `file` |
| **`_field`** | Tên Cột số liệu | VD: `used_percent` (của `mem`), `temperature_gpu` (của `nvidia_smi`) |
| **`tag`** | Nhãn để lọc (`WHERE`) | `device` (tên máy), `csv_name` (tên file CSV), `path` (ổ đĩa) |

### 2.2. Công thức Flux chuẩn cho mọi biểu đồ đường

Trong Flux, các bước xử lý nối với nhau bằng dấu `|>` (làm xong bước trên rồi chuyển xuống bước dưới):

```flux
from(bucket: "system_metrics")                                                  // 1. Chọn kho dữ liệu
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)                      // 2. Lấy theo khung giờ trên Grafana
  |> filter(fn: (r) => r._measurement == "mem" and r._field == "used_percent")  // 3. Chọn bảng & chỉ số cần xem
  |> filter(fn: (r) => r.device =~ /^${device:regex}$/)                         // 4. Lọc theo máy đang chọn
  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)       // 5. Gom điểm cho mượt biểu đồ
  |> drop(columns: ["device", "device_name", "host", "location", "_measurement", "_start", "_stop"]) // 6. Bỏ nhãn thừa
```

> **3 mẹo quan trọng cần nhớ khi tự viết Query:**
> 1. **Cần lấy 1 con số hiện tại** (ô Stat, biểu đồ tròn Pie, đồng hồ Gauge): Dùng `range(start: -5m)` và thêm `|> last()` để lấy đúng giá trị mới nhất thay vì vẽ đường dài.
> 2. **Đo tốc độ mạng / ổ đĩa (`net`, `diskio`):** Telegraf lưu tổng số bytes cộng dồn từ lúc bật máy (tăng mãi). Muốn ra **tốc độ mỗi giây (B/s)** thì phải thêm `|> derivative(unit: 1s, nonNegative: true)`.
> 3. **Dùng biến `${device}` trong Flux:** Viết `r.device =~ /^${device:regex}$/` để khớp chính xác tên máy (`^` là đầu, `$` là cuối, tránh máy `pc1` dính nhầm `pc10`).

### 2.3. Tự tìm tên bảng & chỉ số có sẵn (không cần nhớ thuộc lòng)

Vào menu trái Grafana → **Explore** → chọn nguồn `InfluxDB-Monitoring` → chuyển sang chế độ **Code**:
- Xem máy đang gửi lên những bảng (`_measurement`) nào:
  ```flux
  import "influxdata/influxdb/schema"
  schema.measurements(bucket: "system_metrics")
  ```
- Xem một bảng (ví dụ `nvidia_smi`) có những chỉ số (`_field`) nào:
  ```flux
  import "influxdata/influxdb/schema"
  schema.measurementFieldKeys(bucket: "system_metrics", measurement: "nvidia_smi")
  ```
*(Chạy thử thấy lên dữ liệu rồi bấm nút **Add to dashboard** ở góc trên là đưa thẳng vào Dashboard được luôn).*

---

## Bước 3: Tạo Dashboard & 4 Biến Lọc Ở Đầu Trang

1. Vào **Dashboards → New → New dashboard**.
2. Bấm icon bánh răng (**Dashboard settings**) góc trên phải → đặt **Name:** `System Monitoring & Central ERD Dashboard`.
3. Quay lại màn hình chính, chọn góc trên phải: thời gian **Last 6 hours**, Refresh **10s**.
4. Vào **Dashboard settings → Variables → Add variable** để thêm các biến ở dưới.

### Tạo 4 biến lọc *(tạo `device` trước `db_name`)*

1. **Biến `ds_postgres`** *(Label: `Kho Metadata Catalog`)*
   - **Type:** `Data source` | **Data source type:** `PostgreSQL` | **Refresh:** `On dashboard load`

2. **Biến `device`** *(Label: `Thiết Bị (Device)`)* — lấy danh sách tên máy từ InfluxDB:
   - **Type:** `Query` | **Data source:** `InfluxDB-Monitoring` | **Refresh:** `On time range change`
   - Tắt **Multi-value** và **Include All option**.
   - **Query:**
     ```flux
     import "influxdata/influxdb/schema"
     schema.tagValues(bucket: "system_metrics", tag: "device")
       |> filter(fn: (r) => r._value != "THAY_THANH_TEN_MAY_CUA_BAN" and r._value != "")
     ```

3. **Biến `db_name`** *(Label: `Cơ Sở Dữ Liệu`)* — lấy danh sách DB của máy đang chọn:
   - **Type:** `Query` | **Data source:** `PostgreSQL-Catalog` | **Refresh:** `On time range change`
   - *(Mẹo: nếu muốn xem gộp tất cả DB cùng lúc trên ERD, bật **Include All** và điền Custom all value là `All`)*.
   - **Query:**
     ```sql
     SELECT DISTINCT database_name
     FROM db_metadata_tables
     WHERE device = '${device}'
     ORDER BY database_name;
     ```

4. **Biến `csv_file`** *(Label: `Tập Tin CSV`)* — lấy danh sách file CSV:
   - **Type:** `Query` | **Data source:** `InfluxDB-Monitoring` | **Refresh:** `On time range change`
   - **Bật Include All option**, điền **Custom all value** là: **`.*`**
   - **Query:**
     ```flux
     import "influxdata/influxdb/schema"
     schema.tagValues(bucket: "device_csv", tag: "csv_name")
     ```

---

## Bước 4: Tạo Từng Nhóm Panel

Trong chế độ **Edit**, bấm **Add → Visualization** để thêm biểu đồ, và **Add → Row** để thêm thanh tiêu đề ngăn nhóm.

---

### 4.1. Hai Ô Số Tổng Quan (Trên Cùng)

**1. Panel `Tổng Số Thiết Bị` (Chọn kiểu: `Stat` | Nguồn: `InfluxDB-Monitoring`)**
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
- Giải thích:  Lấy chỉ số `cpu` trong 5 phút gần nhất → gom theo từng `device` và lấy 1 dòng cuối (`last()`) để mỗi máy chỉ tính 1 lần → gộp hết lại (`group()`) rồi đếm (`count()`).
- **Cài đặt bên phải:** Calculation `Last*`, Color mode `Background`, Unit `Short`, No value `0`, Color `blue`.

**2. Panel `Thiết Bị Online` (Duplicate Panel 1)**
- Giống hệt Panel 1, chỉ sửa **`range(start: -2m)`** (máy nào gửi tin trong 2 phút qua thì tính là đang online) và đổi Color sang `green`.

---

### 4.2. Thông Tin Tài Nguyên Máy (`Row: TÀI NGUYÊN HỆ THỐNG: $device`)

#### 1. CPU (`CPU Usage (%) - ${device}`) — Kiểu `Time series`
Thêm 2 query (bấm **+ Add query**) để vẽ 2 đường System và User:
- **Query A** *(đặt tên RefID: `System`)*:
  ```flux
  from(bucket: "system_metrics")
    |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
    |> filter(fn: (r) => r._measurement == "cpu" and r.cpu == "cpu-total" and r._field == "usage_system")
    |> filter(fn: (r) => r.device =~ /^${device:regex}$/)
    |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)
    |> drop(columns: ["cpu", "device", "device_name", "host", "location", "_measurement", "_start", "_stop"])
    |> yield(name: "System")
  ```
- **Query B** *(đặt tên RefID: `User`)*: Giống Query A, chỉ đổi `usage_system` → **`usage_user`** và `yield(name: "User")`.
- **Giải thích:** Lọc `r.cpu == "cpu-total"` để lấy % CPU tổng (không tách lẻ từng nhân).
- **Cài đặt:** Unit `Percent (0-100)`, Line interpolation `Smooth`, Fill opacity `15`. Vào tab **Overrides** đổi tên `System` → `CPU Hệ Thống (Kernel)` (màu `blue`), `User` → `CPU Ứng Dụng (User)` (màu `orange`).

#### 2. RAM (`RAM Usage (%) - ${device}`) — Kiểu `Time series`
```flux
from(bucket: "system_metrics")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "mem" and r._field == "used_percent")
  |> filter(fn: (r) => r.device =~ /^${device:regex}$/)
  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)
  |> drop(columns: ["device", "device_name", "host", "location", "_measurement", "_start", "_stop"])
  |> yield(name: "RAM")
```
- **Cài đặt:** Unit `Percent (0-100)`, Color `green`, Legend `Table` (chọn `Last*`, `Max`). Tab **Overrides** đổi tên `RAM` → `RAM Đã Dùng (%)`.

#### 3. Ổ đĩa (`Disk Usage (Root /) - ${device}`) — Kiểu `Pie chart`
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
- **Giải thích:** Lấy dung lượng `used` và `free` của thư mục gốc `/` (nếu muốn xem ổ khác như `/data` thì đổi `r.path == "/data"`), lấy giá trị mới nhất (`last()`), rồi dùng `map(...)` đổi tên sang tiếng Việt.
- **Cài đặt:** Pie chart type `Donut`, Labels `Name` + `Percent`, Unit `Data -> bytes (IEC)`. Tab **Overrides** (`Fields with name`): `Đã dùng` (`orange`), `Còn trống` (`green`).

#### 4. Mạng (`Network Download` & `Network Upload`) — Kiểu `Gauge`
- **Panel Download (`Network Download - ${device}`):**
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
- **Panel Upload (`Network Upload - ${device}`):** Duplicate panel Download, sửa `bytes_recv` → **`bytes_sent`**.
- **Giải thích:** `derivative(unit: 1s)` đổi tổng bytes thành tốc độ **bytes/giây** cho từng card mạng; sau đó `last() |> group() |> sum()` cộng tốc độ tất cả card mạng trên máy lại (muốn đo riêng 1 card như `eth0` thì thêm `and r.interface == "eth0"` ở dòng `filter`).
- **Cài đặt:** Unit `Data rate -> bytes/sec (IEC)`, Min `0`, No value `0 B/s`, Color `From thresholds`. Thresholds: Base `green`, `5242880` (5 MiB/s) vàng, `20971520` (20 MiB/s) đỏ.

---

### 4.3. Card Đồ Họa NVIDIA GPU (`Row: GIÁM SÁT CARD ĐỒ HỌA (NVIDIA GPU): $device`)

Cả 4 biểu đồ GPU đều là **`Time series`** và dùng chung một khung Query (chỉ khác tên `_field`):

```flux
from(bucket: "system_metrics")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "nvidia_smi" and r._field == "TEN_FIELD")
  |> filter(fn: (r) => r.device =~ /^${device:regex}$/)
  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)
  |> drop(columns: ["arch", "compute_mode", "pstate", "uuid", "device", "device_name", "host", "location", "_measurement", "_start", "_stop"])
```


Bảng thông số để tạo nhanh 4 panel GPU:

| Panel | Thay `TEN_FIELD` bằng | Unit & Cấu hình riêng |
| :--- | :--- | :--- |
| **GPU Core Utilization (%)** | `utilization_gpu` | Unit: `Percent (0-100)`, Min `0`, Max `100`, No value `0%` |
| **GPU VRAM Memory Usage (MiB)** | Tạo 2 query:<br>• `Used`: `memory_used`<br>• `Total`: `memory_total` | Unit: `Data -> megabytes (mbytes)`, No value `Thiết bị không có GPU`.<br>Overrides: `Total` chọn Line style `Dash` (nét đứt), Fill opacity `0`. |
| **GPU Nhiệt Độ (°C)** | `temperature_gpu` | Unit: `Temperature -> Celsius (°C)`, Fill opacity `20` |
| **GPU Công Suất (W)** | `power_draw` *(nên sửa `every: 1m` cho mượt)* | Unit: `Energy -> Watt (W)`, Fill opacity `0`, Line `Linear` |

---

### 4.4. Bảng Dữ Liệu File CSV (`Row: DỮ LIỆU TẬP TIN CSV: $device`)

Tạo Panel **`Table`** dùng nguồn `InfluxDB-Monitoring`, tiêu đề `Bảng Dữ Liệu CSV Chi Tiết: ${device} (Tập tin: ${csv_file})`:

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

**Giải thích:**
1. `range(start: -30d)`: lấy trong 30 ngày gần nhất để file CSV cũ vẫn hiện.
2. `group(... "row_id", "_field") |> last()`: mỗi phút Telegraf đọc lại file CSV 1 lần; lệnh này giữ **bản mới nhất của từng ô**, tránh bị lặp dòng.
3. `toString()`: ép mọi giá trị về dạng chữ để không bị lỗi khi file có nhiều kiểu dữ liệu.
4. `pivot(...)`: InfluxDB lưu từng cột CSV thành từng dòng riêng; `pivot` giúp **xoay ngang lại thành bảng giống file CSV gốc**.
5. `drop(...) |> limit(n: 500)`: bỏ cột kỹ thuật thừa và giới hạn 500 dòng cho nhẹ trình duyệt.
- **Cài đặt:** Bật **Pagination** (`20` dòng/trang), Display name: `${__field.name}`.

---

### 4.5. Sơ Đồ ERD (`Row: SƠ ĐỒ THỰC THỂ QUAN HỆ (ERD))

Tạo Panel **`Business Charts`** (plugin vừa cài), nguồn **`PostgreSQL-Catalog`**, tiêu đề `Sơ Đồ Thực Thể Quan Hệ (ERD) — Thiết Bị: ${device} | DB: ${db_name}`.

> **Nguyên lý chung:** Grafana không tự vẽ được sơ đồ bảng Database đẹp như pgAdmin 4, nên ta **mượn khung Panel này để nhúng trang web vẽ ERD đang chạy ở cổng `8088`**. Khi bạn đổi máy hoặc database trên thanh lọc, code sẽ tự cập nhật lại trang web nhúng bên trong.

#### 1. Phần Query SQL *(chuyển sang chế độ **Code**, Format chọn **Table**)*
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

**Giải thichs Query SQL**
- **`nodes` & `edges`:** Lấy danh sách các **bảng** (tên bảng, cột, PK/FK) và **đường nối khóa ngoại** của `${device}` / `${db_name}` từ PostgreSQL.
- **Tác dụng chính:** Dùng để kiểm tra dữ liệu bảng thô (khi bật *Table view*), đồng thời mỗi khi đổi máy hay database trên dropdown, query chạy lại và báo cho phần JavaScript bên dưới vẽ lại sơ đồ mới.

#### 2. Phần Script JavaScript (`Charts Function` / `getOption`) ở thanh bên phải
```javascript
// BƯỚC 1: Tìm khung HTML chứa Panel này trên trang Grafana
let chart = (typeof echartsInstance !== 'undefined')
  ? echartsInstance
  : (typeof context !== 'undefined' && context.panel ? context.panel.chart : null);

let dom = null;
if (chart && typeof chart.getDom === 'function') {
  dom = chart.getDom();
} else if (typeof context !== 'undefined' && context.element) {
  dom = context.element;
} else if (typeof context !== 'undefined' && context.container) {
  dom = context.container;
}

// BƯỚC 2: Đọc tên Máy và Database bạn đang chọn ở menu trên cùng
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
} catch (e) {}

// BƯỚC 3: Tạo đường link gọi tới web vẽ ERD (cổng 8088)
const host = window.location.hostname || 'localhost';
const iframeUrl = 'http://' + host + ':8088/?device=' + encodeURIComponent(deviceName) + '&db=' + encodeURIComponent(dbName);

// BƯỚC 4: Nhúng cửa sổ web (iframe) vào khung Panel
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
    iframe.style.cssText = 'position:absolute;top:0;left:0;width:100%;height:100%;border:none;z-index:100;background:#f8fafc;border-radius:6px;';
    dom.appendChild(iframe);
  } else if (iframe.getAttribute('data-url') !== iframeUrl) {
    iframe.src = iframeUrl;
    iframe.setAttribute('data-url', iframeUrl);
  }
}

// BƯỚC 5: Trả về rỗng để plugin không vẽ biểu đồ khác đè lên
return {};
```
Phương pháp nghiên cứu và kỹ năng viết học thuật
**Tóm tắt 5 bước Script làm gì (dành cho người mới):**
1. **Tìm ô chứa Panel (`dom`):** Lấy đúng vùng trống của Panel này trên màn hình *(viết nhiều điều kiện `if` để tương thích mọi phiên bản Grafana)*.
2. **Đọc biến đang chọn:** Lấy tên **Máy** và **Database** từ thanh dropdown
3. **Ghép link web ERD:** Tự lấy IP máy chủ trên trình duyệt (`window.location.hostname`) để tạo thành link `http://<IP_MAY_A>:8088/?device=...&db=...` .
4. **Nhúng web vào Panel (`<iframe>`):**
   - Lần đầu mở: tạo một khung web con tràn 100% Panel trỏ vào link trên.
   - Khi Dashboard tự làm mới mỗi 10s: kiểm tra `data-url`, **chỉ tải lại khi bạn đổi sang Máy hoặc DB khác** để sơ đồ không bị giật hay mất vị trí vừa kéo.
5. **Trả về `{}`:** Báo cho plugin không cần vẽ biểu đồ ECharts nào đè lên khung web vừa nhúng.

> **Cổng `8088` xử lý gì bên trong?** Service [`server.py`](../Script/May_A/erd_service/server.py) nhận tên máy & DB từ link trên, lấy dữ liệu bảng/khóa từ PostgreSQL rồi dùng [`index.html`](../Script/May_A/erd_service/public/index.html) (Cytoscape + ELK) vẽ thành sơ đồ kéo thả và xuất ảnh PNG.

---

## Bước 5: Tự Tạo Thêm Biểu Đồ Mới (Nếu Muốn Mở Rộng)

Telegraf đã gửi sẵn thêm một số dữ liệu khác vào `system_metrics`. Bạn chỉ cần đổi `_measurement` và `_field` theo công thức ở Bước 2:

- **Tốc độ đọc/ghi ổ đĩa (`diskio`):**
  ```flux
  from(bucket: "system_metrics")
    |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
    |> filter(fn: (r) => r._measurement == "diskio" and (r._field == "read_bytes" or r._field == "write_bytes"))
    |> filter(fn: (r) => r.device =~ /^${device:regex}$/)
    |> derivative(unit: 1s, nonNegative: true)
    |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)
    |> drop(columns: ["device", "device_name", "host", "location", "_measurement", "_start", "_stop"])
  ```
- **Thời gian máy chạy liên tục (Uptime — chọn `Stat`, Unit `seconds`):**
  ```flux
  from(bucket: "system_metrics")
    |> range(start: -5m)
    |> filter(fn: (r) => r._measurement == "system" and r._field == "uptime")
    |> filter(fn: (r) => r.device =~ /^${device:regex}$/)
    |> last()
  ```
- **Số kết nối vào PostgreSQL (`postgresql`):**
  ```flux
  from(bucket: "system_metrics")
    |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
    |> filter(fn: (r) => r._measurement == "postgresql" and r._field == "numbackends")
    |> filter(fn: (r) => r.device =~ /^${device:regex}$/)
    |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)
    |> drop(columns: ["device", "device_name", "host", "location", "server", "_measurement", "_start", "_stop"])
  ```
