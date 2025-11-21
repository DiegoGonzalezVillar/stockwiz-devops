# Build stage
FROM python:3.11-slim as builder

WORKDIR /app

RUN apt-get update && apt-get install -y sqlite3

COPY requirements.txt .
RUN pip install --user -r requirements.txt

COPY main.py .
COPY init.sql .

RUN sqlite3 /app/micro.db < init.sql

# Final image
FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y sqlite3 curl

COPY --from=builder /app /app

ENV DB_PATH=/app/micro.db

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fsS http://localhost:8001/health || exit 1

EXPOSE 8001

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"]
