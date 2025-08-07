@echo off
REM Jenkins Build Script for Windows - Redis Pub/Sub Application
REM This script handles the complete build and deployment process for Jenkins on Windows

setlocal enabledelayedexpansion

echo =================================================
echo Redis Pub/Sub Application - Jenkins Build Script
echo =================================================

REM Set build environment variables
set "BUILD_NUMBER=%BUILD_NUMBER%"
if "%BUILD_NUMBER%"=="" set "BUILD_NUMBER=local"
set "DOCKER_IMAGE=redis-pubsub-app"
set "DOCKER_TAG=%BUILD_NUMBER%"

echo [INFO] Build Number: %BUILD_NUMBER%
echo [INFO] Docker Image: %DOCKER_IMAGE%:%DOCKER_TAG%

REM Step 1: Clean previous builds
echo.
echo [STEP 1] Cleaning previous builds...
if exist build rmdir /s /q build
echo [INFO] Build directory cleaned

REM Step 2: Build and test the application
echo.
echo [STEP 2] Building and testing application...
call gradlew.bat clean build test
if errorlevel 1 (
    echo [ERROR] Build or tests failed
    exit /b 1
)
echo [INFO] Build and tests completed successfully

REM Step 3: Check Docker availability
echo.
echo [STEP 3] Checking Docker availability...
docker --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not available
    exit /b 1
)
echo [INFO] Docker is available

REM Step 4: Stop existing containers
echo.
echo [STEP 4] Stopping existing containers...
docker-compose down 2>nul || echo [INFO] No existing containers to stop

REM Step 5: Build Docker image
echo.
echo [STEP 5] Building Docker image...
docker build -t %DOCKER_IMAGE%:%DOCKER_TAG% .
if errorlevel 1 (
    echo [ERROR] Docker build failed
    exit /b 1
)

docker tag %DOCKER_IMAGE%:%DOCKER_TAG% %DOCKER_IMAGE%:latest
echo [INFO] Docker image built successfully

REM Step 6: Deploy with Docker Compose
echo.
echo [STEP 6] Deploying application...
docker-compose up -d --build
if errorlevel 1 (
    echo [ERROR] Deployment failed
    exit /b 1
)
echo [INFO] Application deployed successfully

REM Step 7: Health check
echo.
echo [STEP 7] Performing health check...
echo [INFO] Waiting for application to start...
timeout /t 30 /nobreak >nul

REM Try health check for up to 5 minutes
set /a "max_attempts=30"
set /a "attempt=0"

:health_check_loop
set /a "attempt+=1"
curl -f http://localhost:8445/actuator/health >nul 2>&1
if not errorlevel 1 (
    echo [INFO] Application is healthy and ready!
    goto :health_check_success
)

if %attempt% geq %max_attempts% (
    echo [ERROR] Health check failed after %max_attempts% attempts
    echo [ERROR] Application logs:
    docker-compose logs redis-pubsub-app
    exit /b 1
)

echo [INFO] Health check attempt %attempt%/%max_attempts% - waiting...
timeout /t 10 /nobreak >nul
goto :health_check_loop

:health_check_success
echo.
echo [SUCCESS] Deployment completed successfully!
echo.
echo Application URLs:
echo   • Main Application: http://localhost:8445
echo   • Live Messages: http://localhost:8445/messages
echo   • Health Check: http://localhost:8445/actuator/health
echo.
echo Management Commands:
echo   • View logs: docker-compose logs -f
echo   • Stop application: docker-compose down
echo   • Restart: docker-compose restart

exit /b 0
