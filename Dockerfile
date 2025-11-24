FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

############################
# 1) System dependencies
############################
RUN apt-get update && apt-get install -y \
    build-essential \
    ca-certificates \
    curl \
    wget \
    python3 python3-pip python3-venv \
    postgresql postgresql-contrib \
    redis-server \
    && rm -rf /var/lib/apt/lists/*

############################
# 2) Create app directory
############################
WORKDIR /app

############################
# 3) Copy API Gateway (Go)
############################
COPY api-gateway /app/api-gateway
WORKDIR /app/api-gateway
RUN go build -o api-gateway .

############################
# 4) Copy Product Service (Python)
############################
COPY product-service /app/product-service
WORKDIR /app/product-service
RUN pip3 install --no-cache-dir -r requirements.txt

############################
# 5) Copy Inventory Service (Go)
############################
COPY inventory-service /app/inventory-service
WORKDIR /app/inventory-service
RUN go build -o inventory-service .

############################
# 6) Back to /app
############################
WORKDIR /app

############################
# 7) Postgres init + Start script
############################
COPY start.sh /app/start.sh
COPY init.sql /app/init.sql
RUN chmod +x /app/start.sh

############################
# 8) Expose ports
############################
EXPOSE 8000 5432 6379

############################
# 9) Start application suite
############################
CMD ["/app/start.sh"]

