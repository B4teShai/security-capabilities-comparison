# Security Capabilities Comparison

This project compares security implementations across three different programming languages: Golang, TypeScript (Node.js), and Java (Spring Boot). The goal is to analyze and compare how each language/framework handles various security concerns in web applications.

## Project Structure

```
.
├── golang/           # Golang implementation
├── typescript/       # TypeScript (Node.js) implementation
├── java/            # Java Spring Boot implementation
├── grafana/         # Security metrics dashboard
└── docker-compose.yml
```

## Features Compared

1. **Input Validation & Sanitization**
   - Golang: Manual validation with custom functions
   - TypeScript: Zod schema validation
   - Java: Bean Validation (JSR 380)

2. **SQL Injection Protection**
   - Golang: Parameterized queries with `database/sql`
   - TypeScript: Prisma ORM with built-in protection
   - Java: JPA/Hibernate with prepared statements

3. **JWT Token Security**
   - Golang: `dgrijalva/jwt-go` package
   - TypeScript: `jsonwebtoken` package
   - Java: Spring Security JWT

4. **Security Headers**
   - Golang: Manual header setting
   - TypeScript: Helmet middleware
   - Java: Spring Security headers

5. **Error Handling & Information Disclosure**
   - Golang: Custom error types
   - TypeScript: Error middleware
   - Java: Global exception handler

6. **CSRF Protection**
   - Golang: Custom CSRF middleware
   - TypeScript: CSRF tokens
   - Java: Spring Security CSRF

7. **Rate Limiting**
   - Golang: Rate limiter middleware
   - TypeScript: Express rate limit
   - Java: Bucket4j implementation

8. **Dependency Security**
   - Golang: Go modules
   - TypeScript: npm audit
   - Java: Maven dependencies

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Make (optional, for convenience)

### Running the Services

1. Start all services:
   ```bash
   docker-compose up -d
   ```

2. Services will be available at:
   - Golang: http://localhost:8080
   - TypeScript: http://localhost:3000
   - Java: http://localhost:8081
   - Security Dashboard: http://localhost:3001
   - OWASP Juice Shop (for testing): http://localhost:3002

### Running Security Tests

The project includes a comprehensive security test script:

```bash
./comparative_security_test.sh
```

This script performs automated security testing across all three implementations and generates a detailed report.

## Security Dashboard

The project includes a Grafana dashboard for visualizing security metrics:

1. Access the dashboard at http://localhost:3001
2. Login with:
   - Username: admin
   - Password: admin
3. Navigate to the "Security Comparison" dashboard

## API Endpoints

Each service implements the following endpoints:

- `GET /health` - Health check endpoint
- `POST /register` - User registration
- `POST /login` - User authentication
- `GET /protected` - Protected endpoint (requires JWT)

## Security Considerations

- JWT secrets should be properly configured in production
- Database credentials should be secured
- HTTPS should be enabled in production
- Rate limiting should be adjusted based on requirements
- Security headers should be reviewed and customized

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- OWASP Security Guidelines
- Spring Security Documentation
- Express.js Security Best Practices
- Golang Security Guidelines 