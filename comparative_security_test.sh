#!/bin/bash

# =============================================================================
# Comparative Security Analysis Script
# 
# This script performs a comprehensive security analysis of web applications
# implemented in different programming languages (Golang, TypeScript, and Java).
# It tests various security aspects including input validation, SQL injection,
# JWT security, headers, error handling, CSRF, rate limiting, and dependencies.
#
# Usage:
#   ./comparative_security_test.sh
#   GOLANG_PORT=8081 TYPESCRIPT_PORT=3001 JAVA_PORT=8082 ./comparative_security_test.sh
# =============================================================================

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

# Terminal colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Service ports with fallback defaults
GOLANG_PORT=${GOLANG_PORT:-8080}
TYPESCRIPT_PORT=${TYPESCRIPT_PORT:-3000}
JAVA_PORT=${JAVA_PORT:-8081}

# Test results file
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
RESULT_FILE="language_security_comparison_${TIMESTAMP}.log"

# Test results storage
declare -a golang_results
declare -a typescript_results
declare -a java_results

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

# Check if a service is running and accessible
check_service() {
    local port=$1
    local name=$2
    
    echo -e "${BLUE}Checking $name service on port $port...${NC}"
    
    if ! curl -s "http://localhost:$port/health" > /dev/null; then
        echo -e "${RED}Error: $name service is not running on port $port${NC}"
        return 1
    fi
    
    echo -e "${GREEN}$name service is running${NC}"
    return 0
}

# Make HTTP requests with proper error handling
make_request() {
    local url=$1
    local method=${2:-GET}
    local data=$3
    local headers=$4
    
    local response
    local status_code
    
    # Build curl command based on parameters
    if [ -n "$data" ]; then
        response=$(curl -f -s -X "$method" "$url" \
            -H "Content-Type: application/json" \
            -H "$headers" \
            -d "$data" \
            -w "\nStatus: %{http_code}")
    else
        response=$(curl -f -s -X "$method" "$url" \
            -H "$headers" \
            -w "\nStatus: %{http_code}")
    fi
    
    # Check if request was successful
    status_code=$?
    if [ $status_code -ne 0 ]; then
        echo -e "${RED}Error: Request failed with status code $status_code${NC}"
        return 1
    fi
    
    echo "$response"
    return 0
}

# Determine security status based on failure count
get_security_status() {
    local failures=$1
    
    if [ $failures -eq 0 ]; then
        echo "✅"
    elif [ $failures -le 2 ]; then
        echo "⚠️"
    else
        echo "❌"
    fi
}

# Generate descriptive notes based on test results
get_notes() {
    local test=$1
    local failures=$2
    
    case $test in
        "input_validation")
            if [ $failures -eq 0 ]; then
                echo "Strong validation framework"
            elif [ $failures -le 2 ]; then
                echo "Basic validation present"
            else
                echo "Manual validation required"
            fi
            ;;
        "sql_injection")
            if [ $failures -eq 0 ]; then
                echo "All SQL injection attempts blocked"
            else
                echo "Vulnerable to SQL injection"
            fi
            ;;
        "jwt_security")
            if [ $failures -eq 0 ]; then
                echo "Proper token validation"
            else
                echo "Invalid tokens accepted"
            fi
            ;;
        "security_headers")
            if [ $failures -eq 0 ]; then
                echo "All security headers present"
            elif [ $failures -le 2 ]; then
                echo "Most security headers present"
            else
                echo "Missing critical security headers"
            fi
            ;;
        "error_handling")
            if [ $failures -eq 0 ]; then
                echo "Secure error handling"
            else
                echo "Information disclosure in errors"
            fi
            ;;
        "csrf")
            if [ $failures -eq 0 ]; then
                echo "CSRF protection present"
            else
                echo "CSRF protection missing"
            fi
            ;;
        "rate_limiting")
            if [ $failures -eq 0 ]; then
                echo "Rate limiting implemented"
            else
                echo "Rate limiting not implemented"
            fi
            ;;
        "dependency_vulnerability")
            if [ $failures -eq 0 ]; then
                echo "No known vulnerable dependencies"
            else
                echo "Vulnerable dependencies found"
            fi
            ;;
    esac
}

# -----------------------------------------------------------------------------
# Test Functions
# -----------------------------------------------------------------------------

