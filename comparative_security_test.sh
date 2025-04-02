#!/bin/bash

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default port 
GOLANG_PORT=${GOLANG_PORT:-8080}
TYPESCRIPT_PORT=${TYPESCRIPT_PORT:-3000}
JAVA_PORT=${JAVA_PORT:-8081}

# Create log file
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
RESULT_FILE="аюулгүй_байдлын_харьцуулалт_${TIMESTAMP}.log"

# Test results
declare -A results

# Function to check if a service is running
check_service() {
    local port=$1
    local name=$2
    if ! curl -s -f "http://localhost:$port/health" > /dev/null; then
        echo -e "${RED}Алдаа: $name үйлчилгээ $port портод ажиллахгүй байна${NC}"
        return 1
    fi
    return 0
}

# error handling
make_request() {
    local url=$1
    local method=${2:-GET}
    local data=$3
    local headers=$4
    
    local response
    local status_code
    
    if [ -n "$data" ]; then
        response=$(curl -s -f -X "$method" "$url" \
            -H "Content-Type: application/json" \
            -H "$headers" \
            -d "$data" \
            -w "\n%{http_code}")
    else
        response=$(curl -s -f -X "$method" "$url" \
            -H "$headers" \
            -w "\n%{http_code}")
    fi
    
    status_code=$(echo "$response" | tail -n1)
    response=$(echo "$response" | sed '$d')
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Алдаа: Хүсэлт амжилтгүй боллоо${NC}"
        return 1
    fi
    
    echo "$response"
    return 0
}

print_section() {
    echo -e "\n${YELLOW}=== $1 ===${NC}"
}

# test endpoint
test_endpoint() {
    local url=$1
    local method=${2:-GET}
    local data=$3
    local headers=$4
    
    if [ -n "$data" ]; then
        curl -s -X "$method" -H "Content-Type: application/json" -H "$headers" -d "$data" "$url"
    else
        curl -s -X "$method" -H "$headers" "$url"
    fi
}

# check security headers
check_security_headers() {
    local url=$1
    local service=$2
    
    print_section "$service-н аюулгүй байдлын header-үүдийг шалгаж байна"
    
    local headers=$(curl -s -I "$url")
    local score=0
    
    # Check for various security headers
    if echo "$headers" | grep -q "X-Frame-Options"; then
        echo -e "${GREEN}✓ X-Frame-Options байна${NC}"
        score=$((score + 1))
    else
        echo -e "${RED}✗ X-Frame-Options байхгүй${NC}"
    fi
    
    if echo "$headers" | grep -q "X-Content-Type-Options"; then
        echo -e "${GREEN}✓ X-Content-Type-Options байна${NC}"
        score=$((score + 1))
    else
        echo -e "${RED}✗ X-Content-Type-Options байхгүй${NC}"
    fi
    
    if echo "$headers" | grep -q "X-XSS-Protection"; then
        echo -e "${GREEN}✓ X-XSS-Protection байна${NC}"
        score=$((score + 1))
    else
        echo -e "${RED}✗ X-XSS-Protection байхгүй${NC}"
    fi
    
    if echo "$headers" | grep -q "Strict-Transport-Security"; then
        echo -e "${GREEN}✓ HSTS байна${NC}"
        score=$((score + 1))
    else
        echo -e "${RED}✗ HSTS байхгүй${NC}"
    fi
    
    echo "$score"
}

# test SQL injection protection
test_sql_injection() {
    local service=$1
    local base_url=$2
    
    print_section "$service-н SQL Injection хамгаалалтыг шалгаж байна"
    
    local payloads=(
        "' OR '1'='1"
        "admin'--"
        "'; DROP TABLE users;--"
        "' UNION SELECT * FROM users;--"
    )
    
    local score=0
    for payload in "${payloads[@]}"; do
        local response=$(test_endpoint "$base_url/login" "POST" "{\"username\":\"$payload\",\"password\":\"test\"}")
        if [[ $response == *"Invalid credentials"* ]]; then
            echo -e "${GREEN}✓ SQL injection халдлагаас хамгаалагдсан: $payload${NC}"
            score=$((score + 1))
        else
            echo -e "${RED}✗ SQL injection халдлагад өртөмтгий: $payload${NC}"
        fi
    done
    
    echo "$score"
}

