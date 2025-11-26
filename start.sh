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
PG_BIN_DIR="/usr/lib/postgresql/13/bin"
INIT_SQL="/app/init.sql"

# --- OBTENCIÓN DE VARIABLES CRÍTICAS ---
# Estos valores DEBEN ser inyectados por ECS (ya sea como environment o secrets)
DB_NAME="${DB_NAME:-microservices_db}"
DB_USER="${DB_USER:-admin}"
# >>>>>>> CAMBIO CRÍTICO: USAR LA VARIABLE DE ENTORNO SEGURA INYECTADA POR ECS <<<<<<<
# La variable DB_PASSWORD viene de AWS Secrets Manager.
DB_PASS="$DB_PASSWORD"
# Se asume que el host es 'localhost' ya que DB y aplicación están en el mismo contenedor
DB_HOST="${DB_HOST:-localhost}" 
# ===================================================================================

# CORRECCIÓN: Se construye la URL usando las variables.
DB_URL="postgresql://$DB_USER:$DB_PASS@$DB_HOST:5432/$DB_NAME?sslmode=disable"

# Verificar si la base de datos ya está inicializada (El directorio 'main' es estándar en Debian)
if [ ! -s "$PGDATA_DIR/main/PG_VERSION" ]; then
    echo "Initializing PostgreSQL data directory..."
    
    # ... (Pasos de initdb, arranque temporal, espera, detención - Tu código original) ...
    
    # 4. Crear usuario, base de datos y ejecutar el script SQL
    echo "Creating user, database, and running init.sql..."
    # Usamos la ruta completa de psql y createdb
    # Nótese el uso de $DB_PASS
    $PG_BIN_DIR/psql -U postgres -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
    $PG_BIN_DIR/createdb $DB_NAME -U postgres -O $DB_USER
    $PG_BIN_DIR/psql -d $DB_NAME -U $DB_USER -f $INIT_SQL
    
    # ... (Pasos para detener PostgreSQL temporal) ...
    
    echo "PostgreSQL initialization complete."
fi

# --- 2. PREPARACIÓN DE ENTORNO Y ARRANQUE DE SUPERVISOR ---

# Exportar la URL completa (incluyendo la contraseña segura) para que los microservicios la usen
export DATABASE_URL="$DB_URL"
export REDIS_URL="localhost:6379"

# >>>>>>> EXPORTAR LA CONTRASEÑA SECRETA PARA OTROS SERVICIOS <<<<<<<
# Es crucial que la contraseña inyectada por ECS también esté disponible para las aplicaciones.
export DB_PASSWORD="$DB_PASS" 
# ===================================================================

echo "Starting supervisord..."
# Supervisor usará las variables de entorno exportadas para iniciar los microservicios
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf