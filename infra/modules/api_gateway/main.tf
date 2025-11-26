# 1. API GATEWAY HTTP
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-${var.env}-api-gw"
  protocol_type = "HTTP"
}

# 2. INTEGRACIÓN: Define cómo el API Gateway se conecta al ALB
# Este bloque es el corazón de la integración Serverless con la VPC.
resource "aws_apigatewayv2_integration" "alb_integration" {
  api_id                    = aws_apigatewayv2_api.main.id
  integration_type          = "HTTP_PROXY"
  integration_method        = "ANY"
  
  # La URL de integración es el ARN del Listener del ALB
  integration_uri           = var.alb_listener_arn 
  
  # CRÍTICO: Indica que la conexión es a un recurso dentro de la VPC (el ALB)
  connection_type           = "VPC_LINK" 
  
  # ❗ CRÍTICO: Usamos el ARN del LabRole en lugar de crear un nuevo rol
  credentials_arn           = var.lab_role_arn 
  
  integration_response_selection_expression = "$default"
}

# 3. RUTA: Captura todas las peticiones
resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.main.id
  # $default captura cualquier método (GET, POST, etc.) y cualquier ruta
  route_key = "$default" 
  target    = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"
}

# 4. STAGE: Despliegue de la API
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
}