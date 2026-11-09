# Hướng Dẫn Tạo Dashboard Grafana

## Mục Tiêu

Tạo dashboard để giám sát nhiều máy, hiển thị:
- CPU, RAM, Disk, Network của từng máy
- Trạng thái Online/Offline
- Graphs theo thời gian
- Cảnh báo khi có vấn đề

---

## Phần 1: Tạo Dashboard Đầu Tiên

### Bước 1.1: Tạo Dashboard Mới

1. Vào Grafana: http://192.168.1.53:3000
2. Click **+** (dấu cộng) ở sidebar
3. Chọn **Dashboard**
4. Click **Add new panel**

### Bước 1.2: Tạo Panel CPU Usage

Trong panel editor:

**1. Query:**
```flux
from(bucket: "system_metrics")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "cpu")
  |> filter(fn: (r) => r._field == "usage_system" or r._field == "usage_user")
  |> filter(fn: (r) => r.cpu == "cpu-total")
  |> group(columns: ["device", "_field"])
  |> aggregateWindow(every: v.windowPeriod, fn: mean)
```

**2. Transform:**
- Click **Transform** tab
- Add transformation: **Organize fields**
- Rename:
  - `_value` → `CPU %`
  - `device` → `Machine`

**3. Panel Settings:**
```
Title: CPU Usage by Machine
Unit: Percent (0-100)
Min: 0
Max: 100
Legend: {{Machine}} - {{_field}}
```

**4. Visualization:**
- Type: **Time series**
- Style: **Lines**
- Fill opacity: 10%

Click **Apply** để lưu panel.

---

## Phần 2: Thêm Panel Memory Usage

### Bước 2.1: Add Panel

- Click **Add panel** icon (ở top-right dashboard)
- Chọn **Add new panel**

### Bước 2.2: Query Memory

```flux
from(bucket: "system_metrics")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "mem")
  |> filter(fn: (r) => r._field == "used_percent")
  |> group(columns: ["device"])
  |> aggregateWindow(every: v.windowPeriod, fn: mean)
```

### Bước 2.3: Panel Settings

```
Title: Memory Usage by Machine
Unit: Percent (0-100)
Min: 0
Max: 100
Legend: {{device}}
Thresholds:
  - 70% → Yellow
  - 85% → Red
```

Visualization: **Time series** hoặc **Gauge**

Click **Apply**.

---

## Phần 3: Panel Disk Usage

### Query

```flux
from(bucket: "system_metrics")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "disk")
  |> filter(fn: (r) => r._field == "used_percent")
  |> filter(fn: (r) => r.path == "/" or r.path == "/home")
  |> group(columns: ["device", "path"])
  |> aggregateWindow(every: v.windowPeriod, fn: mean)
```

### Settings

```
Title: Disk Usage
Unit: Percent (0-100)
Legend: {{device}} {{path}}
Thresholds:
  - 80% → Yellow
  - 90% → Red
```

Visualization: **Bar gauge** (hiển thị thanh ngang)

---

## Phần 4: Panel Network Traffic

### Query

```flux
from(bucket: "system_metrics")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "net")
  |> filter(fn: (r) => r._field == "bytes_sent" or r._field == "bytes_recv")
  |> filter(fn: (r) => r.interface !~ /docker|veth|lo/)
  |> group(columns: ["device", "_field", "interface"])
  |> aggregateWindow(every: v.windowPeriod, fn: mean)
  |> derivative(unit: 1s, nonNegative: true)
```

### Settings

```
Title: Network Traffic
Unit: Bytes/sec
Legend: {{device}} {{interface}} {{_field}}
```

Visualization: **Time series**

---

## Phần 5: Panel Status Online/Offline

### Bước 5.1: Query Heartbeat

```flux
from(bucket: "system_metrics")
  |> range(start: -1m)
  |> filter(fn: (r) => r._measurement == "device_heartbeat")
  |> filter(fn: (r) => r._field == "online")
  |> group(columns: ["device"])
  |> last()
```

### Bước 5.2: Settings

```
Title: Machine Status
Visualization: Stat (hoặc Table)
Value mappings:
  1 → Online (Green)
  0 → Offline (Red)
Color mode: Background
```

