variable "env" {
  description = "El ambiente de despliegue (dev, test, prod)."
  type        = string
}


variable "db_password_secret" {
  description = "Valor sensible de la contraseña de la DB."
  type        = string
  sensitive   = true 
}

variable "inventory_api_key_secret" {
  description = "Valor sensible de la clave de la API interna."
  type        = string
  sensitive   = true 
}
