import json
import os
import boto3

sfn = boto3.client('stepfunctions')

def lambda_handler(event, context):
    execution_arn = event.get('queryStringParameters', {}).get('executionArn')
    provided_cv_id = event.get('queryStringParameters', {}).get('cv_id')
    
    if not execution_arn:
        return {
            "statusCode": 400,
            "headers": {"Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"error": "Missing executionArn parameter"})
        }
        
    try:
        response = sfn.describe_execution(executionArn=execution_arn)
        status = response['status']
        
        input_data = json.loads(response.get('input', '{}'))
        if input_data.get('cv_id') != provided_cv_id:
            return {
                "statusCode": 403,
                "body": json.dumps({"error": "Unauthorized: Access denied to this execution."})
            }
        
        result = {
            "status": status,
            "executionArn": execution_arn
        }
        
        if status == 'SUCCEEDED':
            output = json.loads(response.get('output', '{}'))
            result['report_url'] = output.get('report_file')
        
        elif status == 'FAILED':
            result['error'] = "The analysis failed or the location was invalid."

        return {
            "statusCode": 200,
            "headers": {"Access-Control-Allow-Origin": "*"},
            "body": json.dumps(result)
        }
    except Exception as e:
        return  {
            "statusCode": 500,
            "headers": {"Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"error": str(e)})
        }