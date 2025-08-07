@echo off
REM Quick deployment script for Redis Pub/Sub application
REM This script builds, deploys, and starts port forwarding in one command

echo ========================================
echo Redis Pub/Sub Quick Deploy
echo ========================================
echo.

REM Check if kubectl is available
kubectl version --client >nul 2>&1
if errorlevel 1 (
    echo [ERROR] kubectl is not installed or not in PATH
    pause
    exit /b 1
)

REM Check if docker is available
docker version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] docker is not installed or not in PATH
    pause
    exit /b 1
)

echo [INFO] Building Docker image...
docker build -t redispubsub-redis-pubsub-app:latest .
if errorlevel 1 (
    echo [ERROR] Failed to build Docker image
    pause
    exit /b 1
)

REM Load into kind if available
kind version >nul 2>&1
if not errorlevel 1 (
    echo [INFO] Loading image into kind cluster...
    kind load docker-image redispubsub-redis-pubsub-app:latest
)

echo [INFO] Deploying to Kubernetes...
kubectl apply -f k8s\environments\development\all-in-one.yaml
if errorlevel 1 (
    echo [ERROR] Failed to deploy to Kubernetes
    pause
    exit /b 1
)

echo [INFO] Waiting for deployment to be ready...
kubectl wait --for=condition=available deployment --all -n redis-pubsub-dev --timeout=300s

echo [INFO] Deployment status:
kubectl get pods -n redis-pubsub-dev

echo.
echo [SUCCESS] Deployment completed!
echo.
echo To access the application:
echo 1. Run: kubectl port-forward service/redis-pubsub-app-service 8445:8445 -n redis-pubsub-dev
echo 2. Open: http://localhost:8445
echo.
echo Or use the port forwarding script:
echo scripts\port-forward.bat
echo.
pause
