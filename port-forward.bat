@echo off
echo Setting up port forwarding for Redis Pub/Sub application...
echo Application will be available at: http://localhost:8445
echo Press Ctrl+C to stop port forwarding
echo.
kubectl port-forward svc/redis-pubsub-app-service 8445:8445 -n redis-pubsub-dev
