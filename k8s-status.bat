@echo off
echo ================================================
echo   Redis Pub/Sub Kubernetes Deployment Status
echo ================================================
echo.

echo Checking namespace...
kubectl get namespace redis-pubsub-dev

echo.
echo Checking deployments...
kubectl get deployments -n redis-pubsub-dev

echo.
echo Checking pods...
kubectl get pods -n redis-pubsub-dev

echo.
echo Checking services...
kubectl get services -n redis-pubsub-dev

echo.
echo Checking persistent volume claims...
kubectl get pvc -n redis-pubsub-dev

echo.
echo ================================================
echo   Access Instructions
echo ================================================
echo 1. To access the application, run: port-forward.bat
echo 2. Then open your browser to: http://localhost:8445
echo 3. To check logs: kubectl logs -l app=redis-pubsub-app -n redis-pubsub-dev
echo 4. To check Redis logs: kubectl logs -l app=redis -n redis-pubsub-dev
echo.
echo ================================================
echo   Cleanup Instructions
echo ================================================
echo To delete the deployment: kubectl delete namespace redis-pubsub-dev
echo.
