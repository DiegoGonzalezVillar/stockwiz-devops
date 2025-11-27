import json
import boto3

sns = boto3.client('sns')

def lambda_handler(event, context):
    """
    Función de notificación que se invoca después del deploy.
    Publica un mensaje de éxito en un tópico de SNS.
    """
    
    # ARN del Tópico (simplificación, en producción se usaría variables de ambiente)
    topic_arn = next((r['Sns']['TopicArn'] for r in event.get('Records', []) if 'Sns' in r), None)
    
    message = {
        "deployment_status": "SUCCESS",
        "service": "StockWiz Microservices",
        "environment": "DEV",
        "message": "El despliegue de infraestructura de Terraform ha finalizado con éxito."
    }
    
    # Publica el mensaje en el Tópico de SNS (asumiendo que el LabRole tiene sns:Publish)
    if topic_arn:
        sns.publish(
            TopicArn=topic_arn,
            Message=json.dumps(message),
            Subject=f"[ALERTA DEV] Despliegue Exitoso: {message['service']}"
        )

    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Alerta publicada en SNS'})
    }