-- ============================================================================
-- Tệp 01: Khởi tạo cấu trúc 5 bảng mẫu cho giáo trình Database.md
-- Hệ quản trị: PostgreSQL 16
-- Mô hình: Thương mại điện tử (categories, products, users, orders, order_items)
-- ============================================================================

-- Xóa bảng theo thứ tự từ bảng con đến bảng cha để chạy lại sạch sẽ khi cần thực hành lại
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- 1. Bảng danh mục sản phẩm (categories)
CREATE TABLE categories (
    id          int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        varchar(100) NOT NULL UNIQUE,
    description text
);

-- 2. Bảng sản phẩm (products)
CREATE TABLE products (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        varchar(255)   NOT NULL,
    price       numeric(12, 2) NOT NULL CHECK (price >= 0),
    stock       int            NOT NULL DEFAULT 0 CHECK (stock >= 0),
    category_id int            REFERENCES categories(id) ON DELETE SET NULL,
    specs       jsonb          NOT NULL DEFAULT '{}'::jsonb,
    created_at  timestamptz    NOT NULL DEFAULT now()
);

-- 3. Bảng khách hàng (users)
-- Lưu ý: cột email dùng UNIQUE mặc định -> cho phép nhiều dòng mang giá trị NULL
-- (từ PostgreSQL 15+ có thể dùng UNIQUE NULLS NOT DISTINCT nếu chỉ cho phép tối đa 1 giá trị NULL)
CREATE TABLE users (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        varchar(100) NOT NULL,
    email       varchar(255) UNIQUE,
    phone       varchar(15),
    is_active   boolean      NOT NULL DEFAULT true,
    created_at  timestamptz  NOT NULL DEFAULT now()
);

-- 4. Bảng đơn hàng (orders)
-- Lưu ý: user_id cho phép NULL để biểu diễn đơn hàng vãng lai (khách mua tại quầy không tạo tài khoản),
-- đồng thời giúp minh họa rõ hành vi JOIN và bẫy NOT IN với giá trị NULL ở Phần 3 và Phần 5.
CREATE TABLE orders (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     bigint         REFERENCES users(id) ON DELETE SET NULL,
    amount      numeric(12, 2) NOT NULL CHECK (amount >= 0),
    status      varchar(20)    NOT NULL DEFAULT 'pending'
                               CHECK (status IN ('pending', 'completed', 'cancelled')),
    created_at  timestamptz    NOT NULL DEFAULT now()
);

-- 5. Bảng chi tiết đơn hàng (order_items)
-- Bảng trung gian giải quyết quan hệ Nhiều - Nhiều (N - N) giữa orders và products,
-- sử dụng khóa chính ghép (Composite Primary Key) gồm (order_id, product_id).
CREATE TABLE order_items (
    order_id    bigint         NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id  bigint         NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    quantity    int            NOT NULL CHECK (quantity > 0),
    unit_price  numeric(12, 2) NOT NULL CHECK (unit_price >= 0),
    PRIMARY KEY (order_id, product_id)
);
