# Redis Pub/Sub Kubernetes Deployment

## 📋 Table of Contents

- [Overview](#overview)
- [Quick Start](#-quick-start)
- [Project Structure](#-project-structure)
- [Environment Configurations](#environment-configurations)
- [Advanced Deployment](#advanced-deployment)
- [Monitoring and Maintenance](#monitoring-and-maintenance)
- [Troubleshooting](#troubleshooting)

## Overview

This repository contains a comprehensive Kubernetes deployment setup for the Redis Pub/Sub application with both development and production configurations.

## 🚀 Quick Start

### Option 1: One-Command Deployment (Windows)
```batch
# Build, deploy, and get ready for access
scripts\quick-deploy.bat

# Start port forwarding (in a separate terminal)
scripts\port-forward.bat
```

### Option 2: Step-by-Step Deployment
```batch
# Build Docker image
scripts\deploy.ps1 build

# Deploy to development
scripts\deploy.ps1 deploy

# Start port forwarding
scripts\deploy.ps1 port-forward
```

### Option 3: Manual Deployment
```bash
# Build and load image
docker build -t redispubsub-redis-pubsub-app:latest .
kind load docker-image redispubsub-redis-pubsub-app:latest  # if using kind

# Deploy to development
kubectl apply -f k8s/environments/development/all-in-one.yaml

# Port forward to access
kubectl port-forward service/redis-pubsub-app-service 8445:8445 -n redis-pubsub-dev
```

## 📁 Project Structure

```
k8s/
├── environments/
│   ├── development/
│   │   └── all-in-one.yaml          # Complete dev deployment
│   └── production/
│       └── all-in-one.yaml          # Complete prod deployment
├── base/                            # Original base manifests (legacy)
└── overlays/                        # Original overlays (legacy)

scripts/
├── deploy.ps1                       # PowerShell deployment script
├── deploy.sh                        # Bash deployment script
├── quick-deploy.bat                 # One-command deployment
├── port-forward.bat                 # Port forwarding helper
└── cleanup.bat                      # Cleanup script
```

## 🛠️ Available Commands

### PowerShell Script (`scripts\deploy.ps1`)
```powershell
# Build Docker image
.\scripts\deploy.ps1 build

# Deploy to development
.\scripts\deploy.ps1 deploy

# Deploy to production
.\scripts\deploy.ps1 deploy -Environment prod

# Check status
.\scripts\deploy.ps1 status

# Show logs
.\scripts\deploy.ps1 logs

# Start port forwarding
.\scripts\deploy.ps1 port-forward

# Delete deployment
.\scripts\deploy.ps1 delete

# Help
.\scripts\deploy.ps1 help
```

### Batch Scripts
```batch
# Quick deployment (build + deploy)
scripts\quick-deploy.bat

# Port forwarding
scripts\port-forward.bat

# Cleanup deployment
scripts\cleanup.bat
```

## 🌍 Environments

### Development Environment
- **Namespace**: `redis-pubsub-dev`
- **Features**:
  - Single replica for app and Redis
  - Debug logging enabled
  - Lower resource limits
  - Direct kubectl port-forwarding
  - Development-optimized configuration

### Production Environment
- **Namespace**: `redis-pubsub-prod`
- **Features**:
  - High availability (2 app replicas)
  - Production logging levels
  - Higher resource limits
  - Redis persistence configuration
  - Ingress configuration
  - Security contexts
  - Rolling update strategy

## 🔧 Configuration

### Application Configuration
The application is configured through ConfigMaps:
- **Development**: Debug logging, simple Redis connection
- **Production**: Info logging, connection pooling, monitoring endpoints

### Resource Allocation
- **Development**: 256Mi-512Mi memory, 100m-500m CPU
- **Production**: 512Mi-1Gi memory, 200m-1000m CPU

## 📊 Monitoring and Health Checks

Both environments include:
- **Liveness probes**: HTTP health checks on `/actuator/health`
- **Readiness probes**: HTTP readiness checks on `/actuator/health/readiness`
- **Resource monitoring**: CPU and memory limits/requests

## 🌐 Access Methods

### Development Access
```bash
# Port forwarding (recommended for development)
kubectl port-forward service/redis-pubsub-app-service 8445:8445 -n redis-pubsub-dev

# Access at: http://localhost:8445
```

### Production Access
```bash
# Port forwarding
kubectl port-forward service/redis-pubsub-app-service 8080:80 -n redis-pubsub-prod

# Ingress (if configured)
# Access at: http://redis-pubsub.example.com
```

## 🗃️ Data Persistence

- **Redis data**: Stored in PersistentVolumeClaim (`redis-data-pvc`)
- **Development**: 1Gi storage
- **Production**: 5Gi storage with backup configuration

## 🔍 Troubleshooting

### Common Commands
```bash
# Check pod status
kubectl get pods -n redis-pubsub-dev

# View application logs
kubectl logs -l app=redis-pubsub-app -n redis-pubsub-dev

# View Redis logs
kubectl logs -l app=redis -n redis-pubsub-dev

# Describe problematic pod
kubectl describe pod <pod-name> -n redis-pubsub-dev

# Check service endpoints
kubectl get endpoints -n redis-pubsub-dev
```

### Common Issues

1. **Image not found**: Make sure to build and load the image into your cluster
2. **Port forwarding issues**: Check if the service and pods are running
3. **Connection refused**: Verify Redis service is accessible from the app pod

## 🧹 Cleanup

```bash
# Development environment
kubectl delete -f k8s/environments/development/all-in-one.yaml

# Production environment
kubectl delete -f k8s/environments/production/all-in-one.yaml

# Or use the cleanup script
scripts\cleanup.bat
```

## 📝 Next Steps

1. **Customize configurations**: Edit the all-in-one.yaml files for your specific needs
2. **Set up monitoring**: Add Prometheus/Grafana for production monitoring
3. **Configure ingress**: Update the production ingress with your domain
4. **Add secrets**: Implement proper secret management for production
5. **CI/CD integration**: Integrate with your CI/CD pipeline

## 🔧 Development Workflow

1. Make code changes
2. Run `scripts\quick-deploy.bat` to rebuild and redeploy
3. Use `scripts\port-forward.bat` to access the application
4. View logs with `scripts\deploy.ps1 logs`
5. Clean up with `scripts\cleanup.bat` when done

## Related Deployment Guides

- **[Docker Deployment](DOCKER_DEPLOYMENT_GUIDE.md)** - For simpler containerized deployments and local development
- **[Jenkins CI/CD Pipeline](JENKINS_DEPLOYMENT_GUIDE.md)** - For automated Kubernetes deployments and GitOps workflows
- **[Main README](README.md)** - Overview and local development setup

## Next Steps

1. **Customize configurations**: Edit the all-in-one.yaml files for your specific needs
2. **Set up monitoring**: Add Prometheus/Grafana for production monitoring
3. **Configure ingress**: Update the production ingress with your domain
4. **Add secrets**: Implement proper secret management for production
5. **CI/CD integration**: Integrate with Jenkins or GitLab CI for automated deployments
6. **Horizontal Pod Autoscaling**: Configure HPA for automatic scaling based on load
