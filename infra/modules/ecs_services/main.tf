
##############################################
# IAM ROLE: LabRole 
##############################################
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

##############################################
# LOG GROUPS (uno por servicio)
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

### API GATEWAY ###
resource "aws_ecs_task_definition" "gateway" {
  family                   = "${var.environment}-api-gateway"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"

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
          hostPort      = 8000
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

### PRODUCT SERVICE ###
resource "aws_ecs_task_definition" "product" {
  family                   = "${var.environment}-product-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = data.aws_iam_role.lab_role.arn
  task_role_arn      = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name      = "product-service"
      image     = var.product_image
      essential = true

      portMappings = [
        {
          containerPort = 8001
          hostPort      = 8001
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

### INVENTORY ###
resource "aws_ecs_task_definition" "inventory" {
  family                   = "${var.environment}-inventory-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = data.aws_iam_role.lab_role.arn
  task_role_arn      = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name      = "inventory-service"
      image     = var.inventory_image
      essential = true

      portMappings = [
        {
          containerPort = 8002
          hostPort      = 8002
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

##############################################
# SERVICES
##############################################

### API GATEWAY (expuesto por ALB)
resource "aws_ecs_service" "gateway" {
  name            = "${var.environment}-api-gateway-svc"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.gateway.arn
  desired_count   = var.gateway_desired_count
  launch_type     = "EC2"

  network_configuration {
    subnets         = var.public_subnets_ids       # 🔥 CAMBIO
    security_groups = [var.ecs_sg_id]
    assign_public_ip = true                        # 🔥 CAMBIO
  }

  load_balancer {
    target_group_arn = var.gateway_tg_arn
    container_name   = "api-gateway"
    container_port   = 8000
  }

  health_check_grace_period_seconds = 30

  lifecycle {
    ignore_changes = [task_definition]
  }
}


resource "aws_ecs_service" "product" {
  name            = "${var.environment}-product-service-svc"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.product.arn
  desired_count   = var.product_desired_count
  launch_type     = "EC2"

  network_configuration {
    subnets         = var.public_subnets_ids        # 🔥 CAMBIO
    security_groups = [var.ecs_sg_id]
    assign_public_ip = true                         # 🔥 CAMBIO
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}


resource "aws_ecs_service" "inventory" {
  name            = "${var.environment}-inventory-service-svc"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.inventory.arn
  desired_count   = var.inventory_desired_count
  launch_type     = "EC2"

  network_configuration {
    subnets         = var.public_subnets_ids        # 🔥 CAMBIO
    security_groups = [var.ecs_sg_id]
    assign_public_ip = true                         # 🔥 CAMBIO
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