# Ftest JWT token security
test_jwt_security() {
    local service=$1
    local base_url=$2
    
    print_section "$service-н JWT токен аюулгүй байдлыг шалгаж байна"
    
    local score=0
    
    # Test invalid token
    local response=$(test_endpoint "$base_url/protected" "GET" "" "Authorization: invalid-token")
    if [[ $response == *"Invalid token"* ]]; then
        echo -e "${GREEN}✓ Буруу токенийг хүлээн авахгүй байна${NC}"
        score=$((score + 1))
    else
        echo -e "${RED}✗ Буруу токенийг хүлээн авч байна${NC}"
    fi
    
    # Test expired token
    local expired_token="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJ1c2VybmFtZSI6InRlc3QiLCJleHAiOjE1MTYyMzkwMjJ9.4Adcj3UFYzPUVaVF43FmMze6JcZgqVh3qVh3qVh3qVh3"
    response=$(test_endpoint "$base_url/protected" "GET" "" "Authorization: $expired_token")
    if [[ $response == *"Invalid token"* ]]; then
        echo -e "${GREEN}✓ Хугацаа дууссан токенийг хүлээн авахгүй байна${NC}"
        score=$((score + 1))
    else
        echo -e "${RED}✗ Хугацаа дууссан токенийг хүлээн авч байна${NC}"
    fi
    
    echo "$score"
}

# test rate limiting
test_rate_limiting() {
    local service=$1
    local base_url=$2
    
    print_section "$service-н хүсэлтийн хязгаарлалтыг шалгаж байна"
    
    local score=0
    for i in $(seq 1 10); do
        local response=$(test_endpoint "$base_url/login" "POST" "{\"username\":\"test\",\"password\":\"test\"}")
        if [[ $response == *"Too many requests"* ]]; then
            echo -e "${GREEN}✓ $i хүсэлтийн дараа хязгаарлалт илэрлээ${NC}"
            score=1
            break
        fi
    done
    
    if [ $score -eq 0 ]; then
        echo -e "${RED}✗ Хүсэлтийн хязгаарлалт байхгүй байна${NC}"
    fi
    
    echo "$score"
}

# measure response time
measure_response_time() {
    local url=$1
    local iterations=${2:-10}
    local total_time=0
    
    for i in $(seq 1 $iterations); do
        local start_time=$(date +%s%N)
        curl -s -f "$url" > /dev/null
        local end_time=$(date +%s%N)
        local duration=$((end_time - start_time))
        total_time=$((total_time + duration))
        sleep 0.1
    done
    
    # Convert nanoseconds to milliseconds
    echo "scale=2; $total_time / ($iterations * 1000000)" | bc -l
}

# arrays to store test results
golang_results=()
typescript_results=()
java_results=()

# Header for the result file
cat << EOF > "$RESULT_FILE"
================================================================================================
                    Програмчлалын хэлнүүдийн аюулгүй байдлын харьцуулалт
                           Тестийн огноо: $(date)
================================================================================================

Энэхүү дүн шинжилгээ нь гурван өөр програмчлалын хэлний аюулгүй байдлын чадварыг харьцуулж байна:
- Golang (порт $GOLANG_PORT)
- TypeScript (порт $TYPESCRIPT_PORT)
- Java Spring Boot (порт $JAVA_PORT)

Дараах чухал аюулгүй байдлын тестүүдийг гүйцэтгэсэн:
1. Оролтын өгөгдлийн баталгаажуулалт
2. SQL Injection халдлагаас хамгаалалт
3. JWT токен аюулгүй байдал
4. Аюулгүй байдлын header-үүд
5. Алдааны мэдээллийн задралт
6. CSRF халдлагаас хамгаалалт
7. Хүсэлтийн хязгаарлалт
8. Хамаарлын сан аюулгүй байдал

EOF

echo -e "${YELLOW}Аюулгүй байдлын харьцуулах тест эхэллээ...${NC}"

# Check if all services are running
echo -e "${BLUE}Үйлчилгээнүүдийн боломжит байдлыг шалгаж байна...${NC}"
for service in "Golang:$GOLANG_PORT" "TypeScript:$TYPESCRIPT_PORT" "Java:$JAVA_PORT"; do
    IFS=":" read -r name port <<< "$service"
    if ! check_service "$port" "$name"; then
        echo -e "${RED}Aborting tests: Required services are not running${NC}"
        exit 1
    fi
done

# ================ TEST 1: INPUT VALIDATION ================
echo -e "${BLUE}Оролтын өгөгдлийн баталгаажуулалтыг шалгаж байна...${NC}"
echo -e "\n## 1. ОРОЛТЫН ӨГӨГДЛИЙН БАТАЛГААЖУУЛАЛТ\n" >> "$RESULT_FILE"

# input validation
input_payloads=(
  '{"username":"admin","password":"short"}'
  '{"username":"","password":""}'
  '{"username":null,"password":null}'
  '{"username":12345,"password":54321}'
  '{"username":"<test@example.com>","password":"password123"}'
  '{"username":"admin","password":"password123","xss":"<script>alert(1)</script>"}'
)

# tests in parallel
for impl in "Golang:$GOLANG_PORT" "TypeScript:$TYPESCRIPT_PORT" "Java:$JAVA_PORT"; do
    IFS=":" read -r name port <<< "$impl"
    
    echo -e "\n### 1.1 $name Input Validation\n" >> "$RESULT_FILE"
    
    validation_failures=0
    for payload in "${input_payloads[@]}"; do
        response=$(make_request "http://localhost:$port/register" "POST" "$payload")
        if [ $? -eq 0 ]; then
            echo -e "Тест хийгдэж байна: $payload" >> "$RESULT_FILE"
            echo -e "Хариу: $response\n" >> "$RESULT_FILE"
            
            if [[ "$response" =~ "error" || "$response" =~ "Status: 200" ]]; then
                validation_failures=$((validation_failures + 1))
            fi
        fi
    done &
    
    # Store validation results
    case $name in
        "Golang") golang_results[0]=$validation_failures ;;
        "TypeScript") typescript_results[0]=$validation_failures ;;
        "Java") java_results[0]=$validation_failures ;;
    esac
done

# Wait for all background jobs to complete
wait

# ================ TEST 2: SQL INJECTION PROTECTION ================
echo -e "${BLUE}SQL Injection халдлагаас хамгаалалтыг шалгаж байна...${NC}"
echo -e "\n## 2. SQL INJECTION ХАЛДЛАГААС ХАМГААЛАЛТ\n" >> "$RESULT_FILE"

# SQL injection payloads
sqli_payloads=(
  "{\"username\":\"user' OR '1'='1\",\"password\":\"password123\"}"
  "{\"username\":\"user'; DROP TABLE users; --\",\"password\":\"password123\"}"
  "{\"username\":\"admin' UNION SELECT * FROM users; --\",\"password\":\"password123\"}"
  "{\"username\":\"admin' WAITFOR DELAY '0:0:5'--\",\"password\":\"password123\"}"
  "{\"username\":\"admin' AND 1=CONVERT(int,(SELECT @@version))--\",\"password\":\"password123\"}"
)

# tests in parallel
for impl in "Golang:$GOLANG_PORT" "TypeScript:$TYPESCRIPT_PORT" "Java:$JAVA_PORT"; do
    IFS=":" read -r name port <<< "$impl"
    
    echo -e "\n### 2.1 $name SQL Injection Protection\n" >> "$RESULT_FILE"
    
    sqli_vulnerabilities=0
    for payload in "${sqli_payloads[@]}"; do
        response=$(make_request "http://localhost:$port/login" "POST" "$payload")
        if [ $? -eq 0 ]; then
            echo -e "Тест хийгдэж байна: $payload" >> "$RESULT_FILE"
            echo -e "Хариу: $response\n" >> "$RESULT_FILE"
            
            if [[ "$response" =~ "success" || "$response" =~ "logged in" ]]; then
                sqli_vulnerabilities=$((sqli_vulnerabilities + 1))
            fi
        fi
    done &
    
    case $name in
        "Golang") golang_results[1]=$sqli_vulnerabilities ;;
        "TypeScript") typescript_results[1]=$sqli_vulnerabilities ;;
        "Java") java_results[1]=$sqli_vulnerabilities ;;
    esac
done

wait

# ================ TEST 3: JWT TOKEN SECURITY ================
echo -e "${BLUE}JWT токен аюулгүй байдлыг шалгаж байна...${NC}"
echo -e "\n## 3. JWT ТОКЕН АЮУЛГҮЙ БАЙДАЛ\n" >> "$RESULT_FILE"

# Enhanced JWT test payloads
jwt_payloads=(
  "invalid.token.string"
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjB9.signature"
  "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ."
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjE1MTYyMzkwMjJ9.4Adcj3UFYzPUVaVF43FmMze0xwYzQ6N8qB3kqgXh7w"
)

# tests in parallel
for impl in "Golang:$GOLANG_PORT" "TypeScript:$TYPESCRIPT_PORT" "Java:$JAVA_PORT"; do
    IFS=":" read -r name port <<< "$impl"
    
    echo -e "\n### 3.1 $name JWT Security\n" >> "$RESULT_FILE"
    
    jwt_vulnerabilities=0
    for token in "${jwt_payloads[@]}"; do
        response=$(make_request "http://localhost:$port/protected" "GET" "" "Authorization: Bearer $token")
        if [ $? -eq 0 ]; then
            echo -e "Тест хийгдэж байна: $token" >> "$RESULT_FILE"
            echo -e "Хариу: $response\n" >> "$RESULT_FILE"
            
            if [[ "$response" =~ "Status: 200" ]]; then
                jwt_vulnerabilities=$((jwt_vulnerabilities + 1))
            fi
        fi
    done &
    
    case $name in
        "Golang") golang_results[2]=$jwt_vulnerabilities ;;
        "TypeScript") typescript_results[2]=$jwt_vulnerabilities ;;
        "Java") java_results[2]=$jwt_vulnerabilities ;;
    esac
