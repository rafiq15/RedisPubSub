# Redis Pub/Sub Kubernetes Deployment Script (PowerShell)
# Simplified deployment for development and production environments

param(
    [Parameter(Position=0)]
    [ValidateSet("build", "deploy", "status", "logs", "port-forward", "delete", "help")]
    [string]$Action = "help",
    
    [Parameter()]
    [ValidateSet("dev", "prod")]
    [string]$Environment = "dev",
    
    [Parameter()]
    [string]$ImageTag = "latest",
    
    [Parameter()]
    [switch]$Help
)

# Colors for output
$InfoColor = "Blue"
$SuccessColor = "Green"
$WarningColor = "Yellow"
$ErrorColor = "Red"

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $InfoColor
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor $SuccessColor
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $WarningColor
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $ErrorColor
}

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "================================" -ForegroundColor $InfoColor
    Write-Host " $Message" -ForegroundColor $InfoColor
    Write-Host "================================" -ForegroundColor $InfoColor
    Write-Host ""
}

function Show-Help {
    @"
Redis Pub/Sub Kubernetes Deployment Script (PowerShell)

Usage: .\deploy.ps1 [ACTION] [-Environment ENV] [-ImageTag TAG]

ACTIONS:
    build                   Build Docker image
    deploy                  Deploy to Kubernetes
    status                  Show deployment status
    logs                    Show application logs
    port-forward           Start port forwarding
    delete                  Delete deployment
    help                    Show this help

OPTIONS:
    -Environment ENV       Environment (dev|prod) [default: dev]
    -ImageTag TAG          Docker image tag [default: latest]
    -Help                  Show this help

EXAMPLES:
    .\deploy.ps1 build                              # Build Docker image
    .\deploy.ps1 deploy                             # Deploy to development
    .\deploy.ps1 deploy -Environment prod           # Deploy to production
    .\deploy.ps1 status                             # Show development status
    .\deploy.ps1 status -Environment prod           # Show production status
    .\deploy.ps1 logs                               # Show development logs
    .\deploy.ps1 port-forward                       # Start port forwarding for dev
    .\deploy.ps1 delete                             # Delete development deployment

QUICK START:
    .\deploy.ps1 build
    .\deploy.ps1 deploy
    .\deploy.ps1 port-forward

"@
}

function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Check kubectl
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        Write-Error "kubectl is not installed"
        exit 1
    }
    
    # Check docker
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "docker is not installed"
        exit 1
    }
    
    # Check cluster connectivity
    try {
        kubectl cluster-info | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Cluster connection failed"
        }
    }
    catch {
        Write-Error "Cannot connect to Kubernetes cluster"
        exit 1
    }
    
    Write-Success "Prerequisites check passed"
}

function Build-Image {
    Write-Header "Building Docker Image"
    
    Write-Info "Building image with tag: $ImageTag"
    docker build -t "redispubsub-redis-pubsub-app:$ImageTag" .
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build Docker image"
        exit 1
    }
    
    # Load into kind if available
    if (Get-Command kind -ErrorAction SilentlyContinue) {
        $clusters = kind get clusters 2>$null
        if ($clusters -contains "kind") {
            Write-Info "Loading image into kind cluster..."
            kind load docker-image "redispubsub-redis-pubsub-app:$ImageTag"
        }
    }
    
    Write-Success "Docker image built successfully"
}

function Deploy-App {
    Write-Header "Deploying Redis Pub/Sub Application"
    
    $namespace = "redis-pubsub-dev"
    $manifestFile = "k8s\environments\development\all-in-one.yaml"
    
    if ($Environment -eq "prod") {
        $namespace = "redis-pubsub-prod"
        $manifestFile = "k8s\environments\production\all-in-one.yaml"
    }
    
    Write-Info "Deploying to $Environment environment (namespace: $namespace)"
    
    # Apply the manifests
    kubectl apply -f $manifestFile
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to deploy application"
        exit 1
    }
    
    # Wait for deployments to be ready
    Write-Info "Waiting for deployments to be ready..."
    kubectl wait --for=condition=available deployment --all -n $namespace --timeout=300s
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Deployment did not become ready in time"
        exit 1
    }
    
    Write-Success "Application deployed successfully"
    Show-Status
}

function Show-Status {
    Write-Header "Deployment Status"
    
    $namespace = "redis-pubsub-dev"
    if ($Environment -eq "prod") {
        $namespace = "redis-pubsub-prod"
    }
    
    Write-Info "Namespace: $namespace"
    
    Write-Host "Deployments:" -ForegroundColor $InfoColor
    kubectl get deployments -n $namespace
    
    Write-Host "`nPods:" -ForegroundColor $InfoColor
    kubectl get pods -n $namespace
    
    Write-Host "`nServices:" -ForegroundColor $InfoColor
    kubectl get services -n $namespace
    
    if ($Environment -eq "prod") {
        Write-Host "`nIngress:" -ForegroundColor $InfoColor
        kubectl get ingress -n $namespace
    }
}

function Show-Logs {
    $namespace = "redis-pubsub-dev"
    if ($Environment -eq "prod") {
        $namespace = "redis-pubsub-prod"
    }
    
    Write-Info "Showing application logs for $Environment environment..."
    kubectl logs -l app=redis-pubsub-app -n $namespace --tail=50 -f
}

function Start-PortForward {
    $namespace = "redis-pubsub-dev"
    $port = "8445"
    
    if ($Environment -eq "prod") {
        $namespace = "redis-pubsub-prod"
        $port = "80"
    }
    
    Write-Info "Starting port forwarding for $Environment environment..."
    Write-Info "Application will be available at: http://localhost:$port"
    Write-Warning "Press Ctrl+C to stop port forwarding"
    
    $targetPort = if ($Environment -eq "prod") { "80" } else { "8445" }
    kubectl port-forward "service/redis-pubsub-app-service" "${port}:${targetPort}" -n $namespace
}

function Remove-Deployment {
    $namespace = "redis-pubsub-dev"
    $manifestFile = "k8s\environments\development\all-in-one.yaml"
    
    if ($Environment -eq "prod") {
        $namespace = "redis-pubsub-prod"
        $manifestFile = "k8s\environments\production\all-in-one.yaml"
    }
    
    Write-Warning "This will delete the entire $Environment deployment!"
    $confirmation = Read-Host "Are you sure? (y/N)"
    
    if ($confirmation -eq "y" -or $confirmation -eq "Y") {
        Write-Info "Deleting deployment..."
        kubectl delete -f $manifestFile
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Deployment deleted successfully"
        } else {
            Write-Error "Failed to delete deployment"
            exit 1
        }
    } else {
        Write-Info "Deletion cancelled"
    }
}

# Main script logic
if ($Help -or $Action -eq "help") {
    Show-Help
    exit 0
}

# Execute action
switch ($Action) {
    "build" {
        Test-Prerequisites
        Build-Image
    }
    "deploy" {
        Test-Prerequisites
        Deploy-App
    }
    "status" {
        Test-Prerequisites
        Show-Status
    }
    "logs" {
        Test-Prerequisites
        Show-Logs
    }
    "port-forward" {
        Test-Prerequisites
        Start-PortForward
    }
    "delete" {
        Test-Prerequisites
        Remove-Deployment
    }
    default {
        Write-Error "Unknown action: $Action"
        Show-Help
        exit 1
    }
}
