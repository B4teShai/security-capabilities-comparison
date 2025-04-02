# Build stage
FROM openjdk:17-slim AS builder

WORKDIR /app

# Copy pom.xml first to leverage Docker cache
COPY pom.xml .
COPY src ./src

# Install Maven and build the application
RUN apt-get update && apt-get install -y maven && \
    mvn clean package -DskipTests && \
    apt-get remove -y maven && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Production stage
FROM openjdk:17-slim

WORKDIR /app

# Create a non-root user
RUN useradd -m -u 1000 appuser

# Create data directory with proper permissions
RUN mkdir -p /app/data && chown -R appuser:appuser /app/data

# Copy the built jar from builder
COPY --from=builder /app/target/*.jar app.jar

# Use non-root user
USER appuser

EXPOSE 8080

CMD ["java", "-jar", "app.jar"] 