-- ============================================================================
-- Tệp 02: Nạp dữ liệu mẫu cho 5 bảng thương mại điện tử
-- Lưu ý: Chạy sau 01_create_tables.sql
-- ============================================================================

BEGIN;

-- 1. Danh mục sản phẩm (4 danh mục)
INSERT INTO categories (name, description) VALUES
    ('Laptop',   'Máy tính xách tay văn phòng và đồ họa'),
    ('Phụ kiện', 'Chuột, cáp kết nối, bộ chia cổng và tai nghe'),
    ('Màn hình', 'Màn hình máy tính độ phân giải cao'),
    ('Âm thanh', 'Loa để bàn và micro hội nghị');

-- 2. Sản phẩm (10 sản phẩm thuộc 4 danh mục)
-- Thiết kế có chủ đích:
--   * Danh mục 1 (Laptop): 3 sản phẩm > 50.000đ
--   * Danh mục 2 (Phụ kiện): 3 sản phẩm > 50.000đ và 1 sản phẩm <= 50.000đ (45.000đ)
--   * Danh mục 3 (Màn hình): 2 sản phẩm > 50.000đ (sẽ bị HAVING COUNT(*) >= 3 loại ở bài 3.4)
--   * Danh mục 4 (Âm thanh): 1 sản phẩm > 50.000đ
--   * Có sản phẩm stock = 1 (id = 3) để thực hành chống bán vượt tồn kho bằng FOR UPDATE
--   * Có cột specs (JSONB) để thực hành truy vấn JSONB và GIN Index
INSERT INTO products (name, price, stock, category_id, specs) VALUES
    ('MacBook Air M3 13"',        27990000.00, 12, 1, '{"ram": "16GB", "cpu": "Apple M3", "storage": "512GB"}'),
    ('ThinkPad X1 Carbon Gen 11', 34500000.00,  8, 1, '{"ram": "16GB", "cpu": "Core i7",  "storage": "1TB"}'),
    ('Laptop Gaming Phiên Bản Giới Hạn', 24000000.00, 1, 1, '{"ram": "32GB", "cpu": "Ryzen 7", "storage": "1TB"}'),
    ('Chuột không dây MX',          350000.00, 50, 2, '{"dpi": 4000, "connection": "Bluetooth", "battery_hours": 70}'),
    ('Hub chuyển đổi USB-C 6-in-1', 650000.00, 30, 2, '{"ports": 6, "power_w": 100}'),
    ('Tai nghe chụp tai Studio',    890000.00, 20, 2, '{"connection": "USB-C", "anc": true}'),
    ('Cáp sạc USB-C cơ bản',         45000.00, 90, 2, '{"length_m": 1.5, "power_w": 60}'),
    ('Màn hình Dell UltraSharp 27"', 8500000.00, 10, 3, '{"size_inch": 27, "resolution": "4K", "panel": "IPS"}'),
    ('Màn hình LG IPS 24"',        3200000.00, 15, 3, '{"size_inch": 24, "resolution": "1080p", "panel": "IPS"}'),
    ('Loa hội nghị Bluetooth',     1450000.00,  7, 4, '{"connection": "Bluetooth", "mic": true}');

-- 3. Khách hàng (5 khách hàng)
--   * ID 1 (Phong): VIP (>= 10 triệu), đầy đủ email & phone
--   * ID 2 (Linh): Có đơn hàng, phone là NULL (để thực hành IS NULL và COALESCE)
--   * ID 3 (Tuấn): Chưa từng đặt đơn hàng nào (để thực hành LEFT JOIN và ANTI-JOIN)
--   * ID 4 (An): Tài khoản ngừng hoạt động, email và phone đều NULL (minh họa UNIQUE cho phép nhiều NULL)
--   * ID 5 (Minh): Có email NULL và có đơn hàng đang chờ xử lý
INSERT INTO users (name, email, phone, is_active) VALUES
    ('Phong', 'phong@mail.com', '0912345678', true),
    ('Linh',  'linh@mail.com',  NULL,         true),
    ('Tuấn',  'tuan@mail.com',  '0987654321', true),
    ('An',    NULL,             NULL,         false),
    ('Minh',  NULL,             '0901122334', true);

-- 4. Đơn hàng (6 đơn hàng)
--   * Đơn 1 & 2 của Phong (id=1): 27.990.000 + 700.000 = 28.690.000 (completed -> khách VIP)
--   * Đơn 3 của Linh (id=2): 8.500.000 (completed)
--   * Đơn 4 của Linh (id=2): 650.000 (pending -> dùng cho Partial Index)
--   * Đơn 5 của Minh (id=5): 890.000 (cancelled)
--   * Đơn 6 khách vãng lai (user_id = NULL): 350.000 (completed -> dùng cho RIGHT JOIN / bẫy NOT IN)
INSERT INTO orders (user_id, amount, status, created_at) VALUES
    (1,    27990000.00, 'completed', '2026-03-01 09:30:00+07'),
    (1,      700000.00, 'completed', '2026-03-05 14:15:00+07'),
    (2,     8500000.00, 'completed', '2026-03-10 10:00:00+07'),
    (2,      650000.00, 'pending',   '2026-03-18 16:45:00+07'),
    (5,      890000.00, 'cancelled', '2026-03-20 11:20:00+07'),
    (NULL,   350000.00, 'completed', '2026-03-22 15:00:00+07');

-- 5. Chi tiết đơn hàng (order_items) - tổng quantity * unit_price khớp chính xác với orders.amount
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
    (1, 1, 1, 27990000.00), -- Đơn 1: 1 MacBook Air M3
    (2, 4, 2,   350000.00), -- Đơn 2: 2 Chuột không dây MX
    (3, 8, 1,  8500000.00), -- Đơn 3: 1 Màn hình Dell 27"
    (4, 5, 1,   650000.00), -- Đơn 4: 1 Hub USB-C
    (5, 6, 1,   890000.00), -- Đơn 5: 1 Tai nghe Studio
    (6, 4, 1,   350000.00); -- Đơn 6 (vãng lai): 1 Chuột không dây MX

COMMIT;
