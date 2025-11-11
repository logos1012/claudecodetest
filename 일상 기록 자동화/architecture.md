# 일상 기록 자동화 시스템 아키텍처

## 개요
아이폰 음성 전사 텍스트를 Airtable에 자동으로 기록하고, GPT로 정리하여 저장하는 시스템

## 워크플로우

```
┌─────────────────┐
│ 아이폰 단축어    │ (음성 → 텍스트 변환)
└────────┬────────┘
         │ POST /daily-log
         │ { "text": "...", "date": "2025-11-11" }
         ↓
┌─────────────────┐
│  API Gateway    │ (HTTP API)
└────────┬────────┘
         │ Lambda 트리거
         ↓
┌─────────────────────────────────────┐
│         Lambda 함수                  │
│                                      │
│  1. 요청 데이터 파싱                 │
│  2. Airtable 레코드 생성             │
│     - 본문 (원본 텍스트)             │
│     - 날짜                           │
│     - GPT 수정 내용 (빈 값)          │
│  3. OpenAI GPT API 호출              │
│     - 텍스트 정리 및 개선            │
│  4. Airtable 레코드 업데이트         │
│     - GPT 수정 내용 필드 업데이트    │
└──┬──────────────┬──────────────────┘
   │              │
   ↓              ↓
┌─────────┐  ┌──────────┐
│Airtable │  │ OpenAI   │
│   API   │  │ GPT API  │
└─────────┘  └──────────┘
```

## AWS 리소스

### 1. API Gateway
- **타입**: HTTP API (REST API보다 저렴하고 간단)
- **엔드포인트**: POST /daily-log
- **인증**: API Key (선택사항) 또는 Public
- **CORS**: 필요시 활성화

### 2. Lambda 함수
- **런타임**: Python 3.11 또는 Node.js 20.x
- **메모리**: 512 MB (GPT API 호출 고려)
- **타임아웃**: 30초
- **환경 변수**:
  - SECRET_NAME: Secrets Manager 시크릿 이름

### 3. Secrets Manager
```json
{
  "airtable_api_key": "keyXXXXXXXXXXXXXX",
  "airtable_base_id": "appXXXXXXXXXXXXXX",
  "airtable_table_name": "일상기록",
  "openai_api_key": "sk-XXXXXXXXXXXXXXXX"
}
```

### 4. IAM Role (Lambda 실행 역할)
- AWSLambdaBasicExecutionRole (CloudWatch Logs)
- SecretsManager 읽기 권한
- 커스텀 정책

### 5. CloudWatch Logs
- 자동 생성: /aws/lambda/{function-name}
- 보존 기간: 7일 (비용 절감)

## Airtable 스키마

**테이블명**: 일상기록

| 필드명          | 타입        | 설명                    |
|----------------|-------------|------------------------|
| 본문           | Long text   | 원본 음성 전사 텍스트    |
| 날짜           | Date        | 기록 날짜               |
| GPT 수정 내용  | Long text   | GPT로 정리한 텍스트      |
| 생성일시       | Created time| 자동 생성               |

## 아이폰 단축어 설정

```
1. "받아쓰기 텍스트" 액션
2. "URL 내용 가져오기" 액션
   - URL: https://[API-Gateway-URL]/daily-log
   - Method: POST
   - Headers: Content-Type: application/json
   - Body:
     {
       "text": "[받아쓰기 결과]",
       "date": "[현재 날짜]"
     }
```

## 비용 예상 (월 30회 사용 기준)

- API Gateway: $0.01 (100만 요청당 $1)
- Lambda: $0.01 (프리티어 포함)
- Secrets Manager: $0.40 (시크릿당 $0.40/월)
- CloudWatch Logs: $0.01

**총 예상 비용**: ~$0.50/월

## 보안 고려사항

1. API Gateway에 API Key 추가 (선택)
2. Secrets Manager로 민감 정보 보호
3. Lambda 함수에 최소 권한 부여
4. VPC 내부 배치 (선택, 추가 비용 발생)

## 확장 가능성

- DynamoDB 추가: Airtable 백업 저장소
- S3: 원본 텍스트 파일 아카이브
- EventBridge: 정기적인 요약 리포트 생성
- SNS: 처리 완료 알림
