# --------------------------------------------------------------------------
# ETAPA 1: BUILD (Compilación de binarios Go)
# Usamos una imagen de Go basada en Alpine (porque es pequeña para el build)
# --------------------------------------------------------------------------
FROM golang:1.21-alpine AS builder

# Instalar dependencias necesarias para la compilación (si aplica)
RUN apk update && apk add --no-cache git build-base 

WORKDIR /app

# Copiar directorios de servicios Go
COPY api-gateway/ /app/api-gateway/
COPY inventory-service/ /app/inventory-service/

# Compilar binarios de Go (usando CGO_ENABLED=0 para binarios estáticos más portables)
# Esto asegura que los binarios funcionarán en la imagen final Debian
RUN CGO_ENABLED=0 go build -o /app/api-gateway/api-bin /app/api-gateway
RUN CGO_ENABLED=0 go build -o /app/inventory-service/inventory-bin /app/inventory-service


# --------------------------------------------------------------------------
# ETAPA 2: FINAL (Entorno de Ejecución Estable - Debian Slim)
# Usamos Debian Slim para evitar los problemas de APK con Postgres/Supervisor.
# --------------------------------------------------------------------------
FROM debian:bullseye-slim

ENV DEBIAN_FRONTEND=noninteractive

# --------------------------------------------------------------------------
# PASO ÚNICO: Instalar TODAS las dependencias de ejecución usando APT.
# --------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip \
    supervisor \
    bash \
    redis-server \
    # Paquetes estables de Debian
    postgresql-13 postgresql-client-13 \
    # Limpieza
    && rm -rf /var/lib/apt/lists/*

############################################
# CONFIGURACIÓN DE USUARIOS Y DIRECTORIOS
############################################
# La instalación de postgresql-13 ya crea el usuario 'postgres' en Debian.

WORKDIR /app

RUN mkdir -p /app/logs \
    && chmod -R 777 /app/logs

# Inicializar el directorio de datos de PostgreSQL para asegurar permisos correctos
RUN mkdir -p /var/lib/postgresql/data/main \
    && chown -R postgres:postgres /var/lib/postgresql/data

############################################
# COPIAR ARCHIVOS DE CONFIGURACIÓN Y BINARIOS
############################################
COPY start.sh /app/start.sh
COPY init.sql /app/init.sql
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copiar el servicio Python y sus requisitos
COPY product-service/ /app/product-service/

# Copiar los binarios de Go compilados desde la etapa 'builder'
COPY --from=builder /app/api-gateway/api-bin /app/api-gateway/api-bin
COPY --from=builder /app/inventory-service/inventory-bin /app/inventory-service/inventory-bin

# Permisos
RUN chmod +x /app/start.sh
RUN pip3 install --no-cache-dir -r /app/product-service/requirements.txt

############################################
# PUERTO Y PUNTO DE ENTRADA
############################################
EXPOSE 8000

# El ENTRYPOINT ejecuta el script de inicialización y supervisor
CMD ["/app/start.sh"]

# El ENTRYPOINT ejecuta el script de inicialización y supervisor
CMD ["/app/start.sh"]

