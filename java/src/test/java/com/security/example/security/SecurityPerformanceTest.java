package com.security.example.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.test.util.ReflectionTestUtils;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class SecurityPerformanceTest {

    private JwtService jwtService;
    private JwtAuthenticationFilter jwtAuthenticationFilter;
    private UserDetailsService userDetailsService;
    private UserDetails userDetails;
    private static final int ITERATIONS = 1000;

    @BeforeEach
    void setUp() {
        jwtService = new JwtService();
        ReflectionTestUtils.setField(jwtService, "secretKey", "404E635266556A586E3272357538782F413F4428472B4B6250645367566B5970");
        ReflectionTestUtils.setField(jwtService, "jwtExpiration", 86400000L); // 24 hours

        userDetails = new User("testuser", "password", new ArrayList<>());
        userDetailsService = mock(UserDetailsService.class);
        when(userDetailsService.loadUserByUsername("testuser")).thenReturn(userDetails);

        jwtAuthenticationFilter = new JwtAuthenticationFilter(jwtService, userDetailsService);
    }

    @Test
    void measureFullAuthenticationFlowPerformance() throws ServletException, IOException {
        String token = jwtService.generateToken(userDetails);
        HttpServletRequest request = mock(HttpServletRequest.class);
        HttpServletResponse response = mock(HttpServletResponse.class);
        FilterChain filterChain = mock(FilterChain.class);
        when(request.getHeader("Authorization")).thenReturn("Bearer " + token);

        long totalTime = 0;
        for (int i = 0; i < ITERATIONS; i++) {
            SecurityContextHolder.clearContext();
            long startTime = System.nanoTime();
            jwtAuthenticationFilter.doFilterInternal(request, response, filterChain);
            long endTime = System.nanoTime();
            totalTime += (endTime - startTime);
            assertNotNull(SecurityContextHolder.getContext().getAuthentication(), "Authentication should be set");
        }
        double averageTimeMs = (totalTime / (double) ITERATIONS) / 1_000_000;
        System.out.printf("Average full authentication flow time: %.3f ms%n", averageTimeMs);
        assertTrue(averageTimeMs < 20, "Full authentication flow should be fast");
    }

    @Test
    void measureInvalidTokenHandlingPerformance() throws ServletException, IOException {
        String invalidToken = "invalid.token.here";
        HttpServletRequest request = mock(HttpServletRequest.class);
        HttpServletResponse response = mock(HttpServletResponse.class);
        FilterChain filterChain = mock(FilterChain.class);
        when(request.getHeader("Authorization")).thenReturn("Bearer " + invalidToken);

        long totalTime = 0;
        for (int i = 0; i < ITERATIONS; i++) {
            SecurityContextHolder.clearContext();
            long startTime = System.nanoTime();
            jwtAuthenticationFilter.doFilterInternal(request, response, filterChain);
            long endTime = System.nanoTime();
            totalTime += (endTime - startTime);
            assertNull(SecurityContextHolder.getContext().getAuthentication(), "Authentication should not be set for invalid token");
        }
        double averageTimeMs = (totalTime / (double) ITERATIONS) / 1_000_000;
        System.out.printf("Average invalid token handling time: %.3f ms%n", averageTimeMs);
        assertTrue(averageTimeMs < 10, "Invalid token handling should be fast");
    }

    @Test
    void measureMissingTokenHandlingPerformance() throws ServletException, IOException {
        HttpServletRequest request = mock(HttpServletRequest.class);
        HttpServletResponse response = mock(HttpServletResponse.class);
        FilterChain filterChain = mock(FilterChain.class);
        when(request.getHeader("Authorization")).thenReturn(null);

        long totalTime = 0;
        for (int i = 0; i < ITERATIONS; i++) {
            SecurityContextHolder.clearContext();
            long startTime = System.nanoTime();
            jwtAuthenticationFilter.doFilterInternal(request, response, filterChain);
            long endTime = System.nanoTime();
            totalTime += (endTime - startTime);
            assertNull(SecurityContextHolder.getContext().getAuthentication(), "Authentication should not be set for missing token");
        }
        double averageTimeMs = (totalTime / (double) ITERATIONS) / 1_000_000;
        System.out.printf("Average missing token handling time: %.3f ms%n", averageTimeMs);
        assertTrue(averageTimeMs < 5, "Missing token handling should be very fast");
    }

    @Test
    void measureConcurrentAuthenticationPerformance() throws ServletException, IOException {
        String token = jwtService.generateToken(userDetails);
        HttpServletRequest request = mock(HttpServletRequest.class);
        HttpServletResponse response = mock(HttpServletResponse.class);
        FilterChain filterChain = mock(FilterChain.class);
        when(request.getHeader("Authorization")).thenReturn("Bearer " + token);

        // Simulate concurrent requests
        int concurrentRequests = 10;
        long totalTime = 0;
        for (int i = 0; i < ITERATIONS; i++) {
            SecurityContextHolder.clearContext();
            long startTime = System.nanoTime();
            for (int j = 0; j < concurrentRequests; j++) {
                jwtAuthenticationFilter.doFilterInternal(request, response, filterChain);
            }
            long endTime = System.nanoTime();
            totalTime += (endTime - startTime);
            assertNotNull(SecurityContextHolder.getContext().getAuthentication(), "Authentication should be set");
        }
        double averageTimeMs = (totalTime / (double) ITERATIONS) / 1_000_000;
        System.out.printf("Average concurrent authentication time (10 requests): %.3f ms%n", averageTimeMs);
        assertTrue(averageTimeMs < 100, "Concurrent authentication should be reasonably fast");
    }

    @Test
    void measureTokenExpirationPerformance() throws ServletException, IOException {
        // Generate a token with very short expiration
        ReflectionTestUtils.setField(jwtService, "jwtExpiration", 1000L); // 1 second
        String token = jwtService.generateToken(userDetails);
        ReflectionTestUtils.setField(jwtService, "jwtExpiration", 86400000L); // Reset to 24 hours

        HttpServletRequest request = mock(HttpServletRequest.class);
        HttpServletResponse response = mock(HttpServletResponse.class);
        FilterChain filterChain = mock(FilterChain.class);
        when(request.getHeader("Authorization")).thenReturn("Bearer " + token);

        // Wait for token to expire
        try {
            Thread.sleep(1100);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        long totalTime = 0;
        for (int i = 0; i < ITERATIONS; i++) {
            SecurityContextHolder.clearContext();
            long startTime = System.nanoTime();
            jwtAuthenticationFilter.doFilterInternal(request, response, filterChain);
            long endTime = System.nanoTime();
            totalTime += (endTime - startTime);
            assertNull(SecurityContextHolder.getContext().getAuthentication(), "Authentication should not be set for expired token");
        }
        double averageTimeMs = (totalTime / (double) ITERATIONS) / 1_000_000;
        System.out.printf("Average expired token handling time: %.3f ms%n", averageTimeMs);
        assertTrue(averageTimeMs < 10, "Expired token handling should be fast");
    }
} 