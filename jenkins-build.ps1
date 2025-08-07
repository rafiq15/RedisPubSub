# Jenkins Build Script for Windows PowerShell - Redis Pub/Sub Application
# This script handles the complete build and deployment process for Jenkins on Windows

param(
    [string]$BuildNumber = "local",
    [string]$DockerImage = "redis-pubsub-app",
    [switch]$SkipTests = $false,
    [switch]$CleanBuild = $true
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to write colored output
function Write-ColorOutput {
    param([string]$Text, [string]$Color = "White")
    
    switch ($Color) {
        "Red" { Write-Host $Text -ForegroundColor Red }
        "Green" { Write-Host $Text -ForegroundColor Green }
        "Yellow" { Write-Host $Text -ForegroundColor Yellow }
        "Blue" { Write-Host $Text -ForegroundColor Blue }
        default { Write-Host $Text }
    }
}

function Write-Step {
    param([string]$StepName, [int]$StepNumber)
    Write-Host ""
    Write-ColorOutput "========================================" "Blue"
    Write-ColorOutput "[STEP $StepNumber] $StepName" "Blue"
    Write-ColorOutput "========================================" "Blue"
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "[INFO] $Message" "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "[WARNING] $Message" "Yellow"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "[ERROR] $Message" "Red"
}

try {
    # Display build information
    Write-ColorOutput "========================================" "Blue"
    Write-ColorOutput "Redis Pub/Sub Jenkins Build Script" "Blue"
    Write-ColorOutput "========================================" "Blue"
    Write-Info "Build Number: $BuildNumber"
    Write-Info "Docker Image: $DockerImage`:$BuildNumber"
    Write-Info "Skip Tests: $SkipTests"
    Write-Info "Clean Build: $CleanBuild"

    # Step 1: Clean previous builds
    if ($CleanBuild) {
        Write-Step "Cleaning previous builds" 1
        if (Test-Path "build") {
            Remove-Item -Path "build" -Recurse -Force
            Write-Info "Build directory cleaned"
        } else {
            Write-Info "No build directory to clean"
        }
    }

    # Step 2: Build application
    Write-Step "Building application" 2
    
    $gradleCommand = if ($SkipTests) { "clean build -x test" } else { "clean build test" }
    
    if (Test-Path "gradlew.bat") {
        Write-Info "Using Gradle wrapper..."
        $process = Start-Process -FilePath ".\gradlew.bat" -ArgumentList $gradleCommand -Wait -PassThru -NoNewWindow
    } else {
        Write-Info "Using system Gradle..."
        $process = Start-Process -FilePath "gradle" -ArgumentList $gradleCommand -Wait -PassThru -NoNewWindow
    }
    
    if ($process.ExitCode -ne 0) {
        throw "Gradle build failed with exit code $($process.ExitCode)"
    }
    Write-Info "Application built successfully"

    # Step 3: Check Docker availability
    Write-Step "Checking Docker availability" 3
    try {
        $dockerVersion = docker --version
        Write-Info "Docker is available: $dockerVersion"
    } catch {
        throw "Docker is not available or not in PATH"
    }

    # Step 4: Stop existing containers
    Write-Step "Stopping existing containers" 4
    try {
        docker-compose down 2>$null
        Write-Info "Existing containers stopped"
    } catch {
        Write-Warning "No existing containers to stop or docker-compose not available"
    }

    # Step 5: Build Docker image
    Write-Step "Building Docker image" 5
    
    $buildProcess = Start-Process -FilePath "docker" -ArgumentList "build", "-t", "$DockerImage`:$BuildNumber", "." -Wait -PassThru -NoNewWindow
    if ($buildProcess.ExitCode -ne 0) {
        throw "Docker build failed"
    }

    # Tag as latest
    $tagProcess = Start-Process -FilePath "docker" -ArgumentList "tag", "$DockerImage`:$BuildNumber", "$DockerImage`:latest" -Wait -PassThru -NoNewWindow
    if ($tagProcess.ExitCode -ne 0) {
        throw "Docker tag failed"
    }
    
    Write-Info "Docker image built and tagged successfully"

    # Step 6: Deploy with Docker Compose
    Write-Step "Deploying application" 6
    
    $deployProcess = Start-Process -FilePath "docker-compose" -ArgumentList "up", "-d", "--build" -Wait -PassThru -NoNewWindow
    if ($deployProcess.ExitCode -ne 0) {
        throw "Docker Compose deployment failed"
    }
    
    Write-Info "Application deployed successfully"

    # Step 7: Health check
    Write-Step "Performing health check" 7
    Write-Info "Waiting for application to start..."
    Start-Sleep -Seconds 30

    $maxAttempts = 30
    $attempt = 0
    $healthCheckUrl = "http://localhost:8445/actuator/health"

    do {
        $attempt++
        Write-Info "Health check attempt $attempt/$maxAttempts"
        
        try {
            $response = Invoke-WebRequest -Uri $healthCheckUrl -Method Get -TimeoutSec 10
            if ($response.StatusCode -eq 200) {
                Write-Info "Application is healthy and ready!"
                break
            }
        } catch {
            if ($attempt -eq $maxAttempts) {
                Write-Error "Health check failed after $maxAttempts attempts"
                Write-Error "Application logs:"
                docker-compose logs redis-pubsub-app
                throw "Health check failed"
            }
            Write-Info "Health check failed, waiting 10 seconds..."
            Start-Sleep -Seconds 10
        }
    } while ($attempt -lt $maxAttempts)

    # Success message
    Write-Host ""
    Write-ColorOutput "========================================" "Green"
    Write-ColorOutput "DEPLOYMENT COMPLETED SUCCESSFULLY!" "Green"
    Write-ColorOutput "========================================" "Green"
    Write-Host ""
    Write-Info "Application URLs:"
    Write-Host "  • Main Application: http://localhost:8445"
    Write-Host "  • Live Messages: http://localhost:8445/messages"
    Write-Host "  • Health Check: http://localhost:8445/actuator/health"
    Write-Host ""
    Write-Info "Management Commands:"
    Write-Host "  • View logs: docker-compose logs -f"
    Write-Host "  • Stop application: docker-compose down"
    Write-Host "  • Restart: docker-compose restart"

} catch {
    Write-Error "Build failed: $($_.Exception.Message)"
    
    # Cleanup on failure
    Write-Warning "Performing cleanup..."
    try {
        docker-compose down 2>$null
    } catch {
        Write-Warning "Cleanup completed with warnings"
    }
    
    exit 1
}
