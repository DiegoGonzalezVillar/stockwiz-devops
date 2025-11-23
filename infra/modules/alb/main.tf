
# Application Load Balancer

resource "aws_lb" "this" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [var.alb_sg_id]
  subnets         = var.public_subnets_ids

  enable_deletion_protection = false
  idle_timeout               = 60

  tags = {
    Name        = "${var.environment}-alb"
    Environment = var.environment
  }
}

# Target Group para el api-gateway

resource "aws_lb_target_group" "gateway" {
  name        = "${var.environment}-gateway-tg"
  port        = var.gateway_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # asumiendo ECS con awsvpc

  health_check {
    enabled             = true
    path                = "/health"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.environment}-gateway-tg"
    Environment = var.environment
  }
}

# Listener HTTP 80

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gateway.arn
  }
}
