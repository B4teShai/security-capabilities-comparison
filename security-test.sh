#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Starting Security Testing Suite${NC}"

# Function to test SQL injection
test_sql_injection() {
    local url=$1
    local name=$2
    echo -e "\n${YELLOW}Testing SQL Injection on $name${NC}"
    
    # Test payloads
    local payloads=(
        "' OR '1'='1"
        "'; DROP TABLE users; --"
        "' UNION SELECT * FROM users; --"
    )
    
    for payload in "${payloads[@]}"; do
        curl -s -X POST "$url/register" \
            -H "Content-Type: application/json" \
            -d "{\"username\": \"$payload\", \"password\": \"test123\"}" \
            > /dev/null
        
        if [ $? -eq 0 ]; then
            echo -e "${RED}Potential SQL Injection vulnerability found with payload: $payload${NC}"
        else
            echo -e "${GREEN}SQL Injection test passed for payload: $payload${NC}"
        fi
    done
}

# Function to test XSS
test_xss() {
    local url=$1
    local name=$2
    echo -e "\n${YELLOW}Testing XSS on $name${NC}"
    
    # Test payloads
    local payloads=(
        "<script>alert('xss')</script>"
        "<img src=x onerror=alert('xss')>"
        "javascript:alert('xss')"
    )
    
    for payload in "${payloads[@]}"; do
        curl -s -X POST "$url/register" \
            -H "Content-Type: application/json" \
            -d "{\"username\": \"$payload\", \"password\": \"test123\"}" \
            > /dev/null
        
        if [ $? -eq 0 ]; then
            echo -e "${RED}Potential XSS vulnerability found with payload: $payload${NC}"
        else
            echo -e "${GREEN}XSS test passed for payload: $payload${NC}"
        fi
    done
}

# Function to test JWT vulnerabilities
test_jwt() {
    local url=$1
    local name=$2
    echo -e "\n${YELLOW}Testing JWT Security on $name${NC}"
    
    # Test invalid token
    curl -s -X GET "$url/protected" \
        -H "Authorization: Bearer invalid.token.here" \
        > /dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${RED}Potential JWT vulnerability found: Invalid token accepted${NC}"
    else
        echo -e "${GREEN}JWT test passed: Invalid token rejected${NC}"
    fi
}

# Test all applications
echo -e "\n${YELLOW}Testing Golang Application${NC}"
test_sql_injection "http://localhost:8080" "Golang"
test_xss "http://localhost:8080" "Golang"
test_jwt "http://localhost:8080" "Golang"

echo -e "\n${YELLOW}Testing TypeScript Application${NC}"
test_sql_injection "http://localhost:3000" "TypeScript"
test_xss "http://localhost:3000" "TypeScript"
test_jwt "http://localhost:3000" "TypeScript"

echo -e "\n${YELLOW}Testing Java Application${NC}"
test_sql_injection "http://localhost:8081" "Java"
test_xss "http://localhost:8081" "Java"
test_jwt "http://localhost:8081" "Java"

echo -e "\n${YELLOW}Security Testing Complete${NC}" 