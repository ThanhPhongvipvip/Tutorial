# Docker Demo - Node.js

Demo đơn giản về Docker với Node.js.

## Cấu trúc

```
Demo/
├── Dockerfile
├── docker-compose.yml
├── package.json
├── server.js
├── .dockerignore
├── run.sh
└── README.md
```

## Cách chạy

### Cách 1: Docker Compose

```bash
# Docker Compose V1
docker-compose build
docker-compose up -d

# Docker Compose V2
docker compose build
docker compose up -d
```

### Cách 2: Script

```bash
chmod +x run.sh
./run.sh
```

## API Endpoints

**GET /**
```bash
curl http://localhost:3000
```

**GET /users**
```bash
curl http://localhost:3000/users
```

**POST /users**
```bash
curl -X POST http://localhost:3000/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","email":"alice@example.com"}'
```

## Các lệnh Docker

### Docker Compose

```bash
# Sử dụng docker-compose (V1) hoặc docker compose (V2)

# Build
docker compose build
docker compose build --no-cache

# Start
docker compose up
docker compose up -d

# Build và start
docker compose up -d --build

# Logs
docker compose logs
docker compose logs -f

# Stop
docker compose stop
docker compose down
```

### Docker commands

```bash
# Build image
docker build -t nodejs-demo .

# Run container
docker run -d -p 3000:3000 --name app nodejs-demo

# Logs
docker logs app
docker logs -f app

# Stop
docker stop app
docker rm app
```

## Giải thích

### Dockerfile
```dockerfile
FROM node:18-alpine        # Base image
WORKDIR /app               # Working directory
COPY package*.json ./      # Copy dependencies
RUN npm install            # Install
COPY . .                   # Copy source code
EXPOSE 3000                # Port
CMD ["npm", "start"]       # Start command
```

### docker-compose.yml
```yaml
services:
  app:
    build: .               # Build từ Dockerfile
    ports:
      - "3000:3000"        # Map port
    environment:
      - NODE_ENV=production
```

### .dockerignore
```
node_modules              # Không copy vào image
.git
README.md
```

## Cleanup

```bash
# Stop và xóa
docker compose down

# Xóa image
docker rmi demo-nodejs-app:latest
```

## Kiểm tra Docker

```bash
# Kiểm tra Docker
docker --version

# Kiểm tra Docker Compose V1
docker-compose --version

# Kiểm tra Docker Compose V2
docker compose version
```
