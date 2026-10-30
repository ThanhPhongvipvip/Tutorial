# Docker

## Docker là gì?

Docker là một nền tảng mã nguồn mở giúp đóng gói, phân phối và chạy ứng dụng trong các container ảo hóa. Docker cho phép developers và sysadmins phát triển, triển khai và vận hành ứng dụng một cách nhất quán trên nhiều môi trường khác nhau.

### Định nghĩa
- Docker tạo ra lớp trừu tượng cho phép ảo hóa hệ điều hành dựa trên Linux và Windows
- Container chứa toàn bộ những gì cần thiết để chạy ứng dụng: code, runtime, thư viện, dependencies
- Đảm bảo ứng dụng chạy giống nhau trên mọi môi trường: development, testing, production

---

## Lịch sử hình thành

| Thời gian | Sự kiện |
|-----------|---------|
| 2013 | Solomon Hykes tạo ra Docker tại công ty dotCloud (Pháp) |
| 13/3/2013 | Docker được công bố mã nguồn mở |
| 2014 | Trở thành Top 20 dự án nổi bật trên GitHub |
| 2/2016 | Ra mắt Docker Enterprise Edition |
| Hiện nay | Hơn 3,300 contributors, 43,000+ stars, 12,000+ forks |

---

## Kiến trúc Docker

```
┌─────────────────────────────────────────────────────┐
│                  Docker Client                       │
│              (Command Line Interface)                │
└─────────────────┬───────────────────────────────────┘
                  │ Docker API (REST)
                  ↓
┌─────────────────────────────────────────────────────┐
│               Docker Daemon (dockerd)                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │Container │  │Container │  │Container │          │
│  │    1     │  │    2     │  │    3     │          │
│  └──────────┘  └──────────┘  └──────────┘          │
│                                                      │
│  ┌─────────────────────────────────────┐            │
│  │        Images (Read-only)           │            │
│  └─────────────────────────────────────┘            │
└─────────────────────────────────────────────────────┘
                  │
                  ↓
┌─────────────────────────────────────────────────────┐
│             Docker Registry (Docker Hub)             │
│         (Public/Private Image Repository)            │
└─────────────────────────────────────────────────────┘
```

### Các thành phần chính

**Docker Client**
- Giao diện dòng lệnh để tương tác với Docker
- Gửi commands tới Docker Daemon qua API

**Docker Daemon (dockerd)**
- Server Docker chạy ngầm trên host
- Quản lý images, containers, networks, volumes

**Docker Registry**
- Nơi lưu trữ Docker images
- Docker Hub là registry công khai lớn nhất

---

## Cách hoạt động của Docker

### Quy trình làm việc

**Bước 1: Build Dockerfile**
```bash
# Viết Dockerfile định nghĩa môi trường
# Build image từ Dockerfile
docker build -t my-app:1.0 .
```
Kết quả: Docker Image (template để tạo container)

**Bước 2: Push Image lên Registry**
```bash
# Đăng nhập Docker Hub
docker login

# Push image lên repository
docker push username/my-app:1.0
```
Kết quả: Image được lưu trên cloud, có thể chia sẻ

**Bước 3: Pull và Run Container**
```bash
# Trên máy khác, pull image về
docker pull username/my-app:1.0

# Chạy container từ image
docker run -d -p 8080:80 username/my-app:1.0
```
Kết quả: Ứng dụng chạy với đầy đủ môi trường như ban đầu

---

## Các khái niệm quan trọng

### 1. Docker Engine
- Thành phần cốt lõi của Docker
- Bao gồm: Docker Daemon, REST API, Docker CLI
- Chịu trách nhiệm xây dựng, chạy và quản lý containers

### 2. Docker Image
- Template chỉ đọc (read-only) để tạo container
- Chứa: OS, application code, libraries, dependencies
- Có thể build từ Dockerfile hoặc pull từ registry
- Image được tạo từ nhiều layers chồng lên nhau

```
Image = Base OS + Dependencies + Application Code
```

### 3. Docker Container
- Instance đang chạy của một image
- Có thể start, stop, restart, delete
- Mỗi container cô lập với nhau và với host
- Nhẹ, có thể tạo/xóa nhanh chóng

