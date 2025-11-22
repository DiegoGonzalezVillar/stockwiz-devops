########################################
# IAM ROLE (LabRole)
########################################
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

########################################
# CLOUDWATCH LOG GROUPS
########################################

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

resource "aws_cloudwatch_log_group" "data" {
  name              = "/ecs/${var.environment}-data-service"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "product" {
  family                   = "${var.environment}-product-service"
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  execution_role_arn = data.aws_iam_role.lab_role.arn
  task_role_arn      = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    ###########################
    ## PRODUCT SERVICE
    ###########################
    {
      name      = "product-service"
      image     = var.product_image
      essential = true

      portMappings = [{
        containerPort = 8001
        protocol      = "tcp"
      }]

      environment = [
        { name = "DATABASE_URL", value = "postgresql://admin:admin123@postgres:5432/microservices_db" },
        { name = "REDIS_URL", value = "redis://redis:6379" }
      ]

      dependsOn = [
        { containerName = "postgres", condition = "START" },
        { containerName = "redis", condition = "START" }
      ]

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-region"        = var.aws_region,
          "awslogs-group"         = aws_cloudwatch_log_group.product.name,
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },

    ###########################
    ## POSTGRES SIN PERSISTENCIA
    ###########################
    {
      name      = "postgres"
      image     = "postgres:15"
      essential = false

      environment = [
        { name = "POSTGRES_USER", value = "admin" },
        { name = "POSTGRES_PASSWORD", value = "admin123" },
        { name = "POSTGRES_DB", value = "microservices_db" }
      ]

      portMappings = [{
        containerPort = 5432
      }]

      mountPoints = [{
        sourceVolume  = "tmp-data"
        containerPath = "/var/lib/postgresql/data"
      }]

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-region"        = var.aws_region,
          "awslogs-group"         = aws_cloudwatch_log_group.postgres.name,
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },

    ###########################
    ## REDIS SIN CONFIG EXTRA
    ###########################
    {
      name      = "redis"
      image     = "redis:7"
      essential = false

      portMappings = [{
        containerPort = 6379
      }]

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-region"        = var.aws_region,
          "awslogs-group"         = aws_cloudwatch_log_group.redis.name,
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  volume {
    name = "tmp-data"
  }
}

########################################
# ECS SERVICE – PRODUCT SERVICE
########################################

resource "aws_ecs_service" "product" {
  name            = "${var.environment}-product-service"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.product.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.public_subnets_ids
    security_groups = [var.ecs_sg_id]
    assign_public_ip = true
  }
}

########################################
# TASK DEFINITIONS – INVENTORY SERVICE
########################################

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
      { name = "DATABASE_URL", value = "postgresql://admin:admin123@dev-data-service.ecs-fargate-cluster-${var.environment}.local:5432/microservices_db" },
      { name = "REDIS_URL",    value = "redis://dev-data-service.ecs-fargate-cluster-${var.environment}.local:6379" }
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

########################################
# ECS SERVICE – INVENTORY SERVICE
########################################

resource "aws_ecs_service" "inventory" {
  name            = "${var.environment}-inventory-service"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.inventory.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.public_subnets_ids
    security_groups = [var.ecs_sg_id]
    assign_public_ip = true
  }
}

########################################
# TASK DEFINITIONS – API GATEWAY
########################################

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
      { name = "REDIS_URL",              value = "redis://dev-data-service.ecs-fargate-cluster-${var.environment}.local:6379" },
      { name = "PRODUCT_SERVICE_URL",    value = "http://dev-product-service.ecs-fargate-cluster-${var.environment}.local:8001" },
      { name = "INVENTORY_SERVICE_URL",  value = "http://dev-inventory-service.ecs-fargate-cluster-${var.environment}.local:8002" }
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

########################################
# ECS SERVICE – API GATEWAY (ALB)
########################################

resource "aws_ecs_service" "gateway" {
  name            = "${var.environment}-api-gateway"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.gateway.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.public_subnets_ids
    security_groups = [var.ecs_sg_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.gateway_tg_arn
    container_name   = "api-gateway"
    container_port   = 8000
  }
}
