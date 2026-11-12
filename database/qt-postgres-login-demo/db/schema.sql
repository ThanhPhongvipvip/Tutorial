-- Lược đồ cho demo đăng nhập (PostgreSQL 16).
-- Chạy bởi init.sh với quyền superuser của container, biến :app_pw do init.sh truyền vào.

CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- crypt(), gen_salt() cho bcrypt

CREATE TABLE app_users (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username      varchar(50)  NOT NULL CHECK (username ~ '^[A-Za-z0-9_.-]{3,50}$'),
    password_hash text         NOT NULL,           -- bcrypt, KHÔNG lưu mật khẩu rõ
    full_name     varchar(150),
    created_at    timestamptz  NOT NULL DEFAULT now(),
    last_login_at timestamptz
);

-- Tên đăng nhập không phân biệt hoa/thường và là duy nhất.
-- Index này cũng phục vụ truy vấn WHERE lower(username) = lower(?).
CREATE UNIQUE INDEX uq_app_users_username ON app_users (lower(username));

-- Dữ liệu mẫu (CHỈ DÙNG CHO DEMO): admin / admin123 và demo / demo123
INSERT INTO app_users (username, password_hash, full_name) VALUES
    ('admin', crypt('admin123', gen_salt('bf', 10)), 'Administrator'),
    ('demo',  crypt('demo123',  gen_salt('bf', 10)), 'Demo User');

-- Role dành cho ứng dụng: quyền tối thiểu (nguyên tắc ít đặc quyền nhất).
CREATE ROLE login_app LOGIN PASSWORD :'app_pw';
GRANT CONNECT ON DATABASE :"DBNAME" TO login_app;
GRANT USAGE   ON SCHEMA public      TO login_app;
GRANT SELECT, INSERT          ON app_users TO login_app;
GRANT UPDATE (last_login_at)  ON app_users TO login_app;   -- chỉ được sửa cột này
-- Không cấp UPDATE/DELETE đầy đủ: ứng dụng không thể đổi hash hay xóa người dùng.
-- Không cần GRANT cho sequence: cột IDENTITY tự xử lý.
