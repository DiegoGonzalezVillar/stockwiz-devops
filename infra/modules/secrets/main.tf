
resource "aws_secretsmanager_secret" "db_password" {
  name        = "${var.env}/stockwiz/db_password_v2"
  description = "Contraseña de la DB para el ambiente ${var.env}."
  recovery_window_in_days = 0 
}

resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  # Este valor debe venir de una variable sensible pasada por el CI/CD
  secret_string = var.db_password_secret 
}




resource "aws_secretsmanager_secret" "inventory_api_key" {
  name        = "${var.env}/stockwiz/inventory_api_key_v2"
  description = "Clave de autenticación para llamadas internas (Product a Inventory)."
  recovery_window_in_days = 0 
}

resource "aws_secretsmanager_secret_version" "inventory_api_key_version" {
  secret_id     = aws_secretsmanager_secret.inventory_api_key.id
  # El valor real se pasa desde el CI/CD
  secret_string = var.inventory_api_key_secret 
}