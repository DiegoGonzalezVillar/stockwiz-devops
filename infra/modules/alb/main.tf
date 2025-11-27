resource "aws_lb" "app_lb" {
  name               = "${var.project_name}-${var.env}-alb"
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnets
  tags = {
    Name        = "${var.project_name}-${var.env}-ALB"
  }
}

####################################
# TARGET GROUP
####################################
resource "aws_lb_target_group" "tg" {
  name     = "${var.project_name}-${var.env}-tg"
  port     = 8000
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = module.network.vpc_id

  tags = { 
    Name        = "${var.project_name}-${var.env}-TG"
  }

  health_check {
    path                = "/health"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

####################################
# LISTENER
####################################
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}
