# Redis Pub/Sub Application - Docker Deployment Guide

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start with Docker Compose](#quick-start-with-docker-compose)
- [Manual Docker Deployment](#manual-docker-deployment)
- [Environment Configuration](#environment-configuration)
- [Monitoring and Logs](#monitoring-and-logs)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)

## Overview
This Spring Boot application demonstrates Redis Pub/Sub messaging with WebSocket integration for real-time message display.

## Prerequisites
- Docker and Docker Compose installed
- Git (for cloning the repository)
- Port 8445 and 6379 available on your host machine

## Quick Start with Docker Compose

### 1. Clone and Navigate to Project
```bash
git clone <repository-url>
cd RedisPubSub
```

### 2. Deploy with Docker Compose
```bash
# Start all services (Redis + Application)
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down

# Stop and remove volumes (clears Redis data)
docker-compose down -v
```

### 3. Access the Application
- **Web Interface**: http://localhost:8445
- **Live Messages**: http://localhost:8445/messages
- **Health Check**: http://localhost:8445/actuator/health

## Manual Docker Deployment

### 1. Start Redis Container
```bash
docker run -d \
  --name redis-server \
  -p 6379:6379 \
  redis:7-alpine
```

### 2. Build Application Image
```bash
# Build the Docker image
docker build -t redis-pubsub-app .
```

### 3. Run Application Container
```bash
docker run -d \
  --name redis-pubsub-app \
  -p 8445:8445 \
  -e SPRING_REDIS_HOST=redis-server \
  --link redis-server \
  redis-pubsub-app
```

## Production Deployment Considerations

### 1. Environment Variables
Configure these environment variables for different environments:

```bash
# Redis Configuration
SPRING_REDIS_HOST=your-redis-host
SPRING_REDIS_PORT=6379
SPRING_REDIS_PASSWORD=your-redis-password  # if authentication enabled

# Application Configuration
SERVER_PORT=8445
SPRING_PROFILES_ACTIVE=production

# Logging
LOGGING_LEVEL_ROOT=INFO
```

### 2. Docker Compose for Production
Create a `docker-compose.prod.yml`:

```yaml
version: '3.8'

services:
  redis:
    image: redis:7-alpine
    container_name: redis-server-prod
    volumes:
      - ./redis.conf:/usr/local/etc/redis/redis.conf
      - redis-data:/data
    command: redis-server /usr/local/etc/redis/redis.conf
    restart: always
    networks:
      - redis-network

  redis-pubsub-app:
    image: redis-pubsub-app:latest
    container_name: redis-pubsub-app-prod
    ports:
      - "8445:8445"
    environment:
      - SPRING_REDIS_HOST=redis
      - SPRING_PROFILES_ACTIVE=production
    depends_on:
      - redis
    restart: always
    networks:
      - redis-network

volumes:
  redis-data:

networks:
  redis-network:
    driver: bridge
```

### 3. Kubernetes Deployment
For Kubernetes deployment, create these manifests:

#### Redis Deployment
```yaml
# redis-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
---
apiVersion: v1
kind: Service
metadata:
  name: redis-service
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
```

#### Application Deployment
```yaml
# app-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-pubsub-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: redis-pubsub-app
  template:
    metadata:
      labels:
        app: redis-pubsub-app
    spec:
      containers:
      - name: redis-pubsub-app
        image: redis-pubsub-app:latest
        ports:
        - containerPort: 8445
        env:
        - name: SPRING_REDIS_HOST
          value: "redis-service"
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8445
          initialDelaySeconds: 60
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8445
          initialDelaySeconds: 30
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: redis-pubsub-service
spec:
  selector:
    app: redis-pubsub-app
  ports:
  - port: 80
    targetPort: 8445
  type: LoadBalancer
```

## Monitoring and Maintenance

### 1. Health Checks
```bash
# Check application health
curl http://localhost:8445/actuator/health

# Check Redis connectivity
docker exec redis-server redis-cli ping
```

### 2. Viewing Logs
```bash
# Application logs
docker logs redis-pubsub-app -f

# Redis logs
docker logs redis-server -f

# Docker Compose logs
docker-compose logs -f
```

### 3. Scaling
```bash
# Scale application instances
docker-compose up -d --scale redis-pubsub-app=3
```

## Troubleshooting

### Common Issues

1. **Connection Refused to Redis**
   - Ensure Redis container is running
   - Check network connectivity between containers
   - Verify Redis host configuration

2. **Port Already in Use**
   ```bash
   # Find process using port
   netstat -tulpn | grep :8445
   
   # Kill process or use different port
   docker-compose up -d -p 8446:8445
   ```

3. **Container Health Check Failures**
   ```bash
   # Check container status
   docker ps
   
   # Inspect health check logs
   docker inspect redis-pubsub-app
   ```

### Debugging Commands
```bash
# Enter container shell
docker exec -it redis-pubsub-app /bin/sh

# Test Redis connection from app container
docker exec -it redis-pubsub-app curl -f http://localhost:8445/actuator/health

# Redis CLI access
docker exec -it redis-server redis-cli
```

## Security Considerations

1. **Redis Security**
   - Enable Redis authentication in production
   - Use Redis ACL for fine-grained access control
   - Configure Redis to bind to specific interfaces

2. **Application Security**
   - Implement authentication/authorization
   - Use HTTPS in production
   - Validate and sanitize user inputs

3. **Container Security**
   - Run containers as non-root users (already implemented)
   - Use minimal base images
   - Regularly update base images

## Performance Optimization

1. **Redis Configuration**
   - Tune Redis memory settings
   - Configure appropriate persistence settings
   - Use Redis Cluster for high availability

2. **Application Configuration**
   - Adjust connection pool settings
   - Configure appropriate JVM heap size
   - Enable compression for WebSocket messages

3. **Container Resources**
   ```yaml
   # Add resource limits in docker-compose.yml
   resources:
     limits:
       memory: 512M
       cpus: '0.5'
     reservations:
       memory: 256M
       cpus: '0.25'
   ```

## Related Deployment Guides

- **[Kubernetes Deployment](KUBERNETES_README.md)** - For scalable production deployments with orchestration
- **[Jenkins CI/CD Pipeline](JENKINS_DEPLOYMENT_GUIDE.md)** - For automated Docker image builds and deployments
- **[Main README](README.md)** - Overview and local development setup

## Next Steps

1. **For Production**: Consider migrating to Kubernetes for better scalability and management
2. **For Automation**: Set up Jenkins CI/CD pipeline for automated deployments
3. **For Monitoring**: Implement application monitoring with Prometheus and Grafana
4. **For Security**: Configure SSL/TLS and implement authentication
