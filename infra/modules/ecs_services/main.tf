##############################################
# IAM ROLE (LabRole)
##############################################
data "aws_iam_role" "lab_role" {
  name = "LabRole"
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

### DBCACHE
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
      name  = "postgres"
      image = "postgres:15-alpine"
      essential = true
      environment = [
        { name = "POSTGRES_USER", value = "admin" },
        { name = "POSTGRES_PASSWORD", value = "admin123" },
        { name = "POSTGRES_DB", value = "microservices_db" }
      ]
      portMappings = [{
        containerPort = 5432
      }]
    },
    {
      name  = "redis"
      image = "redis:7-alpine"
      essential = true
      portMappings = [{
        containerPort = 6379
      }]
    }
  ])
}

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
}

##############################################
# GATEWAY (detrás del ALB público)
##############################################

resource "aws_ecs_task_definition" "gateway" {
  family                   = "${var.environment}-api-gateway"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = data.aws_iam_role.lab_role.arn
  task_role_arn            = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name  = "api-gateway"
      image = var.gateway_image
      essential = true

      portMappings = [{
        containerPort = 8000
      }]

      environment = [
  { name = "PRODUCT_SERVICE_URL",  value = "http://${var.dns_product}:8001" },
  { name = "INVENTORY_SERVICE_URL", value = "http://${var.dns_inventory}:8002" },
  { name = "REDIS_URL", value = "redis://${var.dns_dbcache}:6379" }
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

##############################################
# PRODUCT (ALB interno)
##############################################

resource "aws_ecs_task_definition" "product" {
  family                   = "${var.environment}-product-service"
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = data.aws_iam_role.lab_role.arn
  task_role_arn            = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name  = "product"
      image = var.product_image
      essential = true

      portMappings = [{
        containerPort = 8001
      }]

     environment = [
  { name = "DATABASE_URL", value = "postgresql://admin:admin123@${var.dns_dbcache}:5432/microservices_db" },
  { name = "REDIS_URL",     value = "redis://${var.dns_dbcache}:6379" }
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
    container_name   = "product"
    container_port   = 8001
  }
}

##############################################
# INVENTORY (ALB interno)
##############################################

resource "aws_ecs_task_definition" "inventory" {
  family                   = "${var.environment}-inventory-service"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = data.aws_iam_role.lab_role.arn
  task_role_arn            = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name  = "inventory"
      image = var.inventory_image
      essential = true

      portMappings = [{
        containerPort = 8002
      }]

      environment = [
  { name = "DATABASE_URL", value = "postgresql://admin:admin123@${var.dns_dbcache}:5432/microservices_db" },
  { name = "REDIS_URL",     value = "redis://${var.dns_dbcache}:6379" }
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
    container_name   = "inventory"
    container_port   = 8002
  }
}
