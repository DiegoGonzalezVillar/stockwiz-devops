##############################################
# IAM ROLE (LabRole)
##############################################
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

##############################################
# CLOUD MAP NAMESPACE (REQUIERE LabRole OK)
##############################################

resource "aws_service_discovery_http_namespace" "services" {
  name        = "${var.environment}.local"
  description = "Service discovery namespace"
}

##############################################
# LOG GROUPS
##############################################

resource "aws_cloudwatch_log_group" "gateway" {
  name              = "/ecs/${var.environment}-api-gateway"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "product" {
  name              = "/ecs/${var.environment}-product-service"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "inventory" {
  name              = "/ecs/${var.environment}-inventory-service"
  retention_in_days = 7
}

##############################################
# TASK DEFINITIONS
##############################################

### DBCACHE – Postgres + Redis
resource "aws_ecs_task_definition" "dbcache" {
  family                   = "${var.environment}-dbcache"
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  execution_role_arn = data.aws_iam_role.lab_role.arn
  task_role_arn      = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name  = "postgres"
      image = "postgres:15-alpine"
      essential = true
      environment = [
        { name = "POSTGRES_USER",     value = "admin" },
        { name = "POSTGRES_PASSWORD", value = "admin123" },
        { name = "POSTGRES_DB",       value = "microservices_db" }
      ]
      portMappings = [{ containerPort = 5432 }]
    },
    {
      name  = "redis"
      image = "redis:7-alpine"
      essential = true
      portMappings = [{ containerPort = 6379 }]
    }
  ])
}

resource "aws_ecs_service" "dbcache" {
  name            = "${var.environment}-dbcache"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.dbcache.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnets_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_http_namespace.services.arn
    port         = 5432
  }
}

##############################################
# GATEWAY – ALB Público
##############################################

resource "aws_ecs_task_definition" "gateway" {
  family                   = "${var.environment}-api-gateway"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  execution_role_arn = data.aws_iam_role.lab_role.arn
  task_role_arn      = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name  = "api-gateway"
      image = var.gateway_image
      essential = true
      portMappings = [{ containerPort = 8000 }]

      environment = [
        { name = "PRODUCT_SERVICE_URL",   value = "http://product.${var.environment}.local:8001" },
        { name = "INVENTORY_SERVICE_URL", value = "http://inventory.${var.environment}.local:8002" },
        { name = "REDIS_URL",             value = "redis://dbcache.${var.environment}.local:6379" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.gateway.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "gateway" {
  name            = "${var.environment}-api-gateway-svc"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.gateway.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.public_subnets_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.gateway_tg_arn
    container_name   = "api-gateway"
    container_port   = 8000
  }
}

##############################################
# PRODUCT SERVICE – Cloud Map
##############################################

resource "aws_ecs_task_definition" "product" {
  family                   = "${var.environment}-product-service"
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  execution_role_arn = data.aws_iam_role.lab_role.arn
  task_role_arn      = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name  = "product"
      image = var.product_image
      essential = true
      portMappings = [{ containerPort = 8001 }]

      environment = [
        { name = "DATABASE_URL", value = "postgresql://admin:admin123@dbcache.${var.environment}.local:5432/microservices_db" },
        { name = "REDIS_URL",     value = "redis://dbcache.${var.environment}.local:6379" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.product.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "product" {
  name            = "${var.environment}-product-service"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.product.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnets_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_http_namespace.services.arn
    port         = 8001
  }
}

##############################################
# INVENTORY SERVICE – Cloud Map
##############################################

resource "aws_ecs_task_definition" "inventory" {
  family                   = "${var.environment}-inventory-service"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  execution_role_arn = data.aws_iam_role.lab_role.arn
  task_role_arn      = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name  = "inventory"
      image = var.inventory_image
      essential = true
      portMappings = [{ containerPort = 8002 }]

      environment = [
        { name = "DATABASE_URL", value = "postgresql://admin:admin123@dbcache.${var.environment}.local:5432/microservices_db" },
        { name = "REDIS_URL",     value = "redis://dbcache.${var.environment}.local:6379" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.inventory.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "inventory" {
  name            = "${var.environment}-inventory-service"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.inventory.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnets_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_http_namespace.services.arn
    port         = 8002
  }
}
