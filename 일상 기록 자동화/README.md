# 일상 기록 자동화 시스템

아이폰 음성 전사 텍스트를 Airtable에 자동으로 기록하고, GPT로 정리하여 저장하는 AWS 기반 자동화 시스템입니다.

## 시스템 구성

- **API Gateway**: 아이폰 단축어에서 호출할 HTTP API
- **Lambda**: 텍스트 처리 및 Airtable/GPT 연동
- **Secrets Manager**: API 키 안전한 저장
- **CloudWatch Logs**: 로그 모니터링

자세한 아키텍처는 [architecture.md](./architecture.md)를 참고하세요.

## 사전 준비

### 1. AWS 계정 및 CLI 설정

```bash
# AWS CLI 설치 확인
aws --version

# AWS 자격 증명 구성
aws configure
```

### 2. Terraform 설치

```bash
# Terraform 설치 확인
terraform version
```

### 3. Airtable 설정

1. [Airtable](https://airtable.com)에 로그인
2. 새 Base 생성
3. 테이블 생성: "일상기록"
4. 필드 생성:
   - **본문** (Long text)
   - **날짜** (Date)
   - **GPT 수정 내용** (Long text)
   - **생성일시** (Created time) - 자동 생성

5. API 키 발급:
   - [Airtable Account](https://airtable.com/account) → API 섹션
   - Personal Access Token 생성
   - Scopes: `data.records:read`, `data.records:write`

6. Base ID 확인:
   - [Airtable API 문서](https://airtable.com/api)에서 Base 선택
   - URL에서 `app...` 형태의 Base ID 확인

### 4. OpenAI API 키

1. [OpenAI Platform](https://platform.openai.com/api-keys)에서 API 키 생성
2. 결제 정보 등록 (사용량 기반 과금)

## 배포 방법

### 1. 저장소 클론 및 디렉토리 이동

```bash
cd "일상 기록 자동화"
```

### 2. Terraform 초기화

```bash
terraform init
```

### 3. 인프라 배포

```bash
# 배포 계획 확인
terraform plan

# 배포 실행
terraform apply
```

배포가 완료되면 출력되는 정보를 저장하세요:
- `api_endpoint`: API 엔드포인트 URL
- `secret_name`: Secrets Manager 시크릿 이름

### 4. API 키 설정

배포 후 AWS Secrets Manager에 실제 API 키를 입력해야 합니다.

#### AWS CLI 사용:

```bash
aws secretsmanager put-secret-value \
  --secret-id daily-log-automation-secrets \
  --secret-string '{
    "airtable_api_key": "YOUR_ACTUAL_AIRTABLE_API_KEY",
    "airtable_base_id": "YOUR_ACTUAL_BASE_ID",
    "airtable_table_name": "일상기록",
    "openai_api_key": "YOUR_ACTUAL_OPENAI_API_KEY"
  }'
```

#### AWS Console 사용:

1. [AWS Secrets Manager Console](https://console.aws.amazon.com/secretsmanager/)
2. `daily-log-automation-secrets` 시크릿 선택
3. "Retrieve secret value" → "Edit"
4. JSON 형식으로 실제 값 입력
5. "Save" 클릭

## 아이폰 단축어 설정

### 1. 단축어 앱에서 새 단축어 생성

### 2. 액션 추가:

#### a. 받아쓰기 텍스트
- "텍스트" 카테고리 → "받아쓰기 텍스트" 액션 추가
- 언어: 한국어

#### b. 현재 날짜 가져오기
- "날짜" 카테고리 → "현재 날짜" 액션 추가
- 형식: 사용자 지정 → `yyyy-MM-dd`

#### c. JSON 딕셔너리 만들기
- "스크립팅" 카테고리 → "딕셔너리" 액션 추가
- 키-값:
  - `text`: [받아쓰기 결과]
  - `date`: [현재 날짜]

#### d. URL 내용 가져오기
- "웹" 카테고리 → "URL 내용 가져오기" 액션 추가
- URL: `https://YOUR_API_ENDPOINT` (terraform output에서 확인)
- 방법: POST
- 헤더:
  - `Content-Type`: `application/json`
- 본문: [딕셔너리] (이전 단계의 결과)

#### e. 알림 표시 (선택사항)
- "알림" 카테고리 → "알림 표시" 액션 추가
- 내용: "일상 기록이 저장되었습니다"

### 3. 단축어 이름 설정
- "일상 기록" 또는 원하는 이름으로 설정

### 4. 테스트
- 단축어 실행하여 정상 동작 확인
- Airtable에서 레코드 생성 확인

## 테스트

### API 엔드포인트 테스트

```bash
# API 엔드포인트 URL 확인
terraform output api_endpoint

# curl로 테스트
curl -X POST "YOUR_API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "오늘은 날씨가 좋아서 산책을 갔다. 공원에서 강아지를 보았는데 정말 귀여웠다.",
    "date": "2025-11-11"
  }'
```

### Lambda 로그 확인

```bash
# CloudWatch Logs 확인
aws logs tail /aws/lambda/daily-log-automation --follow
```

## 비용 예상

월 30회 사용 기준:
- API Gateway: ~$0.01
- Lambda: ~$0.01
- Secrets Manager: $0.40
- CloudWatch Logs: ~$0.01
- **총 예상 비용**: ~$0.50/월

> 외부 API 비용 별도:
> - OpenAI GPT-4o-mini: ~$0.03 (텍스트 길이에 따라 변동)

## 모니터링

### CloudWatch 대시보드

```bash
# Lambda 로그 확인
aws logs tail /aws/lambda/daily-log-automation --follow

# API Gateway 로그 확인
aws logs tail /aws/apigateway/daily-log-automation --follow
```

### Airtable에서 확인
- Airtable Base에서 실시간으로 레코드 생성 확인
- GPT 수정 내용이 자동으로 업데이트되는지 확인

## 문제 해결

### Lambda 함수 오류
```bash
# Lambda 로그 확인
aws logs tail /aws/lambda/daily-log-automation --follow

# Lambda 함수 재배포
terraform apply -replace=aws_lambda_function.daily_log_processor
```

### API 키 오류
- Secrets Manager에서 API 키가 올바르게 설정되었는지 확인
- Airtable Base ID와 Table 이름 확인

### 권한 오류
- IAM 역할이 올바르게 설정되었는지 확인
- Lambda 함수에 Secrets Manager 접근 권한이 있는지 확인

## 리소스 삭제

```bash
# 모든 AWS 리소스 삭제
terraform destroy

# 확인 후 yes 입력
```

> **주의**: Secrets Manager는 7일의 복구 기간이 있어 즉시 삭제되지 않습니다.

## 확장 아이디어

- [ ] S3에 원본 텍스트 백업
- [ ] DynamoDB로 중복 저장
- [ ] 주간/월간 요약 리포트 자동 생성
- [ ] SNS 알림 연동
- [ ] 음성 감정 분석 추가
- [ ] 이미지 첨부 기능

## 라이선스

MIT License

## 문의

이슈가 있으시면 GitHub Issues를 통해 문의해주세요.
