##############################
# LAB ROLE (MANDATORY)
##############################
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

##############################
# ECS INSTANCE ROLE
##############################
resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.project_name}-${var.env}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_attach" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.project_name}-${var.env}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

##############################
# ECS-OPTIMIZED AMI
##############################
data "aws_ami" "ecs_optimized" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  owners = ["amazon"]
}

##############################
# LAUNCH TEMPLATE
##############################
resource "aws_launch_template" "ecs" {
  name_prefix = "${var.project_name}-${var.env}-lt"

  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = var.instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs_instance_profile.arn
  }

  user_data = base64encode(<<EOF
#!/bin/bash
echo "ECS_CLUSTER=${var.project_name}-${var.env}-cluster" >> /etc/ecs/ecs.config
EOF
  )
}

##############################
# AUTO SCALING GROUP
##############################
resource "aws_autoscaling_group" "ecs" {
  name                      = "${var.project_name}-${var.env}-asg"
  max_size                  = var.max_capacity
  min_size                  = var.desired_capacity
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.public_subnets

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }
}

##############################
# CAPACITY PROVIDER
##############################
resource "aws_ecs_capacity_provider" "cp" {
  name = "${var.project_name}-${var.env}-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs.arn

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 2
    }

    managed_termination_protection = "DISABLED"
  }
}

##############################
# ECS CLUSTER
##############################
resource "aws_ecs_cluster" "cluster" {
  name = "${var.project_name}-${var.env}-cluster"
}

resource "aws_ecs_cluster_capacity_providers" "cp_assoc" {
  cluster_name       = aws_ecs_cluster.cluster.name
  capacity_providers = [aws_ecs_capacity_provider.cp.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.cp.name
    weight            = 1
  }
}

##############################
# TASK DEFINITION (API + PG + REDIS)
##############################
resource "aws_ecs_task_definition" "api" {
  family                   = "${var.project_name}-${var.env}-task"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"

  execution_role_arn = data.aws_iam_role.lab_role.arn
  task_role_arn      = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name         = "api_gateway"
      essential    = true
      image        = var.api_image
      portMappings = [{ containerPort = 8000 }]
    },
    {
      name         = "postgres"
      essential    = true
      image        = var.postgres_image
      portMappings = [{ containerPort = 5432 }]
    },
    {
      name         = "redis"
      essential    = true
      image        = var.redis_image
      portMappings = [{ containerPort = 6379 }]
    }
  ])
}

##############################
# ECS SERVICE
##############################
resource "aws_ecs_service" "svc" {
  name            = "${var.project_name}-${var.env}-svc"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets          = var.public_subnets
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "api_gateway"
    container_port   = 8000
  }

  depends_on = [
    aws_ecs_cluster_capacity_providers.cp_assoc
  ]
}
