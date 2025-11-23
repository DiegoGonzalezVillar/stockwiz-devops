##############################################
# INTERNAL ALB FOR A BACKEND SERVICE
##############################################

resource "aws_lb" "this" {
  name               = "${var.name}-alb-internal"
  internal           = true
  load_balancer_type = "application"

  security_groups = [var.sg_id]
  subnets         = var.private_subnets

  tags = {
    Name        = "${var.name}-alb-internal"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "service" {
  name        = "${var.name}-tg"
  port        = var.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 20
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.name}-tg"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service.arn
  }
}
