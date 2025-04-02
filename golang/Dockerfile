# Build stage
FROM golang:1.24-bullseye AS builder

WORKDIR /app

# Install SQLite development files
RUN apt-get update && apt-get install -y gcc libc6-dev sqlite3 libsqlite3-dev && rm -rf /var/lib/apt/lists/*

# Copy go.mod first for better caching
COPY go.mod .
COPY go.sum .

# Download dependencies
RUN go mod download && go mod verify

# Copy the rest of the source code
COPY . .

# Build with CGO enabled
ENV CGO_ENABLED=1
RUN go build -o main

# Final stage
FROM debian:bullseye-slim

WORKDIR /app

# Install SQLite runtime
RUN apt-get update && apt-get install -y sqlite3 libsqlite3-0 && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -m -u 1001 appuser

# Create data directory with proper permissions
RUN mkdir -p /app/data && chown -R appuser:appuser /app/data

# Copy the binary from builder
COPY --from=builder /app/main .

# Use non-root user
USER appuser

EXPOSE 8080

CMD ["./main"] 