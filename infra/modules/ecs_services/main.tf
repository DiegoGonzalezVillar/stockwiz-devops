
# IAM ROLE (LabRole del laboratorio)
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# Log Groups

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

# resource "aws_cloudwatch_log_group" "postgres" {
#   name              = "/ecs/${var.environment}-product-postgres"
#   retention_in_days = 3
# }

# resource "aws_cloudwatch_log_group" "redis" {
#   name              = "/ecs/${var.environment}-product-redis"
#   retention_in_days = 3
# }

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
}

resource "aws_service_discovery_private_dns_namespace" "internal" {
  name        = "internal"
  description = "Private namespace"
  vpc         = vpc.vpc_id
}

# TASK DEFINITIONS (FARGATE)

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
      name      = "postgres"
      image     = "postgres:15-alpine"
      essential = true
      environment = [
        { name = "POSTGRES_USER", value = "admin" },
        { name = "POSTGRES_PASSWORD", value = "admin123" },
        { name = "POSTGRES_DB", value = "microservices_db" }
      ]
      portMappings = [{ containerPort = 5432 }]
    },
    {
      name         = "redis"
      image        = "redis:7-alpine"
      essential    = true
      portMappings = [{ containerPort = 6379 }]
    }
  ])
}

resource "aws_ecs_service" "dbcache" {
  name            = "dbcache-service"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.dbcache.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.public_subnets_ids
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.dbcache.arn
  }
}

resource "aws_service_discovery_service" "dbcache" {
  name = "postgres-redis"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id
    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}


# API Gateway
resource "aws_ecs_task_definition" "gateway" {
  family                   = "${var.environment}-api-gateway"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  execution_role_arn = data.aws_iam_role.lab_role.arn
  task_role_arn      = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name      = "api-gateway"
    image     = var.gateway_image
    essential = true

    portMappings = [{
      containerPort = 8000
      protocol      = "tcp"
    }]

    environment = [
      { name = "PRODUCT_SERVICE_URL", value = "http://product.internal:8001" },
      { name = "INVENTORY_SERVICE_URL", value = "http://inventory.internal:8002" },
      { name = "REDIS_URL", value = "redis://postgres-redis.internal:6379" }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-region"        = var.aws_region
        "awslogs-group"         = aws_cloudwatch_log_group.gateway.name
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# PRODUCT
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
      name      = "product-service"
      image     = var.product_image
      essential = true

      portMappings = [{
        containerPort = 8001
        protocol      = "tcp"
      }]

      environment = [
        { name = "DATABASE_URL", value = "postgresql://admin:admin123@postgres-redis.internal:5432/microservices_db" },
        { name = "REDIS_URL", value = "redis://postgres-redis.internal:6379" }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-region"        = var.aws_region,
          "awslogs-group"         = aws_cloudwatch_log_group.product.name,
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}


# INVENTORY
resource "aws_ecs_task_definition" "inventory" {
  family                   = "${var.environment}-inventory-service"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  execution_role_arn = data.aws_iam_role.lab_role.arn
  task_role_arn      = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name      = "inventory-service"
    image     = var.inventory_image
    essential = true

    portMappings = [{
      containerPort = 8002
      protocol      = "tcp"
    }]

    environment = [
      { name = "DATABASE_URL", value = "postgresql://admin:admin123@postgres-redis.internal:5432/microservices_db" },
      { name = "REDIS_URL", value = "redis://postgres-redis.internal:6379" }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-region"        = var.aws_region
        "awslogs-group"         = aws_cloudwatch_log_group.inventory.name
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# ECS SERVICES — FARGATE

resource "aws_ecs_service" "gateway" {
  name            = "${var.environment}-api-gateway-svc"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.gateway.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = var.public_subnets_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.gateway_tg_arn
    container_name   = "api-gateway"
    container_port   = 8000
  }
}

resource "aws_ecs_service" "product" {
  name            = "${var.environment}-product-service-svc"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.product.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = var.public_subnets_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }
}

resource "aws_ecs_service" "inventory" {
  name            = "${var.environment}-inventory-service-svc"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.inventory.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = var.public_subnets_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }
}
