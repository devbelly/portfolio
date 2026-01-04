#!/bin/bash

# SSL 인증서 생성 스크립트
# 1세대/2세대 Root CA 시뮬레이션을 위한 자체 서명 인증서 생성

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 1세대 Root CA 생성
echo "=========================================="
echo "1세대 Root CA 인증서 생성 중..."
echo "=========================================="

mkdir -p "$SCRIPT_DIR/gen1"
cd "$SCRIPT_DIR/gen1"

# Root CA 개인키 생성
echo "[1/7] Root CA 개인키 생성..."
openssl genrsa -out root-ca.key 2048 2>/dev/null

# Root CA 인증서 생성
echo "[2/7] Root CA 인증서 생성..."
openssl req -x509 -new -nodes -key root-ca.key \
    -sha256 -days 3650 -out root-ca.crt \
    -subj "/C=KR/O=Gen1 Root CA/CN=Gen1 Root CA" 2>/dev/null

# 중간 CA 개인키 생성
echo "[3/7] 중간 CA 개인키 생성..."
openssl genrsa -out intermediate-ca.key 2048 2>/dev/null

# 중간 CA 인증서 서명 요청 생성
echo "[4/7] 중간 CA 인증서 서명 요청 생성..."
openssl req -new -key intermediate-ca.key \
    -out intermediate-ca.csr \
    -subj "/C=KR/O=Gen1 Intermediate CA/CN=Gen1 Intermediate CA" 2>/dev/null

# 중간 CA 확장 설정 파일 생성
cat > intermediate-ca-ext.cnf <<EOF
basicConstraints = critical, CA:TRUE
keyUsage = critical, keyCertSign, cRLSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
EOF

# 중간 CA 인증서 생성 (Root CA로 서명)
echo "[5/7] 중간 CA 인증서 생성..."
openssl x509 -req -in intermediate-ca.csr \
    -CA root-ca.crt -CAkey root-ca.key \
    -CAcreateserial -out intermediate-ca.crt \
    -days 1825 -sha256 -extfile intermediate-ca-ext.cnf 2>/dev/null

# 서버 인증서용 개인키 생성
echo "[6/7] 서버 인증서 생성..."
openssl genrsa -out server.key 2048 2>/dev/null

# 서버 인증서 서명 요청 생성
openssl req -new -key server.key \
    -out server.csr \
    -subj "/C=KR/O=Example/CN=localhost" 2>/dev/null

# SAN (Subject Alternative Name) 확장 설정
cat > server-ext.cnf <<EOF
subjectAltName = DNS:localhost,DNS:ssl-server,IP:127.0.0.1
EOF

# 서버 인증서 생성 (중간 CA로 서명)
openssl x509 -req -in server.csr \
    -CA intermediate-ca.crt -CAkey intermediate-ca.key \
    -CAcreateserial -out server.crt \
    -days 365 -sha256 -extfile server-ext.cnf 2>/dev/null

# PKCS12 형식 생성 (Spring Boot용)
cat server.crt intermediate-ca.crt > server-chain.crt
openssl pkcs12 -export -in server-chain.crt \
    -inkey server.key -out server.p12 \
    -name server -password pass:changeit 2>/dev/null

# Truststore 생성 (클라이언트용)
keytool -import -trustcacerts -alias gen1-root \
    -file root-ca.crt -keystore truststore.jks \
    -storepass changeit -noprompt 2>/dev/null

# 임시 파일 정리
rm -f intermediate-ca.csr intermediate-ca-ext.cnf server.csr server-ext.cnf server-chain.crt *.srl

echo "✓ 1세대 인증서 생성 완료"
echo ""

# 2세대 Root CA 생성
echo "=========================================="
echo "2세대 Root CA 인증서 생성 중..."
echo "=========================================="

mkdir -p "$SCRIPT_DIR/gen2"
cd "$SCRIPT_DIR/gen2"

# Root CA 개인키 생성
echo "[1/7] Root CA 개인키 생성..."
openssl genrsa -out root-ca.key 2048 2>/dev/null

# Root CA 인증서 생성
echo "[2/7] Root CA 인증서 생성..."
openssl req -x509 -new -nodes -key root-ca.key \
    -sha256 -days 3650 -out root-ca.crt \
    -subj "/C=KR/O=Gen2 Root CA/CN=Gen2 Root CA" 2>/dev/null

# 중간 CA 개인키 생성
echo "[3/7] 중간 CA 개인키 생성..."
openssl genrsa -out intermediate-ca.key 2048 2>/dev/null

# 중간 CA 인증서 서명 요청 생성
echo "[4/7] 중간 CA 인증서 서명 요청 생성..."
openssl req -new -key intermediate-ca.key \
    -out intermediate-ca.csr \
    -subj "/C=KR/O=Gen2 Intermediate CA/CN=Gen2 Intermediate CA" 2>/dev/null

# 중간 CA 확장 설정 파일 생성
cat > intermediate-ca-ext.cnf <<EOF
basicConstraints = critical, CA:TRUE
keyUsage = critical, keyCertSign, cRLSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
EOF

# 중간 CA 인증서 생성 (Root CA로 서명)
echo "[5/7] 중간 CA 인증서 생성..."
openssl x509 -req -in intermediate-ca.csr \
    -CA root-ca.crt -CAkey root-ca.key \
    -CAcreateserial -out intermediate-ca.crt \
    -days 1825 -sha256 -extfile intermediate-ca-ext.cnf 2>/dev/null

# 서버 인증서용 개인키 생성
echo "[6/7] 서버 인증서 생성..."
openssl genrsa -out server.key 2048 2>/dev/null

# 서버 인증서 서명 요청 생성
openssl req -new -key server.key \
    -out server.csr \
    -subj "/C=KR/O=Example/CN=localhost" 2>/dev/null

# SAN (Subject Alternative Name) 확장 설정
cat > server-ext.cnf <<EOF
subjectAltName = DNS:localhost,DNS:ssl-server,IP:127.0.0.1
EOF

# 서버 인증서 생성 (중간 CA로 서명)
openssl x509 -req -in server.csr \
    -CA intermediate-ca.crt -CAkey intermediate-ca.key \
    -CAcreateserial -out server.crt \
    -days 365 -sha256 -extfile server-ext.cnf 2>/dev/null

# PKCS12 형식 생성 (Spring Boot용)
cat server.crt intermediate-ca.crt > server-chain.crt
openssl pkcs12 -export -in server-chain.crt \
    -inkey server.key -out server.p12 \
    -name server -password pass:changeit 2>/dev/null

# Truststore 생성 (클라이언트용)
keytool -import -trustcacerts -alias gen2-root \
    -file root-ca.crt -keystore truststore.jks \
    -storepass changeit -noprompt 2>/dev/null

# 임시 파일 정리
rm -f intermediate-ca.csr intermediate-ca-ext.cnf server.csr server-ext.cnf server-chain.crt *.srl

echo "✓ 2세대 인증서 생성 완료"
echo ""

echo "=========================================="
echo "✓ 모든 인증서 생성 완료!"
echo "=========================================="
