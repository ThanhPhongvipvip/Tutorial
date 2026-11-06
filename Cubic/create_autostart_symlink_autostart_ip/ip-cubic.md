# Hướng dẫn: Tích hợp IP tĩnh `192.168.1.86` vào ISO Ubuntu bằng Cubic

## 1. Mục tiêu và giới hạn

Sau khi cài Ubuntu từ ISO lên ổ cứng và khởi động hệ thống đã cài, một service systemd sẽ tự chạy một lần để:

1. Bỏ qua phiên Ubuntu Live.
2. Chờ NetworkManager có IPv4, gateway và profile hoạt động.
3. Chỉ tiếp tục nếu mạng hiện tại là `192.168.1.0/24` và gateway nằm trong subnet đó.
4. Dùng ARP để kiểm tra dấu hiệu địa chỉ `192.168.1.86` đã có thiết bị sử dụng.
5. Tạo profile NetworkManager tĩnh cho `192.168.1.86/24`, gateway phát hiện từ mạng và DNS dạng danh sách phân tách bằng dấu phẩy.
6. Ưu tiên profile tĩnh qua các lần khởi động lại; giữ profile DHCP làm phương án dự phòng.
7. Ghi log và đánh dấu hoàn tất sau khi xác minh IP đã được gán.

**Giới hạn:** Cách này chỉ áp dụng trực tiếp cho mạng `192.168.1.0/24`. Ở mạng khác, script từ chối áp dụng IP tĩnh và giữ cấu hình mạng hiện tại. ARP không thể bảo đảm địa chỉ nằm ngoài dải DHCP của router. Trước khi triển khai, dành riêng `192.168.1.86` ngoài DHCP pool trên router hoặc xác nhận với quản trị mạng. Không cài cùng ISO cho nhiều máy trong cùng LAN nếu tất cả đều dùng chung IP này.

## 2. Khai báo biến đường dẫn

### Trong terminal máy host

Khai báo biến ROOT để sử dụng trong các bước sau:

```bash
# Thay bằng đường dẫn đến custom root thực tế
ROOT="/custom-root"
```

**Hoặc thêm vào ~/.bashrc để không phải khai báo lại:**

```bash
echo 'export ROOT="/custom-root"' >> ~/.bashrc
source ~/.bashrc
```

Tất cả thay đổi dưới đây phải được đưa vào `custom-root` trước khi tạo ISO mới. Sửa file bên trong Ubuntu đã cài chỉ ảnh hưởng hệ thống đó, không tự cập nhật ISO.

## 3. Cài tiện ích ARP vào hệ thống đích

Mở terminal chroot của Cubic và chạy:

```bash
apt update
apt install -y iputils-arping
command -v arping
```

Không chỉ cài `iputils-arping` trên máy nguồn; tiện ích phải có trong hệ thống Ubuntu được tạo từ ISO.

## 4. Cài script vào `custom-root`

Script `c-auto-static-ip.sh` nằm trong thư mục `script/` của dự án. Trên máy Ubuntu nguồn chạy:

```bash
# Biến ROOT đã khai báo ở bước 2

sudo install -D -o root -g root -m 755 \
  /c-auto-static-ip.sh \
  "$ROOT/usr/local/sbin/c-auto-static-ip.sh"
```

Nếu script ở nơi khác, thay đường dẫn nguồn cho đúng.

Kiểm tra cú pháp:

```bash
sudo bash -n "$ROOT/usr/local/sbin/c-auto-static-ip.sh"
echo "Cú pháp OK"
```

## 5. Tạo service systemd

Tạo unit file:

```bash
# Biến ROOT vẫn còn từ bước 2

sudo tee "$ROOT/etc/systemd/system/c-auto-static-ip.service" >/dev/null <<'EOF'
[Unit]
Description=Configure fixed IPv4 address 192.168.1.86/24 after installation
Wants=NetworkManager-wait-online.service
After=NetworkManager.service NetworkManager-wait-online.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/c-auto-static-ip.sh
TimeoutStartSec=180

[Install]
WantedBy=multi-user.target
EOF
```

Bật service trong root filesystem mà không chạy `systemctl enable` trên máy nguồn:

```bash
# Biến ROOT vẫn còn từ bước trên

sudo mkdir -p "$ROOT/etc/systemd/system/multi-user.target.wants"
sudo ln -sfn \
  ../c-auto-static-ip.service \
  "$ROOT/etc/systemd/system/multi-user.target.wants/c-auto-static-ip.service"
```

Kiểm tra file và symlink:

```bash
sudo ls -l \
  "$ROOT/usr/local/sbin/c-auto-static-ip.sh" \
  "$ROOT/etc/systemd/system/c-auto-static-ip.service" \
  "$ROOT/etc/systemd/system/multi-user.target.wants/c-auto-static-ip.service"
sudo bash -n "$ROOT/usr/local/sbin/c-auto-static-ip.sh"
```

## 6. Tạo ISO mới bằng Cubic

1. Mở dự án Cubic.
2. Xác nhận các file đã nằm trong `custom-root`.
3. Đảm bảo `iputils-arping` đã được cài trong môi trường đích/chroot.
4. Hoàn tất quy trình tạo ISO mới.
5. Giữ lại ISO cũ làm bản dự phòng, không nhầm với ISO mới.

## 7. Kiểm thử ISO

### Mạng cần kiểm thử

- Test IP đích `192.168.1.86` cần máy có kết nối vào mạng `192.168.1.0/24`.
- Cài Ubuntu từ ISO vào ổ cứng ảo hoặc ổ đích, rồi boot vào Ubuntu đã cài; script chủ động bỏ qua phiên Live.
- Trước khi test, xác nhận IP `.86` không bị dùng và được loại khỏi DHCP pool hoặc được quản trị mạng dành riêng.

### Sau lần boot đầu tiên của Ubuntu đã cài

```bash
ip -4 -br addr
ip -4 route
nmcli connection show --active
sudo cat /var/log/c-auto-static-ip.log
sudo journalctl -u c-auto-static-ip.service -b --no-pager
```

Kết quả mong đợi trong LAN phù hợp:

```text
enp...  UP  192.168.1.86/24
```

Gateway được phát hiện khi DHCP ban đầu hoạt động, ví dụ `192.168.1.1`.

Kiểm tra Internet:

```bash
ping -c 3 192.168.1.1
curl -4 -I --connect-timeout 5 --max-time 10 https://ubuntu.com
```

Ping có thể bị chặn; `curl` thành công là một kiểm tra hữu ích cho kết nối HTTPS IPv4.

### Kiểm tra sau reboot

```bash
sudo reboot
```

Sau khi quay lại desktop:

```bash
ip -4 -br addr
ip -4 route
nmcli connection show --active
```

Xác nhận IP vẫn là `192.168.1.86/24` và profile `c-fixed-ip-<interface>` đang hoạt động.


## 8. Những điều cần nhớ

- Script chạy một lần trên Ubuntu đã cài, không chỉnh mạng phiên Live.
- Chỉ dùng IP cố định này trong subnet `192.168.1.0/24`.
- Nếu mang máy sang subnet khác, script không tự đổi IP tĩnh cũ sang subnet mới; cần cấu hình lại hoặc dùng thiết kế DHCP thích ứng.
- Không triển khai cùng IP `.86` cho nhiều máy trong cùng mạng.
- Để đảm bảo không xung đột, cấu hình router/quản trị mạng để dành riêng IP ngoài DHCP pool là quan trọng hơn kiểm tra ARP đơn thuần.
