package com.example.sslserver;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * SSL Root CA 1세대-2세대 전환 문제 재연 프로젝트
 * HTTPS 서버 애플리케이션
 */
@SpringBootApplication
public class SslServerApplication {

    public static void main(String[] args) {
        SpringApplication.run(SslServerApplication.class, args);
    }

}
