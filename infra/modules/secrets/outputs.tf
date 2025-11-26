
output "db_password_arn" {
  description = "ARN del secreto de la contraseña de la DB."
  value       = aws_secretsmanager_secret.db_password.arn
}

output "inventory_api_key_arn" {
  description = "ARN del secreto de la clave de la API interna."
  value       = aws_secretsmanager_secret.inventory_api_key.arn
}