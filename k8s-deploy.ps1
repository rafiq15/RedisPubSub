# PowerShell Kubernetes Deployment Script for Redis Pub/Sub Application

param(
    [Parameter(Position=0)]
    [string]$Command = "help",
    [Parameter(Position=1)]
    [string]$Environment = "development",
    [Parameter(Position=2)]
    [string]$Tag = "latest"
)

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Header {
    param([string]$Message)
    Write-Host "[HEADER] $Message" -ForegroundColor Blue
}

# Function to check if kubectl is available
function Test-Kubectl {
    try {
        kubectl version --client --output=json | Out-Null
        Write-Status "kubectl is available"
        return $true
    }
    catch {
        Write-Error "kubectl is not installed. Please install kubectl and try again."
        return $false
    }
}

# Function to check if kind is available
function Test-Kind {
    try {
        kind version | Out-Null
        Write-Status "kind is available"
        return $true
    }
    catch {
        Write-Error "kind is not installed. Please install kind and try again."
        return $false
    }
}

# Function to check cluster connectivity
function Test-Cluster {
    try {
        kubectl cluster-info | Out-Null
        Write-Status "Connected to Kubernetes cluster"
        kubectl cluster-info
        return $true
    }
    catch {
        Write-Error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        return $false
    }
}

# Function to build Docker image
function Build-Image {
    param([string]$ImageTag = "latest")
    
    Write-Status "Building Docker image with tag: $ImageTag"
    
    docker build -t "redispubsub-redis-pubsub-app:$ImageTag" .
    
    if ($LASTEXITCODE -eq 0) {
        Write-Status "Docker image built successfully"
        return $true
    } else {
        Write-Error "Failed to build Docker image"
        return $false
    }
}

# Function to load image into kind cluster
function Load-ImageToKind {
    param([string]$ImageTag = "latest")
    
    if (Test-Kind) {
        Write-Status "Loading image into kind cluster..."
        kind load docker-image "redispubsub-redis-pubsub-app:$ImageTag"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Status "Image loaded into kind cluster successfully"
            return $true
        } else {
            Write-Warning "Failed to load image into kind cluster"
            return $false
        }
    } else {
        Write-Warning "kind not found, skipping image load"
        return $false
    }
}

# Function to apply Kubernetes manifests using kubectl
function Deploy-App {
    param(
        [string]$Environment = "development",
        [string]$ImageTag = "latest"
    )
    
    Write-Header "Deploying Redis Pub/Sub Application to $Environment environment"
    
    $namespace = switch ($Environment) {
        "development" { "redis-pubsub-dev" }
        "production" { "redis-pubsub-prod" }
        default { "redis-pubsub" }
    }
    
    # Create namespace first
    Write-Status "Creating namespace: $namespace"
    kubectl create namespace $namespace --dry-run=client -o yaml | kubectl apply -f -
    
    # Apply base manifests with modifications for the environment
    Write-Status "Applying Kubernetes manifests for $Environment..."
    
    # Apply base resources
    kubectl apply -f "k8s/base/configmap.yaml" -n $namespace
    kubectl apply -f "k8s/base/redis-pvc.yaml" -n $namespace
    kubectl apply -f "k8s/base/redis-deployment.yaml" -n $namespace
    kubectl apply -f "k8s/base/redis-service.yaml" -n $namespace
    
    # Modify and apply app deployment with correct image tag
    $appDeployment = Get-Content "k8s/base/app-deployment.yaml" -Raw
    $appDeployment = $appDeployment -replace "image: redispubsub-redis-pubsub-app:latest", "image: redispubsub-redis-pubsub-app:$ImageTag"
    $appDeployment = $appDeployment -replace "namespace: redis-pubsub", "namespace: $namespace"
    
    # Apply environment-specific modifications
    if ($Environment -eq "development") {
        $appDeployment = $appDeployment -replace "replicas: 2", "replicas: 1"
    }
    
    $appDeployment | kubectl apply -f - -n $namespace
    
    # Apply app service
    $appService = Get-Content "k8s/base/app-service.yaml" -Raw
    $appService = $appService -replace "namespace: redis-pubsub", "namespace: $namespace"
    $appService | kubectl apply -f - -n $namespace
    
    if ($LASTEXITCODE -eq 0) {
        Write-Status "Application deployed successfully to $Environment environment"
        return $true
    } else {
        Write-Error "Failed to deploy application"
        return $false
    }
}

# Function to check deployment status
function Get-DeploymentStatus {
    param([string]$Environment = "development")
    
    $namespace = switch ($Environment) {
        "development" { "redis-pubsub-dev" }
        "production" { "redis-pubsub-prod" }
        default { "redis-pubsub" }
    }
    
    Write-Status "Checking deployment status in namespace: $namespace"
    
    # Wait for deployments to be ready
    Write-Status "Waiting for deployments to be ready..."
    kubectl wait --for=condition=available deployment --all -n $namespace --timeout=300s
    
    # Show status
    Write-Status "Deployment status:"
    kubectl get deployments -n $namespace
    
    Write-Status "Pod status:"
    kubectl get pods -n $namespace
    
    Write-Status "Service status:"
    kubectl get services -n $namespace
    
    # Port forward for local access
    Write-Status "Setting up port forwarding for local access..."
    Write-Status "You can access the application at: http://localhost:8445"
    Write-Status "To set up port forwarding, run: kubectl port-forward svc/redis-pubsub-app-service 8445:8445 -n $namespace"
}

