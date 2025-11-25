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

# --- 2. PRUEBA DE DEPURACIÓN (INVENTORY) ---
# Ejecutamos PostgreSQL en segundo plano de forma permanente antes de Supervisor,
# para garantizar que el servicio de inventario pueda conectarse para la depuración.
echo "Starting PostgreSQL for execution..."
su - postgres -c "$PG_BIN_DIR/pg_ctl -D $PGDATA_DIR/main -o '-c listen_addresses=localhost' start > /app/logs/postgres-main.log 2>&1"

# Damos 5 segundos extra para que el servidor de postgres esté realmente listo
sleep 5 

echo "===================================="
echo "DEBUG: Ejecutando Inventory Service directamente para capturar el error."
echo "===================================="
# Ejecutamos el binario Inventory con sus variables de entorno.
# La salida (stdout/stderr) irá directamente a los logs del contenedor.
export DATABASE_URL="$DB_URL"
export REDIS_URL="redis://localhost:6379"

/app/inventory-service/inventory-bin

# Si el comando anterior tiene éxito, el script continuará hasta el punto 3 (Supervisor).
# Si el comando anterior falla (que es lo que estaba pasando), imprimirá el error
# y el script terminará (debido a set -e).

# --- 3. INICIAR SUPERVISORD (Asumiendo que la prueba fue exitosa) ---
echo "===================================="
echo "PRUEBA DE INVENTORY EXITOSA. Iniciando Supervisor."
echo "===================================="
# Si el script llega aquí, el binario de inventario arrancó con éxito.
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
