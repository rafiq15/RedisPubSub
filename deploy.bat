@echo off
setlocal enabledelayedexpansion

REM Redis Pub/Sub Application Deployment Script for Windows

set "command=%~1"
if "%command%"=="" set "command=start"

echo.
echo Redis Pub/Sub Application Deployment Script
echo ==========================================

goto :%command% 2>nul || goto :help

:start
echo [INFO] Starting Redis Pub/Sub application...
call :check_docker
if errorlevel 1 exit /b 1

echo [INFO] Building and starting services...
docker-compose up -d --build

if errorlevel 1 (
    echo [ERROR] Failed to start services
    exit /b 1
)

echo [INFO] Services started successfully!
echo [INFO] Waiting for services to be ready...
timeout /t 10 /nobreak >nul

echo.
echo [INFO] Application URLs:
echo   • Main Application: http://localhost:8445
echo   • Live Messages: http://localhost:8445/messages
echo   • Health Check: http://localhost:8445/actuator/health
echo.
echo [INFO] View logs with: docker-compose logs -f
echo [INFO] Stop services with: docker-compose down
goto :eof

:stop
echo [INFO] Stopping Redis Pub/Sub application...
call :check_docker
if errorlevel 1 exit /b 1

docker-compose down
echo [INFO] Services stopped successfully!
goto :eof

:restart
echo [INFO] Restarting Redis Pub/Sub application...
call :stop
call :start
goto :eof

:logs
echo [INFO] Viewing application logs...
call :check_docker
if errorlevel 1 exit /b 1

docker-compose logs -f
goto :eof

:status
echo [INFO] Service Status:
call :check_docker
if errorlevel 1 exit /b 1

docker-compose ps
echo.

echo [INFO] Health Checks:
curl -s http://localhost:8445/actuator/health >nul 2>&1
if errorlevel 1 (
    echo ❌ Application is not responding
) else (
    echo ✅ Application is healthy
)
goto :eof

:cleanup
echo [WARNING] This will remove all containers, networks, and volumes...
set /p "confirm=Are you sure? (y/N): "
if /i not "%confirm%"=="y" (
    echo [INFO] Cleanup cancelled
    goto :eof
)

echo [INFO] Cleaning up...
call :check_docker
if errorlevel 1 exit /b 1

docker-compose down -v --remove-orphans
docker system prune -f
echo [INFO] Cleanup completed!
goto :eof

:help
echo.
echo Usage: %~nx0 [COMMAND]
echo.
echo Commands:
echo   start     Build and start the application
echo   stop      Stop the application
echo   restart   Restart the application
echo   logs      View application logs
echo   status    Show service status
echo   cleanup   Remove all containers and volumes
echo   help      Show this help message
echo.
goto :eof

:check_docker
docker info >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not running. Please start Docker and try again.
    exit /b 1
)
echo [INFO] Docker is running

docker-compose --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker Compose is not available. Please install Docker Compose.
    exit /b 1
)
echo [INFO] Docker Compose is available
goto :eof
