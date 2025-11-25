#!/bin/bash
set -e

echo "===================================="
echo " STARTING FULLSTACK CONTAINER"
echo "===================================="

# Crear carpeta logs
mkdir -p /app/logs

# Inicializar la DB la primera vez
if [ ! -f "/var/lib/postgresql/data/PG_VERSION" ]; then
    echo "Initializing PostgreSQL data directory..."
    su postgres -c "/usr/lib/postgresql/14/bin/initdb -D /var/lib/postgresql/data"
fi

echo "Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
