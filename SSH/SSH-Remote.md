# SSH Remote với VirtualGL và Qt GUI

## Tổng quan

Hướng dẫn này giúp chạy ứng dụng Qt có sử dụng GPU từ máy **Ubuntu 2** (remote server) và hiển thị GUI trên máy **Ubuntu 1** (client) thông qua SSH X11 forwarding và VirtualGL.

## Cơ chế hoạt động

### Các thành phần quan trọng

| Thành phần | Mục đích |
|:-----------|:---------|
| `DISPLAY=localhost:10.0` | SSH X11 forwarding từ Ubuntu 2 về Ubuntu 1 |
| `VGL_DISPLAY=:1` | X server có GPU trên Ubuntu 2 |
| `vglclient` | Nhận và hiển thị frame từ VirtualGL trên Ubuntu 1 |
| `VGL_CLIENT` | Địa chỉ IPv6 của Ubuntu 1 để VirtualGL kết nối |

### Luồng dữ liệu

```
Ubuntu 2 (Server)          SSH X11 Forwarding          Ubuntu 1 (Client)
[Ứng dụng Qt]  ─────────────────────────────────▶  [Display GUI]
    ↓ (render GPU)                                      ↑
[VirtualGL]  ──────────────VGL Protocol──────────▶  [vglclient]
```

---

## Thiết lập Ubuntu 1 (Client - Máy hiển thị GUI)

### 1. Cài đặt các gói cần thiết

```bash
# Cài OpenSSH client và X11 utilities
sudo apt update
sudo apt install -y openssh-client xauth x11-utils
```

### 2. Cài đặt VirtualGL

```bash
# Tải VirtualGL package
wget -O ~/virtualgl_3.1.5_amd64.deb \
  https://github.com/VirtualGL/virtualgl/releases/download/3.1.5/virtualgl_3.1.5_amd64.deb

# Kiểm tra file đã tải
file ~/virtualgl_3.1.5_amd64.deb
ls -lh ~/virtualgl_3.1.5_amd64.deb

# Cài đặt
sudo apt install -y ~/virtualgl_3.1.5_amd64.deb

# Xác nhận vglclient đã được cài
which vglclient
```

### 3. Xác định DISPLAY của máy

```bash
echo $DISPLAY
```

**Kết quả mong đợi:** `:0` hoặc `:1`

**Kiểm tra X server hoạt động:**
```bash
DISPLAY=:1 xdpyinfo >/dev/null && echo "✓ X11 :1 OK"
```

### 4. Chạy vglclient

Giả sử DISPLAY của Ubuntu 1 là `:1`:

```bash
DISPLAY=:1 VGLCLIENT_IPV6=1 vglclient -display :1 -port 4242 -ipv6
```

**Kiểm tra vglclient đang chạy:**

```bash
# Kiểm tra process
pgrep -a vglclient

# Kiểm tra port đang listen
sudo ss -lntp | grep 4242
```

**Xem log (nếu có vấn đề):**
```bash
cat ~/.vglclient.log
# Hoặc theo dõi real-time
tail -f ~/.vglclient.log
```

### 5. Kiểm tra IPv6

```bash
# Xem tất cả địa chỉ IPv6
ip -6 addr show

# Hoặc ngắn gọn
ip a | grep inet6
```

Ghi nhớ địa chỉ IPv6 global để cấu hình SSH.

---

## Kết nối SSH

### Phương án 1: SSH thủ công

```bash
ssh -Y username@<IPv6-Ubuntu-2>
```

### Phương án 2: Cấu hình SSH Config (Khuyến nghị)

Chỉnh sửa `~/.ssh/config`:

```bash
Host ubuntu-remote
    HostName <IPv6-Ubuntu-2>
    User username
    Port 22
    AddressFamily inet6
    ForwardX11 yes
    ForwardX11Trusted yes
```

**Kết nối:**
```bash
ssh ubuntu-remote
```

Hoặc dùng **VS Code Remote SSH** với config trên.

---

## Thiết lập Ubuntu 2 (Server - Máy chạy ứng dụng)

### 1. Kiểm tra SSH X11 Forwarding

Sau khi SSH vào Ubuntu 2, kiểm tra:

```bash
echo $DISPLAY
```

**Kết quả mong đợi:** `localhost:10.0` (hoặc `localhost:11.0`, v.v.)

**⚠️ KHÔNG được là:** `:0` hoặc `:1` (nghĩa là X11 forwarding không hoạt động)

**Test X11:**
```bash
xdpyinfo >/dev/null && echo "✓ X11 forwarding OK"
```

### 2. Kiểm tra VirtualGL với GPU NVIDIA

```bash
# Đặt biến môi trường
export VGL_DISPLAY=:1

# Kiểm tra GPU thông qua VirtualGL
vglrun -d :1 glxinfo -B | grep -E 'OpenGL vendor|OpenGL renderer'
```

**Kết quả mong đợi:**
```
OpenGL vendor string: NVIDIA Corporation
OpenGL renderer string: NVIDIA GeForce RTX 3060/PCIe/SSE2
```

### 3. Tự động phát hiện IPv6 client

**Quan trọng:** Bỏ qua `VGL_CLIENT` để VirtualGL tự động phát hiện:

