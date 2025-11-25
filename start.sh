#!/bin/bash
set -e

echo "===================================="
echo " STARTING FULLSTACK CONTAINER"
echo "===================================="

mkdir -p /app/logs

# Inicializar PostgreSQL si no existe
if [ ! -f "/var/lib/postgresql/data/PG_VERSION" ]; then
    echo "Initializing PostgreSQL data directory..."
    su postgres -c "/usr/lib/postgresql/14/bin/initdb -D /var/lib/postgresql/data"

    echo "Creating user, password and database..."
    su postgres -c "pg_ctl -D /var/lib/postgresql/data -l /app/logs/postgres-init.log start"
    sleep 3

    su postgres -c "psql -c \"CREATE USER admin WITH PASSWORD 'admin123';\""
    su postgres -c "psql -c \"CREATE DATABASE microservices_db OWNER admin;\""
    su postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE microservices_db TO admin;\""

    su postgres -c "pg_ctl -D /var/lib/postgresql/data stop"
fi

echo "Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
