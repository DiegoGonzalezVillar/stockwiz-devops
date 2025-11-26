###############################
# CloudWatch Dashboard
###############################
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.env}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # Widget 1: ECS Service CPU Utilization
      {
        type = "metric",
        width = 24,
        height = 6,
        properties = {
          title = "ECS Service CPU Utilization"
          metrics = [
            [
              "AWS/ECS",
              "CPUUtilization",
              "ClusterName", "${var.project_name}-${var.env}-cluster",
              "ServiceName", "${var.project_name}-${var.env}-svc"
            ]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
        }
      },
      # Widget 2: Application Load Balancer 5xx Errors
      {
        type = "metric",
        width = 24,
        height = 6,
        properties = {
          title = "Application Load Balancer 5xx Errors"
          metrics = [
            [
              "AWS/ApplicationELB",
              "HTTPCode_ELB_5XX_Count",
              "LoadBalancer", "${var.alb_arn_suffix}" # ❗ CAMBIO: Usa la variable de entrada
            ]
          ]
          period = 60
          stat   = "Sum"
          region = var.aws_region
        }
      }
    ]
  })
}

#########################################
# Alarm: High CPU on ECS Service
#########################################
resource "aws_cloudwatch_metric_alarm" "ecs_high_cpu" {
  alarm_name          = "${var.project_name}-${var.env}-ecs-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  datapoints_to_alarm = 4
  threshold           = 80
  treat_missing_data  = "notBreaching"

  metric_name = "CPUUtilization"
  namespace   = "AWS/ECS"
  period      = 60
  statistic   = "Average"

  dimensions = {
    ClusterName = "${var.project_name}-${var.env}-cluster"
    ServiceName = "${var.project_name}-${var.env}-svc"
  }

  alarm_description = "ECS CPU usage is above 80% for 5 minutes"
}

#########################################
# Alarm: ALB 5xx Errors
#########################################
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project_name}-${var.env}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 5
  period              = 60
  statistic           = "Sum"

  metric_name = "HTTPCode_ELB_5XX_Count"
  namespace   = "AWS/ApplicationELB"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix # ❗ CAMBIO: Usa la variable de entrada
  }

  alarm_description = "ALB is returning 5xx errors"
}