done

wait

# ================ TEST 4: SECURITY HEADERS ================
echo -e "${BLUE}Аюулгүй байдлын header-үүдийг шалгаж байна...${NC}"
echo -e "\n## 4. АЮУЛГҮЙ БАЙДЛЫН HEADER-ҮҮД\n" >> "$RESULT_FILE"

# Enhanced security headers to check
security_headers=(
  "Content-Security-Policy"
  "X-Content-Type-Options"
  "X-Frame-Options"
  "X-XSS-Protection"
  "Strict-Transport-Security"
  "Referrer-Policy"
  "Permissions-Policy"
  "Cross-Origin-Embedder-Policy"
  "Cross-Origin-Opener-Policy"
  "Cross-Origin-Resource-Policy"
)

# tests in parallel
for impl in "Golang:$GOLANG_PORT" "TypeScript:$TYPESCRIPT_PORT" "Java:$JAVA_PORT"; do
    IFS=":" read -r name port <<< "$impl"
    
    echo -e "\n### 4.1 $name Security Headers\n" >> "$RESULT_FILE"
    
    headers_response=$(curl -s -I "http://localhost:$port/")
    
    echo -e "Хариу header-үүд:" >> "$RESULT_FILE"
    echo -e "$headers_response\n" >> "$RESULT_FILE"
    
    missing_headers=0
    echo -e "Аюулгүй байдлын header-үүдийн шинжилгээ:" >> "$RESULT_FILE"
    for header in "${security_headers[@]}"; do
        if echo "$headers_response" | grep -qi "$header"; then
            echo -e "✅ $header: Байна" >> "$RESULT_FILE"
        else
            echo -e "❌ $header: Байхгүй" >> "$RESULT_FILE"
            missing_headers=$((missing_headers + 1))
        fi
    done
    echo -e "" >> "$RESULT_FILE"
    
    case $name in
        "Golang") golang_results[3]=$missing_headers ;;
        "TypeScript") typescript_results[3]=$missing_headers ;;
        "Java") java_results[3]=$missing_headers ;;
    esac
done

# ================ TEST 5: ERROR HANDLING ================
echo -e "${BLUE}Алдааны боловсруулалтыг шалгаж байна...${NC}"
echo -e "\n## 5. АЛДААНЫ МЭДЭЭЛЛИЙН ЗАДРАЛТ\n" >> "$RESULT_FILE"

# Enhanced error test payloads
error_payloads=(
  '{"username":"test_user"}'
  'malformed json'
  ''
  '{"username":"test_user","password":"test_password","exploit":"true"}'
  '{"username":"test_user","password":"test_password","sql":"SELECT * FROM users"}'
  '{"username":"test_user","password":"test_password","xss":"<script>alert(1)</script>"}'
)

# tests in parallel
for impl in "Golang:$GOLANG_PORT" "TypeScript:$TYPESCRIPT_PORT" "Java:$JAVA_PORT"; do
    IFS=":" read -r name port <<< "$impl"
    
    echo -e "\n### 5.1 $name Error Handling\n" >> "$RESULT_FILE"
    
    info_disclosure=0
    for payload in "${error_payloads[@]}"; do
        response=$(make_request "http://localhost:$port/login" "POST" "$payload")
        if [ $? -eq 0 ]; then
            echo -e "Тест хийгдэж байна: $payload" >> "$RESULT_FILE"
            echo -e "Хариу: $response\n" >> "$RESULT_FILE"
            
            if [[ "$response" =~ "Exception" || "$response" =~ "stack trace" || "$response" =~ "at java." || "$response" =~ "at org.springframework" || "$response" =~ "internal server error" ]]; then
                info_disclosure=$((info_disclosure + 1))
                echo -e "❌ Potential information disclosure in error response" >> "$RESULT_FILE"
            fi
        fi
    done &
    
    case $name in
        "Golang") golang_results[4]=$info_disclosure ;;
        "TypeScript") typescript_results[4]=$info_disclosure ;;
        "Java") java_results[4]=$info_disclosure ;;
    esac
done

wait

# ================ TEST 6: CSRF PROTECTION ================
echo -e "${BLUE}CSRF халдлагаас хамгаалалтыг шалгаж байна...${NC}"
echo -e "\n## 6. CSRF ХАЛДЛАГААС ХАМГААЛАЛТ\n" >> "$RESULT_FILE"

