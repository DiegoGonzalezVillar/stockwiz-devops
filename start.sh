#!/bin/bash
set -e

echo "===================================="
echo " STARTING FULLSTACK CONTAINER SETUP"
echo "===================================="

# Crear directorios de logs si no existen
mkdir -p /app/logs
chmod -R 777 /app/logs

# --- 1. CONFIGURACIÓN DE POSTGRES ---
# En Alpine, los binarios de Postgres suelen estar en /usr/bin/
PGDATA_DIR="/var/lib/postgresql/data"
PG_BIN_DIR="/usr/bin" # Directorio de binarios de Postgres en Alpine
INIT_SQL="/app/init.sql"
DB_NAME="microservices_db"
DB_USER="admin"
DB_PASS="admin123"

# Verificar si la base de datos ya está inicializada
if [ ! -s "$PGDATA_DIR/PG_VERSION" ]; then
    echo "Initializing PostgreSQL data directory..."
    
    # El Dockerfile ya inicializó el directorio y permisos. Solo ejecutamos initdb.
    su - postgres -c "$PG_BIN_DIR/initdb -D $PGDATA_DIR"
    
    # Arrancar PostgreSQL temporalmente en segundo plano para inicializar datos
    echo "Starting PostgreSQL temporarily for initialization..."
    # Usamos el comando 'postgres' directamente, no pg_ctl
    su - postgres -c "$PG_BIN_DIR/postgres -D $PGDATA_DIR > /app/logs/postgres-temp.log 2>&1 &"
    
    # Esperar a que la BD esté lista para aceptar conexiones
    echo "Waiting for PostgreSQL to be ready..."
    # Utilizamos pg_isready para verificar el estado
    while ! $PG_BIN_DIR/pg_isready -d postgres -U postgres; do
        sleep 1
    done
    echo "PostgreSQL is ready."

    # Crear usuario, base de datos y ejecutar el script SQL
    echo "Creating user, database, and running init.sql..."
    $PG_BIN_DIR/psql -U postgres -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
    $PG_BIN_DIR/createdb $DB_NAME -U postgres -O $DB_USER
    # Usamos psql con la bandera -f para ejecutar el script
    $PG_BIN_DIR/psql -d $DB_NAME -U $DB_USER -f $INIT_SQL
    
    # Detener PostgreSQL temporal (buscamos el PID y lo matamos)
    echo "Stopping temporary PostgreSQL server..."
    PG_PID=$(pgrep -u postgres -f "postgres -D $PGDATA_DIR")
    if [ ! -z "$PG_PID" ]; then
        kill $PG_PID
    fi
    
    # Dar un momento para que se detenga
    sleep 2
    echo "PostgreSQL initialization complete."
fi

# --- 2. INICIO DE SUPERVISORD ---
echo "Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
