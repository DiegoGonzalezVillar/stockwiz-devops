FROM ubuntu:22.04

#########################
# System dependencies
#########################
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    wget \
    ca-certificates \
    python3 \
    python3-pip \
    python3-venv \
    postgresql \
    postgresql-contrib \
    redis-server \
    && rm -rf /var/lib/apt/lists/*

#########################
# COPY APPLICATION CODE
#########################
WORKDIR /app

# API Gateway (Go)
COPY api-gateway /app/api-gateway
WORKDIR /app/api-gateway
RUN go build -o api-gateway .

# Product service (Python)
WORKDIR /app/product-service
COPY product-service /app/product-service
RUN pip3 install -r requirements.txt

# Inventory service (Go)
WORKDIR /app/inventory-service
COPY inventory-service /app/inventory-service
RUN go build -o inventory-service .

# Postgres initialization SQL
WORKDIR /app
COPY postgres-custom/init.sql /app/init.sql

#########################
# STARTUP SCRIPT
#########################
COPY docker-full/start.sh /app/start.sh
RUN chmod +x /app/start.sh

#########################
# EXPOSE PORTS
#########################
EXPOSE 8000 5432 6379

CMD ["/app/start.sh"]
