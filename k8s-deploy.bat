@echo off
REM Kubernetes Deployment Script for Redis Pub/Sub Application (Windows)

setlocal enabledelayedexpansion

REM Function to print colored output (simplified for Windows)
set "INFO=[INFO]"
set "WARNING=[WARNING]"
set "ERROR=[ERROR]"
set "HEADER=[HEADER]"

REM Function to check if kubectl is available
:check_kubectl
kubectl version --client >nul 2>&1
if errorlevel 1 (
    echo %ERROR% kubectl is not installed. Please install kubectl and try again.
    exit /b 1
)
echo %INFO% kubectl is available
goto :eof

REM Function to check if kustomize is available
:check_kustomize
kustomize version >nul 2>&1
if errorlevel 1 (
    echo %ERROR% kustomize is not installed. Please install kustomize and try again.
    exit /b 1
)
echo %INFO% kustomize is available
goto :eof

REM Function to check cluster connectivity
:check_cluster
kubectl cluster-info >nul 2>&1
if errorlevel 1 (
    echo %ERROR% Cannot connect to Kubernetes cluster. Please check your kubeconfig.
    exit /b 1
)
echo %INFO% Connected to Kubernetes cluster
kubectl cluster-info
goto :eof

REM Function to build Docker image
:build_image
set tag=%1
if "%tag%"=="" set tag=latest
echo %INFO% Building Docker image with tag: %tag%

docker build -t redispubsub-redis-pubsub-app:%tag% .

if errorlevel 1 (
    echo %ERROR% Failed to build Docker image
    exit /b 1
)
echo %INFO% Docker image built successfully
goto :eof

REM Function to load image into kind cluster
:load_image_kind
set tag=%1
if "%tag%"=="" set tag=latest

kind version >nul 2>&1
if not errorlevel 1 (
    echo %INFO% Loading image into kind cluster...
    kind load docker-image redispubsub-redis-pubsub-app:%tag%
    if not errorlevel 1 (
        echo %INFO% Image loaded into kind cluster successfully
    ) else (
        echo %WARNING% Failed to load image into kind cluster (this is OK if not using kind)
    )
) else (
    echo %WARNING% kind not found, skipping image load
)
goto :eof

REM Function to deploy application
:deploy_app
set environment=%1
set tag=%2
if "%environment%"=="" set environment=development
if "%tag%"=="" set tag=latest

echo %HEADER% Deploying Redis Pub/Sub Application to %environment% environment

REM Update image tag in kustomization if provided
if not "%tag%"=="latest" (
    cd k8s\overlays\%environment%
    kustomize edit set image redispubsub-redis-pubsub-app:%tag%
    cd ..\..\..
)

REM Apply the configuration
echo %INFO% Applying Kubernetes manifests for %environment%...
kustomize build k8s\overlays\%environment% | kubectl apply -f -

if errorlevel 1 (
    echo %ERROR% Failed to deploy application
    exit /b 1
)
echo %INFO% Application deployed successfully to %environment% environment
goto :eof

REM Function to check deployment status
:check_deployment
set environment=%1
if "%environment%"=="" set environment=development

set namespace=redis-pubsub
if "%environment%"=="development" set namespace=redis-pubsub-dev
if "%environment%"=="production" set namespace=redis-pubsub-prod

echo %INFO% Checking deployment status in namespace: %namespace%

REM Wait for deployments to be ready
echo %INFO% Waiting for deployments to be ready...
kubectl wait --for=condition=available deployment --all -n %namespace% --timeout=300s

REM Show status
echo %INFO% Deployment status:
kubectl get deployments -n %namespace%

echo %INFO% Pod status:
kubectl get pods -n %namespace%

echo %INFO% Service status:
kubectl get services -n %namespace%

REM Get application URL
echo %INFO% Getting application URL...
kubectl get ingress -n %namespace% >nul 2>&1
if not errorlevel 1 (
    kubectl get ingress -n %namespace%
)
goto :eof

REM Function to show logs
:show_logs
set environment=%1
set component=%2
if "%environment%"=="" set environment=development
if "%component%"=="" set component=app

set namespace=redis-pubsub
if "%environment%"=="development" set namespace=redis-pubsub-dev
if "%environment%"=="production" set namespace=redis-pubsub-prod

if "%component%"=="app" (
    echo %INFO% Showing application logs...
    kubectl logs -l app=redis-pubsub-app -n %namespace% --tail=50 -f
) else if "%component%"=="redis" (
    echo %INFO% Showing Redis logs...
    kubectl logs -l app=redis -n %namespace% --tail=50 -f
) else (
    echo %INFO% Showing all logs...
    kubectl logs -l app.kubernetes.io/name=redis-pubsub -n %namespace% --tail=50 -f
)
goto :eof

REM Function to delete deployment
:delete_deployment
set environment=%1
if "%environment%"=="" set environment=development

set namespace=redis-pubsub
if "%environment%"=="development" set namespace=redis-pubsub-dev
if "%environment%"=="production" set namespace=redis-pubsub-prod

echo %WARNING% This will delete the entire %environment% deployment!
set /p choice="Are you sure? (y/N): "
if /i "%choice%"=="y" (
    echo %INFO% Deleting deployment...
    kustomize build k8s\overlays\%environment% | kubectl delete -f -
    echo %INFO% Deployment deleted successfully
) else (
    echo %INFO% Deletion cancelled
)
goto :eof

REM Function to show help
:show_help
echo Redis Pub/Sub Kubernetes Deployment Script (Windows)
echo.
echo Usage: %0 [COMMAND] [OPTIONS]
echo.
echo Commands:
echo   build [TAG]              Build Docker image (default tag: latest)
echo   deploy [ENV] [TAG]       Deploy application (ENV: development/production, default: development)
echo   status [ENV]             Check deployment status (ENV: development/production, default: development)
echo   logs [ENV] [COMPONENT]   Show logs (ENV: development/production, COMPONENT: app/redis/all)
echo   delete [ENV]             Delete deployment (ENV: development/production, default: development)
echo   help                     Show this help message
echo.
echo Examples:
echo   %0 build v1.0.0
echo   %0 deploy development latest
echo   %0 deploy production v1.0.0
echo   %0 status production
echo   %0 logs development app
echo   %0 delete development
echo.
goto :eof

REM Main script logic
set command=%1
if "%command%"=="" set command=help

if "%command%"=="build" (
    call :check_kubectl
    call :build_image %2
    call :load_image_kind %2
) else if "%command%"=="deploy" (
    call :check_kubectl
    call :check_kustomize
    call :check_cluster
    call :deploy_app %2 %3
    call :check_deployment %2
) else if "%command%"=="status" (
    call :check_kubectl
    call :check_cluster
    call :check_deployment %2
) else if "%command%"=="logs" (
    call :check_kubectl
    call :check_cluster
    call :show_logs %2 %3
) else if "%command%"=="delete" (
    call :check_kubectl
    call :check_kustomize
    call :check_cluster
    call :delete_deployment %2
) else if "%command%"=="help" (
    call :show_help
) else if "%command%"=="-h" (
    call :show_help
) else if "%command%"=="--help" (
    call :show_help
) else (
    echo %ERROR% Unknown command: %command%
    call :show_help
    exit /b 1
)
