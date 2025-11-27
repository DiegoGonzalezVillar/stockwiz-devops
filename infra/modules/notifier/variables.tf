variable "project_name" {
  type = string
}

variable "env" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "alert_email" {
  description = "Correo electrónico para recibir la notificación de despliegue."
  type        = string
}

variable "lab_role_arn" {
  description = "ARN del LabRole para usar como rol de ejecución de la función Lambda."
  type        = string
}