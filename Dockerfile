############################################
# BASE: Ubuntu con herramientas necesarias
############################################
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

############################################
# Instalar dependencias del sistema
############################################
RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-venv \
    redis-server \
    postgresql postgresql-contrib \
    wget curl git ca-certificates build-essential \
    golang-go \
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
COPY api-gateway/ /app/api-gateway/

# Inventory Service
COPY inventory-service/ /app/inventory-service/

# Product Service
COPY product-service/ /app/product-service/

############################################
# COMPILAR GO SERVICES
############################################
RUN cd /app/api-gateway && \
    go mod download && \
    CGO_ENABLED=0 GOOS=linux go build -o /app/api-gateway/api-gateway .

RUN cd /app/inventory-service && \
    go mod download && \
    CGO_ENABLED=0 GOOS=linux go build -o /app/inventory-service/inventory-service .

############################################
# INSTALAR DEPENDENCIAS PYTHON (PRODUCT)
############################################
RUN pip3 install --no-cache-dir -r /app/product-service/requirements.txt

############################################
# CONFIG POSTGRES
############################################
RUN sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" \
    /etc/postgresql/14/main/postgresql.conf

############################################
# PERMISOS
############################################
RUN chmod +x /app/start.sh

############################################
# EXPOSE API Gateway
############################################
EXPOSE 8000

############################################
# START
############################################
CMD ["/app/start.sh"]

