#!/bin/bash
set -e

echo "[1/5] Starting PostgreSQL..."
service postgresql start

echo "Waiting for PostgreSQL to accept connections..."
until pg_isready; do sleep 1; done

echo "[2/5] Initializing database..."
sudo -u postgres psql < /app/init.sql || true

echo "[3/5] Starting Redis..."
redis-server --daemonize yes

echo "[4/5] Starting API Gateway..."
/app/api-gateway/api-gateway &

echo "[5/5] Starting Product Service..."
python3 /app/product-service/main.py &

echo "[5/5] Starting Inventory Service..."
/app/inventory-service/inventory-service &

echo "🔥 ALL SERVICES STARTED SUCCESSFULLY 🔥"
wait -n