```
Container = Image + Writable Layer
```

### 4. Dockerfile
- File text chứa instructions để build image
- Định nghĩa từng bước setup môi trường
- Syntax đơn giản, dễ đọc, dễ maintain

### 5. Docker Volume
- Cơ chế lưu trữ persistent data
- Dữ liệu tồn tại ngay cả khi container bị xóa
- Chia sẻ data giữa containers

```
Container Data (ephemeral) - xóa khi container xóa
Volume Data (persistent) - tồn tại độc lập
```

### 6. Docker Network
- Cho phép containers kết nối với nhau
- Các loại: bridge, host, overlay, none
- Containers có thể gọi nhau qua tên

### 7. Docker Compose
- Tool quản lý multi-container applications
- Định nghĩa cấu hình trong file docker-compose.yml
- Khởi động tất cả services bằng một lệnh

### 8. Docker Hub
- Registry công cộng miễn phí
- Hơn 100,000+ images sẵn có
- Official images: node, python, nginx, mysql, redis, postgres...

### 9. Docker Registry
- Nơi lưu trữ và phân phối images
- Docker Hub là registry mặc định
- Private Registry: AWS ECR, Google GCR, Azure ACR

### 10. Docker Repository
- Tập hợp các phiên bản (tags) của cùng một image
- Ví dụ: node:18, node:20, node:latest

---

## Dockerfile

### Các Instructions quan trọng

| Instruction | Mô tả | Ví dụ |
|------------|-------|-------|
| FROM | Chỉ định base image | FROM node:18-alpine |
| WORKDIR | Thiết lập thư mục làm việc | WORKDIR /app |
| COPY | Copy files từ host vào image | COPY . . |
| ADD | Tương tự COPY, hỗ trợ URL và extract tar | ADD app.tar.gz /app |
| RUN | Chạy lệnh khi build image | RUN npm install |
| CMD | Lệnh mặc định khi container start | CMD ["node", "app.js"] |
| ENTRYPOINT | Lệnh chính khi container start | ENTRYPOINT ["python3"] |
| ENV | Thiết lập biến môi trường | ENV NODE_ENV=production |
| ARG | Biến chỉ dùng lúc build | ARG VERSION=1.0 |
| EXPOSE | Khai báo port container lắng nghe | EXPOSE 8080 |
| VOLUME | Tạo mount point cho persistent data | VOLUME /data |
| USER | Thiết lập user chạy container | USER node |
| LABEL | Thêm metadata cho image | LABEL version="1.0" |

### Ví dụ Dockerfile cơ bản

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install --production

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```

### Multi-stage Build

```dockerfile
# Stage 1: Build
FROM node:18 AS builder
WORKDIR /app
COPY . .
RUN npm install
RUN npm run build

# Stage 2: Production
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
CMD ["node", "dist/server.js"]
```

Lợi ích: Giảm kích thước image bằng cách chỉ copy artifacts cần thiết

## Docker Compose

### Docker Compose là gì?

Docker Compose là tool cho phép định nghĩa và chạy multi-container applications. Thay vì chạy từng container riêng lẻ, bạn định nghĩa tất cả trong file docker-compose.yml.

### Khi nào dùng Docker Compose?

- Application có nhiều services: web, database, cache, queue
- Môi trường development phức tạp
- Cần orchestrate nhiều containers cùng lúc
- Muốn setup dễ dàng cho team members

### File docker-compose.yml

```yaml
version: '3.8'

services:
  web:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DB_HOST=db
    depends_on:
      - db
    networks:
      - app-network

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=myuser
      - POSTGRES_PASSWORD=mypassword
      - POSTGRES_DB=mydb
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - app-network

volumes:
  postgres-data:

networks:
  app-network:
    driver: bridge
```

### Các lệnh Docker Compose

```bash
# Khởi động tất cả services
docker-compose up

# Chạy detached mode (background)
docker-compose up -d

# Build lại images trước khi start
docker-compose up --build

# Stop tất cả services
docker-compose stop

