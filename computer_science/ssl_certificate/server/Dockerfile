# Spring Boot HTTPS 서버 Docker 이미지
# OpenJDK 8 알파인 기반

# Dockerfile 수정
FROM eclipse-temurin:8-jdk

WORKDIR /app

# Maven 빌드 결과물 복사
COPY target/ssl-server-1.0.0.jar app.jar

# 인증서 디렉토리 생성
RUN mkdir /certs

# 현재 사용 중인 인증서 세대 (gen1 또는 gen2)
ENV CERT_GENERATION=gen1

# HTTPS 포트 노출
EXPOSE 8443

# 애플리케이션 실행
ENTRYPOINT ["java", "-jar", "app.jar"]
