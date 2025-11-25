FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

############################################
# INSTALAR DEPENDENCIAS
############################################
RUN apt-get update && apt-get install -y \
    python3 python3-pip \
    redis-server \
    supervisor \
    curl git ca-certificates wget unzip \
    build-essential \
    golang-go \
    && rm -rf /var/lib/apt/lists/*

############################################
# INSTALAR POSTGRES OFICIAL DENTRO DEL CONTENEDOR
############################################
ADD https://github.com/docker-library/postgres/archive/master.zip /tmp/postgres.zip
RUN unzip /tmp/postgres.zip -d /tmp/ && \
    cp -r /tmp/postgres-master/15/* / && \
    rm -rf /tmp/postgres.zip /tmp/postgres-master

RUN mkdir -p /var/lib/postgresql/data && \
    chmod 700 /var/lib/postgresql/data && \
    chown -R root:root /var/lib/postgresql

############################################
# DIRECTORIO APP
############################################
WORKDIR /app

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start.sh /app/start.sh
COPY init.sql /docker-entrypoint-initdb.d/init.sql

COPY api-gateway/ /app/api-gateway/
COPY inventory-service/ /app/inventory-service/
COPY product-service/ /app/product-service/

RUN dos2unix /app/start.sh && chmod +x /app/start.sh

############################################
# COMPILAR GO SERVICES
############################################
RUN cd /app/api-gateway && go build -o api-gateway
RUN cd /app/inventory-service && go build -o inventory-service

############################################
# INSTALAR DEPENDENCIAS PRODUCT SERVICE
############################################
RUN pip3 install --no-cache-dir -r /app/product-service/requirements.txt

############################################
# EXPOSE SOLO API GATEWAY
############################################
EXPOSE 8000

############################################
# INICIO CON SUPERVISORD
############################################
CMD ["/app/start.sh"]
