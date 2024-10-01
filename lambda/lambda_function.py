import json

def lambda_handler(event, context):
    try:
        return {
            'statusCode': 200,
            'body': 'Hello from Lambda!'
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }