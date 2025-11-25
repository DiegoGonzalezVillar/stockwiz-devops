#!/bin/bash
set -e

echo "===================================="
echo " STARTING FULLSTACK CONTAINER"
echo "===================================="

mkdir -p /app/logs

PG_BIN=/usr/lib/postgresql/14/bin

if [ ! -f "/var/lib/postgresql/data/PG_VERSION" ]; then
    echo "Initializing PostgreSQL data directory..."
    su postgres -c "$PG_BIN/initdb -D /var/lib/postgresql/data"

    echo "Starting temporary Postgres..."
    su postgres -c "$PG_BIN/pg_ctl -D /var/lib/postgresql/data -l /app/logs/postgres-init.log start"
    sleep 4

    echo "Creating DB + User..."
    su postgres -c "psql -c \"CREATE USER admin WITH PASSWORD 'admin123';\""
    su postgres -c "psql -c \"CREATE DATABASE microservices_db OWNER admin;\""
    su postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE microservices_db TO admin;\""

    echo "Stopping temporary Postgres..."
    su postgres -c "$PG_BIN/pg_ctl -D /var/lib/postgresql/data stop"
fi

echo "Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf


