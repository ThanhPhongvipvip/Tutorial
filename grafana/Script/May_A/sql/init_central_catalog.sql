-- ============================================================
-- CENTRAL DATABASE METADATA CATALOG
-- Kho Lưu Trữ Metadata PostgreSQL Tập Trung Cho Toàn Bộ Hệ Thống
-- ============================================================

-- Tạo cơ sở dữ liệu nếu chưa có (Chạy bởi postgres user):
-- CREATE DATABASE monitoring_catalog;
-- \c monitoring_catalog

-- 1. Bảng lưu danh sách các bảng và chi tiết cột của từng thiết bị
CREATE TABLE IF NOT EXISTS db_metadata_tables (
    id SERIAL PRIMARY KEY,
    device VARCHAR(100) NOT NULL,
    database_name VARCHAR(100) NOT NULL,
    schema_name VARCHAR(100) NOT NULL,
    table_name VARCHAR(200) NOT NULL,
    column_count INT DEFAULT 0,
    columns_detail TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_device_table UNIQUE (device, database_name, schema_name, table_name)
);

-- 2. Bảng lưu quan hệ khóa ngoại (Foreign Keys / ERD Edges)
CREATE TABLE IF NOT EXISTS db_metadata_relations (
    id SERIAL PRIMARY KEY,
    device VARCHAR(100) NOT NULL,
    database_name VARCHAR(100) NOT NULL,
    schema_name VARCHAR(100) NOT NULL,
    constraint_name VARCHAR(200) NOT NULL,
    from_table VARCHAR(200) NOT NULL,
    from_column VARCHAR(200) NOT NULL,
    to_table VARCHAR(200) NOT NULL,
    to_column VARCHAR(200) NOT NULL,
    cardinality VARCHAR(50) DEFAULT '1 : 0..N',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_device_relation UNIQUE (device, database_name, schema_name, constraint_name)
);

-- Chỉ mục tối ưu tốc độ truy vấn theo thiết bị và database
CREATE INDEX IF NOT EXISTS idx_tables_lookup ON db_metadata_tables (device, database_name, schema_name);
CREATE INDEX IF NOT EXISTS idx_relations_lookup ON db_metadata_relations (device, database_name, schema_name);

-- Phân quyền cho Grafana reader
-- GRANT CONNECT ON DATABASE monitoring_catalog TO grafana_reader;
-- GRANT USAGE ON SCHEMA public TO grafana_reader;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO grafana_reader;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO grafana_reader;
