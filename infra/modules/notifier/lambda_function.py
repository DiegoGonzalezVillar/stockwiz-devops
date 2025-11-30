import json
import boto3
import os

sns = boto3.client('sns')
TOPIC_ARN = os.environ.get("TOPIC_ARN")

def lambda_handler(event, context):
    
    # Intentar obtener ARN desde SNS (si el evento vino desde un disparo SNS real)
    topic_arn = next(
        (r['Sns']['TopicArn'] for r in event.get('Records', []) if 'Sns' in r),
        None
    )

    if not topic_arn:
        topic_arn = TOPIC_ARN

    message_data = {
        "deployment_status": "SUCCESS",
        "service": "StockWiz Microservices",
        "environment": "PROD",
        "detail": "El despliegue en producción se completó correctamente."
    }

    formatted_message = f"""
    --- Alerta de Despliegue de Infraestructura ---
    
    Estado: {message_data['deployment_status']}
    Servicio: {message_data['service']}
    Ambiente: {message_data['environment']}
    Mensaje: {message_data['detail']}
    
    ----------------------------------------------
    """

    sns.publish(
        TopicArn=topic_arn,
        Message=formatted_message,
        Subject=f"[ALERTA PROD] Despliegue Exitoso: {message_data['service']}"
    )

    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Alerta publicada en SNS'})
    }