# Test input validation
test_input_validation() {
    local name=$1
    local port=$2
    local failures=0
    
    echo -e "\n### 1.1 $name Input Validation\n" >> "$RESULT_FILE"
    
    # Test payloads for various validation scenarios
    local input_payloads=(
        '{"username":"admin","password":"short"}'
        '{"username":"","password":""}'
        '{"username":null,"password":null}'
        '{"username":12345,"password":54321}'
        '{"username":"<test@example.com>","password":"password123"}'
    )
    
    for payload in "${input_payloads[@]}"; do
        response=$(make_request "http://localhost:$port/register" "POST" "$payload")
        
        if [ $? -eq 0 ]; then
            echo -e "Test payload: $payload" >> "$RESULT_FILE"
            echo -e "Response: $response\n" >> "$RESULT_FILE"
            
            if [[ "$response" =~ "error" || "$response" =~ "Status: 200" ]]; then
                failures=$((failures + 1))
            fi
        fi
    done
    
    echo $failures
}

# Test SQL injection protection
test_sql_injection() {
    local name=$1
    local port=$2
    local failures=0
    
    echo -e "\n### 2.1 $name SQL Injection Protection\n" >> "$RESULT_FILE"
    
    # SQL injection test payloads
    local sqli_payloads=(
        "{\"username\":\"user' OR '1'='1\",\"password\":\"password123\"}"
        "{\"username\":\"user'; DROP TABLE users; --\",\"password\":\"password123\"}"
        "{\"username\":\"admin' UNION SELECT * FROM users; --\",\"password\":\"password123\"}"
    )
    
    for payload in "${sqli_payloads[@]}"; do
        # Check database state before and after injection attempt
        initial_state=$(make_request "http://localhost:$port/db-state")
        response=$(make_request "http://localhost:$port/login" "POST" "$payload")
        final_state=$(make_request "http://localhost:$port/db-state")
        
        if [ $? -eq 0 ]; then
            echo -e "Test payload: $payload" >> "$RESULT_FILE"
            echo -e "Response: $response" >> "$RESULT_FILE"
            echo -e "Database state changed: $([ "$initial_state" != "$final_state" ] && echo "Yes" || echo "No")\n" >> "$RESULT_FILE"
            
            if [[ "$response" =~ "success" || "$response" =~ "logged in" || "$initial_state" != "$final_state" ]]; then
                failures=$((failures + 1))
            fi
        fi
    done
    
    echo $failures
}

# ... [Similar test functions for other security aspects] ...

# -----------------------------------------------------------------------------
# Main Execution
# -----------------------------------------------------------------------------

# Initialize test report
cat << EOF > "$RESULT_FILE"
================================================================================================
                    Comparative Security Analysis of Golang, TypeScript, and Java
                           Test Date: $(date)
================================================================================================

Configuration:
- Golang (port $GOLANG_PORT)
- TypeScript (port $TYPESCRIPT_PORT)
- Java Spring Boot (port $JAVA_PORT)

The following critical security tests were performed:
1. Input Validation & Sanitization
2. SQL Injection Protection
3. JWT Token Security
4. Security Headers Implementation
5. Error Handling & Information Disclosure
6. CSRF Protection
7. Rate Limiting
8. Dependency Vulnerability Scanning

EOF

echo -e "${YELLOW}Starting critical security comparison test...${NC}"

# Verify all services are running
echo -e "${BLUE}Checking service availability...${NC}"
for port in $GOLANG_PORT $TYPESCRIPT_PORT $JAVA_PORT; do
    case $port in
        $GOLANG_PORT) check_service "$port" "Golang" || exit 1 ;;
        $TYPESCRIPT_PORT) check_service "$port" "TypeScript" || exit 1 ;;
        $JAVA_PORT) check_service "$port" "Java" || exit 1 ;;
    esac
done

# Run tests for each implementation
for impl in "Golang:$GOLANG_PORT" "TypeScript:$TYPESCRIPT_PORT" "Java:$JAVA_PORT"; do
    IFS=":" read -r name port <<< "$impl"
    
    echo -e "${BLUE}Testing $name implementation...${NC}"
    
    # Run tests in parallel where appropriate
    test_input_validation "$name" "$port" &
    input_validation_pid=$!
    
    test_sql_injection "$name" "$port" &
    sql_injection_pid=$!
    
    # ... [Run other tests] ...
    
    # Wait for parallel tests to complete
    wait $input_validation_pid $sql_injection_pid
    
    # Store results
    case $name in
        "Golang")
            golang_results[0]=$input_validation_result
            golang_results[1]=$sql_injection_result
            # ... [Store other results] ...
            ;;
        "TypeScript")
            typescript_results[0]=$input_validation_result
            typescript_results[1]=$sql_injection_result
            # ... [Store other results] ...
            ;;
        "Java")
            java_results[0]=$input_validation_result
            java_results[1]=$sql_injection_result
            # ... [Store other results] ...
            ;;
    esac
done

# Generate analysis report
echo -e "${BLUE}Generating analysis report...${NC}"
# ... [Report generation code] ...

echo -e "${GREEN}Security test complete! Results saved to $RESULT_FILE${NC}" 