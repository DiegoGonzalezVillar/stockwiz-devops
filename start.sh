#!/bin/bash
set -e

echo "===================================="
echo " STARTING FULLSTACK CONTAINER SETUP"
echo "===================================="

# Crear directorios de logs si no existen y ajustar permisos
mkdir -p /app/logs
chmod -R 777 /app/logs

# --- 1. CONFIGURACIÓN DE POSTGRES ---
PGDATA_DIR="/var/lib/postgresql/data"
PG_BIN_DIR="/usr/lib/postgresql/13/bin"
INIT_SQL="/app/init.sql"

# --- OBTENCIÓN DE VARIABLES CRÍTICAS ---
# Los valores seguros (DB_PASSWORD, INVENTORY_API_KEY) vienen inyectados por ECS (Secrets Manager).

# Base de Datos
DB_NAME="${DB_NAME:-microservices_db}"
DB_USER="${DB_USER:-admin}"
# CONTRASENA SEGURA: Usa el valor inyectado por ECS/Secrets Manager
DB_PASS="$DB_PASSWORD"
DB_HOST="${DB_HOST:-localhost}" 

# URL completa para la conexión de las aplicaciones
DB_URL="postgresql://$DB_USER:$DB_PASS@$DB_HOST:5432/$DB_NAME?sslmode=disable"
# ===================================================================================

# Verificar si la base de datos ya está inicializada
if [ ! -s "$PGDATA_DIR/main/PG_VERSION" ]; then
    echo "Initializing PostgreSQL data directory..."
    
    # 1. Ejecutar initdb
    su - postgres -c "$PG_BIN_DIR/initdb -D $PGDATA_DIR/main"
    
    # 2. Arrancar PostgreSQL temporalmente
    echo "Starting PostgreSQL temporarily for initialization..."
    # Se inicia en modo TCP/IP escuchando en localhost
    su - postgres -c "$PG_BIN_DIR/pg_ctl -D $PGDATA_DIR/main -o '-c listen_addresses=localhost' start > /app/logs/postgres-temp.log 2>&1"
    
    # 3. Esperar a que la BD esté lista
    echo "Waiting for PostgreSQL to be ready..."
    # pg_isready usa por defecto conexión local, lo dejamos así
    while ! $PG_BIN_DIR/pg_isready -d postgres -U postgres; do
        sleep 1
    done
    echo "PostgreSQL is ready."

    # 4. Crear usuario, base de datos y ejecutar el script SQL
    echo "Creating user, database, and running init.sql..."
    # *** CORRECCIÓN CRÍTICA: Se añade -h localhost para forzar la conexión TCP/IP
    #     y evitar el error de socket de dominio Unix. ***
    
    # Crea el usuario con la contraseña segura
    $PG_BIN_DIR/psql -h localhost -U postgres -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
    
    # Crea la base de datos
    $PG_BIN_DIR/createdb -h localhost $DB_NAME -U postgres -O $DB_USER
    
    # Ejecuta el script de inicialización
    $PG_BIN_DIR/psql -h localhost -d $DB_NAME -U $DB_USER -f $INIT_SQL
    
    # 5. Detener PostgreSQL temporal
    echo "Stopping temporary PostgreSQL server..."
    su - postgres -c "$PG_BIN_DIR/pg_ctl -D $PGDATA_DIR/main stop"
    
    sleep 2
    echo "PostgreSQL initialization complete."
fi

# --- 2. PREPARACIÓN DE ENTORNO Y ARRANQUE DE SUPERVISOR ---

# 1. Exportar la URL de conexión (incluye el secreto de la contraseña)
export DATABASE_URL="$DB_URL"
export REDIS_URL="localhost:6379"

# 2. Exportar la clave de API interna
# Esta variable fue inyectada de forma segura por ECS/Secrets Manager.
export INVENTORY_API_KEY="$INVENTORY_API_KEY"

# 3. Arrancar el demonio supervisor, que iniciará los microservicios
echo "Starting supervisord..."
# Supervisor usará las variables de entorno exportadas para iniciar los microservicios
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf