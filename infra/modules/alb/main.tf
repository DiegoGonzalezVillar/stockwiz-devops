resource "aws_lb" "app_lb" {
  name               = "stockwiz-${var.subnet_id}-alb"
  load_balancer_type = "application"
  subnets            = [var.subnet_id]
  security_groups    = [var.alb_sg_id]
}

resource "aws_lb_target_group" "tg" {
  name        = "stockwiz-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = aws_lb.app_lb.vpc_id
  target_type = "ip"
  health_check {
  path    = "/"
  matcher = "200-399"
}
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}


