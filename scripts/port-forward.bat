@echo off
REM Port forwarding script for Redis Pub/Sub application

echo ========================================
echo Redis Pub/Sub Port Forwarding
echo ========================================
echo.

REM Check if the deployment exists
kubectl get deployment redis-pubsub-app-deployment -n redis-pubsub-dev >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Application is not deployed. Please run quick-deploy.bat first.
    pause
    exit /b 1
)

echo [INFO] Starting port forwarding...
echo [INFO] Application will be available at: http://localhost:8445
echo [INFO] Press Ctrl+C to stop port forwarding
echo.

kubectl port-forward service/redis-pubsub-app-service 8445:8445 -n redis-pubsub-dev