# tests in parallel
for impl in "Golang:$GOLANG_PORT" "TypeScript:$TYPESCRIPT_PORT" "Java:$JAVA_PORT"; do
    IFS=":" read -r name port <<< "$impl"
    
    echo -e "\n### 6.1 $name CSRF Protection\n" >> "$RESULT_FILE"
    
    csrf_vulnerabilities=0
    
    # Test 1: Check for CSRF token in response headers
    headers_response=$(curl -s -I "http://localhost:$port/")
    if ! echo "$headers_response" | grep -qi "X-CSRF-Token"; then
        csrf_vulnerabilities=$((csrf_vulnerabilities + 1))
        echo -e "❌ CSRF токен header олдсонгүй" >> "$RESULT_FILE"
    fi
    
    # Test 2: Try to make a POST request w/o CSRF token
    response=$(make_request "http://localhost:$port/api/data" "POST" '{"data":"test"}')
    if [ $? -eq 0 ] && [[ "$response" =~ "success" ]]; then
        csrf_vulnerabilities=$((csrf_vulnerabilities + 1))
        echo -e "❌ CSRF токенгүйгээр хүсэлт амжилттай боллоо" >> "$RESULT_FILE"
    fi
    
    case $name in
        "Golang") golang_results[5]=$csrf_vulnerabilities ;;
        "TypeScript") typescript_results[5]=$csrf_vulnerabilities ;;
        "Java") java_results[5]=$csrf_vulnerabilities ;;
    esac
done

# ================ TEST 7: RATE LIMITING ================
echo -e "${BLUE}Хүсэлтийн хязгаарлалтыг шалгаж байна...${NC}"
echo -e "\n## 7. ХҮСЭЛТИЙН ХЯЗГААРЛАЛТ\n" >> "$RESULT_FILE"

# tests in parallel
for impl in "Golang:$GOLANG_PORT" "TypeScript:$TYPESCRIPT_PORT" "Java:$JAVA_PORT"; do
    IFS=":" read -r name port <<< "$impl"
    
    echo -e "\n### 7.1 $name Rate Limiting\n" >> "$RESULT_FILE"
    
    rate_limit_vulnerabilities=0
    
    # Make multiple requests in quick succession
    for i in {1..10}; do
        response=$(make_request "http://localhost:$port/api/data" "GET")
        if [ $? -eq 0 ]; then
            if [[ "$response" =~ "Status: 200" ]]; then
                rate_limit_vulnerabilities=$((rate_limit_vulnerabilities + 1))
            fi
        fi
        sleep 0.1
    done
    
    if [ $rate_limit_vulnerabilities -eq 10 ]; then
        echo -e "❌ Хүсэлтийн хязгаарлалт илэрсэнгүй" >> "$RESULT_FILE"
    else
        echo -e "✅ Хүсэлтийн хязгаарлалт идэвхтэй байна" >> "$RESULT_FILE"
    fi
    
    case $name in
        "Golang") golang_results[6]=$rate_limit_vulnerabilities ;;
        "TypeScript") typescript_results[6]=$rate_limit_vulnerabilities ;;
        "Java") java_results[6]=$rate_limit_vulnerabilities ;;
    esac
done

# ================ TEST 8: DEPENDENCY SECURITY ================
echo -e "${BLUE}Хамаарлын сан аюулгүй байдлыг шалгаж байна...${NC}"
echo -e "\n## 8. ХАМААРЛЫН САН АЮУЛГҮЙ БАЙДАЛ\n" >> "$RESULT_FILE"

# tests in parallel
for impl in "Golang:$GOLANG_PORT" "TypeScript:$TYPESCRIPT_PORT" "Java:$JAVA_PORT"; do
    IFS=":" read -r name port <<< "$impl"
    
    echo -e "\n### 8.1 $name Dependency Security\n" >> "$RESULT_FILE"
    
    dependency_vulnerabilities=0
    
    # Check for common vulnerable dependencies in response headers
    headers_response=$(curl -s -I "http://localhost:$port/")
    if echo "$headers_response" | grep -qi "X-Powered-By"; then
        dependency_vulnerabilities=$((dependency_vulnerabilities + 1))
        echo -e "❌ Сервер технологийн мэдээлэл задарч байна" >> "$RESULT_FILE"
    fi
    
    # Check for outdated security headers
    if echo "$headers_response" | grep -qi "X-XSS-Protection: 0"; then
        dependency_vulnerabilities=$((dependency_vulnerabilities + 1))
        echo -e "❌ Хуучирсан аюулгүй байдлын header-үүд илэрлээ" >> "$RESULT_FILE"
    fi
    
    case $name in
        "Golang") golang_results[7]=$dependency_vulnerabilities ;;
        "TypeScript") typescript_results[7]=$dependency_vulnerabilities ;;
        "Java") java_results[7]=$dependency_vulnerabilities ;;
    esac
done

