import json
import os
import boto3

s3 = boto3.client('s3')
bedrock = boto3.client('bedrock-runtime', region_name=os.environ.get('AWS_REGION', 'ap-northeast-1'))
CV_BUCKET = os.environ['CV_BUCKET']

def lambda_handler(event, context):
    job_desc = event.get('job_desc')
    cv_id = event.get('cv_id')
    job_url = event.get('job_url')
    url_hash = event.get('url_hash')
    
    try:
        cv_object = s3.get_object(Bucket=CV_BUCKET, Key=f"uploads/cvs/{cv_id}.pdf")
        cv_bytes = cv_object['Body'].read()
        
        system_prompt = (
            "You are an elite Technical Recruiter and Career Strategist. "
            "Your task is to analyze the attached Resume against the provided Job Description (text). "
            "\n\nOBJECTIVE:"
            "1. Perform a high-fidelity gap analysis. Do not use generic filler. "
            "Identify specific technical projects in the resume that prove competency for the job requirements. "
            "2. If the candidate has unique projects (e.g., AI agents, specialized ML architectures, or niche research), "
            "prioritize those as 'High-Signal Strengths.' "
            "3. Write a tailored, persuasive cover letter that 'connects the dots'—explaining exactly how "
            "their specific technical background solves the company's problems."
            "\n\nOUTPUT FORMAT:"
            "Return ONLY a JSON object. No preamble. No markdown code blocks."
            "JSON Keys: 'gap_analysis' (Markdown string), 'cover_letter' (Markdown string)."
        )
        
        response = bedrock.converse(
            modelId="anthropic.claude-3-haiku-20240307-v1:0",
            messages = [
                {
                    "role": "user",
                    "content": [
                      {
                          "document" : {
                              "name" : "resume",
                              "format" : "pdf",
                              "source" : {"bytes" : cv_bytes}
                          }
                      },
                      {
                          "text" : f"Job Description:\n{job_desc}\n\nExecute the JSON analysis."
                      }
                    ]
                }
            ],
            system = [{"text" : system_prompt}],
            inferenceConfig = {"temperature": 0.4}
        )
        
        response_text = response['output']['message']['content'][0]['text']
        clean_json = response_text.replace("```json", "").replace("```", "").strip()
        analysis_data = json.loads(clean_json)
        
        return {
            "success" : True,
            "is_cached" : False,
            "job_url" : job_url,
            "url_hash" : url_hash,
            "gap_analysis" : analysis_data.get('gap_analysis', 'Analysis Failed'),
            "cover_letter" : analysis_data.get('cover_letter', 'Cover Letter Failed')
        }
    except Exception as e:
        print(f"Analysis Failed: {str(e)}")
        return{
            "success" : False,
            "error" : str(e)
        }