# Function to show logs
function Show-Logs {
    param(
        [string]$Environment = "development",
        [string]$Component = "app"
    )
    
    $namespace = switch ($Environment) {
        "development" { "redis-pubsub-dev" }
        "production" { "redis-pubsub-prod" }
        default { "redis-pubsub" }
    }
    
    switch ($Component) {
        "app" {
            Write-Status "Showing application logs..."
            kubectl logs -l app=redis-pubsub-app -n $namespace --tail=50 -f
        }
        "redis" {
            Write-Status "Showing Redis logs..."
            kubectl logs -l app=redis -n $namespace --tail=50 -f
        }
        default {
            Write-Status "Showing all logs..."
            kubectl logs -l app.kubernetes.io/name=redis-pubsub -n $namespace --tail=50 -f
        }
    }
}

# Function to delete deployment
function Remove-Deployment {
    param([string]$Environment = "development")
    
    $namespace = switch ($Environment) {
        "development" { "redis-pubsub-dev" }
        "production" { "redis-pubsub-prod" }
        default { "redis-pubsub" }
    }
    
    Write-Warning "This will delete the entire $Environment deployment!"
    $confirmation = Read-Host "Are you sure? (y/N)"
    
    if ($confirmation -eq "y" -or $confirmation -eq "Y") {
        Write-Status "Deleting deployment..."
        kubectl delete namespace $namespace
        Write-Status "Deployment deleted successfully"
    } else {
        Write-Status "Deletion cancelled"
    }
}

# Function to set up port forwarding
function Start-PortForward {
    param([string]$Environment = "development")
    
    $namespace = switch ($Environment) {
        "development" { "redis-pubsub-dev" }
        "production" { "redis-pubsub-prod" }
        default { "redis-pubsub" }
    }
    
    Write-Status "Starting port forwarding for $Environment environment..."
    Write-Status "Application will be available at: http://localhost:8445"
    Write-Status "Press Ctrl+C to stop port forwarding"
    
    kubectl port-forward svc/redis-pubsub-app-service 8445:8445 -n $namespace
}

# Function to show help
function Show-Help {
    Write-Host "Redis Pub/Sub Kubernetes Deployment Script (PowerShell)"
    Write-Host ""
    Write-Host "Usage: .\k8s-deploy.ps1 [COMMAND] [ENVIRONMENT] [TAG]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  build [TAG]              Build Docker image (default tag: latest)"
    Write-Host "  deploy [ENV] [TAG]       Deploy application (ENV: development/production, default: development)"
    Write-Host "  status [ENV]             Check deployment status (ENV: development/production, default: development)"
    Write-Host "  logs [ENV] [COMPONENT]   Show logs (ENV: development/production, COMPONENT: app/redis/all)"
    Write-Host "  forward [ENV]            Start port forwarding (ENV: development/production, default: development)"
    Write-Host "  delete [ENV]             Delete deployment (ENV: development/production, default: development)"
    Write-Host "  help                     Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\k8s-deploy.ps1 build v1.0.0"
    Write-Host "  .\k8s-deploy.ps1 deploy development latest"
    Write-Host "  .\k8s-deploy.ps1 status development"
    Write-Host "  .\k8s-deploy.ps1 logs development app"
    Write-Host "  .\k8s-deploy.ps1 forward development"
    Write-Host "  .\k8s-deploy.ps1 delete development"
    Write-Host ""
    Write-Host "For kind cluster:"
    Write-Host "  1. Build and load image: .\k8s-deploy.ps1 build"
    Write-Host "  2. Deploy application: .\k8s-deploy.ps1 deploy"
    Write-Host "  3. Forward ports: .\k8s-deploy.ps1 forward"
    Write-Host "  4. Access at: http://localhost:8445"
    Write-Host ""
}

# Main script logic
switch ($Command.ToLower()) {
    "build" {
        if (Test-Kubectl) {
            if (Build-Image $Tag) {
                Load-ImageToKind $Tag
            }
        }
    }
    "deploy" {
        if (Test-Kubectl -and Test-Cluster) {
            if (Deploy-App $Environment $Tag) {
                Get-DeploymentStatus $Environment
            }
        }
    }
    "status" {
        if (Test-Kubectl -and Test-Cluster) {
            Get-DeploymentStatus $Environment
        }
    }
    "logs" {
        if (Test-Kubectl -and Test-Cluster) {
            Show-Logs $Environment $Tag
        }
    }
    "forward" {
        if (Test-Kubectl -and Test-Cluster) {
            Start-PortForward $Environment
        }
    }
    "delete" {
        if (Test-Kubectl -and Test-Cluster) {
            Remove-Deployment $Environment
        }
    }
    "help" {
        Show-Help
    }
    default {
        Write-Error "Unknown command: $Command"
        Show-Help
    }
}