```bash
unset VGL_CLIENT
export VGL_DISPLAY=:1
```

### 4. Chạy ứng dụng

```bash
vglrun -d :1 ./run.sh
```

**VirtualGL sẽ tự động tìm client:**
```
[VGL] NOTICE: Automatically setting VGL_CLIENT to 2001:ee0:40e1:7322:...
```

---

## Xử lý lỗi thường gặp

### Lỗi: Connection refused

```
[VGL] ERROR: Could not connect to VGL client
[VGL] ERROR: Connection refused
```

**Kiểm tra kết nối từ Ubuntu 2:**
```bash
nc -6 -vz <IPv6-Ubuntu-1> 4242
```

**Nếu thành công:** `Connection to ... 4242 port [tcp/*] succeeded!`

**Nếu thất bại:**
1. Kiểm tra vglclient có đang chạy trên Ubuntu 1
2. Kiểm tra firewall
3. Đảm bảo IPv6 được bật và định tuyến đúng

---

## Tự động hóa

### Script tự động khởi động vglclient (Ubuntu 1)

Tạo file `~/bin/start-vglclient.sh`:

```bash
#!/bin/bash

# Nếu vglclient đã chạy, thoát
if pgrep -u "$USER" -x vglclient >/dev/null 2>&1; then
    exit 0
fi

# Khởi động vglclient ở background
DISPLAY=:1 \
VGLCLIENT_IPV6=1 \
nohup vglclient \
    -display :1 \
    -port 4242 \
    -ipv6 \
    > "$HOME/.vglclient.log" 2>&1 &
```

**Cấp quyền thực thi:**
```bash
chmod +x ~/bin/start-vglclient.sh
```

**Kiểm tra:**
```bash
~/bin/start-vglclient.sh
pgrep -a vglclient
sudo ss -lntp6 | grep 4242
```

---

## Quy trình nhanh 

### Cấu hình SSH nâng cao với LocalCommand

Thêm vào `~/.ssh/config`:

```bash
Host ubuntu-vgl
    HostName <IPv6-Ubuntu-2>
    User username
    Port 22

    # X11 Forwarding
    ForwardX11 yes
    ForwardX11Trusted yes
    RequestTTY yes

    # Tự động chạy ứng dụng khi SSH
    RemoteCommand bash -lc 'PROJECT=$(find "$HOME" -type f -name run.sh -path "*/xf4_asr_rdd*" -print -quit); if [ -z "$PROJECT" ]; then echo "Không tìm thấy run.sh"; exit 1; fi; cd "$(dirname "$PROJECT")" || exit 1; unset VGL_CLIENT; export VGL_DISPLAY=:1; exec vglrun -d :1 ./run.sh'

    # Tự động khởi động vglclient trên local
    LocalCommand sh -c 'if ! pgrep -u "$USER" -x vglclient >/dev/null 2>&1; then DISPLAY=:1 VGLCLIENT_IPV6=1 nohup vglclient -display :1 -port 4242 -ipv6 > "$HOME/.vglclient.log" 2>&1 & fi'
    PermitLocalCommand yes
```

**Sử dụng:**
```bash
ssh ubuntu-vgl
```

Lệnh này sẽ:
1. Tự động khởi động `vglclient` trên Ubuntu 1
2. SSH vào Ubuntu 2
3. Tự động chạy ứng dụng với VirtualGL

---

## Tối ưu hiệu suất (Giảm lag)

### Giảm chất lượng và frame rate

Tạo file `remote-run.sh`:

```bash
#!/bin/bash
vglrun -d :1 \
  -c jpeg \
  -q 30 \
  -np 8 \
  -fps 60 \
  ./run.sh
```

**Các tham số:**
- `-c jpeg`: Nén JPEG
- `-q 30`: Chất lượng 30% (giảm bandwidth)
- `-np 8`: Sử dụng 8 threads nén
- `-fps 60`: Giới hạn 60 FPS

**Cấp quyền và chạy:**
```bash
chmod +x remote-run.sh
./remote-run.sh
```

---

## Tổng kết

### Checklist triển khai

- [ ] **Ubuntu 1**: Cài VirtualGL, chạy `vglclient`
- [ ] **Ubuntu 1**: Kiểm tra IPv6 và DISPLAY
- [ ] **SSH**: Cấu hình X11 forwarding trong `~/.ssh/config`
- [ ] **Ubuntu 2**: Kiểm tra `DISPLAY=localhost:10.0`
- [ ] **Ubuntu 2**: Kiểm tra VirtualGL với GPU
- [ ] **Ubuntu 2**: Chạy ứng dụng với `vglrun -d :1 ./run.sh`

### Các biến môi trường quan trọng

| Biến | Máy | Giá trị | Mục đích |
|:-----|:----|:--------|:---------|
| `DISPLAY` | Ubuntu 1 | `:1` | X server cục bộ |
| `DISPLAY` | Ubuntu 2 | `localhost:10.0` | SSH X11 forwarded |
| `VGL_DISPLAY` | Ubuntu 2 | `:1` | X server có GPU |
| `VGL_CLIENT` | Ubuntu 2 | auto/unset | Địa chỉ vglclient |