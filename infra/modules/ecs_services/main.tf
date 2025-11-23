###########################################
# IAM ROLE (LabRole del laboratorio)
###########################################

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

###########################################
# CLOUDWATCH LOG GROUPS
###########################################

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

resource "aws_cloudwatch_log_group" "dbcache" {
  name              = "/ecs/${var.environment}-dbcache"
  retention_in_days = 7
}

###########################################
# ECS TASK DEFINITIONS
###########################################

# ----------- DBCACHE (POSTGRES + REDIS) -----------
resource "aws_ecs_task_definition" "dbcache" {
  family                   = "dbcache-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"

  execution_role_arn = data.aws_iam_role.lab_role.arn
  task_role_arn      = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name      = "postgres",
      image     = "postgres:15-alpine",
      essential = true,
      environment = [
        { name = "POSTGRES_USER",     value = "admin" },
        { name = "POSTGRES_PASSWORD", value = "admin123" },
        { name = "POSTGRES_DB",       value = "microservices_db" }
      ],
      portMappings = [{ containerPort = 5432 }]
    },
    {
      name         = "redis",
      image        = "redis:7-alpine",
      essential    = true,
      portMappings = [{ containerPort = 6379 }]
    }
  ])
}

# ----------- API GATEWAY -----------
resource "aws_ecs_task_definition" "gateway" {
  family                   = "${var.environment}-api-gateway"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  execution_role_arn = data.aws_iam_role.lab_role.arn
  task_role_arn      = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name      = "api-gateway",
    image     = var.gateway_image,
    essential = true,

    portMappings = [{
      containerPort = 8000,
      protocol      = "tcp"
    }],

    environment = [
      { name = "PRODUCT_SERVICE_URL",   value = "http://${var.dns_product}:8001" },
      { name = "INVENTORY_SERVICE_URL", value = "http://${var.dns_inventory}:8002" },
      { name = "REDIS_URL",             value = "redis://${var.dns_dbcache}:6379" }
    ],

    logConfiguration = {
      logDriver = "awslogs",
      options = {
        "awslogs-region"        = var.aws_region,
        "awslogs-group"         = aws_cloudwatch_log_group.gateway.name,
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# ----------- PRODUCT SERVICE -----------
resource "aws_ecs_task_definition" "product" {
  family                   = "${var.environment}-product-service"
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  execution_role_arn = data.aws_iam_role.lab_role.arn
  task_role_arn      = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name      = "product-service",
    image     = var.product_image,
    essential = true,

    portMappings = [{
      containerPort = 8001,
      protocol      = "tcp"
    }],

    environment = [
      { name = "DATABASE_URL", value = "postgresql://admin:admin123@${var.dns_dbcache}:5432/microservices_db" },
      { name = "REDIS_URL",    value = "redis://${var.dns_dbcache}:6379" }
    ],

    logConfiguration = {
      logDriver = "awslogs",
      options = {
        "awslogs-region"        = var.aws_region,
        "awslogs-group"         = aws_cloudwatch_log_group.product.name,
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# ----------- INVENTORY SERVICE -----------
resource "aws_ecs_task_definition" "inventory" {
  family                   = "${var.environment}-inventory-service"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  execution_role_arn = data.aws_iam_role.lab_role.arn
  task_role_arn      = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name      = "inventory-service",
    image     = var.inventory_image,
    essential = true,

    portMappings = [{
      containerPort = 8002,
      protocol      = "tcp"
    }],

    environment = [
      { name = "DATABASE_URL", value = "postgresql://admin:admin123@${var.dns_dbcache}:5432/microservices_db" },
      { name = "REDIS_URL",    value = "redis://${var.dns_dbcache}:6379" }
    ],

    logConfiguration = {
      logDriver = "awslogs",
      options = {
        "awslogs-region"        = var.aws_region,
        "awslogs-group"         = aws_cloudwatch_log_group.inventory.name,
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

###########################################
# ECS SERVICES (FARGATE)
###########################################

# ----------- GATEWAY (PÚBLICO) -----------
resource "aws_ecs_service" "gateway" {
  name            = "${var.environment}-api-gateway-svc"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.gateway.arn
  launch_type     = "FARGATE"
  desired_count   = 1

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

# ----------- PRODUCT (INTERNO) -----------
resource "aws_ecs_service" "product" {
  name            = "${var.environment}-product-service-svc"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.product.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = var.private_subnets_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.tg_product_arn
    container_name   = "product-service"
    container_port   = 8001
  }
}

# ----------- INVENTORY (INTERNO) -----------
resource "aws_ecs_service" "inventory" {
  name            = "${var.environment}-inventory-service-svc"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.inventory.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = var.private_subnets_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.tg_inventory_arn
    container_name   = "inventory-service"
    container_port   = 8002
  }
}

# ----------- DBCACHE (INTERNO) -----------
resource "aws_ecs_service" "dbcache" {
  name            = "dbcache"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.dbcache.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = var.private_subnets_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.tg_dbcache_arn
    container_name   = "postgres"
    container_port   = 5432
  }
}
