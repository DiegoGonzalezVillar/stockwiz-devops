###########################################
# STAGE 1 — API GATEWAY (Go)
###########################################
FROM golang:1.21-alpine AS build_api

WORKDIR /app
COPY api-gateway/go.mod api-gateway/go.sum ./
RUN apk add --no-cache git ca-certificates
RUN go mod download

COPY api-gateway/ .
RUN CGO_ENABLED=0 GOOS=linux go build -o api-gateway .


###########################################
# STAGE 2 — INVENTORY SERVICE (Go)
###########################################
FROM golang:1.21-alpine AS build_inventory

WORKDIR /app
COPY inventory-service/go.mod inventory-service/go.sum ./
RUN apk add --no-cache git ca-certificates
RUN go mod download

COPY inventory-service/ .
RUN CGO_ENABLED=0 GOOS=linux go build -o inventory-service .


###########################################
# STAGE 3 — PRODUCT SERVICE (Python)
###########################################
FROM python:3.11-slim AS build_product

WORKDIR /app
COPY product-service/requirements.txt .
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc libpq-dev && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir --user -r requirements.txt
COPY product-service/ .


###########################################
# STAGE 4 — FINAL IMAGE (Ubuntu + Postgres + Redis)
###########################################
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system services
RUN apt-get update && apt-get install -y \
    ca-certificates \
    python3 python3-pip python3-venv \
    postgresql postgresql-contrib \
    redis-server \
    wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

###########################################
# COPY BINARIES FROM BUILDS
###########################################
COPY --from=build_api       /app/api-gateway         /app/api-gateway
COPY --from=build_inventory /app/inventory-service   /app/inventory-service

###########################################
# COPY PYTHON APP FROM BUILD
###########################################
COPY --from=build_product /root/.local /home/appuser/.local
COPY product-service/ /app/product-service

ENV PATH="/home/appuser/.local/bin:${PATH}"

###########################################
# COPY START SCRIPTS + SQL INIT
###########################################
COPY start.sh /app/start.sh
COPY init.sql /app/init.sql
RUN chmod +x /app/start.sh

###########################################
# EXPOSE PORTS
###########################################
EXPOSE 8000 8001 8002 5432 6379

CMD ["/app/start.sh"]

CMD ["/app/start.sh"]


