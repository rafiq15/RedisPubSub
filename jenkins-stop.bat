@echo off
REM Jenkins Stop Script for Redis Pub/Sub Application
REM This script stops the Docker containers deployed by Jenkins

echo =============================================
echo Stopping Redis Pub/Sub Application
echo =============================================

REM Set variables
set "APP_CONTAINER=redis-pubsub-app"
set "REDIS_CONTAINER=redis-server"

echo [INFO] Checking running containers...
docker ps | findstr redis

echo.
echo [INFO] Stopping application containers...

REM Stop containers individually
docker stop %APP_CONTAINER% 2>nul && echo [SUCCESS] Stopped %APP_CONTAINER% || echo [INFO] %APP_CONTAINER% not running
docker stop %REDIS_CONTAINER% 2>nul && echo [SUCCESS] Stopped %REDIS_CONTAINER% || echo [INFO] %REDIS_CONTAINER% not running

echo.
echo [INFO] Trying docker-compose down...
docker-compose down 2>nul || echo [INFO] No docker-compose services to stop

echo.
echo [INFO] Checking for any remaining redis containers...
docker ps -a | findstr redis || echo [INFO] No Redis containers found

echo.
echo [INFO] Removing stopped containers (optional)...
docker rm %APP_CONTAINER% %REDIS_CONTAINER% 2>nul || echo [INFO] Containers already removed or not found

echo.
echo =============================================
echo Redis Pub/Sub Application Stop Process Complete
echo =============================================

REM Show final status
echo [INFO] Current running containers:
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo.
echo [SUCCESS] Stop process completed successfully!
exit /b 0
