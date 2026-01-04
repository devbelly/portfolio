#!/bin/bash

# 시나리오 2: 2세대 Root CA 인증서로 인증 실패 재연
# 설정: 서버는 2세대 인증서, 클라이언트는 1세대 truststore
# 예상 결과: SSL Handshake Exception 발생

set -e

PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

echo "=========================================="
echo "시나리오 2: 2세대 Root CA - 인증 실패 재연"
echo "=========================================="
echo ""
echo "설정:"
echo "- 서버: 2세대 인증서 사용"
echo "- 클라이언트: 1세대 truststore만 로드"
echo "- 결과: SSL Handshake Exception 발생"
echo ""

# 환경 변수 설정
export CERT_GEN=gen2
export TRUSTSTORE_PATH=/certs/gen1/truststore.jks

echo "[1/5] 2세대 인증서 확인..."
if [ ! -f "$PROJECT_ROOT/certs/gen2/server.p12" ]; then
    echo "  인증서를 생성하는 중..."
    cd "$PROJECT_ROOT/certs"
    ./generate-certs.sh
fi
echo "✓ 인증서 확인 완료"
echo ""

# 빌드 확인
echo "[2/5] 빌드 확인..."
if [ ! -f "$PROJECT_ROOT/server/target/ssl-server-1.0.0.jar" ]; then
    echo "  서버를 빌드하는 중..."
    cd "$PROJECT_ROOT/server"
    mvn clean package -DskipTests > /dev/null 2>&1
fi
if [ ! -f "$PROJECT_ROOT/client/target/ssl-client-1.0.0.jar" ]; then
    echo "  클라이언트를 빌드하는 중..."
    cd "$PROJECT_ROOT/client"
    mvn clean package > /dev/null 2>&1
fi
echo "✓ 빌드 확인 완료"
echo ""

# Docker Compose 실행
echo "[3/5] Docker 환경 시작..."
cd "$PROJECT_ROOT"

# 이전 컨테이너 정리
podman compose down 2>/dev/null || true

# 서버 시작 (2세대 인증서)
podman compose up --build -d ssl-server
sleep 10

echo "✓ 서버 시작 완료 (2세대 인증서)"
echo ""

# 테스트 실행
echo "[4/5] HTTPS 클라이언트 테스트..."
echo ""

echo "--- JDK 7 클라이언트 (오류 예상) ---"
podman compose run --rm client-jdk7 || true

echo ""
echo "--- JDK 8u242 클라이언트 (오류 예상) ---"
podman compose run --rm client-jdk8 || true

echo ""
echo "[5/5] 테스트 완료"
echo ""
echo "=========================================="
echo "✗ 예상 결과: 두 클라이언트 모두 실패"
echo "=========================================="
echo ""
echo "오류 메시지:"
echo "✗ FAILED: SSL Handshake Exception"
echo "Reason: sun.security.validator.ValidatorException:"
echo "PKIX path building failed:"
echo "unable to find valid certification path to requested target"
echo ""
echo "원인:"
echo "- 서버가 2세대 Root CA로 서명된 인증서 사용"
echo "- 클라이언트는 1세대 Root CA만 truststore에 등록"
echo "- 2세대 Root CA를 신뢰하지 않으므로 SSL 핸드셰이크 실패"
echo ""

# 정리
podman compose down
