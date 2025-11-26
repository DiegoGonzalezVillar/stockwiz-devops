data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.project_name}-${var.env}-cluster"
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}-${var.env}"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "task" {
  count = var.full_image == "" ? 0 : 1
  family                   = "${var.project_name}-${var.env}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"

  depends_on = [
    aws_cloudwatch_log_group.ecs
  ]

  execution_role_arn = data.aws_iam_role.lab_role.arn
  task_role_arn      = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name      = "stockwiz"
      image     = var.full_image
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
          awslogs-region        = var.aws_region
          awslogs-group         = "/ecs/${var.project_name}-${var.env}"
          awslogs-stream-prefix = "ecs"
        }
      }
secrets = [
        {
          name      = "DB_PASSWORD" 
          valueFrom = var.db_password_arn
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "svc" {
  count = var.full_image == "" ? 0 : 1
  name            = "${var.project_name}-${var.env}-svc"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task[0].arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.public_subnets
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "stockwiz"
    container_port   = 8000
  }
}


