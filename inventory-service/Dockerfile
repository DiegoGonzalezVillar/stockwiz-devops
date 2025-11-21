# ============================
# STAGE 1 — Build binary + DB
# ============================
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Instalar dependencias necesarias para compilar go-sqlite3
RUN apk add --no-cache git ca-certificates build-base sqlite-dev

COPY go.mod go.sum ./
RUN go mod download

COPY main.go .
COPY init.sql .

# Compilar binario con CGO habilitado
RUN CGO_ENABLED=1 GOOS=linux go build -o inventory-service .

# Crear base SQLite
RUN sqlite3 /app/micro.db < init.sql


# ============================
# STAGE 2 — Final minimal image
# ============================
FROM alpine:3.18

WORKDIR /app

# Instalar sqlite + herramientas básicas
RUN apk add --no-cache sqlite curl ca-certificates

# Copiar binario y DB
COPY --from=builder /app/inventory-service /app/
COPY --from=builder /app/micro.db /app/

# Crear usuario no root
RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser && \
    chown -R appuser:appuser /app

USER appuser

ENV DB_PATH=/app/micro.db

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD curl -fsS http://localhost:8002/health || exit 1

EXPOSE 8002

CMD ["./inventory-service"]
