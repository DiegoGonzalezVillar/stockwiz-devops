data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

resource "aws_ecs_cluster" "cluster" {
  name = "ecs-fargate-cluster-${var.env}"
}

# -------------------------------------------------
# TASK DEFINITIONS (3 microservices + postgres + redis optional)
# -------------------------------------------------

# API GATEWAY
resource "aws_ecs_task_definition" "api" {
  count = var.enabled ? 1 : 0

  family                   = "api-${var.env}"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"

  execution_role_arn = data.aws_iam_role.lab_role.arn
  task_role_arn      = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name  = "api_gateway"
      image = var.api_image
      portMappings = [{ containerPort = 8000 }]
    },
    {
      name  = "postgres"
      image = var.postgres_image
      portMappings = [{ containerPort = 5432 }]
    },
    {
      name  = "redis"
      image = "redis:7-alpine"
      portMappings = [{ containerPort = 6379 }]
    }
  ])
}

# PRODUCT SERVICE
resource "aws_ecs_task_definition" "product" {
  count = var.enabled ? 1 : 0

  family                   = "product-${var.env}"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"

  execution_role_arn = data.aws_iam_role.lab_role.arn
  task_role_arn      = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name  = "product_service"
      image = var.product_image
      portMappings = [{ containerPort = 8001 }]
    }
  ])
}

# INVENTORY SERVICE
resource "aws_ecs_task_definition" "inventory" {
  count = var.enabled ? 1 : 0

  family                   = "inventory-${var.env}"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"

  execution_role_arn = data.aws_iam_role.lab_role.arn
  task_role_arn      = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name  = "inventory_service"
      image = var.inventory_image
      portMappings = [{ containerPort = 8002 }]
    }
  ])
}

# -------------------------------------------------
# SERVICES
# -------------------------------------------------

resource "aws_ecs_service" "api" {
  count = var.enabled ? 1 : 0

  name            = "${var.env}-api-gateway-svc"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.api[0].arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.public_subnets
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "api_gateway"
    container_port   = 8000
  }
}

resource "aws_ecs_service" "product" {
  count = var.enabled ? 1 : 0

  name            = "${var.env}-product-service-svc"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.product[0].arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.public_subnets
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = true
  }
}

resource "aws_ecs_service" "inventory" {
  count = var.enabled ? 1 : 0

  name            = "${var.env}-inventory-service-svc"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.inventory[0].arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.public_subnets
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = true
  }
}
