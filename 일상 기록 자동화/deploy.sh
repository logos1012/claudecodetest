#!/bin/bash

# 일상 기록 자동화 시스템 배포 스크립트

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  일상 기록 자동화 시스템 배포 도구   ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}\n"

# 사전 체크
echo -e "${YELLOW}[1/6] 사전 요구사항 확인 중...${NC}"

# AWS CLI 확인
if ! command -v aws &> /dev/null; then
    echo -e "${RED}✗ AWS CLI가 설치되어 있지 않습니다.${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ AWS CLI 설치 확인${NC}"

# Terraform 확인
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}✗ Terraform이 설치되어 있지 않습니다.${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ Terraform 설치 확인${NC}"

# AWS 자격 증명 확인
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}✗ AWS 자격 증명이 구성되어 있지 않습니다.${NC}"
    echo "  'aws configure'를 실행하세요."
    exit 1
fi
echo -e "${GREEN}  ✓ AWS 자격 증명 확인${NC}"

AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region || echo "us-east-1")
echo -e "${BLUE}  AWS Account: ${AWS_ACCOUNT}${NC}"
echo -e "${BLUE}  AWS Region: ${AWS_REGION}${NC}\n"

# Terraform 초기화
echo -e "${YELLOW}[2/6] Terraform 초기화 중...${NC}"
terraform init
echo -e "${GREEN}  ✓ Terraform 초기화 완료${NC}\n"

# Terraform 검증
echo -e "${YELLOW}[3/6] Terraform 설정 검증 중...${NC}"
terraform validate
echo -e "${GREEN}  ✓ Terraform 설정 검증 완료${NC}\n"

# Terraform Plan
echo -e "${YELLOW}[4/6] 배포 계획 생성 중...${NC}"
terraform plan -out=tfplan
echo -e "${GREEN}  ✓ 배포 계획 생성 완료${NC}\n"

# 사용자 확인
echo -e "${YELLOW}[5/6] 배포를 진행하시겠습니까?${NC}"
read -p "계속하려면 'yes'를 입력하세요: " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${RED}배포가 취소되었습니다.${NC}"
    rm -f tfplan
    exit 0
fi

# Terraform Apply
echo -e "${YELLOW}[6/6] 인프라 배포 중...${NC}"
terraform apply tfplan
rm -f tfplan
echo -e "${GREEN}  ✓ 인프라 배포 완료${NC}\n"

# 출력 정보
echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         배포 완료!                    ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}\n"

echo -e "${BLUE}중요한 정보:${NC}"
API_ENDPOINT=$(terraform output -raw api_endpoint)
SECRET_NAME=$(terraform output -raw secret_name)
LAMBDA_NAME=$(terraform output -raw lambda_function_name)

echo -e "${YELLOW}API 엔드포인트:${NC}"
echo "  $API_ENDPOINT"
echo ""

echo -e "${YELLOW}다음 단계:${NC}"
echo ""
echo -e "${BLUE}1. API 키 설정${NC}"
echo "   Secrets Manager에 실제 API 키를 입력하세요:"
echo ""
echo "   aws secretsmanager put-secret-value \\"
echo "     --secret-id $SECRET_NAME \\"
echo "     --secret-string '{"
echo "       \"airtable_api_key\": \"YOUR_AIRTABLE_API_KEY\","
echo "       \"airtable_base_id\": \"YOUR_AIRTABLE_BASE_ID\","
echo "       \"airtable_table_name\": \"일상기록\","
echo "       \"openai_api_key\": \"YOUR_OPENAI_API_KEY\""
echo "     }'"
echo ""
echo -e "${BLUE}2. 아이폰 단축어 설정${NC}"
echo "   단축어 앱에서 다음 URL을 사용하세요:"
echo "   $API_ENDPOINT"
echo ""
echo -e "${BLUE}3. 테스트${NC}"
echo "   ./test_api.sh 스크립트를 실행하여 테스트하세요."
echo ""
echo -e "${BLUE}4. 로그 모니터링${NC}"
echo "   aws logs tail /aws/lambda/$LAMBDA_NAME --follow"
echo ""
echo -e "${GREEN}자세한 내용은 README.md를 참고하세요.${NC}"
