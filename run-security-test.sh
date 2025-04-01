#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Starting Security Testing Environment${NC}"

# Create necessary directories
mkdir -p zap nikto grafana/provisioning/dashboards

# Start the Docker environment
echo -e "${YELLOW}Starting Docker containers...${NC}"
docker-compose up -d

# Wait for services to be ready
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 30

# Run security tests
echo -e "${YELLOW}Running security tests...${NC}"
chmod +x security-test.sh
./security-test.sh

# Generate report
echo -e "${YELLOW}Generating security report...${NC}"
cat << EOF > security-report.md
# Security Testing Report

## Overview
This report contains the results of security testing performed on three different implementations of a secure web application:
- Golang (http://localhost:8080)
- TypeScript (http://localhost:3000)
- Java (http://localhost:8081)

## OWASP ZAP Results
The OWASP ZAP scan results can be found in the \`zap\` directory.

## Nikto Results
The Nikto scan results can be found in the \`nikto\` directory.

## Security Dashboard
A Grafana dashboard with security metrics is available at http://localhost:3001
- Username: admin
- Password: admin

## Manual Testing Results
The results of manual security testing can be found in the output above.

## Recommendations
Based on the test results, here are some recommendations for improving security:

1. Implement rate limiting
2. Add input validation
3. Use HTTPS
4. Implement proper session management
5. Regular security audits
6. Keep dependencies updated
7. Implement proper logging
8. Use secure password policies

## Next Steps
1. Review the detailed scan reports
2. Address any vulnerabilities found
3. Implement the recommended security improvements
4. Schedule regular security testing
EOF

echo -e "${GREEN}Security testing complete!${NC}"
echo -e "You can find the results in:"
echo -e "- Security report: security-report.md"
echo -e "- OWASP ZAP results: zap/"
echo -e "- Nikto results: nikto/"
echo -e "- Security dashboard: http://localhost:3001" 