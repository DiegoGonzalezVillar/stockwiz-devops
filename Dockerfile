###############################
# BASE: Ubuntu + PostgreSQL + Redis + Python + Go
###############################
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

###############################
# 1) Instalar dependencias base
###############################
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    ca-certificates \
    python3 \
    python3-pip \
    postgresql \
    postgresql-contrib \
    redis-server \
    golang \
    && rm -rf /var/lib/apt/lists/*

###############################
# 2) Crear usuario postgres (si no existe)
###############################
RUN useradd -m postgres || true

###############################
# 3) Crear estructura de trabajo
###############################
WORKDIR /app

###############################
# 4) Copiar API Gateway (Go)
###############################
COPY api-gateway/ ./api-gateway/

WORKDIR /app/api-gateway
RUN go build -o api-gateway .

###############################
# 5) Copiar Inventory Service (Go)
###############################
WORKDIR /app/inventory-service
COPY inventory-service/ .
RUN go build -o inventory-service .

###############################
# 6) Copiar Product Service (Python)
###############################
WORKDIR /app/product-service
COPY product-service/ .
RUN pip install --no-cache-dir -r requirements.txt

###############################
# 7) Copiar SQL + Start script
###############################
WORKDIR /app
COPY docker-full/init.sql /app/init.sql
COPY docker-full/start.sh /app/start.sh

RUN chmod +x /app/start.sh

###############################
# 8) Exponer puerto de API Gateway
###############################
EXPOSE 8000

###############################
# 9) Entry point
###############################
CMD ["/app/start.sh"]