# Stop và xóa containers, networks
docker-compose down

# Xóa cả volumes
docker-compose down -v

# Xem logs
docker-compose logs
docker-compose logs -f

# Xem trạng thái services
docker-compose ps

# Chạy lệnh trong service
docker-compose exec web sh

# Restart service
docker-compose restart web
```

---

## Các lệnh Docker cơ bản

### Quản lý Images

```bash
# List images
docker images
docker image ls

# Pull image từ Docker Hub
docker pull nginx:latest
docker pull node:18-alpine

# Build image từ Dockerfile
docker build -t my-app:1.0 .
docker build -t my-app:latest --no-cache .

# Tag image
docker tag my-app:1.0 username/my-app:1.0

# Push image lên Docker Hub
docker login
docker push username/my-app:1.0

# Xem history của image
docker history my-app:1.0

# Inspect image (xem chi tiết)
docker inspect nginx:latest

# Xóa image
docker rmi nginx:latest
docker image rm my-app:1.0

# Xóa images không sử dụng
docker image prune

# Xóa tất cả images
docker rmi $(docker images -q)
```

### Quản lý Containers

```bash
# List containers đang chạy
docker ps

# List tất cả containers (bao gồm stopped)
docker ps -a

# Chạy container từ image
docker run nginx
docker run -d nginx                    # Detached mode (background)
docker run -d --name web nginx         # Đặt tên container
docker run -d -p 8080:80 nginx         # Map ports
docker run -d -v $(pwd):/app nginx     # Mount volume

# Chạy container với environment variables
docker run -d -e NODE_ENV=production node-app

# Chạy container interactive mode
docker run -it ubuntu bash
docker run -it --rm alpine sh          # Tự động xóa sau khi exit

# Stop container
docker stop web
docker stop $(docker ps -q)            # Stop tất cả

# Start container đã stop
docker start web

# Restart container
docker restart web

# Xem logs
docker logs web
docker logs -f web                     # Follow logs (real-time)
docker logs --tail 100 web             # 100 dòng cuối

# Chạy lệnh trong container đang chạy
docker exec web ls -la
docker exec -it web bash               # Interactive shell

# Xem thông tin container
docker inspect web
docker stats web                       # CPU, RAM usage real-time
docker top web                         # Processes trong container

# Copy files giữa host và container
docker cp file.txt web:/app/
docker cp web:/app/logs.txt ./

# Xóa container
docker rm web
docker rm -f web                       # Force remove (đang chạy)
docker rm $(docker ps -a -q)           # Xóa tất cả containers

# Cleanup
docker container prune                 # Xóa stopped containers
```

### Quản lý Volumes

```bash
# List volumes
docker volume ls

# Tạo volume
docker volume create my-data

# Inspect volume
docker volume inspect my-data

# Sử dụng volume khi run container
docker run -d -v my-data:/app/data nginx

# Mount host directory vào container
docker run -d -v $(pwd)/data:/app/data nginx

# Xóa volume
docker volume rm my-data

# Xóa volumes không sử dụng
docker volume prune
```

### Quản lý Networks

```bash
# List networks
docker network ls

# Tạo network
docker network create my-network

# Inspect network
docker network inspect my-network

# Connect container vào network
docker network connect my-network web

# Run container trong network cụ thể
docker run -d --network my-network --name web nginx

# Xóa network
docker network rm my-network

# Xóa networks không sử dụng
docker network prune
```

### Docker System Commands

```bash
# Xem thông tin tổng quan
docker info

# Xem disk usage
docker system df

# Cleanup toàn bộ (images, containers, volumes, networks không dùng)
docker system prune

# Cleanup aggressive (bao gồm cả images không dùng)
docker system prune -a

# Xem version
docker version
```

### Các lệnh hữu ích khác

```bash
# Login/Logout Docker Hub
docker login
docker logout

# Search image trên Docker Hub
docker search nginx

# Rename container
docker rename old-name new-name

