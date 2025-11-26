output "api_gateway_url" {
  description = "URL pública del API Gateway (nuevo punto de entrada)."
  value       = aws_apigatewayv2_api.main.api_endpoint 
}