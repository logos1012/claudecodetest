import json
import os
import boto3
from datetime import datetime
import requests
from typing import Dict, Any

# Initialize AWS clients
secrets_client = boto3.client('secretsmanager')

def get_secrets() -> Dict[str, str]:
    """Retrieve secrets from AWS Secrets Manager"""
    secret_name = os.environ.get('SECRET_NAME')

    try:
        response = secrets_client.get_secret_value(SecretId=secret_name)
        return json.loads(response['SecretString'])
    except Exception as e:
        print(f"Error retrieving secrets: {str(e)}")
        raise

def create_airtable_record(secrets: Dict[str, str], text: str, date: str) -> str:
    """Create a new record in Airtable and return the record ID"""
    base_id = secrets['airtable_base_id']
    table_name = secrets['airtable_table_name']
    api_key = secrets['airtable_api_key']

    url = f"https://api.airtable.com/v0/{base_id}/{table_name}"

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    data = {
        "fields": {
            "본문": text,
            "날짜": date,
            "GPT 수정 내용": ""  # Will be updated later
        }
    }

    try:
        response = requests.post(url, headers=headers, json=data)
        response.raise_for_status()
        result = response.json()
        return result['id']
    except Exception as e:
        print(f"Error creating Airtable record: {str(e)}")
        raise

def improve_text_with_gpt(secrets: Dict[str, str], text: str) -> str:
    """Use OpenAI GPT to improve and format the text"""
    api_key = secrets['openai_api_key']

    url = "https://api.openai.com/v1/chat/completions"

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    data = {
        "model": "gpt-4o-mini",  # Cost-effective model
        "messages": [
            {
                "role": "system",
                "content": """당신은 일상 기록을 정리하는 도우미입니다.
사용자의 음성 전사 텍스트를 받아서 다음과 같이 정리해주세요:
1. 맞춤법과 문법을 바르게 수정
2. 문단을 적절히 나누기
3. 불필요한 반복이나 추임새 제거
4. 읽기 쉽고 명확하게 재작성
5. 원본의 의미와 감정은 그대로 유지

간결하고 깔끔하게 정리해주되, 내용을 추가하거나 변경하지 마세요."""
            },
            {
                "role": "user",
                "content": text
            }
        ],
        "temperature": 0.7,
        "max_tokens": 2000
    }

    try:
        response = requests.post(url, headers=headers, json=data)
        response.raise_for_status()
        result = response.json()
        return result['choices'][0]['message']['content']
    except Exception as e:
        print(f"Error calling OpenAI API: {str(e)}")
        raise

def update_airtable_record(secrets: Dict[str, str], record_id: str, improved_text: str):
    """Update the Airtable record with improved text"""
    base_id = secrets['airtable_base_id']
    table_name = secrets['airtable_table_name']
    api_key = secrets['airtable_api_key']

    url = f"https://api.airtable.com/v0/{base_id}/{table_name}/{record_id}"

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    data = {
        "fields": {
            "GPT 수정 내용": improved_text
        }
    }

    try:
        response = requests.patch(url, headers=headers, json=data)
        response.raise_for_status()
    except Exception as e:
        print(f"Error updating Airtable record: {str(e)}")
        raise

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Main Lambda handler function"""
    print(f"Received event: {json.dumps(event)}")

    try:
        # Parse request body
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = event.get('body', event)

        text = body.get('text', '')
        date = body.get('date', datetime.now().strftime('%Y-%m-%d'))

        if not text:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'Text is required'
                }, ensure_ascii=False)
            }

        # Get secrets
        secrets = get_secrets()

        # Step 1: Create initial Airtable record
        print("Creating Airtable record...")
        record_id = create_airtable_record(secrets, text, date)
        print(f"Created record with ID: {record_id}")

        # Step 2: Improve text with GPT
        print("Improving text with GPT...")
        improved_text = improve_text_with_gpt(secrets, text)
        print(f"GPT improved text: {improved_text[:100]}...")

        # Step 3: Update Airtable record with improved text
        print("Updating Airtable record with improved text...")
        update_airtable_record(secrets, record_id, improved_text)
        print("Successfully updated record")

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': 'Successfully processed daily log',
                'record_id': record_id,
                'date': date
            }, ensure_ascii=False)
        }

    except Exception as e:
        print(f"Error in lambda_handler: {str(e)}")
        import traceback
        traceback.print_exc()

        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': str(e)
            }, ensure_ascii=False)
        }