# Save/Load image (backup)
docker save -o nginx-backup.tar nginx:latest
docker load -i nginx-backup.tar
```
---

## Best Practices

### Image Best Practices

**Sử dụng official images**
```dockerfile
FROM node:18-alpine
```

**Specify version tags**
```dockerfile
FROM node:18-alpine  # Good: Specific version
FROM node:latest     # Bad: Avoid latest
```

**Minimize layers**
```dockerfile
# Bad
RUN apt-get update
RUN apt-get install -y curl

# Good
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*
```

**Use .dockerignore**
```
node_modules
npm-debug.log
.git
.env
```

### Security Best Practices

**Run as non-root user**
```dockerfile
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
```

**Use secrets properly**
```bash
# Bad: Don't hardcode secrets
ENV DB_PASSWORD=secret123

# Good: Use env files
docker run --env-file .env my-app
```

### Development Best Practices

**Use docker-compose for local dev**
```yaml
version: '3.8'
services:
  web:
    build: .
    volumes:
      - .:/app
    ports:
      - "3000:3000"
```

**Health checks**
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:3000/health || exit 1
```

### Cleanup Best Practices

```bash
# Regular cleanup
docker system prune -f

# Aggressive cleanup
docker system prune -a --volumes -f
```

---

## Tài liệu tham khảo

- Docker Official Documentation: https://docs.docker.com/
- Docker Hub: https://hub.docker.com/
- Dockerfile Reference: https://docs.docker.com/engine/reference/builder/
- Docker Compose Reference: https://docs.docker.com/compose/compose-file/


---

## .dockerignore

### .dockerignore là gì?

File `.dockerignore` tương tự `.gitignore`, dùng để loại trừ các files/folders không cần thiết khi build Docker image.

### Khi nào cần .dockerignore?

**Cần dùng khi:**

1. **Build Docker image với COPY hoặc ADD**
   - Khi Dockerfile có `COPY . .` hoặc `ADD . .`
   - Docker sẽ copy toàn bộ thư mục hiện tại vào image
   - Cần loại trừ files không cần thiết để giảm size và tăng bảo mật

2. **Project có nhiều files không cần thiết:**
   - `node_modules` (cài lại bằng npm install trong image)
   - `.git` (lịch sử git không cần trong container)
   - Log files, temporary files
   - Documentation files (README, docs)
   - Test files, development configs

3. **Cần tăng tốc độ build:**
   - Files ít thay đổi được cache
   - Files không cần thiết làm cache bị invalidate
   - Build context nhỏ hơn → upload nhanh hơn

4. **Bảo mật:**
   - `.env` (chứa secrets)
   - Private keys, certificates
   - Sensitive configuration files

**Không cần dùng khi:**

1. Dockerfile không dùng `COPY . .` hoặc `ADD . .`
2. Project rất nhỏ, ít files
3. Copy selective files (COPY package.json, COPY src/)

### Ví dụ .dockerignore

```
# Node.js
node_modules
npm-debug.log
yarn-error.log

# Git
.git
.gitignore

# Environment
.env
.env.local
.env.*.local

# IDE
.vscode
.idea
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Documentation
README.md
docs/
*.md

# Test
test/
tests/
__tests__/
*.test.js
*.spec.js

# Build artifacts
dist/
build/
*.log

# Docker
Dockerfile
docker-compose.yml
.dockerignore
```

### So sánh với/không có .dockerignore

**Không có .dockerignore:**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY . .              # Copy tất cả: code + node_modules + .git + docs
RUN npm install
CMD ["npm", "start"]
```
Kết quả: Image size lớn, build chậm, có thể có security issues

**Có .dockerignore:**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .              # Chỉ copy code, loại trừ node_modules, .git, docs
CMD ["npm", "start"]
```
Kết quả: Image nhỏ hơn, build nhanh hơn, an toàn hơn

### Best Practice

```dockerfile
# Copy dependencies files trước
COPY package*.json ./
RUN npm install

# Copy source code sau (tận dụng Docker cache)
COPY . .
```

Kết hợp với `.dockerignore`:
```
node_modules
.git
*.md
.env
```

**Lợi ích:**
- Layer `RUN npm install` được cache nếu package.json không đổi
- Chỉ copy source code cần thiết
- Build nhanh hơn nhiều khi develop
