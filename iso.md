# Tạo iso 

Cách cài đặt tự động (Khuyên dùng)
Bạn hãy sao chép và chạy loạt lệnh sau để công cụ tự xử lý sạch sẽ:
bash
# 1. Xóa các file repo cũ bị lỗi nếu còn sót lại
sudo rm -f /etc/apt/sources.list.d/penguins-eggs*

# 2. Clone script cài đặt chính thức từ Github của tác giả
git clone https://github.com/pieroproietti/fresh-eggs

# 3. Truy cập vào thư mục và chạy script cài đặt
cd fresh-eggs
sudo ./fresh-eggs.sh
Use code with caution.
Script này sẽ tự động làm gì?
• Tự kiểm tra và cấu hình đúng GPG key mới nhất.
• Thêm kho lưu trữ chuẩn penguins-eggs-repo vào hệ thống.
• Gọi lệnh apt update và apt install eggs tự động để hoàn tất


cd ~/fresh-eggs
sudo ./fresh-eggs.sh --cli