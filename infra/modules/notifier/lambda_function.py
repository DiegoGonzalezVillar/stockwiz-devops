import json
import boto3

sns = boto3.client('sns')

def lambda_handler(event, context):

    topic_arn = next((r['Sns']['TopicArn'] for r in event.get('Records', []) if 'Sns' in r), None)
    
    message_data = {
        "deployment_status": "SUCCESS",
        "service": "StockWiz Microservices",
        "environment": "DEV",
        "detail": "El despliegue de infraestructura de Terraform ha finalizado con éxito."
    }
    
    formatted_message = f"""
    --- Alerta de Despliegue de Infraestructura ---
    
    Estado: {message_data['deployment_status']}
    Servicio: {message_data['service']}
    Ambiente: {message_data['environment']}
    Mensaje: {message_data['detail']}
    
    ----------------------------------------------
    """
    if topic_arn:
        sns.publish(
            TopicArn=topic_arn,
            Message=formatted_message, 
            Subject=f"[ALERTA DEV] Despliegue Exitoso: {message_data['service']}"
        )

    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Alerta publicada en SNS'})
    }