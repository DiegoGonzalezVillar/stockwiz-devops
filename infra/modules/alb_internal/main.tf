resource "aws_lb" "this" {
  name               = "${var.environment}-alb-internal"
  internal           = true
  load_balancer_type = "application"

  security_groups = [var.alb_sg_id]
  subnets         = var.private_subnets_ids

  idle_timeout               = 60
  enable_deletion_protection = false

  tags = {
    Name        = "${var.environment}-alb-internal"
    Environment = var.environment
  }
}

# TG para Product
resource "aws_lb_target_group" "product" {
  name        = "${var.environment}-product-tg"
  port        = 8001
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path     = "/health"
    matcher  = "200"
    interval = 20
    timeout  = 5
  }
}

# TG para Inventory
resource "aws_lb_target_group" "inventory" {
  name        = "${var.environment}-inventory-tg"
  port        = 8002
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path     = "/health"
    matcher  = "200"
    interval = 20
    timeout  = 5
  }
}

# Listener que enruta por path
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.product.arn
  }
}

