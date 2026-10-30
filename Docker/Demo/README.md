# Docker Demo - Node.js & PostgreSQL

Demo đơn giản về Docker với Node.js và PostgreSQL sử dụng Docker Compose.

## Cấu trúc

```
Demo/
├── Dockerfile              # Docker image configuration
├── docker-compose.yml      # Multi-container setup
├── package.json            # Node.js dependencies
├── server.js               # Express server
├── .dockerignore           # Files to ignore
├── run.sh                  # Build and run script
└── README.md              # This file
```

## Yêu cầu

- Docker
- Docker Compose

## Cách chạy

### Cách 1: Sử dụng Docker Compose (Khuyến nghị)

```bash
# Build images
docker-compose build

# Start containers
docker-compose up -d

# Hoặc build và start cùng lúc
docker-compose up -d --build
```

### Cách 2: Sử dụng script run.sh

```bash
chmod +x run.sh
./run.sh
```

Script run.sh sẽ tự động:
- Stop containers cũ
- Build images với Docker Compose
- Start containers
- Test API endpoints

### Cách 3: Build riêng từng bước

```bash
# Build image cho app
docker-compose build app

# Build tất cả images
docker-compose build

# Start containers
docker-compose up -d
```

## API Endpoints

### GET /
Thông tin cơ bản về API

```bash
curl http://localhost:3000
```

### GET /health
Kiểm tra trạng thái server và database

```bash
curl http://localhost:3000/health
```

### GET /users
Lấy danh sách tất cả users

```bash
curl http://localhost:3000/users
```

### POST /users
Tạo user mới

```bash
curl -X POST http://localhost:3000/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com"}'
```

### GET /users/:id
Lấy thông tin user theo ID

```bash
curl http://localhost:3000/users/1
```

### DELETE /users/:id
Xóa user theo ID

```bash
curl -X DELETE http://localhost:3000/users/1
```

## Quản lý với Docker Compose

### Build và Start

```bash
# Build images
docker-compose build

# Build không dùng cache
docker-compose build --no-cache

# Build service cụ thể
docker-compose build app

# Start containers (background)
docker-compose up -d

# Start và xem logs
docker-compose up

# Build và start cùng lúc
docker-compose up -d --build
```

### Kiểm tra và Logs

```bash
# Xem containers đang chạy
docker-compose ps

# Xem logs tất cả services
docker-compose logs

# Follow logs real-time
docker-compose logs -f

# Xem logs của service cụ thể
docker-compose logs app
docker-compose logs db
docker-compose logs -f app
```

### Exec vào containers

```bash
# Exec vào app container
docker-compose exec app sh

# Exec vào database container
docker-compose exec db psql -U postgres -d mydb

# Chạy lệnh trong container
docker-compose exec app npm --version
docker-compose exec db psql --version
```

### Stop và Cleanup

```bash
# Stop containers (giữ data)
docker-compose stop

# Start lại containers đã stop
docker-compose start

# Restart containers
docker-compose restart

# Stop và xóa containers
docker-compose down

# Stop, xóa containers và volumes (mất data)
docker-compose down -v
```

## Kết nối PostgreSQL

```bash
# Từ host machine
psql -h localhost -p 5432 -U postgres -d mydb
# Password: postgres

# Hoặc exec vào container
docker-compose exec db psql -U postgres -d mydb
```

## SQL Commands

```sql
-- Xem tables
\dt

-- Xem dữ liệu
SELECT * FROM users;

-- Insert dữ liệu
INSERT INTO users (name, email) VALUES ('Jane Smith', 'jane@example.com');

-- Thoát
\q
```

## Rebuild và Cleanup

### Rebuild khi có thay đổi code

```bash
# Stop containers
docker-compose down

# Rebuild images
docker-compose build

# Start lại
docker-compose up -d

# Hoặc gộp lại
docker-compose up -d --build
```

### Rebuild từ đầu (no cache)

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Cleanup hoàn toàn

```bash
# Stop và xóa containers
docker-compose down

# Stop, xóa containers và volumes (mất data)
docker-compose down -v

# Xóa images đã build
docker rmi demo-nodejs-app
docker rmi postgres:15-alpine

# Hoặc xóa tất cả images không dùng
docker image prune -a
```

## Troubleshooting

### Port đã được sử dụng

Thay đổi port trong docker-compose.yml:
```yaml
ports:
  - "3001:3000"  # Thay vì 3000:3000
```

### Database connection failed

```bash
# Kiểm tra db container
docker-compose logs db

# Restart containers
docker-compose restart
```

### Rebuild từ đầu

```bash
# Stop và xóa tất cả
docker-compose down -v

# Build lại không dùng cache
docker-compose build --no-cache

# Start containers
docker-compose up -d
```

### Xem image đã build

```bash
# List tất cả images
docker images

# Xem image của demo này
docker images | grep demo
docker images | grep postgres
```


## Giải thích Docker Compose

### File docker-compose.yml

```yaml
version: '3.8'

services:
  app:
    build: .                    # Build từ Dockerfile trong thư mục hiện tại
    container_name: nodejs-app
    ports:
      - "3000:3000"             # Map port host:container
    environment:
      - DB_HOST=db              # Service name trong Docker network
      - DB_PORT=5432
      - DB_USER=postgres
      - DB_PASSWORD=postgres
      - DB_NAME=mydb
    depends_on:
      - db                      # Start db trước app
    networks:
      - app-network             # Kết nối vào network chung
    restart: unless-stopped     # Auto restart khi crash

  db:
    image: postgres:15-alpine   # Sử dụng image có sẵn
    container_name: postgres-db
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=mydb
    volumes:
      - postgres-data:/var/lib/postgresql/data  # Persistent data
    ports:
      - "5432:5432"
    networks:
      - app-network
    restart: unless-stopped

volumes:
  postgres-data:                # Named volume cho database

networks:
  app-network:                  # Private network cho containers
    driver: bridge
```

### Lợi ích của Docker Compose

1. **Định nghĩa tất cả services** trong một file duy nhất
2. **Build và start** tất cả containers với một lệnh
3. **Tự động tạo network** để containers giao tiếp
4. **Quản lý volumes** cho persistent data
5. **Environment variables** dễ dàng config
6. **Dependencies** với depends_on

### Quy trình làm việc

```bash
# 1. Viết code và Dockerfile
# 2. Định nghĩa services trong docker-compose.yml
# 3. Build images
docker-compose build

# 4. Start containers
docker-compose up -d

# 5. Xem logs và debug
docker-compose logs -f

# 6. Stop khi không dùng
docker-compose down
```
