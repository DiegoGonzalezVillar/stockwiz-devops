
# ECS Cluster (EC2)

resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  tags = {
    Name        = var.cluster_name
    Environment = var.environment
  }
}

# AMI ECS-Optimized (Amazon Linux 2)

data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

locals {
  ecs_ami_id = jsondecode(data.aws_ssm_parameter.ecs_ami.value).image_id
}


resource "aws_launch_template" "ecs_lt" {
  name_prefix   = "${var.environment}-ecs-lt-"
  image_id      = local.ecs_ami_id
  instance_type = var.instance_type


  iam_instance_profile {
    name = "LabInstanceProfile"
  }
  # el SG de ECS que sale del módulo VPC
  vpc_security_group_ids = [var.ecs_sg_id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "ECS_CLUSTER=${var.cluster_name}" >> /etc/ecs/ecs.config
  EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.environment}-ecs-instance"
      Environment = var.environment
    }
  }
}

# Auto Scaling Group

resource "aws_autoscaling_group" "ecs_asg" {
  name                = "${var.environment}-ecs-asg"
  max_size            = var.max_size
  min_size            = var.min_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.private_subnets_ids

  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.ecs_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-ecs-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}
