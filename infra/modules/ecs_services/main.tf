
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

# TASK DEFINITIONS (FARGATE)

# API Gateway
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
      name      = "api-gateway"
      image     = var.gateway_image
      essential = true

      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-region"        = var.aws_region
          "awslogs-group"         = aws_cloudwatch_log_group.gateway.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# PRODUCT
resource "aws_ecs_task_definition" "product" {
  family                   = "${var.environment}-product-service"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  execution_role_arn = data.aws_iam_role.lab_role.arn
  task_role_arn      = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name  = "product-service"
      image = var.product_image

      portMappings = [
        {
          containerPort = 8001
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-region"        = var.aws_region
          "awslogs-group"         = aws_cloudwatch_log_group.product.name
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

  container_definitions = jsonencode([
    {
      name  = "inventory-service"
      image = var.inventory_image

      portMappings = [
        {
          containerPort = 8002
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-region"        = var.aws_region
          "awslogs-group"         = aws_cloudwatch_log_group.inventory.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
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
    assign_public_ip = true
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
    assign_public_ip = true
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
    assign_public_ip = true
  }
}

