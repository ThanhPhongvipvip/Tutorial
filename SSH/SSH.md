# SSH Remote ( + VirtualGL + Qt GUI)

## Nhiệm vụ SSH X11 forwarding và VirtualGL:
- DISPLAY=localhost:10.0 -> dduongwg GUI/X11 từ Ubuntu 2 về Ubuntu 1
- VGL_DISPLAY=:1 -> display GPU/X server trên ubuntu 2
- vglclient -> nhận frame VirtualGL và hiển thị ở Ubuntu 1
- VGL_CLIENT -> địa chỉ Ubuntu 1 mà Ubuntu 2 dùng để kết nối tới vglclient.

## Các bước 
### 1. Ubuntu 1 - Máy nhận GUI

#### Mục tiêu cần:
- OpenSSH client
- X11/XWayland
- VirtualGL
- vglclient

#### Install

```bash
sudo apt update
sudo apt install openssh-client xauth x11-utils
```

##### Install VirtualGL
```bash
wget -O ~/virtualgl_3.1.5_amd64.deb \
  https://github.com/VirtualGL/virtualgl/releases/download/3.1.5/virtualgl_3.1.5_amd64.deb
```

- Kiểm tra (Cần Debian binary package):
```bash
file ~/virtualgl_3.1.5_amd64.deb
ls -lh ~/virtualgl_3.1.5_amd64.deb
```

- Install
```bash
sudo apt install ~/virtualgl_3.1.5_amd64.deb

```

- Check:
```bash
which vglclient
```

#### Kiểm tra X display
```bash
echo $DISPLAY
```
Kết quả cần : 
```bash
:0
```
hoặc
```bash
:1
```

Giả sử nếu kết quả là 
```bash
DISPLAY=:1
```
- Kiểm tra:
```bash
DISPLAY=:1 xdpyinfo >/dev/null && echo "X11 :1 OK"
```
Thành công: 
```bash
X11 :1 OK
```

#### Chạy vglclient
Giả sử display GUI của ubuntu 1 là :1 :

```bash
DISPLAY=:1 VGLCLIENT_IPV6=1 \
vglclient -display :1 -port 4242 -ipv6
```

Kiểm tra: 
```bash
pgrep -a vglclient
```

Cần phải thấy:
```bash
xxxx /usr/bin/vglclient -display :1 -port 4242 -ipv6
```
Kiểm tra port :
```bash
sudo ss -lntp | grep 4242
```

Xem log:
```bash
cat ~/.vglclient.log
```
hoặc 
```bash
tail -f ~/.vglclient.log
```

#### Kiểm tra IPv6
```bash
ip a
```
hoặc 
```bash
ip -6 addr
```
### 2. SSH 
```bash 
ssh -Y ubuntu-remote
``` 
hoặc sử dụng ssh remote (VSCode)

Trong ~/.ssh/config
```bash
Host ubuntu-remote
    HostName IPv6
    User hieu
    Port 22
    AddressFamily inet
    ForwardX11 yes
    ForwardX11Trusted yes
```

### 3. Kiểm tra SSH X11 trong Ubuntu 2

```bash
echo $DISPLAY
```
Kết quả mong muốn:
```bash
localhost:10.0
``` 
không phải <span style= "color: red">:1</span> hoặc <span style= "color: red">:0</span> 

Test:
```bash
xdpyinfo >/dev/null && echo "X11 OK"
```
Kết quả mong muốn:
```bash
X11 OK
```

### 4. Kiểm tra VirtualGL + NVIDIA

```bash
export VGL_DISPLAY=:1
```

```bash
vglrun -d :1 glxinfo -B | grep -E \
'OpenGL vendor|OpenGL renderer'
```

Kết quả: 
```bash
OpenGL vendor string: NVIDIA Corporation
OpenGL renderer string: NVIDIA GeForce RTX 5050/PCIe/SSE2
```

### 5. Để vglrun tự nhận IPv6
Trên ubuntu 2:
```bash
unset VGL_CLIENT
export VGL_DISPLAY=:1
```

```bash
vglrun -d :1 ./run.sh
```

Log xuất hiện ví dụ: 
```bash
[VGL] NOTICE: Automatically setting the VGL_CLIENT environment variable to
2001:ee0:40e1:7322:30db:568f:6e72:9c97
``` 
là IPv6 mong muốn

## Note:

### Nếu báo Connection refused

```bash
[VGL] ERROR: Could not connect to VGL client
[VGL] ERROR: Connection refused
```

Kiểm tra:
```bash
nc -6 -vz <IPv6-của-Ubuntu-1> 4242
```
Nếu thành công: succeeded thì đường tới vglclient OK

Giả sử vẫn không được thì kiểm tra vglclient/firewall/listener

### Nếu muốn tự dộng chạy vglclient

Trên Ubuntu `:

```bash
#!/bin/bash

if pgrep -u "$USER" -x vglclient >/dev/null 2>&1; then
    exit 0
fi

DISPLAY=:1 \
VGLCLIENT_IPV6=1 \
nohup vglclient \
    -display :1 \
    -port 4242 \
    -ipv6 \
    > "$HOME/.vglclient.log" 2>&1 &
```

```bash
chmod +x ~/bin/start-vglclient.sh
```

Check:

```bash
pgrep -a vglclient
```
và
```bash
sudo ss -lntp6 | grep 4242
```

## Quy trình chạy:
### 1. Ubuntu 1:

```bash
~/bin/start-vglclient.sh
```
Kiểm tra:
```bash
pgrep -a vglclient
sudo ss -lntp6 | grep 4242
```

### 2. SSH

### 3. Ubuntu 2:
```bash 
cd ...
 
unset VGL_CLIENT
export VGL_DISPLAY=:1

vglrun -d :1 ./run.sh  
```

## Nhanh hơn:

### Config ssh:

```bash
Host ubuntu-vgl
    HostName <IPv6>
    User hieu
    Port 22

    ForwardX11 yes
    ForwardX11Trusted yes
    RequestTTY yes

    RemoteCommand bash -lc 'PROJECT=$(find "$HOME" -type f -name run.sh -path "*/xf4_asr_rdd*" -print -quit); if [ -z "$PROJECT" ]; then echo "Không tìm thấy run.sh"; exit 1; fi; cd "$(dirname "$PROJECT")" || exit 1; unset VGL_CLIENT; export VGL_DISPLAY=:1; exec vglrun -d :1 ./run.sh'

    LocalCommand sh -c 'if ! pgrep -u "$USER" -x vglclient >/dev/null 2>&1; then DISPLAY=:1 VGLCLIENT_IPV6=1 nohup vglclient -display :1 -port 4242 -ipv6 > "$HOME/.vglclient.log" 2>&1 & fi'
    PermitLocalCommand yes
```

### SSH-remote

### Build
```bash
export VGL_DISPLAY=:1
unset VGL_CLIENT
vglrun -d :1 ./run.sh
```  

### Hoặc muốn nhanh hơn nữa:
```bash
ssh ubuntu-vgl
```

## Giảm lag GUI ( GIảm FPS)
remote-run.sh
```bash
vglrun -d :1 \
  -c jpeg \
  -q 30 \
  -np 8 \
  -fps 60 \
  ./run.sh
```


```bash
chmod +x remote-run.sh run.sh
```