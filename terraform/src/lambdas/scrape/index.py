import json
import urllib.request
import re
import requests
from bs4 import BeautifulSoup

def lambda_handler(event, context):
   job_url = event.get('job_url', '')
   
   try:
        headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'}
        response = requests.get(job_url, headers=headers, timeout=10)
        response.raise_for_status()
       
        soup = BeautifulSoup(response.text, 'html.parser')
       
        for script in soup(["script", "style", "header", "footer", "nav"]):
           script.extract()
           
        raw_text = soup.get_text(separator=' ')
        clean_text = re.sub(r'\s+', ' ', raw_text).strip()
        
        job_desc = clean_text[:5000]
        text_lower = job_desc.lower()
        valid_locations = ['taichung', 'taipei', 'remote', 'hybrid', 'taiwan']
        
        location_valid = any(loc in text_lower for loc in valid_locations)
        
        return {
            "is_cached" : False,
            "job_url" : job_url,
            "cv_id": event.get('cv_id'),
            "url_hash": event.get('url_hash'),
            "job_desc" : job_desc,
            "location_valid": location_valid    
        }
    
   except Exception as e:
        print(f"Scraping failed: {e}")
        return {
            "location_valid": False,
            "error": str(e)
        }
        