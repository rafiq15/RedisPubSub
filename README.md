# Redis Pub/Sub WebSocket Example

This project demonstrates a simple messaging application using **Spring Boot**, **Redis Pub/Sub**, and **WebSocket** for real-time message delivery.

## 📋 Table of Contents

- [Features](#features)
- [Getting Started](#getting-started)
  - [Quick Start Options](#quick-start-options)
  - [Local Development Setup](#local-development-setup)
  - [Usage](#usage)
- [Deployment Options](#deployment-options)
- [Configuration](#configuration)
- [Project Structure](#project-structure)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Features

- Publish messages via a web form.
- Messages are sent to a Redis channel.
- Messages are broadcast to all connected clients using WebSocket (STOMP).
- Live message updates on the UI.

## Getting Started

### Quick Start Options

**For Development:**
1. **Local Development**: Follow the steps below for local setup with Gradle
2. **Docker**: Use the [Docker Deployment Guide](DOCKER_DEPLOYMENT_GUIDE.md) for containerized development
3. **Kubernetes**: Use the [Kubernetes Guide](KUBERNETES_README.md) for local Kubernetes clusters (kind/minikube)

**For Production:**
- **Docker**: Production-ready Docker deployment instructions in [Docker Guide](DOCKER_DEPLOYMENT_GUIDE.md)
- **Kubernetes**: Production configurations available in [Kubernetes Guide](KUBERNETES_README.md)
- **CI/CD**: Automated deployments with [Jenkins Guide](JENKINS_DEPLOYMENT_GUIDE.md)

### Local Development Setup

#### Prerequisites

- Java 17 or higher
- Gradle
- Redis server running on `localhost:6379`

#### Running the Application

1. Start your Redis server.
2. Build and run the Spring Boot application:
   ```bash
   ./gradlew bootRun
   ```
3. Open [http://localhost:8445](http://localhost:8445) in your browser.

- **Usage**: Enter a message in the form on the home page and submit.
- **View Live Messages**: Click "View Live Messages" to see messages appear in real time as they are published.

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Web Browser   │    │  Spring Boot App │    │   Redis Server  │
│                 │    │                  │    │                 │
│  WebSocket      │◄──►│  WebSocket       │    │  Pub/Sub        │
│  (STOMP)        │    │  Controller      │    │  Channel        │
│                 │    │                  │    │                 │
│  HTTP Forms     │◄──►│  REST API        │◄──►│  Message        │
│                 │    │                  │    │  Queue          │
└─────────────────┘    └──────────────────┘    └─────────────────┘
       :8445                    :8445                   :6379
```

**Message Flow:**
1. User submits message via web form (HTTP POST)
2. Spring Boot app publishes message to Redis channel
3. Redis notifies all subscribers (including the same app)
4. App broadcasts message to all WebSocket clients
5. Connected browsers display the message in real-time

## Configuration

- Redis connection settings are in `src/main/resources/application.properties`.
- WebSocket endpoint: `/ws`
- STOMP topic: `/topic/messages`
- Redis channel: `messageQueue`

## Project Structure

### Core Application Files
- `src/main/java/com/redis/config/RedisConfig.java` — Redis and topic configuration.
- `src/main/resources/templates/index.html` — Message publishing form.
- `src/main/resources/templates/messages.html` — Live message view.
- `src/main/resources/application.properties` — Application configuration.

### Deployment Files
- `Dockerfile` — Docker image configuration
- `docker-compose.yml` — Multi-container Docker setup
- `k8s/` — Kubernetes deployment manifests
- `Jenkinsfile` — Jenkins CI/CD pipeline configuration

### Documentation
- `DOCKER_DEPLOYMENT_GUIDE.md` — Docker deployment instructions
- `KUBERNETES_README.md` — Kubernetes deployment guide  
- `JENKINS_DEPLOYMENT_GUIDE.md` — Jenkins CI/CD setup guide

### Scripts
- `scripts/` — Deployment and utility scripts for different platforms

## Deployment Options

This application can be deployed using multiple methods. Choose the one that best fits your environment:

| Deployment Method | Use Case | Complexity | Best For |
|-------------------|----------|------------|----------|
| 🐳 **[Docker](DOCKER_DEPLOYMENT_GUIDE.md)** | Development & Production | Low | Quick setup, local development, simple production |
| ☸️ **[Kubernetes](KUBERNETES_README.md)** | Production | Medium | Scalable production, microservices, cloud-native |
| 🚀 **[Jenkins CI/CD](JENKINS_DEPLOYMENT_GUIDE.md)** | Automated Deployment | High | Continuous integration, enterprise workflows |

### 🐳 Docker Deployment
For containerized deployment using Docker and Docker Compose:
- **[Docker Deployment Guide](DOCKER_DEPLOYMENT_GUIDE.md)** - Complete guide for Docker and Docker Compose deployment
- ✅ Quick setup with `docker-compose up`
- ✅ Perfect for development and testing
- ✅ Production-ready with proper configuration

### ☸️ Kubernetes Deployment
For scalable deployment on Kubernetes clusters:
- **[Kubernetes Deployment Guide](KUBERNETES_README.md)** - Comprehensive Kubernetes deployment with development and production configurations
- ✅ Auto-scaling and load balancing
- ✅ Rolling updates and health checks
- ✅ Production-grade orchestration

### 🚀 CI/CD with Jenkins
For automated deployment and continuous integration:
- **[Jenkins CI/CD Pipeline Guide](JENKINS_DEPLOYMENT_GUIDE.md)** - Setup Jenkins for automated builds and deployments
- ✅ Automated testing and deployment
- ✅ Cross-platform support (Windows/Linux)
- ✅ Integration with Git workflows

## Troubleshooting

- If you see unreadable characters in received messages, ensure `RedisTemplate` uses `StringRedisSerializer` for all serializers (already configured in this project).
- Make sure Redis is running and accessible at the configured host and port.

## License

This project is for educational purposes. All code is AI-generated.
