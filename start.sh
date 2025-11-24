#!/bin/bash
set -e

echo "===================================="
echo "  STARTING FULLSTACK CONTAINER"
echo "===================================="

############################################
# 1) Start Redis
############################################
echo "[1/5] Starting Redis..."
redis-server --daemonize yes
sleep 2

############################################
# 2) Start Postgres
############################################
echo "[2/5] Starting PostgreSQL..."
service postgresql start
sleep 3

echo "Loading initial SQL..."
sudo -u postgres psql -f /app/init.sql || true

############################################
# 3) Start API Gateway
############################################
echo "[3/5] Starting API Gateway..."
/app/api-gateway > /app/api.log 2>&1 &

############################################
# 4) Start Product Service
############################################
echo "[4/5] Starting Product Service..."
python3 /app/product-service/main.py > /app/product.log 2>&1 &

############################################
# 5) Start Inventory Service
############################################
echo "[5/5] Starting Inventory Service..."
/app/inventory-service > /app/inventory.log 2>&1 &

############################################
# 6) Logs + wait
############################################
echo "===================================="
echo " ALL SERVICES STARTED SUCCESSFULLY"
echo "===================================="
tail -f /app/*.log
