
resource "aws_secretsmanager_secret" "db_password" {
  name        = "${var.environment}/stockwiz/db_password"
  description = "Contraseña de la base de datos para StockWiz."
}

resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  # Este valor debe venir de una variable sensible pasada por el CI/CD
  secret_string = var.db_password_secret 
}


resource "aws_secretsmanager_secret" "inventory_api_key" {
  name        = "${var.environment}/stockwiz/inventory_api_key"
  description = "Clave de autenticación para llamadas internas (Product a Inventory)."
}

resource "aws_secretsmanager_secret_version" "inventory_api_key_version" {
  secret_id     = aws_secretsmanager_secret.inventory_api_key.id
  # El valor real se pasa desde el CI/CD
  secret_string = var.inventory_api_key_secret 
}