variable "project_name" {
  type = string
}

variable "env" {
  type = string
}

variable "alb_listener_arn" {
  description = "ARN del Listener del ALB al que se integrará el API Gateway."
  type        = string
}

variable "alb_arn" {
  description = "ARN completo del Application Load Balancer."
  type        = string
}

variable "lab_role_arn" {
  description = "ARN del LabRole de estudiante con permisos para usar como credencial de API Gateway."
  type        = string
}