---

## Phần 6: Panel Tổng Quan (Overview)

### Query: Tổng Số Máy Online

```flux
from(bucket: "system_metrics")
  |> range(start: -1m)
  |> filter(fn: (r) => r._measurement == "device_heartbeat")
  |> filter(fn: (r) => r._field == "online")
  |> group()
  |> sum()
```

Settings:
```
Title: Total Machines Online
Visualization: Stat
Unit: None
Color: Green
Text size: 40px
```

### Query: CPU Trung Bình

```flux
from(bucket: "system_metrics")
  |> range(start: -5m)
  |> filter(fn: (r) => r._measurement == "cpu")
  |> filter(fn: (r) => r._field == "usage_system" or r._field == "usage_user")
  |> filter(fn: (r) => r.cpu == "cpu-total")
  |> group()
  |> mean()
```

Settings:
```
Title: Average CPU Usage
Visualization: Gauge
Unit: Percent (0-100)
Thresholds: 70% → 85% → Red
```

---

## Phần 7: Layout Dashboard

### Bước 7.1: Sắp Xếp Panels

Kéo thả các panel để tạo layout:

```
┌──────────────────────────────────────────────────┐
│  Dashboard: System Monitoring                    │
├──────────────┬──────────────┬────────────────────┤
│ Machines     │ Avg CPU      │ Avg Memory         │
│ Online: 3    │ 45%          │ 62%                │
├──────────────┴──────────────┴────────────────────┤
│  Machine Status                                  │
│  may-01: Online ✓   may-02: Online ✓            │
│  may-03: Offline ✗                               │
├──────────────────────────────────────────────────┤
│  CPU Usage (%)                                   │
│  [Graph theo thời gian]                          │
├──────────────────────────────────────────────────┤
│  Memory Usage (%)                                │
│  [Graph theo thời gian]                          │
├──────────────────────────────────────────────────┤
│  Disk Usage (%)     │  Network Traffic           │
│  [Bar gauge]        │  [Time series]             │
└─────────────────────┴────────────────────────────┘
```

### Bước 7.2: Lưu Dashboard

1. Click **Save dashboard** (💾 icon ở top-right)
2. Tên: `System Monitoring`
3. Folder: `General` hoặc tạo folder mới
4. Click **Save**

---

## Phần 8: Thêm Biến (Variables)

Variables giúp chọn máy cụ thể để xem.

### Bước 8.1: Tạo Variable `machine`

1. Dashboard settings (⚙️ icon) → **Variables**
2. Click **Add variable**

**Cấu hình:**
```
Name: machine
Type: Query
Label: Machine

Data source: InfluxDB-Monitoring
Query type: Flux

Query:
import "influxdata/influxdb/schema"
schema.tagValues(
  bucket: "system_metrics",
  tag: "device",
  predicate: (r) => r._measurement == "cpu"
)

Multi-value: Yes (cho phép chọn nhiều máy)
Include All option: Yes
```

Click **Update** và **Save dashboard**.

### Bước 8.2: Sử Dụng Variable Trong Query

Sửa lại query CPU Usage:

```flux
from(bucket: "system_metrics")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "cpu")
  |> filter(fn: (r) => r._field == "usage_system" or r._field == "usage_user")
  |> filter(fn: (r) => r.cpu == "cpu-total")
  |> filter(fn: (r) => contains(value: r.device, set: ${machine:json}))
  |> group(columns: ["device", "_field"])
  |> aggregateWindow(every: v.windowPeriod, fn: mean)
```

**Kết quả:** Ở top dashboard có dropdown để chọn máy cần xem

---

## Phần 9: Thêm Alerts (Cảnh Báo)

### Bước 9.1: Alert Khi CPU > 80%

1. Edit panel **CPU Usage**
2. Click **Alert** tab
3. Click **Create alert rule from this panel**

**Cấu hình:**
```
Rule name: High CPU Alert
Evaluate every: 1m
For: 5m

Condition:
  WHEN avg() OF query(A, 5m, now) IS ABOVE 80

No data: Alerting
Error: Alerting

Notifications:
  Send to: Default contact point (hoặc email)
Message: CPU usage on {{device}} is {{value}}%
```

