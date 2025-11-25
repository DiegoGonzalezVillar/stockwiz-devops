############################################
# BASE: Ubuntu con herramientas necesarias
############################################
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

############################################
# Actualizar e instalar dependencias
############################################
RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-venv \
    redis-server \
    postgresql postgresql-contrib \
    wget curl git build-essential ca-certificates \
    && rm -rf /var/lib/apt/lists/*

############################################
# DIRECTORIO APP
############################################
WORKDIR /app

############################################
# COPIAR ARCHIVOS DEL PROYECTO
############################################
COPY start.sh /app/start.sh
COPY init.sql /app/init.sql

# API Gateway
RUN mkdir -p /app/api-gateway
COPY api-gateway/ /app/api-gateway/

# Inventory Service
RUN mkdir -p /app/inventory-service
COPY inventory-service/ /app/inventory-service/

# Product Service
RUN mkdir -p /app/product-service
COPY product-service/ /app/product-service/

############################################
# COMPILAR SERVICIOS (Go + Python)
############################################

### API Gateway (Go)
RUN cd /app/api-gateway && \
    go mod download && \
    CGO_ENABLED=0 GOOS=linux go build -o /app/api-gateway/api-gateway .

### Inventory Service (Go)
RUN cd /app/inventory-service && \
    go mod download && \
    CGO_ENABLED=0 GOOS=linux go build -o /app/inventory-service/inventory-service .

### Product Service (Python)
RUN pip install --no-cache-dir -r /app/product-service/requirements.txt

############################################
# PostgreSQL CONFIG
############################################
RUN sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" \
    /etc/postgresql/14/main/postgresql.conf

############################################
# FIX PERMISOS + PERMISOS DE EJECUCIÓN
############################################
RUN chmod +x /app/start.sh

############################################
# EXPONER SOLO PUERTO 8000 (API Gateway)
############################################
EXPOSE 8000

############################################
# COMANDO DE INICIO
############################################
CMD ["/app/start.sh"]


