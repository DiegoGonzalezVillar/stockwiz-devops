FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

############################################
# INSTALL SYSTEM DEPENDENCIES
############################################
RUN apt-get update && apt-get install -y \
    python3 python3-pip \
    redis-server \
    supervisor \
    curl git ca-certificates wget \
    build-essential \
    golang-go \
    postgresql-14 postgresql-client-14 postgresql-contrib-14 \
    && rm -rf /var/lib/apt/lists/*

############################################
# CREATE APP DIRS
############################################
WORKDIR /app

RUN mkdir -p /app/logs \
    && chmod -R 777 /app/logs

############################################
# COPY FILES
############################################
COPY start.sh /app/start.sh
COPY init.sql /app/init.sql
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy microservices
COPY api-gateway/ /app/api-gateway/
COPY inventory-service/ /app/inventory-service/
COPY product-service/ /app/product-service/

RUN chmod +x /app/start.sh

############################################
# BUILD GO BINARIES
############################################
RUN cd /app/api-gateway && go build -o /app/api-gateway
RUN cd /app/inventory-service && go build -o /app/inventory-service

############################################
# INSTALL PYTHON DEPENDENCIES
############################################
RUN pip3 install --no-cache-dir -r /app/product-service/requirements.txt

############################################
# EXPOSE ONLY API PORT
############################################
EXPOSE 8000

############################################
# ENTRYPOINT VIA SUPERVISOR
############################################
CMD ["/app/start.sh"]





