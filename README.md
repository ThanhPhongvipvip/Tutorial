# Tổng Hợp Tài Liệu Kỹ Thuật

Bộ tài liệu tổng hợp các kiến thức về lập trình, hệ thống và công cụ phát triển phần mềm.

## Nội dung

### 1. Lập trình C++ (`Cpp/`)
- [**Cpp_tong_hop.md**](Cpp/Cpp_tong_hop.md) - C++ cơ bản và OOP (Viết lại chi tiết)
  - 4 nguyên tắc OOP với ví dụ thực tế
  - Con trỏ và tham chiếu (So sánh chi tiết)
  - Quản lý bộ nhớ (Stack/Heap, new/delete)
  - Smart Pointers (unique_ptr, shared_ptr, weak_ptr)
  - Constructor/Destructor và RAII
  - Virtual functions và Polymorphism
  - Rule of Three/Five/Zero
  - Best practices và compiler flags

- [**Demo/**](Cpp/Demo/) - **Project demo thực tế** ✨
  - `01_raw_pointer.cpp` - Raw pointers và các lỗi thường gặp
  - `02_unique_ptr.cpp` - std::unique_ptr (default choice)
  - `03_shared_ptr.cpp` - std::shared_ptr (shared ownership)
  - `04_weak_ptr.cpp` - std::weak_ptr (phá circular references)
  - `05_comparison.cpp` - So sánh performance và use cases
  - `run.sh` - Script build và run tất cả demos
  - [README.md](Cpp/Demo/README.md) - Hướng dẫn chi tiết

### 2. Git và GitHub (`Git/`)
- [**Git.md**](Git/Git.md) - Quản lý phiên bản và collaboration
  - **Git Release**: Tạo release qua Web UI hoặc GitHub CLI
  - **GitHub Packages**: Lưu trữ Docker images, npm, Maven, PyPI packages
  - **GitHub Projects**: Quản lý công việc theo Kanban board

### 3. SSH và Remote Desktop (`SSH/`)
- [**SSH.md**](SSH/SSH.md) - SSH X11 Forwarding với VirtualGL
  - Chạy ứng dụng Qt có GPU từ server remote
  - VirtualGL để render GPU và stream qua network
  - Tối ưu hiệu suất (giảm lag, FPS)
  - Tự động hóa với script và SSH config

- [**RustDesk.md**](SSH/RustDesk.md) - Remote desktop nhanh với Tailscale
  - Kết nối peer-to-peer thay vì relay server
  - Cấu hình Direct IP Access
  - Sử dụng IPv6 Tailscale

### 4. Tạo Custom Ubuntu ISO (`Cubic/`)
- [**iso.md**](Cubic/iso.md) - Hướng dẫn chi tiết tạo ISO Ubuntu tùy chỉnh
  - Cài đặt sẵn Qt, ROS 2, Snap7, Qwt
  - Tự động cài NVIDIA driver khi boot lần đầu
  - Script kiểm tra môi trường đã cài
  - Disable Wayland để dùng X11

- [**autostart_symlink.md**](Cubic/autostart_symlink.md) - Đóng gói ứng dụng vào ISO
  - Tự động chạy ứng dụng khi đăng nhập desktop
  - Quản lý file cấu hình qua symlink
  - GNOME Autostart với systemd service
  - First-boot script để setup user home

- [**ip-cubic.md**](Cubic/ip-cubic.md) - Cấu hình IP tĩnh trong ISO
  - Tự động gán IP `192.168.1.86/24` sau khi cài Ubuntu
  - Kiểm tra ARP conflict trước khi gán
  - NetworkManager profile management
  - Chỉ áp dụng cho mạng `192.168.1.0/24`

### 5. Markdown và Mermaid (`Markdown/`)
- [**Markdown_syntax.md**](Markdown/Markdown_syntax.md) - Biểu thức toán học LaTeX
  - Ký hiệu toán học cơ bản
  - Chỉ số trên/dưới, phân số, căn bậc
  - Tổng, tích phân, ma trận
  - Chữ Hy Lạp và toán tử logic

- [**Mermaid.md**](Markdown/Mermaid.md) - Vẽ diagram với Mermaid
  - **Flowchart**: Sơ đồ luồng với nhiều loại shape
  - **Sequence Diagram**: Biểu đồ tuần tự (actors, lifelines)
  - **Architecture Diagram**: Sơ đồ kiến trúc hệ thống
  - Align, junctions, và custom icons

---

## Quick Start

### C++ Demo Project
```bash
cd Cpp/Demo
./run.sh              # Interactive mode
./run.sh debug        # Debug build with sanitizers
```

### Xem tài liệu trong VS Code
1. Cài extension **Markdown Preview Enhanced** hoặc **Markdown All in One**
2. Mở file `.md` và nhấn `Ctrl+Shift+V` để xem preview

### Render Mermaid diagrams
- GitHub tự động render Mermaid
- VS Code: Cài extension **Markdown Preview Mermaid Support**
- Online: [mermaid.live](https://mermaid.live)

---

## Scripts có sẵn

### C++ Demo Scripts (`Cpp/Demo/`)
- `run.sh` - Build và run tất cả demos (interactive)

### Cubic Scripts (`Cubic/script/`)
- `prepare-host.sh` - Chuẩn bị môi trường trên máy host
- `deploy-nvidia.sh` - Cấu hình tự động cài NVIDIA driver
- `c-auto-static-ip.sh` - Gán IP tĩnh sau khi cài Ubuntu
- `apply-c-passwordless-login.sh` - Cấu hình tự đăng nhập
- `check_env_iso.sh` - Kiểm tra môi trường trong ISO
- `prepare-cubic-env.sh` - Chuẩn bị Cubic environment

---


