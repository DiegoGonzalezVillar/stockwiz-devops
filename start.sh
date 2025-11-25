#!/bin/bash
set -e

echo "===================================="
echo " STARTING FULLSTACK CONTAINER"
echo "===================================="

mkdir -p /app/logs
chmod -R 777 /app/logs

echo "Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf



