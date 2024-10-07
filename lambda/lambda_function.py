import json
import logging
import os

# Configure logging
logger = logging.getLogger()
logging_level = os.getenv('LOGGING_LEVEL', 'INFO').upper()
if logging_level not in ['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL']:
    logging_level = 'INFO'
logger.setLevel(getattr(logging, logging_level, logging.INFO))

def lambda_handler(event, context):
    """
    AWS Lambda handler function that processes incoming events and returns a response.

    This function extracts query parameters from the incoming event, specifically the 'name' parameter,
    and returns a personalized greeting message. If the 'name' parameter is not provided, it defaults to 'Guest'.
    The function also handles various types of errors, including invalid data types, JSON decoding errors,
    and runtime errors, and returns appropriate HTTP status codes and error messages.

    Parameters:
    event (dict): The event data passed to the Lambda function, typically from API Gateway.
    context (object): The runtime context information for the Lambda function.

    Returns:
    dict: A dictionary containing the HTTP status code, headers, and body of the response.
    """
    try:
        logger.info("Received event: %s", json.dumps(event))

        query_params = event.get('queryStringParameters')
        if not isinstance(query_params, dict):
            query_params = {}
        
        name = query_params.get('name', 'Guest')
        
        message = f"Hello, {name} from Lambda!"

        response = {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': os.getenv('ALLOWED_ORIGIN', '*')
            },
            'body': json.dumps({'message': message})
        }

        return response

    except TypeError as e:
        logger.error("TypeError encountered: %s. Event details: %s", str(e), json.dumps(event))
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({'error': 'Bad Request: Invalid data type', 'details': str(e)})
        }

    except json.JSONDecodeError as e:
        logger.error("JSONDecodeError encountered: %s. Event details: %s", str(e), json.dumps(event))
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({'error': 'Bad Request: JSON decoding error', 'details': str(e)})
        }

    except RuntimeError as e:
        logger.error("RuntimeError encountered: %s. Event details: %s", str(e), json.dumps(event))
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({'error': 'Internal Server Error: Runtime error', 'details': str(e)})
        }