# ================ ANALYSIS SUMMARY ================
echo -e "${BLUE}Generating Analysis Summary...${NC}"
echo -e "\n## ДҮН ШИНЖИЛГЭЭНИЙ ХУРААНГУЙ\n" >> "$RESULT_FILE"
echo -e "### ЧУХАЛ АЮУЛГҮЙ БАЙДЛЫН ТЕСТИЙН ҮР ДҮН\n" >> "$RESULT_FILE"

# security status
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

# notes based on test results
get_notes() {
  local test=$1
  local failures=$2
  case $test in
    "input_validation")
      if [ $failures -eq 0 ]; then
        echo "Хүчтэй баталгаажуулалтын систем"
      elif [ $failures -le 2 ]; then
        echo "Энгийн баталгаажуулалт байгаа"
      else
        echo "Гар аргаар баталгаажуулах шаардлагатай"
      fi
      ;;
    "sql_injection")
      if [ $failures -eq 0 ]; then
        echo "Бүх SQL injection халдлагыг блоклосон"
      else
        echo "SQL injection-д өртөмтгий"
      fi
      ;;
    "jwt_security")
      if [ $failures -eq 0 ]; then
        echo "Зөв токен баталгаажуулалт"
      else
        echo "Буруу токенийг хүлээн авсан"
      fi
      ;;
    "security_headers")
      if [ $failures -eq 0 ]; then
        echo "Бүх аюулгүй байдлын header-үүд байгаа"
      elif [ $failures -le 2 ]; then
        echo "Ихэнх аюулгүй байдлын header-үүд байгаа"
      else
        echo "Чухал аюулгүй байдлын header-үүд байхгүй"
      fi
      ;;
    "error_handling")
      if [ $failures -eq 0 ]; then
        echo "Аюулгүй алдааны боловсруулалт"
      else
        echo "Алдааны мэдээлэл задарсан"
      fi
      ;;
    "csrf_protection")
      if [ $failures -eq 0 ]; then
        echo "CSRF хамгаалалт идэвхтэй"
      else
        echo "CSRF халдлагад өртөмтгий"
      fi
      ;;
    "rate_limiting")
      if [ $failures -eq 0 ]; then
        echo "Хүсэлтийн хязгаарлалт хийгдсэн"
      else
        echo "Хүсэлтийн хязгаарлалт байхгүй"
      fi
      ;;
    "dependency_security")
      if [ $failures -eq 0 ]; then
        echo "Мэдэгдсэн эмзэг байдал байхгүй"
      else
        echo "Эмзэг байдал илэрсэн"
      fi
      ;;
  esac
}

echo -e "### 9.1 Critical Security Test Results\n" >> "$RESULT_FILE"
echo -e "| Аюулгүй байдлын тест | Golang | TypeScript | Java | Тайлбар |" >> "$RESULT_FILE"
echo -e "|----------------------|---------|------------|------|----------|" >> "$RESULT_FILE"

# Generate table rows based on actual test results
test_names=("input_validation" "sql_injection" "jwt_security" "security_headers" "error_handling" "csrf_protection" "rate_limiting" "dependency_security")
for i in "${!test_names[@]}"; do
  test=${test_names[$i]}
  golang_status=$(get_security_status "${golang_results[$i]}")
  typescript_status=$(get_security_status "${typescript_results[$i]}")
  java_status=$(get_security_status "${java_results[$i]}")
  notes=$(get_notes "$test" "${golang_results[$i]}")
  
  echo -e "| $test | $golang_status | $typescript_status | $java_status | $notes |" >> "$RESULT_FILE"
done

echo -e "\nТайлбар: ✅ Аюулгүй   ⚠️ Хэсэгчлэн аюулгүй   ❌ Эмзэг\n" >> "$RESULT_FILE"

echo -e "### ГОЛ ОЛДВОРУУД\n" >> "$RESULT_FILE"

# 1. Input Validation
echo -e "1. **Оролтын өгөгдлийн баталгаажуулалт:**" >> "$RESULT_FILE"
if [ "${golang_results[0]}" -gt 2 ]; then
  echo -e "   - Golang гар аргаар баталгаажуулалт хийх шаардлагатай" >> "$RESULT_FILE"
fi
if [ "${typescript_results[0]}" -eq 0 ]; then
  echo -e "   - TypeScript хүчтэй баталгаажуулалтын системтэй" >> "$RESULT_FILE"
fi
if [ "${java_results[0]}" -eq 0 ]; then
  echo -e "   - Java найдвартай баталгаажуулалт үзүүлж байна" >> "$RESULT_FILE"
fi
echo -e "" >> "$RESULT_FILE"

