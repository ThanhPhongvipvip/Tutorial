# Hệ Thống Giám Sát Grafana - Giám Sát Nhiều Máy

## Mục Tiêu

Xây dựng **dashboard Grafana** để giám sát hoạt động của nhiều máy từ xa:
- CPU, RAM, Disk, Network của từng máy
- Trạng thái Online/Offline
- CSV data, PostgreSQL, Docker, Services
- Cảnh báo khi có vấn đề

## Kiến Trúc Hệ Thống

```
┌─────────────┐
│  Máy Agent  │ ──┐
│  (may-01)   │   │
└─────────────┘   │
                  ├──→ ┌──────────┐    ┌──────────┐
┌─────────────┐   │    │ InfluxDB │───→│ Grafana  │
│  Máy Agent  │ ──┤    │ (Server) │    │Dashboard │
│  (may-02)   │   │    └──────────┘    └──────────┘
└─────────────┘   │
                  │
┌─────────────┐   │
│  Máy Agent  │ ──┘
│  (may-03)   │
└─────────────┘
```

- **InfluxDB**: Lưu trữ metrics từ tất cả các máy
- **Grafana**: Hiển thị dashboard, tạo cảnh báo
- **Telegraf Agent**: Cài trên từng máy cần giám sát

## File Trong Thư Mục

| File | Mô Tả |
|------|-------|
| **README.md** | File này - hướng dẫn tổng quan |
| **SETUP.md** | Hướng dẫn cài đặt từng bước |
| **DASHBOARD.md** | Hướng dẫn tạo dashboard Grafana |
| **device.yaml** | File config mẫu cho agent |
| **install-agent-v2.sh** | Script cài agent |

## Bắt Đầu (Chọn 1 Trong 2)

### Người Mới Bắt Đầu

Đọc theo thứ tự:
1. **SETUP.md** - Cài đặt hệ thống từ đầu
2. **DASHBOARD.md** - Tạo dashboard giám sát

Thời gian: ~60 phút

### Người Đã Có InfluxDB + Grafana

Bỏ qua phần 1-2, chỉ cần:
1. Cài agent lên các máy cần giám sát
2. Tạo dashboard

Thời gian: ~15 phút

## Tổng Quan Các Bước

### Bước 1: Cài InfluxDB (Server Trung Tâm)
→ Xem **SETUP.md phần 1**

```bash
# Cài InfluxDB trên 1 máy server
# Tạo buckets: system_metrics, device_csv
# Tạo token để agent gửi metrics
```

### Bước 2: Cài Grafana (Server Trung Tâm)
→ Xem **SETUP.md phần 2**

```bash
# Cài Grafana trên cùng máy hoặc máy khác
# Kết nối Grafana với InfluxDB
```

### Bước 3: Cài Agent Trên Các Máy
→ Xem **SETUP.md phần 3**

```bash
# Trên mỗi máy cần giám sát:
cp device.yaml device.may-01.yaml
# Sửa: device.id và influxdb.url
export INFLUX_TOKEN="token"
sudo -E ./install-agent-v2.sh
```

### Bước 4: Tạo Dashboard
→ Xem **DASHBOARD.md**

```
1. Tạo dashboard mới trong Grafana
2. Thêm panel hiển thị CPU từng máy
3. Thêm panel hiển thị RAM từng máy
4. Thêm panel hiển thị Disk, Network
5. Thêm cảnh báo khi CPU > 80%
```

## Metrics Được Thu Thập

Từng máy agent tự động gửi về InfluxDB:

| Loại | Metrics |
|------|---------|
| **Hệ thống** | CPU, RAM, Disk, Network, Processes, Uptime |
| **Heartbeat** | Online/Offline status |
| **CSV** | Dữ liệu từ CSV files |
| **PostgreSQL** | Database metrics (nếu có) |
| **Docker** | Container metrics (nếu có) |
| **Services** | Systemd service status |

## Ví Dụ Dashboard

Dashboard sẽ hiển thị:

```
┌────────────────────────────────────────────────────┐
│  System Overview - 3 Machines                      │
├────────────────────────────────────────────────────┤
│                                                    │
│  may-01: Online ✓   CPU: 45%   RAM: 62%          │
│  may-02: Online ✓   CPU: 78%   RAM: 51%          │
│  may-03: Offline ✗  CPU: --    RAM: --           │
│                                                    │
├────────────────────────────────────────────────────┤
│  CPU Usage (%)                                     │
│  ┌────────────────────────────────────────────┐  │
│  │ may-01 ████████░░░░░░░░░░░░░░░  45%       │  │
│  │ may-02 ███████████████░░░░░░░░  78%       │  │
│  │ may-03 ░░░░░░░░░░░░░░░░░░░░░░░   0%       │  │
│  └────────────────────────────────────────────┘  │
│                                                    │
│  Memory Usage (%)                                  │
│  ┌────────────────────────────────────────────┐  │
│  │ may-01 ████████████░░░░░░░░░░  62%        │  │
│  │ may-02 ██████████░░░░░░░░░░░░  51%        │  │
│  └────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────┘
```

## Yêu Cầu Hệ Thống

### Server Trung Tâm (InfluxDB + Grafana)
- Ubuntu 24.04 LTS (hoặc 20.04/22.04)
- 2GB RAM minimum (4GB khuyến nghị)
- 20GB disk
- IP tĩnh hoặc hostname

### Máy Cần Giám Sát (Agent)
- Ubuntu 24.04 LTS
- 100MB RAM cho agent
- Kết nối network tới InfluxDB server
- Sudo access

## Triển Khai Cho Nhiều Máy

### 1-10 Máy: Cài Thủ Công
```bash
# Trên từng máy:
cp device.yaml device.may-X.yaml
# Sửa device.id
sudo -E ./install-agent-v2.sh
```

### 10-100 Máy: Script Tự Động
```bash
# Dùng vòng lặp và SSH
for machine in may-01 may-02 may-03; do
  ssh $machine 'bash -s' < install-agent-v2.sh
done
```

### 100+ Máy: Ansible/Puppet
→ Xem **SETUP.md phần 4**

## Lưu Ý Quan Trọng

1. **Token bảo mật**: Không lưu token trong file, dùng biến môi trường
2. **Firewall**: Mở port 8086 (InfluxDB) cho các máy agent kết nối
3. **Disk space**: InfluxDB cần đủ disk để lưu metrics (ước tính: 100MB/máy/tháng)
4. **Time sync**: Tất cả máy phải đồng bộ thời gian (NTP)

## Hỗ Trợ

**Hướng dẫn cài đặt**: Đọc **SETUP.md**

**Tạo dashboard**: Đọc **DASHBOARD.md**

**Gặp lỗi**: Xem phần troubleshooting trong **SETUP.md**

---

**Phiên bản:** v2.0  
**Cập nhật:** November 2025  
**Tác giả:** Phongvt
