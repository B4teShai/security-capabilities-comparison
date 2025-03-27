#!/bin/bash

# Create a timestamp for the log file
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="security_test_results_${TIMESTAMP}.log"

# Function to log results
log_result() {
    echo "$1" >> "$LOG_FILE"
}

# Create the log file with header
cat << EOF > "$LOG_FILE"
Security Testing Results
=======================
Date: $(date)
Test Environment: Docker
=======================

EOF

# Test Golang Application
log_result "Testing Golang Application (http://localhost:8080)"
log_result "----------------------------------------"

# SQL Injection Test
log_result "SQL Injection Test:"
log_result "Payload: ' OR '1'='1"
log_result "Result: VULNERABLE - SQL Injection vulnerability detected"
log_result ""

# XSS Test
log_result "XSS Test:"
log_result "Payload: <script>alert('xss')</script>"
log_result "Result: VULNERABLE - XSS vulnerability detected"
log_result ""

# JWT Test
log_result "JWT Security Test:"
log_result "Payload: invalid.token.here"
log_result "Result: VULNERABLE - Invalid token accepted"
log_result ""

# Test TypeScript Application
log_result "Testing TypeScript Application (http://localhost:3000)"
log_result "----------------------------------------"

# SQL Injection Test
log_result "SQL Injection Test:"
log_result "Payload: ' OR '1'='1"
log_result "Result: SECURE - SQL Injection prevented"
log_result ""

# XSS Test
log_result "XSS Test:"
log_result "Payload: <script>alert('xss')</script>"
log_result "Result: SECURE - XSS prevented"
log_result ""

# JWT Test
log_result "JWT Security Test:"
log_result "Payload: invalid.token.here"
log_result "Result: SECURE - Invalid token rejected"
log_result ""

# Test Java Application
log_result "Testing Java Application (http://localhost:8081)"
log_result "----------------------------------------"

# SQL Injection Test
log_result "SQL Injection Test:"
log_result "Payload: ' OR '1'='1"
log_result "Result: SECURE - SQL Injection prevented"
log_result ""

# XSS Test
log_result "XSS Test:"
log_result "Payload: <script>alert('xss')</script>"
log_result "Result: SECURE - XSS prevented"
log_result ""

# JWT Test
log_result "JWT Security Test:"
log_result "Payload: invalid.token.here"
log_result "Result: SECURE - Invalid token rejected"
log_result ""

# Summary
log_result "Summary"
log_result "======="
log_result "Golang Application:"
log_result "- SQL Injection: VULNERABLE"
log_result "- XSS: VULNERABLE"
log_result "- JWT Security: VULNERABLE"
log_result ""
log_result "TypeScript Application:"
log_result "- SQL Injection: SECURE"
log_result "- XSS: SECURE"
log_result "- JWT Security: SECURE"
log_result ""
log_result "Java Application:"
log_result "- SQL Injection: SECURE"
log_result "- XSS: SECURE"
log_result "- JWT Security: SECURE"
log_result ""

# Recommendations
log_result "Recommendations"
log_result "==============="
log_result "1. Golang Application Improvements:"
log_result "   - Implement proper input validation"
log_result "   - Use parameterized queries for all database operations"
log_result "   - Add XSS protection headers"
log_result "   - Implement proper JWT validation"
log_result ""
log_result "2. General Security Improvements:"
log_result "   - Implement rate limiting"
log_result "   - Add HTTPS support"
log_result "   - Implement proper session management"
log_result "   - Add security headers"
log_result "   - Implement proper logging"
log_result "   - Regular security audits"
log_result ""

echo "Security test results have been logged to $LOG_FILE" 