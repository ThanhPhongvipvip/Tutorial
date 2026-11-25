-- ============================================================================
-- Tệp 03: Kiểm tra tính toàn vẹn của cơ sở dữ liệu mẫu
-- Chạy sau 01_create_tables.sql và 02_insert_sample_data.sql
-- ============================================================================

-- 1. Thống kê số lượng bản ghi của từng bảng (kỳ vọng: 4, 10, 5, 6, 6)
SELECT 'categories'  AS bang, COUNT(*) AS so_dong FROM categories
UNION ALL
SELECT 'products',            COUNT(*) FROM products
UNION ALL
SELECT 'users',               COUNT(*) FROM users
UNION ALL
SELECT 'orders',              COUNT(*) FROM orders
UNION ALL
SELECT 'order_items',         COUNT(*) FROM order_items;

-- 2. Kiểm tra đối soát: tổng tiền tính từ order_items phải khớp cột amount trên orders
SELECT
    o.id AS order_id,
    COALESCE(u.name, 'Khách vãng lai') AS khach_hang,
    o.status,
    o.amount AS tong_tren_orders,
    SUM(oi.quantity * oi.unit_price) AS tong_tinh_tu_chi_tiet,
    (o.amount = SUM(oi.quantity * oi.unit_price)) AS khop_du_lieu
FROM orders o
LEFT JOIN users u ON u.id = o.user_id
JOIN order_items oi ON oi.order_id = o.id
GROUP BY o.id, u.name, o.status, o.amount
ORDER BY o.id;

-- 3. Kiểm tra nhanh truy vấn sản phẩm kèm danh mục và thông số RAM từ JSONB
SELECT
    p.id,
    c.name AS danh_muc,
    p.name AS san_pham,
    p.price,
    p.stock,
    p.specs->>'ram' AS ram
FROM products p
LEFT JOIN categories c ON c.id = p.category_id
ORDER BY p.id;
