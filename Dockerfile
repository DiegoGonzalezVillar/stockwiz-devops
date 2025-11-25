# --------------------------------------------------------------------------
# ETAPA 1: BUILD (Compilación de binarios Go)
# Usamos una imagen de Go basada en Alpine para mantener la coherencia
# --------------------------------------------------------------------------
FROM golang:1.21-alpine AS builder

# Instalar dependencias necesarias para la compilación (si aplica)
RUN apk update && apk add --no-cache git build-base 

WORKDIR /app

# Copiar directorios de servicios Go
COPY api-gateway/ /app/api-gateway/
COPY inventory-service/ /app/inventory-service/

# Compilar binarios de Go (usando CGO_ENABLED=0 para binarios estáticos más portables)
# Esto asegura que los binarios funcionarán en la imagen final Alpine
RUN CGO_ENABLED=0 go build -o /app/api-gateway/api-bin /app/api-gateway
RUN CGO_ENABLED=0 go build -o /app/inventory-service/inventory-bin /app/inventory-service


# --------------------------------------------------------------------------
# ETAPA 2: FINAL (Entorno de Ejecución Mínimo)
# Usamos una imagen base Alpine para el entorno de ejecución, la más pequeña posible.
# --------------------------------------------------------------------------
FROM alpine:3.18

ENV DEBIAN_FRONTEND=noninteractive

# --------------------------------------------------------------------------
# PASO ÚNICO: Instalar TODAS las dependencias de ejecución.
# Se instalan primero los paquetes de Python, bash y redis, 
# y luego se instalan los paquetes versionados de PostgreSQL que suelen estar en el repositorio 'community'.
# --------------------------------------------------------------------------
RUN apk update && apk add --no-cache \
    python3 py3-pip \
    supervisor \
    bash \
    redis

# Instalar PostgreSQL versionado y su cliente, ya que los nombres genéricos fallaron.
# El error indica que 'postgresql-server' no existe, por lo que usaremos la versión 15.
RUN apk add --no-cache \
    postgresql15-server \
    postgresql15-client \
    && rm -rf /var/cache/apk/*

############################################
# CONFIGURACIÓN DE USUARIOS Y DIRECTORIOS
############################################
# Crear el usuario 'postgres' que necesita el servidor de PostgreSQL
RUN adduser -D -h /home/postgres postgres

WORKDIR /app

RUN mkdir -p /app/logs \
    && chmod -R 777 /app/logs

# Inicializar el directorio de datos de PostgreSQL para asegurar permisos correctos
RUN mkdir -p /var/lib/postgresql/data \
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
