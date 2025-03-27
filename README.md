# Security Capabilities Comparison

This project demonstrates security features in three different programming languages: Golang, TypeScript, and Java. Each implementation includes:

- User registration and login
- Password hashing
- JWT-based authentication
- Protected endpoints
- Input validation
- SQL injection prevention

## Prerequisites

- Go 1.21 or later
- Node.js 18 or later
- Java 17 or later
- Maven

## Running the Applications

### Golang Application

```bash
cd golang
go mod tidy
go run main.go
```

The application will run on http://localhost:8080

### TypeScript Application

```bash
cd typescript
npm install
npx prisma generate
npm run dev
```

The application will run on http://localhost:3000

### Java Application

```bash
cd java
mvn spring-boot:run
```

The application will run on http://localhost:8080

## Testing the Applications

### 1. Register a new user

```bash
# Golang
curl -X POST http://localhost:8080/register \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "password123"}'

# TypeScript
curl -X POST http://localhost:3000/register \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "password123"}'

# Java
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "password123"}'
```

### 2. Login

```bash
# Golang
curl -X POST http://localhost:8080/login \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "password123"}'

# TypeScript
curl -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "password123"}'

# Java
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "password123"}'
```

### 3. Access Protected Endpoint

```bash
# Golang
curl -X GET http://localhost:8080/protected \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# TypeScript
curl -X GET http://localhost:3000/protected \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Java
curl -X GET http://localhost:8080/api/protected \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Security Features Comparison

### Golang
- Strong type system
- Built-in concurrency safety
- Explicit error handling
- Memory safety through garbage collection
- Standard library security features

### TypeScript
- Static type checking
- Interface-based type safety
- Null safety through strict null checks
- Type inference
- Integration with JavaScript security features

### Java
- Strong type system
- Exception handling
- Memory management
- Security manager
- Rich security libraries
- Built-in cryptography support

## Security Testing

To test security vulnerabilities, you can try:

1. SQL Injection attempts
2. XSS attacks
3. CSRF attacks
4. Buffer overflow attempts
5. Input validation bypass attempts

Note: These applications are for demonstration purposes only. In a production environment, you should:

1. Use environment variables for sensitive data
2. Implement rate limiting
3. Use HTTPS
4. Implement proper session management
5. Use secure password policies
6. Implement proper logging and monitoring
7. Regular security audits and updates 