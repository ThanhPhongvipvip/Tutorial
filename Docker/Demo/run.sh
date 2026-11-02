#!/bin/bash

echo "Docker Demo - Building and Starting..."
echo ""

# Check Docker Compose command
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    echo "Error: Docker Compose not found"
    echo "Install: https://docs.docker.com/compose/install/"
    exit 1
fi

$COMPOSE_CMD down
$COMPOSE_CMD build
$COMPOSE_CMD up -d

echo ""
echo "Waiting for service..."
sleep 3

echo ""
echo "Service running at: http://localhost:3000"
echo ""
echo "Test endpoints:"
curl -s http://localhost:3000
echo ""
echo ""
curl -s http://localhost:3000/users
echo ""
