data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.project_name}-${var.env}-cluster"
}

resource "aws_ecs_task_definition" "task" {
  family                   = "${var.project_name}-${var.env}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"

  execution_role_arn = data.aws_iam_role.lab_role.arn
  task_role_arn      = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name  = "stockwiz"
      image = var.full_image
      essential = true
      portMappings = [
        { containerPort = 8000 }
      ]
    }
  ])
}

resource "aws_ecs_service" "svc" {
  name            = "${var.project_name}-${var.env}-svc"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
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

