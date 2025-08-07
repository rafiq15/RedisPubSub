#!/bin/bash
# Redis Pub/Sub Kubernetes Deployment Script
# Simplified deployment for development and production environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="dev"
ACTION="deploy"
IMAGE_TAG="latest"

# Functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}================================${NC}\n"
}

show_help() {
    cat << EOF
Redis Pub/Sub Kubernetes Deployment Script

Usage: $0 [OPTIONS] [ACTION]

ACTIONS:
    build                   Build Docker image
    deploy                  Deploy to Kubernetes
    status                  Show deployment status
    logs                    Show application logs
    port-forward           Start port forwarding
    delete                  Delete deployment
    help                    Show this help

OPTIONS:
    -e, --env ENV          Environment (dev|prod) [default: dev]
    -t, --tag TAG          Docker image tag [default: latest]
    -h, --help             Show this help

EXAMPLES:
    $0 build                           # Build Docker image
    $0 deploy                          # Deploy to development
    $0 -e prod deploy                  # Deploy to production
    $0 status                          # Show development status
    $0 -e prod status                  # Show production status
    $0 logs                            # Show development logs
    $0 port-forward                    # Start port forwarding for dev
    $0 delete                          # Delete development deployment

QUICK START:
    $0 build && $0 deploy && $0 port-forward

EOF
}

check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_error "docker is not installed"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

build_image() {
    print_header "Building Docker Image"
    
    print_info "Building image with tag: $IMAGE_TAG"
    docker build -t redispubsub-redis-pubsub-app:$IMAGE_TAG .
    
    # Load into kind if available
    if command -v kind &> /dev/null && kind get clusters | grep -q kind; then
        print_info "Loading image into kind cluster..."
        kind load docker-image redispubsub-redis-pubsub-app:$IMAGE_TAG
    fi
    
    print_success "Docker image built successfully"
}

deploy_app() {
    print_header "Deploying Redis Pub/Sub Application"
    
    local namespace="redis-pubsub-dev"
    local manifest_file="k8s/environments/development/all-in-one.yaml"
    
    if [ "$ENVIRONMENT" = "prod" ]; then
        namespace="redis-pubsub-prod"
        manifest_file="k8s/environments/production/all-in-one.yaml"
    fi
    
    print_info "Deploying to $ENVIRONMENT environment (namespace: $namespace)"
    
    # Apply the manifests
    kubectl apply -f $manifest_file
    
    # Wait for deployments to be ready
    print_info "Waiting for deployments to be ready..."
    kubectl wait --for=condition=available deployment --all -n $namespace --timeout=300s
    
    print_success "Application deployed successfully"
    show_status
}

show_status() {
    print_header "Deployment Status"
    
    local namespace="redis-pubsub-dev"
    if [ "$ENVIRONMENT" = "prod" ]; then
        namespace="redis-pubsub-prod"
    fi
    
    print_info "Namespace: $namespace"
    
    echo "Deployments:"
    kubectl get deployments -n $namespace
    
    echo -e "\nPods:"
    kubectl get pods -n $namespace
    
    echo -e "\nServices:"
    kubectl get services -n $namespace
    
    if [ "$ENVIRONMENT" = "prod" ]; then
        echo -e "\nIngress:"
        kubectl get ingress -n $namespace
    fi
}

show_logs() {
    local namespace="redis-pubsub-dev"
    if [ "$ENVIRONMENT" = "prod" ]; then
        namespace="redis-pubsub-prod"
    fi
    
    print_info "Showing application logs for $ENVIRONMENT environment..."
    kubectl logs -l app=redis-pubsub-app -n $namespace --tail=50 -f
}

start_port_forward() {
    local namespace="redis-pubsub-dev"
    local port="8445"
    
    if [ "$ENVIRONMENT" = "prod" ]; then
        namespace="redis-pubsub-prod"
        port="80"
    fi
    
    print_info "Starting port forwarding for $ENVIRONMENT environment..."
    print_info "Application will be available at: http://localhost:$port"
    print_warning "Press Ctrl+C to stop port forwarding"
    
    kubectl port-forward service/redis-pubsub-app-service $port:$([[ "$ENVIRONMENT" = "prod" ]] && echo "80" || echo "8445") -n $namespace
}

delete_deployment() {
    local namespace="redis-pubsub-dev"
    local manifest_file="k8s/environments/development/all-in-one.yaml"
    
    if [ "$ENVIRONMENT" = "prod" ]; then
        namespace="redis-pubsub-prod"
        manifest_file="k8s/environments/production/all-in-one.yaml"
    fi
    
    print_warning "This will delete the entire $ENVIRONMENT deployment!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deleting deployment..."
        kubectl delete -f $manifest_file
        print_success "Deployment deleted successfully"
    else
        print_info "Deletion cancelled"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        build|deploy|status|logs|port-forward|delete|help)
            ACTION="$1"
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate environment
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
    print_error "Invalid environment: $ENVIRONMENT. Use 'dev' or 'prod'"
    exit 1
fi

# Execute action
case $ACTION in
    build)
        check_prerequisites
        build_image
        ;;
    deploy)
        check_prerequisites
        deploy_app
        ;;
    status)
        check_prerequisites
        show_status
        ;;
    logs)
        check_prerequisites
        show_logs
        ;;
    port-forward)
        check_prerequisites
        start_port_forward
        ;;
    delete)
        check_prerequisites
        delete_deployment
        ;;
    help)
        show_help
        ;;
    *)
        print_error "Unknown action: $ACTION"
        show_help
        exit 1
        ;;
esac
