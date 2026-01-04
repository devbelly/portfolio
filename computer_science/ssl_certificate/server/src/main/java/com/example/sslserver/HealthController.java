package com.example.sslserver;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

/**
 * SSL 서버 헬스 체크 컨트롤러
 */
@RestController
public class HealthController {

    /**
     * 서버 상태 조회 엔드포인트
     */
    @GetMapping("/health")
    public Map<String, Object> health() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "UP");
        response.put("timestamp", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
        response.put("message", "SSL Server is running");
        return response;
    }

    /**
     * 현재 적용된 인증서 세대 조회
     */
    @GetMapping("/cert-info")
    public Map<String, String> certInfo() {
        Map<String, String> info = new HashMap<>();
        String generation = System.getenv("CERT_GENERATION");
        if (generation == null) {
            generation = "gen1";
        }
        info.put("generation", generation);
        info.put("description", "현재 사용 중인 인증서 세대");
        return info;
    }

}
