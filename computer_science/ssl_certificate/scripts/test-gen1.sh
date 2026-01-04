#!/bin/bash

# 시나리오 1: 1세대 Root CA 인증서로 정상 동작 확인
# 예상 결과: 클라이언트가 서버의 인증서를 신뢰하고 HTTPS 연결 성공

set -e

PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

echo "=========================================="
echo "시나리오 1: 1세대 Root CA 인증서 테스트"
echo "=========================================="
echo ""

# 현재 디렉토리 확인
echo "프로젝트 경로: $PROJECT_ROOT"
echo ""

# 환경 변수 설정
export CERT_GEN=gen1
export TRUSTSTORE_PATH=/certs/gen1/truststore.jks

echo "[1/5] 프로젝트 구조 확인..."
if [ ! -f "$PROJECT_ROOT/server/pom.xml" ]; then
    echo "✗ 오류: server/pom.xml을 찾을 수 없습니다"
    exit 1
fi
if [ ! -f "$PROJECT_ROOT/client/pom.xml" ]; then
    echo "✗ 오류: client/pom.xml을 찾을 수 없습니다"
    exit 1
fi
echo "✓ 프로젝트 구조 확인 완료"
echo ""

# 1세대 인증서 생성 확인
echo "[2/5] 1세대 인증서 확인..."
if [ ! -f "$PROJECT_ROOT/certs/gen1/server.p12" ]; then
    echo "  인증서를 생성하는 중..."
    cd "$PROJECT_ROOT/certs"
    ./generate-certs.sh
fi
echo "✓ 인증서 확인 완료"
echo ""

# Maven 빌드 (이미 완료된 경우 스킵)
echo "[3/5] 빌드 확인..."
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
echo "[4/5] Docker 환경 시작..."
cd "$PROJECT_ROOT"

# 이전 컨테이너 정리
podman compose down 2>/dev/null || true

# 서버 시작
podman compose up --build -d ssl-server
sleep 10

echo "✓ 서버 시작 완료"
echo ""

# 테스트 실행
echo "[5/5] HTTPS 클라이언트 테스트..."
echo ""

echo "--- JDK 7 클라이언트 ---"
podman compose run --rm client-jdk7

echo ""
echo "--- JDK 8u242 클라이언트 ---"
podman compose run --rm client-jdk8

echo ""
echo "=========================================="
echo "✓ 시나리오 1 테스트 완료"
echo "=========================================="
echo ""
echo "예상 결과:"
echo "- 두 클라이언트 모두 성공 (✓ SUCCESS)"
echo "- 1세대 Root CA가 truststore에 등록되어 있음"
echo "- Response Code: 200"
echo "- SSL 핸드셰이크 성공"
echo ""

# 정리
podman compose down
