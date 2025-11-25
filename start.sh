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
# 2) Start PostgreSQL (NO service, NO sudo)
############################################
echo "[2/5] Starting PostgreSQL..."

# Inicializa base si no existe
if [ ! -d "/var/lib/postgresql/data" ]; then
    mkdir -p /var/lib/postgresql/data
    chown -R postgres:postgres /var/lib/postgresql
    su postgres -c "initdb -D /var/lib/postgresql/data"
fi

# Iniciar postgres en background
su postgres -c "postgres -D /var/lib/postgresql/data" > /app/postgres.log 2>&1 &

sleep 3

echo "Loading initial SQL..."
su postgres -c "psql -f /app/init.sql" || true


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