# 2. SQL Injection Protection
echo -e "2. **SQL Injection халдлагаас хамгаалалт:**" >> "$RESULT_FILE"
if [ "${golang_results[1]}" -eq 0 ] && [ "${typescript_results[1]}" -eq 0 ] && [ "${java_results[1]}" -eq 0 ]; then
  echo -e "   - Бүх хэрэгжүүлэлт SQL injection халдлагыг амжилттай блоклож байна" >> "$RESULT_FILE"
else
  echo -e "   - Зарим хэрэгжүүлэлт SQL injection халдлагад өртөмтгий байна" >> "$RESULT_FILE"
fi
echo -e "" >> "$RESULT_FILE"

# 3. JWT Security
echo -e "3. **JWT токен аюулгүй байдал:**" >> "$RESULT_FILE"
if [ "${golang_results[2]}" -eq 0 ] && [ "${typescript_results[2]}" -eq 0 ] && [ "${java_results[2]}" -eq 0 ]; then
  echo -e "   - Бүх хэрэгжүүлэлт JWT токенийг зөв баталгаажуулж байна" >> "$RESULT_FILE"
else
  echo -e "   - Зарим хэрэгжүүлэлт буруу токенийг хүлээн авч байна" >> "$RESULT_FILE"
fi
echo -e "" >> "$RESULT_FILE"

# 4. Security Headers
echo -e "4. **Аюулгүй байдлын header-үүд:**" >> "$RESULT_FILE"
if [ "${golang_results[3]}" -gt 2 ]; then
  echo -e "   - Golang-д header-үүдийг гараар тохируулах шаардлагатай" >> "$RESULT_FILE"
fi
if [ "${typescript_results[3]}" -le 2 ]; then
  echo -e "   - TypeScript ихэнх аюулгүй байдлын header-үүдийг тохируулсан" >> "$RESULT_FILE"
fi
if [ "${java_results[3]}" -eq 0 ]; then
  echo -e "   - Java иж бүрэн аюулгүй байдлын header-үүдтэй" >> "$RESULT_FILE"
fi
echo -e "" >> "$RESULT_FILE"

# 5. Error Handling
echo -e "5. **Алдааны боловсруулалт:**" >> "$RESULT_FILE"
if [ "${golang_results[4]}" -eq 0 ] && [ "${typescript_results[4]}" -eq 0 ] && [ "${java_results[4]}" -eq 0 ]; then
  echo -e "   - Бүх хэрэгжүүлэлт алдааг аюулгүй боловсруулж байна" >> "$RESULT_FILE"
else
  echo -e "   - Зарим хэрэгжүүлэлт алдааны мэдээллийг задруулж байна" >> "$RESULT_FILE"
fi
echo -e "" >> "$RESULT_FILE"

# 6. CSRF Protection
echo -e "6. **CSRF халдлагаас хамгаалалт:**" >> "$RESULT_FILE"
if [ "${golang_results[5]}" -eq 0 ] && [ "${typescript_results[5]}" -eq 0 ] && [ "${java_results[5]}" -eq 0 ]; then
  echo -e "   - Бүх хэрэгжүүлэлт CSRF халдлагаас хамгаалагдсан" >> "$RESULT_FILE"
else
  echo -e "   - Зарим хэрэгжүүлэлт CSRF халдлагад өртөмтгий" >> "$RESULT_FILE"
fi
echo -e "" >> "$RESULT_FILE"

# 7. Rate Limiting
echo -e "7. **Хүсэлтийн хязгаарлалт:**" >> "$RESULT_FILE"
if [ "${golang_results[6]}" -eq 0 ] && [ "${typescript_results[6]}" -eq 0 ] && [ "${java_results[6]}" -eq 0 ]; then
  echo -e "   - Бүх хэрэгжүүлэлт хүсэлтийн хязгаарлалт хийсэн" >> "$RESULT_FILE"
else
  echo -e "   - Зарим хэрэгжүүлэлт хүсэлтийн хязгаарлалт хийгээгүй" >> "$RESULT_FILE"
fi
echo -e "" >> "$RESULT_FILE"

# 8. Dependency Security
echo -e "8. **Хамаарлын сан аюулгүй байдал:**" >> "$RESULT_FILE"
if [ "${golang_results[7]}" -eq 0 ] && [ "${typescript_results[7]}" -eq 0 ] && [ "${java_results[7]}" -eq 0 ]; then
  echo -e "   - Бүх хэрэгжүүлэлт мэдэгдсэн эмзэг байдлаас хамгаалагдсан" >> "$RESULT_FILE"
else
  echo -e "   - Зарим хэрэгжүүлэлт мэдэгдсэн эмзэг байдалтай" >> "$RESULT_FILE"
fi
echo -e "" >> "$RESULT_FILE"

