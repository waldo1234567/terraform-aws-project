import os
import hashlib
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['CACHE_TABLE']) # type: ignore


def lambda_handler(event, context):
    job_url = event.get('job_url', '')
    cv_id = event.get('cv_id', '')
    
    if not job_url:
        return {
            "is_cached": False,
            "message": "No job URL provided.",
            "location_valid": False
        }
        
    url_hash = hashlib.sha256(job_url.encode()).hexdigest()
    
    try:
        response = table.get_item(Key = {'url_hash': url_hash})
        if 'Item' in response:
            return {
                "is_cached": True,
                "job_url": job_url,
                "cv_id": cv_id,
                "cached_report_url" : response['Item'].get('report_url')
            }
    except Exception as e:
        print(f"DynamoDB error: {str(e)}")
    
    return{
        "is_cached": False,
        "job_url": job_url,
        "cv_id": cv_id,
        "url_hash": url_hash
    }