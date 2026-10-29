# Tăng tốc RustDesk với Tailscale


## 1. Cài đặt Tailscale

Cài Tailscale trên cả hai máy:

```bash
# Ubuntu/Debian
curl -fsSL https://tailscale.com/install.sh | sh

# Khởi động Tailscale
sudo tailscale up

# Kiểm tra trạng thái
tailscale status
```

## 2. Đăng nhập RustDesk cùng tài khoản

- Mở RustDesk trên cả hai máy
- Đăng nhập với **cùng một tài khoản RustDesk**
- Điều này đảm bảo hai máy nhận diện nhau

## 3. Bật Direct IP Access

Trên máy **đích** (máy sẽ bị điều khiển):

1. Mở **RustDesk** → **Settings**
2. Chọn tab **Security**
3. Bật **Enable Direct IP Access**
4. Nhập **Port** (ví dụ: `8686` - port mặc định)
5. Nhấn **Apply**

## 4. Kết nối qua IP Tailscale

Trên máy **nguồn** (máy điều khiển):

### Lấy IP Tailscale của máy đích:

```bash
# Trên máy đích, chạy:
tailscale ip -4
# Ví dụ output: 100.64.15.28
```

### Kết nối từ máy nguồn:

1. Mở RustDesk
2. Thay vì nhập **RustDesk ID**, nhập:
   ```
   100.64.15.28:21116
   ```
   (Thay `100.64.15.28` bằng IP Tailscale thực tế)
3. Nhấn **Connect**

## Lợi ích

- Nhanh hơn: Kết nối peer-to-peer trực tiếp
- Ít lag: Không qua relay server
- Bảo mật: Tailscale mã hóa end-to-end
- Ổn định: Không phụ thuộc RustDesk relay

## Kiểm tra kết nối

```bash
# Kiểm tra IP Tailscale
tailscale ip -4

# Kiểm tra port RustDesk đang mở (trên máy đích)
sudo netstat -tulpn | grep 8686

# Ping qua Tailscale network
ping 100.64.15.28
```

## Lưu ý

- Cả hai máy phải đăng nhập vào cùng Tailscale network
- Firewall phải cho phép port RustDesk (ví dụ: `8686`)
