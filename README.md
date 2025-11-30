# 📘 StockWiz-DevOps

Este documento resume la estructura del proyecto **StockWiz**, la estrategia de versionado, arquitectura de infraestructura, pipeline CI/CD, testing automatizado y observabilidad.

---

# 🗂️ 1. Estado Inicial del Tablero (Trello)

Se definió un tablero Kanban inicial con las columnas:

- **To Do**
- **In Progress**
- **Done**

Se cargaron tareas agrupadas por áreas del proyecto:

- CI/CD
- Containerización
- Infraestructura (IaC)
- Testing
- Observabilidad
- Documentación

Todas las tareas comenzaron en **To Do**, marcando el punto de partida del proyecto.

---

# 🔀 2. Estrategia de Control de Versiones (Git)

### 📌 Repositorio

`stockwiz-devops` (GitHub)

### 📌 Flujo Adoptado

**Git Flow simplificado**

---

## 🔹 Estructura de Ramas

- **main** – Rama estable (producción)
- **develop** – Rama de integración
- **feature/\*** – Desarrollo de funcionalidades

---

## 🔹 Justificación del Flujo

- Claridad en el ciclo de vida del código
- Facilita revisiones limpias
- Escalable para equipos de cualquier tamaño
- Control seguro sobre despliegues

---

## 🔹 Políticas Definidas

- **Conventional Commits**
- Sin merges directos a `main`
- Checks obligatorios en CI/CD
- Se genera merge a `main` mediante pipeline con deploy a producción exitoso.

---

# 🧪 2.1 Análisis de Código Estático (golangci-lint)

Este proyecto utiliza **golangci-lint**, la suite más popular para análisis estático en Go, asegurando calidad, seguridad y limpieza del código.

### 🚀 ¿Qué valida?

Incluye más de 70 linters, entre ellos:

- **errcheck** → Verifica que todos los errores sean manejados
- **typecheck** → Revisa tipos inválidos y compila estáticamente
- **govet** → Detecta patrones sospechosos
- **gosimple** → Simplifica código innecesariamente complejo
- **staticcheck** → Detecta bugs potenciales
- **unused** → Variables y funciones no utilizadas

---

# 🏗️ 3. Arquitectura General del Proyecto

El contenedor _fullstack_ incluye:

- API Gateway (Go)
- Product Service (FastAPI)
- Inventory Service (Go)
- PostgreSQL interno
- Redis interno
- Supervisor para orquestación interna de procesos

---

# 🌐 4. Topología AWS

```
VPC
 ├── Public Subnets (ALB, NAT)
 ├── Private Subnets (ECS Fargulate)
 └── Internet Gateway
```

---

# 🧱 5. Infraestructura con Terraform

Módulos principales:

- **network** – VPC, subnets, routing
- **alb** – Load Balancer
- **ecs** – Servicios + Tasks Fargate
- **ecr** – Repositorios de imágenes
- **monitoring** – CloudWatch + alarmas
- **notifier** – SNS + Lambda
- **secrets** – AWS Secrets Manager

---

# 🐳 6. Contenedor Fullstack (Docker)

El Dockerfile:

- Construye servicios Go
- Instala Python y dependencias
- Configura PostgreSQL 14
- Configura Redis
- Configura Supervisor
- Expone el puerto **8000**

El sistema completo se inicia desde:

```
/app/start.sh
```

La imagen final se publica en ECR.

---

# 🔄 7. Pipeline CI/CD (GitHub Actions)

## **1️⃣ Despliegue a DEV**

- Terraform init + apply (infra base)
- Build & push de la imagen
- Aplicación de la imagen final
- Forzar nuevo despliegue ECS
- Obtener DNS del ALB

---

## **2️⃣ Testing Funcional (TEST)**

- Terraform init + creación temporal de infraestructura
- Pruebas automatizadas con **Newman**
- Reporte en formato XML
- Destrucción del entorno TEST

### **Endpoints probados:**

| Método | Endpoint             | Descripción             |
| ------ | -------------------- | ----------------------- |
| GET    | `/health`            | Healthcheck del gateway |
| POST   | `/api/products`      | Crear producto          |
| GET    | `/api/products/{id}` | Obtener producto        |
| PUT    | `/api/products/{id}` | Actualizar producto     |
| DELETE | `/api/products/{id}` | Eliminar producto       |

---

## **3️⃣ Despliegue a PROD**

- Terraform init + apply
- Uso de la imagen aprobada por TEST
- Actualización del servicio ECS de producción
- Disparo automático de notificación vía Lambda + SNS

---

# 📊 8. Resumen del Flujo CI/CD

| Entorno  | Acción            | Resultado                       |
| -------- | ----------------- | ------------------------------- |
| **DEV**  | Build + Deploy    | Imagen `dev-latest`             |
| **TEST** | Testing funcional | Validación completa             |
| **PROD** | Deploy final      | Imagen productiva `prod-latest` |

---

# 📈 9. Observabilidad

Incluye:

- Dashboard centralizado en CloudWatch
- Logs por servicio ECS
- Alarmas de CPU/Memory
- Alarmas de errores en ALB
- Notificaciones SNS + Lambda para alertas críticas y despliegues

---

# 🧩 10. Estructura del Proyecto

```
.
|-- api-gateway/
|-- inventory-service/
|-- product-service/
|-- infra/
|   |-- backend-config/
|   |-- env/
|   |-- modules/
|   |   |-- alb/
|   |   |-- ecs/
|   |   |-- ecr/
|   |   |-- monitoring/
|   |   |-- network/
|   |   |-- notifier/
|   |   |-- secrets/
|-- tests/
|   |-- stockwiz_api_collection.json
|-- Dockerfile
|-- start.sh
|-- init.sql
|-- supervisord.conf
|-- .github/workflows/deploy.yml
```

---

# ✅ 11. Estado Final del Proyecto

✔ Infraestructura totalmente automatizada  
✔ Pipeline CI/CD completo y funcional  
✔ Testing funcional implementado  
✔ Contenedores orquestados en ECS Fargate  
✔ Observabilidad centralizada  
✔ Notificaciones automáticas de despliegue  
✔ Arquitectura escalable y lista para producción

---

© **StockWiz 2025**
