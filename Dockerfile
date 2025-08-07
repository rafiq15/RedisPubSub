# Multi-stage build for smaller image size
FROM gradle:8.5-jdk21 as build

# Set working directory
WORKDIR /app

# Copy gradle files for dependency caching
COPY build.gradle settings.gradle gradlew ./
COPY gradle/ gradle/

# Download dependencies (cached layer)
RUN gradle dependencies --no-daemon

# Copy source code
COPY src/ src/

# Build the application
RUN gradle bootJar --no-daemon

# Runtime stage
FROM openjdk:21-jdk-slim

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN addgroup --system --gid 1001 spring && \
    adduser --system --uid 1001 --gid 1001 spring

# Set working directory
WORKDIR /app

# Copy the built jar from build stage
COPY --from=build /app/build/libs/redis-pub-sub-1.0.0.jar app.jar

# Change ownership to spring user
RUN chown spring:spring app.jar

# Switch to non-root user
USER spring

# Expose port
EXPOSE 8445

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8445/actuator/health || exit 1

# Environment variables with defaults
ENV SPRING_REDIS_HOST=redis \
    SPRING_REDIS_PORT=6379 \
    SERVER_PORT=8445

# Run the application
ENTRYPOINT ["java", "-jar", "/app/app.jar"]