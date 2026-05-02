import os
import time
import boto3

s3 = boto3.client('s3')
dynamodb = boto3.client('dynamodb')

REPORTS_BUCKET = os.environ['REPORTS_BUCKET']
STATE_TABLE = os.environ['STATE_TABLE']


def lambda_handler(event, context):
    is_cached = event.get('is_cached', False)
    
    if is_cached:
        return {
            "statusCode" : 200,
            "status" : "CACHE_HIT",
            "report_url" : event.get('cached_report_url')
        }
    
    job_url = event.get('job_url')
    url_hash = event.get('url_hash')
    gap_analysis = event.get('gap_analysis', 'No analysis available')
    cover_letter = event.get('cover_letter', 'No cover letter available')
    
    markdown_content = f" Job Fit Analysis & Cover Letter\n**Target Role:** {job_url}\n\n"
    markdown_content += f"## Gap Analysis (Technical)\n{gap_analysis}\n\n"
    markdown_content += f"---\n\n## Tailored Cover Letter\n{cover_letter}\n"
    
    
    file_name = f"{url_hash}.md"
    
    try:
        s3.put_object(
            Bucket = REPORTS_BUCKET,
            Key = file_name,
            Body = markdown_content.encode('utf-8'),
            ContentType = 'text/markdown',
            Metadata = {
                'Access-Control-Allow-Origin': '*'
            }
        )

        dynamodb.put_item(
            TableName = STATE_TABLE,
            Item = {
                'job_id' : {'S': url_hash},
                'status' : {'S' : 'COMPLETED'},
                'report_key' : {'S' : file_name}
            }
        )
        
        dynamodb.put_item(
            TableName=os.environ['CACHE_TABLE'],
            Item={
                'url_hash': {'S': url_hash},
                'report_url': {'S': file_name},
                'ttl': {'N': str(int(time.time()) + 604800)}  # 7 days
            }
        )
        
        return {
            "statusCode": 200,
            "status": "GENERATED",
            "report_file": file_name
        }
        
    except Exception as e:
        print(f"Format/Save failed: {e}")
        return {
            "statusCode": 500,
            "error": str(e)
        }