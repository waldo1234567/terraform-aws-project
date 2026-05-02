import json
import boto3
import os
import uuid

s3 = boto3.client('s3')
BUCKET_NAME = os.environ['BUCKET_NAME']

def lambda_handler(event, context):
    
    try:
        cv_id = f"req-{uuid.uuid4().hex[:8]}"
        object_key = f"uploads/cvs/{cv_id}.pdf"
        
        presigned_url = s3.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': BUCKET_NAME, 
                'Key': object_key,
                'ContentType': 'application/pdf'
            },
            ExpiresIn=100
        )
        
        return {
            "statusCode" : 200,
            "headers" : {
                "Access-Control-Allow-Origin" : "*",
                "Content-Type": "application/json"
            },
            "body" : json.dumps({
                "upload_url": presigned_url,
                "cv_id": cv_id
            })
        }
        
    except Exception as e:
        print(f"Error generating presigned URL: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }