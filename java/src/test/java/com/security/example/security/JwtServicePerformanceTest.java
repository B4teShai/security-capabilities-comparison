package com.security.example.security;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.*;

class JwtServicePerformanceTest {

    private JwtService jwtService;
    private UserDetails userDetails;
    private static final int ITERATIONS = 1000;

    @BeforeEach
    void setUp() {
        jwtService = new JwtService();
        ReflectionTestUtils.setField(jwtService, "secretKey", "404E635266556A586E3272357538782F413F4428472B4B6250645367566B5970");
        ReflectionTestUtils.setField(jwtService, "jwtExpiration", 86400000L); // 24 hours

        userDetails = new User("testuser", "password", new ArrayList<>());
    }

    @Test
    void measureTokenGenerationPerformance() {
        long totalTime = 0;
        for (int i = 0; i < ITERATIONS; i++) {
            long startTime = System.nanoTime();
            String token = jwtService.generateToken(userDetails);
            long endTime = System.nanoTime();
            totalTime += (endTime - startTime);
        }
        double averageTimeMs = (totalTime / (double) ITERATIONS) / 1_000_000;
        System.out.printf("Average token generation time: %.3f ms%n", averageTimeMs);
        assertTrue(averageTimeMs < 10, "Token generation should be fast");
    }

    @Test
    void measureTokenValidationPerformance() {
        String token = jwtService.generateToken(userDetails);
        long totalTime = 0;
        for (int i = 0; i < ITERATIONS; i++) {
            long startTime = System.nanoTime();
            boolean isValid = jwtService.isTokenValid(token, userDetails);
            long endTime = System.nanoTime();
            totalTime += (endTime - startTime);
            assertTrue(isValid, "Token should be valid");
        }
        double averageTimeMs = (totalTime / (double) ITERATIONS) / 1_000_000;
        System.out.printf("Average token validation time: %.3f ms%n", averageTimeMs);
        assertTrue(averageTimeMs < 5, "Token validation should be fast");
    }

    @Test
    void measureTokenWithExtraClaimsPerformance() {
        Map<String, Object> extraClaims = new HashMap<>();
        extraClaims.put("role", "admin");
        extraClaims.put("permissions", new String[]{"read", "write"});

        long totalTime = 0;
        for (int i = 0; i < ITERATIONS; i++) {
            long startTime = System.nanoTime();
            String token = jwtService.generateToken(extraClaims, userDetails);
            long endTime = System.nanoTime();
            totalTime += (endTime - startTime);
        }
        System.out.println("Total time: " + totalTime);
        double averageTimeMs = (totalTime / (double) ITERATIONS) / 1_000_000;
        System.out.printf("Average token generation with extra claims time: %.3f ms%n", averageTimeMs);
        assertTrue(averageTimeMs < 15, "Token generation with extra claims should be fast");
    }

    @Test
    void measureUsernameExtractionPerformance() {
        String token = jwtService.generateToken(userDetails);
        long totalTime = 0;
        for (int i = 0; i < ITERATIONS; i++) {
            long startTime = System.nanoTime();
            String username = jwtService.extractUsername(token);
            long endTime = System.nanoTime();
            totalTime += (endTime - startTime);
            assertEquals("testuser", username, "Username should match");
        }
        System.out.println("Total time: " + totalTime);
        double averageTimeMs = (totalTime / (double) ITERATIONS) / 1_000_000;
        System.out.printf("Average username extraction time: %.3f ms%n", averageTimeMs);
        assertTrue(averageTimeMs < 3, "Username extraction should be fast");
    }

    @Test
    void measureTokenExpirationCheckPerformance() {
        String token = jwtService.generateToken(userDetails);
        long totalTime = 0;
        for (int i = 0; i < ITERATIONS; i++) {
            long startTime = System.nanoTime();
            boolean isValid = jwtService.isTokenValid(token, userDetails);
            long endTime = System.nanoTime();
            totalTime += (endTime - startTime);
            assertTrue(isValid, "Token should be valid");
        }
        System.out.println("Total time: " + totalTime);
        double averageTimeMs = (totalTime / (double) ITERATIONS) / 1_000_000;
        System.out.printf("Average token expiration check time: %.3f ms%n", averageTimeMs);
        assertTrue(averageTimeMs < 5, "Token expiration check should be fast");
    }
} 

