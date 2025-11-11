#!/bin/bash

# 일상 기록 자동화 API 테스트 스크립트

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== 일상 기록 자동화 API 테스트 ===${NC}\n"

# API 엔드포인트 확인
echo -e "${YELLOW}1. API 엔드포인트 확인 중...${NC}"
API_ENDPOINT=$(terraform output -raw api_endpoint 2>/dev/null)

if [ -z "$API_ENDPOINT" ]; then
    echo -e "${RED}ERROR: API 엔드포인트를 찾을 수 없습니다.${NC}"
    echo "먼저 'terraform apply'를 실행하세요."
    exit 1
fi

echo -e "${GREEN}API 엔드포인트: ${API_ENDPOINT}${NC}\n"

# 테스트 데이터
TEST_TEXT="오늘은 날씨가 정말 좋았어요. 아침에 일어나서 커피를 마시고 산책을 갔는데, 공원에 사람들이 많더라고요. 강아지들도 많이 보였는데 특히 골든 리트리버가 정말 귀여웠어요. 점심에는 친구를 만나서 맛있는 파스타를 먹었고, 저녁에는 집에서 영화를 봤습니다."
TEST_DATE=$(date +%Y-%m-%d)

echo -e "${YELLOW}2. 테스트 데이터:${NC}"
echo "날짜: $TEST_DATE"
echo "본문: $TEST_TEXT"
echo ""

# API 호출
echo -e "${YELLOW}3. API 호출 중...${NC}"
RESPONSE=$(curl -s -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -d "{
    \"text\": \"$TEST_TEXT\",
    \"date\": \"$TEST_DATE\"
  }")

# 응답 확인
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ API 호출 성공${NC}\n"
    echo -e "${YELLOW}응답:${NC}"
    echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
    echo ""

    # 상태 코드 확인 (응답에 error가 없으면 성공)
    if echo "$RESPONSE" | grep -q "error"; then
        echo -e "${RED}✗ 오류가 발생했습니다. 위 응답을 확인하세요.${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ 테스트 완료! Airtable에서 레코드를 확인하세요.${NC}"
    fi
else
    echo -e "${RED}✗ API 호출 실패${NC}"
    exit 1
fi

# 로그 확인 안내
echo ""
echo -e "${YELLOW}Lambda 로그를 확인하려면:${NC}"
echo "aws logs tail /aws/lambda/daily-log-automation --follow"
