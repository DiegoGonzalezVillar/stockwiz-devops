#!/bin/bash
set -e

echo "===================================="
echo " STARTING FULLSTACK CONTAINER"
echo "===================================="

# Inicializar la DB si está vacía
if [ ! -f "/var/lib/postgresql/data/PG_VERSION" ]; then
    echo "Initializing PostgreSQL data directory..."
    /usr/local/bin/docker-entrypoint.sh postgres &
    sleep 5
fi

echo "Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
