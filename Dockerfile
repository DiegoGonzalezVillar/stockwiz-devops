FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

############################################
# INSTALL DEPENDENCIES
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
# SETUP WORKDIR
############################################
WORKDIR /app

COPY start.sh /app/start.sh
COPY init.sql /app/init.sql
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY api-gateway/ /app/api-gateway/
COPY inventory-service/ /app/inventory-service/
COPY product-service/ /app/product-service/

RUN chmod +x /app/start.sh

############################################
# BUILD GO BINARIES
############################################
RUN cd /app/api-gateway && go build -o /app/api-gateway-bin
RUN cd /app/inventory-service && go build -o /app/inventory-service-bin

############################################
# INSTALL PYTHON DEPENDENCIES
############################################
RUN pip3 install --no-cache-dir -r /app/product-service/requirements.txt

############################################
# MOVE BINARIES TO SIMPLE PATHS
############################################
RUN mv /app/api-gateway-bin /app/api-gateway \
 && mv /app/inventory-service-bin /app/inventory-service

############################################
# RUN FULLSTACK
############################################
EXPOSE 8000

CMD ["/app/start.sh"]




