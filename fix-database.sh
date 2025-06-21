#!/bin/bash

# Fix database volume issues
echo "Fixing database volume issues..."

# Stop all containers
echo "Stopping containers..."
docker compose down

# Remove old bind mount directories (requires sudo)
echo "Removing old bind mount directories..."
echo "Please enter your sudo password when prompted:"
sudo rm -rf data/database data/minio

# Remove the data directory if empty
rmdir data 2>/dev/null || true

# Remove any existing volumes to start fresh
echo "Removing old volumes..."
docker volume rm urban-vision-erp_database_data 2>/dev/null || true
docker volume rm urban-vision-erp_minio_data 2>/dev/null || true

# Start services
echo "Starting services with proper volumes..."
docker compose up -d

echo "Done! Services should start with proper volume configuration."
echo "Run './uv.sh status' in a few seconds to check if everything is working."