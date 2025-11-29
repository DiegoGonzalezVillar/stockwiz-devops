
resource "aws_sns_topic" "deploy_alerts" {
  name = "${var.project_name}-${var.env}-deploy-alerts"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.deploy_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# 3. ARCHIVO ZIP DE LA FUNCIÓN
# (Asegúrate de que el archivo 'lambda_function.py' esté en la misma carpeta)
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# 4. FUNCIÓN LAMBDA
resource "aws_lambda_function" "deploy_notifier" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-${var.env}-deploy-notifier"
  
  role             = var.lab_role_arn 
  
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.11"

   environment {
    variables = {
      TOPIC_ARN = aws_sns_topic.deploy_alerts.arn
    }
  }
}

# 5. INVOCACIÓN MANUAL (simula el final del deploy)
resource "aws_lambda_invocation" "test_invocation" {
  function_name = aws_lambda_function.deploy_notifier.function_name
  triggers = {
    deployment_id = timestamp() 
  }
  input = jsonencode({
    Records = [{
      Sns = {
        TopicArn = aws_sns_topic.deploy_alerts.arn
      }
    }]
  })
}