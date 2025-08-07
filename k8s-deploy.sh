#!/bin/bash

# Kubernetes Deployment Script for Redis Pub/Sub Application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[HEADER]${NC} $1"
}

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl > /dev/null 2>&1; then
        print_error "kubectl is not installed. Please install kubectl and try again."
        exit 1
    fi
    print_status "kubectl is available"
}

# Function to check if kustomize is available
check_kustomize() {
    if ! command -v kustomize > /dev/null 2>&1; then
        print_error "kustomize is not installed. Please install kustomize and try again."
        exit 1
    fi
    print_status "kustomize is available"
}

# Function to check cluster connectivity
check_cluster() {
    if ! kubectl cluster-info > /dev/null 2>&1; then
        print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
    print_status "Connected to Kubernetes cluster"
    kubectl cluster-info
}

# Function to build Docker image
build_image() {
    local tag=${1:-latest}
    print_status "Building Docker image with tag: $tag"
    
    docker build -t redispubsub-redis-pubsub-app:$tag .
    
    if [ $? -eq 0 ]; then
        print_status "Docker image built successfully"
    else
        print_error "Failed to build Docker image"
        exit 1
    fi
}

# Function to load image into kind cluster (if using kind)
load_image_kind() {
    local tag=${1:-latest}
    
    if command -v kind > /dev/null 2>&1; then
        print_status "Loading image into kind cluster..."
        kind load docker-image redispubsub-redis-pubsub-app:$tag
        if [ $? -eq 0 ]; then
            print_status "Image loaded into kind cluster successfully"
        else
            print_warning "Failed to load image into kind cluster (this is OK if not using kind)"
        fi
    else
        print_warning "kind not found, skipping image load"
    fi
}

# Function to deploy application
deploy_app() {
    local environment=${1:-development}
    local tag=${2:-latest}
    
    print_header "Deploying Redis Pub/Sub Application to $environment environment"
    
    # Update image tag in kustomization if provided
    if [ "$tag" != "latest" ]; then
        cd k8s/overlays/$environment
        kustomize edit set image redispubsub-redis-pubsub-app:$tag
        cd ../../..
    fi
    
    # Apply the configuration
    print_status "Applying Kubernetes manifests for $environment..."
    kustomize build k8s/overlays/$environment | kubectl apply -f -
    
    if [ $? -eq 0 ]; then
        print_status "Application deployed successfully to $environment environment"
    else
        print_error "Failed to deploy application"
        exit 1
    fi
}

# Function to check deployment status
check_deployment() {
    local environment=${1:-development}
    local namespace="redis-pubsub"
    
    if [ "$environment" = "development" ]; then
        namespace="redis-pubsub-dev"
    elif [ "$environment" = "production" ]; then
        namespace="redis-pubsub-prod"
    fi
    
    print_status "Checking deployment status in namespace: $namespace"
    
    # Wait for deployments to be ready
    print_status "Waiting for deployments to be ready..."
    kubectl wait --for=condition=available deployment --all -n $namespace --timeout=300s
    
    # Show status
    print_status "Deployment status:"
    kubectl get deployments -n $namespace
    
    print_status "Pod status:"
    kubectl get pods -n $namespace
    
    print_status "Service status:"
    kubectl get services -n $namespace
    
    # Get application URL
    print_status "Getting application URL..."
    if kubectl get ingress -n $namespace > /dev/null 2>&1; then
        kubectl get ingress -n $namespace
    fi
}

# Function to show logs
show_logs() {
    local environment=${1:-development}
    local component=${2:-app}
    local namespace="redis-pubsub"
    
    if [ "$environment" = "development" ]; then
        namespace="redis-pubsub-dev"
    elif [ "$environment" = "production" ]; then
        namespace="redis-pubsub-prod"
    fi
    
    if [ "$component" = "app" ]; then
        print_status "Showing application logs..."
        kubectl logs -l app=redis-pubsub-app -n $namespace --tail=50 -f
    elif [ "$component" = "redis" ]; then
        print_status "Showing Redis logs..."
        kubectl logs -l app=redis -n $namespace --tail=50 -f
    else
        print_status "Showing all logs..."
        kubectl logs -l app.kubernetes.io/name=redis-pubsub -n $namespace --tail=50 -f
    fi
}

# Function to delete deployment
delete_deployment() {
    local environment=${1:-development}
    local namespace="redis-pubsub"
    
    if [ "$environment" = "development" ]; then
        namespace="redis-pubsub-dev"
    elif [ "$environment" = "production" ]; then
        namespace="redis-pubsub-prod"
    fi
    
    print_warning "This will delete the entire $environment deployment!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Deleting deployment..."
        kustomize build k8s/overlays/$environment | kubectl delete -f -
        print_status "Deployment deleted successfully"
    else
        print_status "Deletion cancelled"
    fi
}

# Function to show help
show_help() {
    echo "Redis Pub/Sub Kubernetes Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  build [TAG]              Build Docker image (default tag: latest)"
    echo "  deploy [ENV] [TAG]       Deploy application (ENV: development/production, default: development)"
    echo "  status [ENV]             Check deployment status (ENV: development/production, default: development)"
    echo "  logs [ENV] [COMPONENT]   Show logs (ENV: development/production, COMPONENT: app/redis/all)"
    echo "  delete [ENV]             Delete deployment (ENV: development/production, default: development)"
    echo "  help                     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 build v1.0.0"
    echo "  $0 deploy development latest"
    echo "  $0 deploy production v1.0.0"
    echo "  $0 status production"
    echo "  $0 logs development app"
    echo "  $0 delete development"
    echo ""
}

# Main script logic
main() {
    case "${1:-help}" in
        "build")
            check_kubectl
            build_image "${2:-latest}"
            load_image_kind "${2:-latest}"
            ;;
        "deploy")
            check_kubectl
            check_kustomize
            check_cluster
            deploy_app "${2:-development}" "${3:-latest}"
            check_deployment "${2:-development}"
            ;;
        "status")
            check_kubectl
            check_cluster
            check_deployment "${2:-development}"
            ;;
        "logs")
            check_kubectl
            check_cluster
            show_logs "${2:-development}" "${3:-app}"
            ;;
        "delete")
            check_kubectl
            check_kustomize
            check_cluster
            delete_deployment "${2:-development}"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
