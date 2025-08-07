#!/bin/bash

# Redis Pub/Sub Application Deployment Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_status "Docker is running"
}

# Function to check if Docker Compose is available
check_docker_compose() {
    if ! command -v docker-compose > /dev/null 2>&1; then
        print_error "Docker Compose is not installed. Please install Docker Compose and try again."
        exit 1
    fi
    print_status "Docker Compose is available"
}

# Function to build and start services
start_services() {
    print_status "Building and starting Redis Pub/Sub application..."
    
    # Build and start services
    docker-compose up -d --build
    
    print_status "Services started successfully!"
    print_status "Waiting for services to be ready..."
    
    # Wait for services to be healthy
    sleep 10
    
    # Check if services are running
    if docker-compose ps | grep -q "Up"; then
        print_status "✅ Services are running!"
        echo ""
        print_status "🌐 Application URLs:"
        echo "   • Main Application: http://localhost:8445"
        echo "   • Live Messages: http://localhost:8445/messages"
        echo "   • Health Check: http://localhost:8445/actuator/health"
        echo ""
        print_status "📊 View logs with: docker-compose logs -f"
        print_status "🛑 Stop services with: docker-compose down"
    else
        print_error "Some services failed to start. Check logs with: docker-compose logs"
        exit 1
    fi
}

# Function to stop services
stop_services() {
    print_status "Stopping Redis Pub/Sub application..."
    docker-compose down
    print_status "Services stopped successfully!"
}

# Function to view logs
view_logs() {
    print_status "Viewing application logs..."
    docker-compose logs -f
}

# Function to show status
show_status() {
    print_status "Service Status:"
    docker-compose ps
    echo ""
    
    print_status "Health Checks:"
    if curl -s http://localhost:8445/actuator/health > /dev/null 2>&1; then
        echo "✅ Application is healthy"
    else
        echo "❌ Application is not responding"
    fi
}

# Function to clean up
cleanup() {
    print_warning "This will remove all containers, networks, and volumes..."
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleaning up..."
        docker-compose down -v --remove-orphans
        docker system prune -f
        print_status "Cleanup completed!"
    else
        print_status "Cleanup cancelled"
    fi
}

# Function to show help
show_help() {
    echo "Redis Pub/Sub Application Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start     Build and start the application"
    echo "  stop      Stop the application"
    echo "  restart   Restart the application"
    echo "  logs      View application logs"
    echo "  status    Show service status"
    echo "  cleanup   Remove all containers and volumes"
    echo "  help      Show this help message"
    echo ""
}

# Main script logic
main() {
    case "${1:-start}" in
        "start")
            check_docker
            check_docker_compose
            start_services
            ;;
        "stop")
            check_docker
            check_docker_compose
            stop_services
            ;;
        "restart")
            check_docker
            check_docker_compose
            stop_services
            start_services
            ;;
        "logs")
            check_docker
            check_docker_compose
            view_logs
            ;;
        "status")
            check_docker
            check_docker_compose
            show_status
            ;;
        "cleanup")
            check_docker
            check_docker_compose
            cleanup
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