Click **Save rule and exit**.

### Bước 9.2: Alert Khi Máy Offline

Tạo alert rule mới:

```
Rule name: Machine Offline Alert

Query:
from(bucket: "system_metrics")
  |> range(start: -5m)
  |> filter(fn: (r) => r._measurement == "device_heartbeat")
  |> filter(fn: (r) => r._field == "online")
  |> group(columns: ["device"])
  |> last()

Condition:
  WHEN last() OF query(A) IS BELOW 1

Message: Machine {{device}} is OFFLINE!
```

---

## Phần 10: Dashboard Templates

### Template 1: Single Machine View

Dashboard chỉ xem 1 máy chi tiết:

**Panels:**
1. CPU Usage per core
2. Memory breakdown (used, cached, buffer)
3. Disk I/O (reads/writes)
4. Network by interface
5. Top processes
6. Service status

### Template 2: Overview All Machines

Dashboard xem tổng quan tất cả:

**Panels:**
1. Total machines online/offline
2. CPU heatmap (tất cả máy)
3. Memory heatmap
4. Alerts summary
5. Top 5 máy CPU cao nhất
6. Top 5 máy RAM cao nhất

### Template 3: CSV Data Dashboard

Nếu có CSV monitoring:

```flux
from(bucket: "device_csv")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "file")
  |> filter(fn: (r) => r.csv_name == "language")
  |> pivot(rowKey: ["_time"], columnKey: ["_field"], valueColumn: "_value")
```

---

## Phần 11: Thủ Thuật Hữu Ích

### 11.1: Auto-Refresh

```
Dashboard settings → Time options
Refresh: 5s, 10s, 30s, 1m (chọn)
```

### 11.2: Time Range Presets

```
Quick ranges:
- Last 5 minutes
- Last 15 minutes
- Last 1 hour
- Last 6 hours
- Last 24 hours
- Last 7 days
```

### 11.3: Panel Links

Thêm link từ overview dashboard → detail dashboard:

```
Panel → Settings → Links
Add link:
  Title: View Details
  URL: /d/machine-detail?var-machine=${__field.labels.device}
  Open in new tab: Yes
```

### 11.4: Repeated Panels

Tạo 1 panel lặp lại cho từng máy:

```
Panel → Settings → Repeat options
Repeat by variable: $machine
Direction: Horizontal
Max per row: 3
```

---

## Phần 12: Export/Import Dashboard

### Export

1. Dashboard settings → JSON Model
2. Copy toàn bộ JSON
3. Lưu vào file `dashboard.json`

### Import

1. Grafana → + → Import
2. Paste JSON hoặc upload file
3. Chọn data source: InfluxDB-Monitoring
4. Click **Import**

---

## Queries Hữu Ích

### Query 1: Top 5 Máy CPU Cao Nhất

```flux
from(bucket: "system_metrics")
  |> range(start: -5m)
  |> filter(fn: (r) => r._measurement == "cpu")
  |> filter(fn: (r) => r._field == "usage_idle")
  |> filter(fn: (r) => r.cpu == "cpu-total")
  |> group(columns: ["device"])
  |> mean()
  |> map(fn: (r) => ({ r with _value: 100.0 - r._value }))
  |> top(n: 5)
```

### Query 2: Tổng Disk Dùng (GB)

```flux
from(bucket: "system_metrics")
  |> range(start: -1m)
  |> filter(fn: (r) => r._measurement == "disk")
  |> filter(fn: (r) => r._field == "used")
  |> filter(fn: (r) => r.path == "/")
  |> group(columns: ["device"])
  |> last()
  |> map(fn: (r) => ({ r with _value: r._value / 1073741824.0 }))
```

Unit: GB

### Query 3: Network Bandwidth Total

```flux
from(bucket: "system_metrics")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "net")
  |> filter(fn: (r) => r._field == "bytes_sent" or r._field == "bytes_recv")
  |> group(columns: ["_field"])
  |> aggregateWindow(every: v.windowPeriod, fn: sum)
  |> derivative(unit: 1s, nonNegative: true)
  |> map(fn: (r) => ({ r with _value: r._value * 8.0 / 1000000.0 }))
```



