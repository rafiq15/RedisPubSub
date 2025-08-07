@echo off
REM Cleanup script for Redis Pub/Sub application

echo ========================================
echo Redis Pub/Sub Cleanup
echo ========================================
echo.

set /p environment="Enter environment to cleanup (dev/prod) [dev]: "
if "%environment%"=="" set environment=dev

if "%environment%"=="dev" (
    set namespace=redis-pubsub-dev
    set manifest=k8s\environments\development\all-in-one.yaml
) else if "%environment%"=="prod" (
    set namespace=redis-pubsub-prod
    set manifest=k8s\environments\production\all-in-one.yaml
) else (
    echo [ERROR] Invalid environment. Use 'dev' or 'prod'
    pause
    exit /b 1
)

echo [WARNING] This will delete the entire %environment% deployment!
set /p confirm="Are you sure? (y/N): "
if /i not "%confirm%"=="y" (
    echo [INFO] Cleanup cancelled
    pause
    exit /b 0
)

echo [INFO] Deleting %environment% deployment...
kubectl delete -f %manifest%

echo [INFO] Cleanup completed
pause