# Generate visualization data
cat << EOF > visualization_data.json
{
  "security_paradigm_comparison": {
    "golang": {
      "security_level": $((5 - ${golang_results[0]})),
      "manual_configuration": $((5 - ${golang_results[3]}))
    },
    "typescript": {
      "security_level": $((5 - ${typescript_results[0]})),
      "manual_configuration": $((5 - ${typescript_results[3]}))
    },
    "java": {
      "security_level": $((5 - ${java_results[0]})),
      "manual_configuration": $((5 - ${java_results[3]}))
    }
  },
  "security_code_distribution": {
    "golang": {
      "validation": $((5 - ${golang_results[0]})),
      "authentication": $((5 - ${golang_results[2]})),
      "headers": $((5 - ${golang_results[3]})),
      "error_handling": $((5 - ${golang_results[4]})),
      "csrf_protection": $((5 - ${golang_results[5]})),
      "rate_limiting": $((5 - ${golang_results[6]})),
      "dependency_security": $((5 - ${golang_results[7]}))
    },
    "typescript": {
      "validation": $((5 - ${typescript_results[0]})),
      "authentication": $((5 - ${typescript_results[2]})),
      "headers": $((5 - ${typescript_results[3]})),
      "error_handling": $((5 - ${typescript_results[4]})),
      "csrf_protection": $((5 - ${typescript_results[5]})),
      "rate_limiting": $((5 - ${typescript_results[6]})),
      "dependency_security": $((5 - ${typescript_results[7]}))
    },
    "java": {
      "validation": $((5 - ${java_results[0]})),
      "authentication": $((5 - ${java_results[2]})),
      "headers": $((5 - ${java_results[3]})),
      "error_handling": $((5 - ${java_results[4]})),
      "csrf_protection": $((5 - ${java_results[5]})),
      "rate_limiting": $((5 - ${java_results[6]})),
      "dependency_security": $((5 - ${java_results[7]}))
    }
  },
  "security_maturity_model": {
    "golang": $((5 - (${golang_results[0]} + ${golang_results[1]} + ${golang_results[2]} + ${golang_results[3]} + ${golang_results[4]} + ${golang_results[5]} + ${golang_results[6]} + ${golang_results[7]}) / 8)),
    "typescript": $((5 - (${typescript_results[0]} + ${typescript_results[1]} + ${typescript_results[2]} + ${typescript_results[3]} + ${typescript_results[4]} + ${typescript_results[5]} + ${typescript_results[6]} + ${typescript_results[7]}) / 8)),
    "java": $((5 - (${java_results[0]} + ${java_results[1]} + ${java_results[2]} + ${java_results[3]} + ${java_results[4]} + ${java_results[5]} + ${java_results[6]} + ${java_results[7]}) / 8))
  },
  "implementation_effort": {
    "golang": $((${golang_results[0]} + ${golang_results[3]})),
    "typescript": $((${typescript_results[0]} + ${typescript_results[3]})),
    "java": $((${java_results[0]} + ${java_results[3]}))
  },
  "security_radar": {
    "golang": {
      "input_validation": $((5 - ${golang_results[0]})),
      "sql_injection": $((5 - ${golang_results[1]})),
      "jwt_security": $((5 - ${golang_results[2]})),
      "security_headers": $((5 - ${golang_results[3]})),
      "error_handling": $((5 - ${golang_results[4]})),
      "csrf_protection": $((5 - ${golang_results[5]})),
      "rate_limiting": $((5 - ${golang_results[6]})),
      "dependency_security": $((5 - ${golang_results[7]}))
    },
    "typescript": {
      "input_validation": $((5 - ${typescript_results[0]})),
      "sql_injection": $((5 - ${typescript_results[1]})),
      "jwt_security": $((5 - ${typescript_results[2]})),
      "security_headers": $((5 - ${typescript_results[3]})),
      "error_handling": $((5 - ${typescript_results[4]})),
      "csrf_protection": $((5 - ${typescript_results[5]})),
      "rate_limiting": $((5 - ${typescript_results[6]})),
      "dependency_security": $((5 - ${typescript_results[7]}))
    },
    "java": {
      "input_validation": $((5 - ${java_results[0]})),
      "sql_injection": $((5 - ${java_results[1]})),
      "jwt_security": $((5 - ${java_results[2]})),
      "security_headers": $((5 - ${java_results[3]})),
      "error_handling": $((5 - ${java_results[4]})),
      "csrf_protection": $((5 - ${java_results[5]})),
      "rate_limiting": $((5 - ${java_results[6]})),
      "dependency_security": $((5 - ${java_results[7]}))
    }
  }
}
EOF

echo -e "${GREEN}Аюулгүй байдлын тест дууслаа! Үр дүн $RESULT_FILE файлд хадгалагдлаа${NC}"