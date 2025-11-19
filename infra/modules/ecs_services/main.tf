
# Rol del laboratorio
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# Task Definition - api-gateway

resource "aws_ecs_task_definition" "gateway" {
  family                   = "${var.environment}-api-gateway"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = data.aws_iam_role.lab_role.arn

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
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Environment = var.environment
  }
}

# Service - api-gateway (con ALB)

resource "aws_ecs_service" "gateway" {
  name            = "${var.environment}-api-gateway-svc"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.gateway.arn
  desired_count   = var.gateway_desired_count
  launch_type     = "EC2"

  network_configuration {
    subnets          = var.private_subnets_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
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

  tags = {
    Environment = var.environment
  }
}

# Task Definition - product-service

resource "aws_ecs_task_definition" "product" {
  family                   = "${var.environment}-product-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = data.aws_iam_role.lab_role.arn

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
    }
  ])

  tags = {
    Environment = var.environment
  }
}



# Service - product-service (sin ALB, interno)

resource "aws_ecs_service" "product" {
  name            = "${var.environment}-product-service-svc"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.product.arn
  desired_count   = var.product_desired_count
  launch_type     = "EC2"

  network_configuration {
    subnets          = var.private_subnets_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  tags = {
    Environment = var.environment
  }
}

# Task Definition - inventory-service

resource "aws_ecs_task_definition" "inventory" {
  family                   = "${var.environment}-inventory-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"

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
    }
  ])

  tags = {
    Environment = var.environment
  }
}

# Service - inventory-service (interno)

resource "aws_ecs_service" "inventory" {
  name            = "${var.environment}-inventory-service-svc"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.inventory.arn
  desired_count   = var.inventory_desired_count
  launch_type     = "EC2"

  network_configuration {
    subnets          = var.private_subnets_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  tags = {
    Environment = var.environment
  }
}
