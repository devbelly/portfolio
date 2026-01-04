package com.example.sslclient;

import javax.net.ssl.*;
import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.net.URL;
import java.security.KeyStore;

/**
 * SSL Root CA 1세대-2세대 전환 문제 재연 프로젝트
 * HTTPS 클라이언트 (JDK 7, JDK 8u251 이하 호환)
 */
public class HttpsClient {

    public static void main(String[] args) {
        String serverUrl = System.getenv("SERVER_URL");
        String truststorePath = System.getenv("TRUSTSTORE_PATH");
        String truststorePassword = System.getenv("TRUSTSTORE_PASSWORD");

        // 기본값 설정
        if (serverUrl == null || serverUrl.isEmpty()) {
            serverUrl = "https://ssl-server:8443/health";
        }
        if (truststorePassword == null || truststorePassword.isEmpty()) {
            truststorePassword = "changeit";
        }

        // 출력
        System.out.println("=== SSL Client Test ===");
        System.out.println("Java Version: " + System.getProperty("java.version"));
        System.out.println("Server URL: " + serverUrl);
        if (truststorePath != null && !truststorePath.isEmpty()) {
            System.out.println("Truststore: " + truststorePath);
        } else {
            System.out.println("Truststore: JDK 기본 CA");
        }
        System.out.println("========================\n");

        try {
            // Truststore가 지정된 경우 커스텀 truststore 로드
            if (truststorePath != null && !truststorePath.isEmpty()) {
                System.out.println("Custom truststore를 로드하는 중...");
                KeyStore trustStore = KeyStore.getInstance("JKS");
                FileInputStream fis = new FileInputStream(truststorePath);
                trustStore.load(fis, truststorePassword.toCharArray());
                fis.close();

                TrustManagerFactory tmf = TrustManagerFactory.getInstance(
                    TrustManagerFactory.getDefaultAlgorithm());
                tmf.init(trustStore);

                SSLContext sslContext = SSLContext.getInstance("TLS");
                sslContext.init(null, tmf.getTrustManagers(), null);

                HttpsURLConnection.setDefaultSSLSocketFactory(
                    sslContext.getSocketFactory());
                System.out.println("✓ Truststore 로드 완료\n");
            }

            // HTTPS 요청 수행
            System.out.println("HTTPS 서버에 요청을 보내는 중...");
            URL url = new URL(serverUrl);
            HttpsURLConnection conn = (HttpsURLConnection) url.openConnection();
            conn.setRequestMethod("GET");
            conn.setConnectTimeout(5000);
            conn.setReadTimeout(5000);

            // 응답 코드 확인
            int responseCode = conn.getResponseCode();
            System.out.println("Response Code: " + responseCode);

            // 응답 본문 읽기
            BufferedReader in = new BufferedReader(
                new InputStreamReader(conn.getInputStream()));
            String inputLine;
            StringBuilder response = new StringBuilder();

            while ((inputLine = in.readLine()) != null) {
                response.append(inputLine);
            }
            in.close();

            System.out.println("Response Body: " + response.toString());
            System.out.println("\n✓ SUCCESS: HTTPS 연결 성공!");
            System.out.println("인증서 검증이 정상적으로 완료되었습니다.");

        } catch (SSLHandshakeException e) {
            System.err.println("\n✗ FAILED: SSL Handshake Exception");
            System.err.println("Reason: " + e.getMessage());
            System.err.println("\n이 오류는 다음 상황에서 발생합니다:");
            System.err.println("1. 서버 인증서가 신뢰되지 않음 (Root CA가 truststore에 없음)");
            System.err.println("2. 구버전 JDK가 새로운 Root CA를 인식하지 못함");
            System.err.println("3. 인증서 체인이 불완전함");
            System.err.println("\n" + e.getClass().getName());
            e.printStackTrace();
            System.exit(1);

        } catch (Exception e) {
            System.err.println("\n✗ FAILED: " + e.getClass().getName());
            System.err.println("Message: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }

}
