# Tổng Quan Hệ Thống Giám Sát & Sơ Đồ ERD

Hệ thống thu thập chỉ số phần cứng, dịch vụ, dữ liệu CSV và cấu trúc cơ sở dữ liệu PostgreSQL từ nhiều máy con về một **Máy Chủ Trung Tâm (Máy A)** để hiển thị trực quan trên Grafana, kèm công cụ vẽ sơ đồ quan hệ ERD tương tác.

---

## 1. Luồng Hoạt Động & Kiến Trúc

```mermaid
flowchart TD
    subgraph AgentMachines ["Các Máy Con (Máy B, Máy C...)"]
        MB_Sys["Phần cứng & GPU\n(CPU, RAM, Disk, NVIDIA)"]
        MB_PG["PostgreSQL\n(Tự phát hiện các DB)"]
        MB_CSV["Tập tin CSV\n(Đánh số dòng row_id)"]
        MB_Telegraf["Telegraf Agent"]
        MB_Cron["manage.py collect\n(Cronjob 5 phút/lần)"]

        MB_Sys --> MB_Telegraf
        MB_PG --> MB_Telegraf
        MB_CSV --> MB_Telegraf
        MB_PG -.-> MB_Cron
    end

    subgraph CentralServer ["Máy Chủ Trung Tâm (Máy A)"]
        MA_Influx["InfluxDB 2.x (:8086)\nsystem_metrics, device_csv, device_database"]
        MA_Catalog["PostgreSQL Catalog (:5432)\nmonitoring_catalog"]
        MA_ERD["ERD Viewer (:8088)\nCytoscape.js + ELK"]
        MA_Grafana["Grafana (:3000)\nDashboard Tổng Hợp"]

        MB_Telegraf -- "Gửi chỉ số & CSV" --> MA_Influx
        MB_Cron -- "Gửi cấu trúc bảng & khóa ngoại" --> MA_Catalog

        MA_Influx --> MA_Grafana
        MA_Catalog --> MA_Grafana
        MA_Catalog --> MA_ERD
        MA_ERD -- "Nhúng Iframe" --> MA_Grafana
    end
```

---

## 2. Vai Trò Từng Thành Phần Chính

| Thành phần | Chạy ở đâu? | Nhiệm vụ chính |
| :--- | :---: | :--- |
| **Telegraf** | Máy con | Thu thập định kỳ chỉ số CPU, RAM, Disk, Network, GPU, PostgreSQL và đọc nội dung file CSV gửi về InfluxDB. |
| **`manage.py collect`** | Máy con | Quét cấu trúc bảng, cột, khóa chính/khóa ngoại của PostgreSQL gửi về `monitoring_catalog` mỗi 5 phút. |
| **InfluxDB 2.x** | Máy A (`:8086`) | Lưu trữ dữ liệu chuỗi thời gian (metrics hệ thống) và nội dung bảng CSV. |
| **PostgreSQL Catalog** | Máy A (`:5432`) | Lưu trữ metadata cấu trúc bảng và quan hệ khóa ngoại của tất cả các máy. |
| **ERD Viewer (`server.py`)** | Máy A (`:8088`) | Dịch vụ web vẽ sơ đồ ERD tương tác (Cytoscape + ELK) và hỗ trợ xuất ảnh PNG. |
| **Grafana** | Máy A (`:3000`) | Giao diện web hiển thị toàn bộ biểu đồ, bảng CSV và nhúng khung sơ đồ ERD. |

---

## 3. Cấu Trúc Thư Mục & Tài Liệu

```text
grafana/
├── Script/
│   ├── May_A/                       # Script cài đặt, service ERD, SQL và Dashboard JSON cho Máy A
│   └── May_Khac/                    # Gói cài Agent (install-agent-v2.sh, device.yaml, manage.py) cho Máy con
├── Other/sample_data/               # File CSV mẫu để thử nghiệm bảng và biểu đồ
└── doc/                             # Bộ tài liệu hướng dẫn
    ├── README.md                    # Tổng quan kiến trúc (file này)
    ├── SETUP.md                     # Hướng dẫn cài đặt chi tiết và mục đích từng gói cài
    ├── USAGE.md                     # Cách thêm CSV, chuyển đổi biểu đồ, đồng bộ ERD & xử lý lỗi
    └── MANUAL_DASHBOARD.md          # Hướng dẫn tự tạo Dashboard thủ công & giải thích câu Query
```

**Thứ tự đọc gợi ý:** Đọc [SETUP.md](SETUP.md) để cài đặt hệ thống → xem [USAGE.md](USAGE.md) để vận hành hàng ngày → xem [MANUAL_DASHBOARD.md](MANUAL_DASHBOARD.md) nếu muốn tự dựng hoặc tùy biến biểu đồ Grafana.


