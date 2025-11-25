#!/bin/bash
set -e

echo "===================================="
echo " STARTING FULLSTACK CONTAINER SETUP"
echo "===================================="

# Crear directorios de logs si no existen (ya está en el Dockerfile, pero no está de más)
mkdir -p /app/logs
chmod -R 777 /app/logs

# --- 1. CONFIGURACIÓN DE POSTGRES ---
PGDATA_DIR="/var/lib/postgresql/data"
PG_BIN="/usr/lib/postgresql/14/bin"
INIT_SQL="/app/init.sql"
DB_NAME="microservices_db"
DB_USER="admin"
DB_PASS="admin123"

# Verificar si la base de datos ya está inicializada
if [ ! -s "$PGDATA_DIR/PG_VERSION" ]; then
    echo "Initializing PostgreSQL data directory..."
    
    # Asegurar que el usuario postgres y el directorio de datos existen
    # Esto se hace temporalmente como root, luego se cambia el dueño
    mkdir -p $PGDATA_DIR
    chown -R postgres:postgres $PGDATA_DIR

    # Ejecutar initdb como usuario 'postgres'
    su - postgres -c "$PG_BIN/initdb -D $PGDATA_DIR"
    
    # Arrancar PostgreSQL temporalmente en segundo plano para inicializar datos
    echo "Starting PostgreSQL temporarily for initialization..."
    su - postgres -c "$PG_BIN/pg_ctl -D $PGDATA_DIR -l /app/logs/postgres-temp.log start"
    
    # Esperar a que la BD esté lista para aceptar conexiones
    echo "Waiting for PostgreSQL to be ready..."
    while ! su - postgres -c "$PG_BIN/pg_isready -d postgres -U postgres"; do
        sleep 1
    done
    echo "PostgreSQL is ready."

    # Crear usuario, base de datos y ejecutar el script SQL
    echo "Creating user, database, and running init.sql..."
    su - postgres -c "$PG_BIN/psql -c \"CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';\""
    su - postgres -c "$PG_BIN/createdb $DB_NAME -O $DB_USER"
    su - postgres -c "$PG_BIN/psql -d $DB_NAME -U $DB_USER -f $INIT_SQL"

    # Detener PostgreSQL temporal
    echo "Stopping temporary PostgreSQL server..."
    su - postgres -c "$PG_BIN/pg_ctl -D $PGDATA_DIR stop"
    
    # Esperar a que se detenga
    while su - postgres -c "$PG_BIN/pg_isready -d postgres -U postgres"; do
        sleep 1
    done
    echo "PostgreSQL initialization complete."
fi

# --- 2. INICIO DE SUPERVISORD ---
echo "Starting supervisord..."
# Supervisord tomará el control del proceso 1, asegurando que el contenedor no se detenga.
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
