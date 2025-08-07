# Kubernetes Deployment Guide

This directory contains Kubernetes manifests and deployment scripts for the Redis Pub/Sub application.

## Structure

```
k8s/
├── base/                           # Base Kubernetes manifests
│   ├── namespace.yaml             # Namespace definition
│   ├── configmap.yaml             # Application configuration
│   ├── redis-pvc.yaml             # Redis persistent volume claim
│   ├── redis-deployment.yaml     # Redis deployment
│   ├── redis-service.yaml        # Redis service
│   ├── app-deployment.yaml       # Application deployment
│   ├── app-service.yaml          # Application service
│   ├── ingress.yaml               # Ingress for external access
│   ├── application-kubernetes.properties  # Kubernetes-specific config
│   └── kustomization.yaml        # Base kustomization
├── overlays/
│   ├── development/               # Development environment
│   │   ├── kustomization.yaml    # Development kustomization
│   │   ├── app-deployment-patch.yaml     # Development-specific patches
│   │   ├── configmap-patch.yaml
│   │   └── ingress-patch.yaml
│   └── production/                # Production environment
│       ├── kustomization.yaml    # Production kustomization
│       ├── app-deployment-patch.yaml     # Production-specific patches
│       ├── configmap-patch.yaml
│       ├── ingress-patch.yaml
│       └── redis-deployment-patch.yaml
├── k8s-deploy.sh                  # Linux/Mac deployment script
└── k8s-deploy.bat                 # Windows deployment script
```

## Prerequisites

1. **Kubernetes Cluster**: You need access to a Kubernetes cluster (local or cloud)
2. **kubectl**: Kubernetes command-line tool
3. **kustomize**: Configuration management tool for Kubernetes
4. **Docker**: For building application images

### Installation

```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install kustomize
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo mv kustomize /usr/local/bin/

# For Windows, use chocolatey or download binaries
choco install kubernetes-cli kustomize
```

## Quick Start

### 1. Build Docker Image

```bash
# Linux/Mac
./k8s-deploy.sh build latest

# Windows
k8s-deploy.bat build latest
```

### 2. Deploy to Development

```bash
# Linux/Mac
./k8s-deploy.sh deploy development latest

# Windows
k8s-deploy.bat deploy development latest
```

### 3. Check Status

```bash
# Linux/Mac
./k8s-deploy.sh status development

# Windows
k8s-deploy.bat status development
```

### 4. Access Application

If using ingress, add to your `/etc/hosts` (Linux/Mac) or `C:\Windows\System32\drivers\etc\hosts` (Windows):

```
127.0.0.1 redis-pubsub-dev.local
```

Then access: http://redis-pubsub-dev.local

## Deployment Environments

### Development Environment

- **Namespace**: `redis-pubsub-dev`
- **Replicas**: 1 application instance
- **Resources**: Lower resource limits
- **Logging**: Debug level
- **Domain**: `redis-pubsub-dev.local`

```bash
./k8s-deploy.sh deploy development
```

### Production Environment

- **Namespace**: `redis-pubsub-prod`
- **Replicas**: 3 application instances (high availability)
- **Resources**: Higher resource limits
- **Logging**: Warn level
- **Domain**: `redis-pubsub.yourdomain.com`
- **TLS**: Enabled with cert-manager

```bash
./k8s-deploy.sh deploy production v1.0.0
```

## Configuration

### Environment Variables

Key configuration options (defined in ConfigMap):

- `SPRING_REDIS_HOST`: Redis service hostname
- `SPRING_REDIS_PORT`: Redis port (6379)
- `SERVER_PORT`: Application port (8445)
- `SPRING_PROFILES_ACTIVE`: Active Spring profiles
- `LOGGING_LEVEL_ROOT`: Root logging level

### Resource Limits

**Development:**
- App: 128Mi-512Mi memory, 100m-500m CPU
- Redis: 128Mi-512Mi memory, 100m-500m CPU

**Production:**
- App: 512Mi-2Gi memory, 300m-1500m CPU
- Redis: 512Mi-2Gi memory, 200m-1000m CPU

## Storage

- **Redis Data**: Persistent volume claim (`redis-pvc`)
- **Size**: 1Gi (adjustable)
- **Access Mode**: ReadWriteOnce
- **Storage Class**: `standard` (change based on your cluster)

## Networking

### Services

- **redis-service**: ClusterIP service for Redis (port 6379)
- **redis-pubsub-app-service**: ClusterIP service for application (port 8445)

### Ingress

- **Development**: `redis-pubsub-dev.local`
- **Production**: `redis-pubsub.yourdomain.com` (with TLS)

## Monitoring & Health Checks

### Health Endpoints

- **Liveness Probe**: `/actuator/health`
- **Readiness Probe**: `/actuator/health`
- **Metrics**: `/actuator/metrics` (Prometheus compatible)

### Logging

```bash
# Application logs
./k8s-deploy.sh logs development app

# Redis logs
./k8s-deploy.sh logs development redis

# All logs
./k8s-deploy.sh logs development all
```

## Troubleshooting

### Common Issues

1. **Image Pull Errors**
   ```bash
   # For local development with kind
   kind load docker-image redispubsub-redis-pubsub-app:latest
   ```

2. **Storage Issues**
   ```bash
   # Check storage classes
   kubectl get storageclass
   
   # Check PVC status
   kubectl get pvc -n redis-pubsub-dev
   ```

3. **Network Issues**
   ```bash
   # Check service endpoints
   kubectl get endpoints -n redis-pubsub-dev
   
   # Test connectivity
   kubectl exec -it deployment/redis-pubsub-app-deployment -n redis-pubsub-dev -- curl redis-service:6379
   ```

### Useful Commands

```bash
# Port forward to access locally
kubectl port-forward svc/redis-pubsub-app-service 8445:8445 -n redis-pubsub-dev

# Execute into pod
kubectl exec -it deployment/redis-pubsub-app-deployment -n redis-pubsub-dev -- /bin/bash

# Scale deployment
kubectl scale deployment redis-pubsub-app-deployment --replicas=3 -n redis-pubsub-dev

# Update image
kubectl set image deployment/redis-pubsub-app-deployment redis-pubsub-app=redispubsub-redis-pubsub-app:v1.1.0 -n redis-pubsub-dev
```

## Cleanup

```bash
# Delete development environment
./k8s-deploy.sh delete development

# Delete production environment
./k8s-deploy.sh delete production
```

## Security Considerations

1. **Network Policies**: Consider implementing network policies to restrict traffic
2. **RBAC**: Use Role-Based Access Control for service accounts
3. **Secrets**: Store sensitive data in Kubernetes secrets
4. **Image Security**: Scan images for vulnerabilities
5. **Pod Security**: Use Pod Security Standards

## Production Checklist

- [ ] Configure proper resource limits and requests
- [ ] Set up monitoring (Prometheus, Grafana)
- [ ] Configure log aggregation (ELK stack, Fluentd)
- [ ] Set up backup strategy for Redis data
- [ ] Configure network policies
- [ ] Set up SSL/TLS certificates
- [ ] Configure horizontal pod autoscaling
- [ ] Set up disaster recovery procedures

## Contributing

When making changes to Kubernetes manifests:

1. Test in development environment first
2. Update both base and overlay configurations as needed
3. Validate with `kubectl --dry-run=client`
4. Update documentation if adding new features
