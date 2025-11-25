#!/bin/bash
set -e

echo "===================================="
echo " STARTING FULLSTACK CONTAINER SETUP"
echo "===================================="

# Crear directorios de logs si no existen
mkdir -p /app/logs
chmod -R 777 /app/logs

# --- 1. CONFIGURACIÓN DE POSTGRES ---
PGDATA_DIR="/var/lib/postgresql/data"
# ¡CORRECCIÓN! Usamos la ruta específica de binarios para PostgreSQL 13 en Debian
PG_BIN_DIR="/usr/lib/postgresql/13/bin"
INIT_SQL="/app/init.sql"
DB_NAME="microservices_db"
DB_USER="admin"
DB_PASS="admin123"
# CORRECCIÓN: Se añade 'sslmode=disable' para evitar que los clientes de Go fallen al conectarse sin SSL.
DB_URL="postgresql://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME?sslmode=disable"

# Verificar si la base de datos ya está inicializada (El directorio 'main' es estándar en Debian)
if [ ! -s "$PGDATA_DIR/main/PG_VERSION" ]; then
    echo "Initializing PostgreSQL data directory..."
    
    # 1. Ejecutar initdb
    # Usamos el usuario 'postgres' para ejecutar el comando
    su - postgres -c "$PG_BIN_DIR/initdb -D $PGDATA_DIR/main"
    
    # 2. Arrancar PostgreSQL temporalmente en segundo plano para inicializar datos
    echo "Starting PostgreSQL temporarily for initialization..."
    # Ejecutamos el servidor temporal con la configuración adecuada
    su - postgres -c "$PG_BIN_DIR/pg_ctl -D $PGDATA_DIR/main -o '-c listen_addresses=localhost' start > /app/logs/postgres-temp.log 2>&1"
    
    # 3. Esperar a que la BD esté lista para aceptar conexiones
    echo "Waiting for PostgreSQL to be ready..."
    # Utilizamos la ruta completa de pg_isready
    while ! $PG_BIN_DIR/pg_isready -d postgres -U postgres; do
        sleep 1
    done
    echo "PostgreSQL is ready."

    # 4. Crear usuario, base de datos y ejecutar el script SQL
    echo "Creating user, database, and running init.sql..."
    # Usamos la ruta completa de psql y createdb
    $PG_BIN_DIR/psql -U postgres -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
    $PG_BIN_DIR/createdb $DB_NAME -U postgres -O $DB_USER
    $PG_BIN_DIR/psql -d $DB_NAME -U $DB_USER -f $INIT_SQL
    
    # 5. Detener PostgreSQL temporal
    echo "Stopping temporary PostgreSQL server..."
    su - postgres -c "$PG_BIN_DIR/pg_ctl -D $PGDATA_DIR/main stop"
    
    sleep 2
    echo "PostgreSQL initialization complete."
fi

# --- 2. PRUEBA DE DEPURACIÓN (PRODUCT SERVICE - PYTHON) ---
# Ejecutamos PostgreSQL y Redis en segundo plano para la prueba.
echo "Starting PostgreSQL permanently..."
su - postgres -c "$PG_BIN_DIR/pg_ctl -D $PGDATA_DIR/main -o '-c listen_addresses=localhost' start > /app/logs/postgres-main.log 2>&1 &"
sleep 5 # Esperar a que Postgres esté listo

echo "Starting Redis permanently..."
/usr/bin/redis-server &
sleep 2 # Esperar a que Redis esté listo

echo "===================================="
echo "DEBUG: Ejecutando Product Service (Python) directamente para capturar el error."
echo "===================================="
# Exportamos las variables de entorno necesarias
export DATABASE_URL="$DB_URL"
export REDIS_URL="localhost:6379"

# Ejecutamos el script de Python. Si falla, el error (stack trace) se imprimirá aquí.
python3 /app/product-service/main.py

# Si el script llega aquí, el servicio Product arrancó con éxito.
echo "===================================="
echo "PRUEBA DE PRODUCT EXITOSA (debería fallar para ver el error)."
echo "===================================="
# Dejamos un comando de larga duración para mantener el contenedor abierto después de la prueba
tail -f /dev/null
