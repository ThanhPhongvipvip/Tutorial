#!/bin/bash

echo "=========================================="
echo "Docker Demo - Node.js & PostgreSQL"
echo "=========================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed"
    exit 1
fi

# Check Docker Compose
if docker compose version &> /dev/null; then
    COMPOSE=(docker compose)
elif command -v docker-compose &> /dev/null; then
    COMPOSE=(docker-compose)
else
    echo "Error: Docker Compose is not installed"
    echo "Install it using: sudo apt install docker-compose-plugin"
    exit 1
fi

echo "Using Docker Compose: ${COMPOSE[*]}"

echo ""
echo "Step 1: Stopping existing containers..."
"${COMPOSE[@]}" down

echo ""
echo "Step 2: Building images with Docker Compose..."
"${COMPOSE[@]}" build --no-cache

echo ""
echo "Step 3: Starting containers..."
"${COMPOSE[@]}" up -d

echo ""
echo "Step 4: Waiting for services to be ready..."
sleep 5

echo ""
echo "=========================================="
echo "Services are running!"
echo "=========================================="
echo ""
echo "API Endpoints:"
echo "  - http://localhost:3000"
echo "  - http://localhost:3000/health"
echo "  - http://localhost:3000/users"
echo ""
echo "PostgreSQL:"
echo "  - Host: localhost"
echo "  - Port: 5432"
echo "  - User: postgres"
echo "  - Password: postgres"
echo "  - Database: mydb"
echo ""
echo "Useful commands:"
echo "  ${COMPOSE[*]} logs -f       # View logs"
echo "  ${COMPOSE[*]} ps            # View status"
echo "  ${COMPOSE[*]} down          # Stop services"
echo "  ${COMPOSE[*]} build         # Rebuild images"
echo ""
echo "=========================================="
echo ""

# Test API
echo "Testing API..."
echo ""

curl -s http://localhost:3000 | jq . 2>/dev/null || \
curl -s http://localhost:3000

echo ""
echo ""
echo "Health check..."
echo ""

curl -s http://localhost:3000/health | jq . 2>/dev/null || \
curl -s http://localhost:3000/health

echo ""
echo ""
echo "=========================================="
echo "Setup complete!"
echo "=========================================="