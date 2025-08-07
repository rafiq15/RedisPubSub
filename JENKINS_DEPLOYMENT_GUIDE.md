# Jenkins Deployment Guide

This guide explains how to set up Jenkins for automated deployment of the Redis Pub/Sub application on Windows.

## Problem Resolution

The error you encountered happens because Jenkins is trying to execute a shell script (`sh`) on Windows, which doesn't have the `sh` command by default. Here are the solutions:

## Solution 1: Use Jenkinsfile (Recommended)

Create a pipeline job in Jenkins and use the provided `Jenkinsfile` which automatically detects the operating system and uses appropriate commands.

### Steps:
1. In Jenkins, create a new "Pipeline" job
2. In the pipeline configuration, set "Pipeline script from SCM"
3. Point to your Git repository
4. The `Jenkinsfile` will handle cross-platform deployment

## Solution 2: Use Windows Batch Script

If you prefer freestyle projects:

### For Freestyle Projects:
1. Create a new "Freestyle project" in Jenkins
2. In "Build Steps", choose **"Execute Windows batch command"** (NOT "Execute shell")
3. Use this command:
   ```bat
   call jenkins-build.bat
   ```

### For Pipeline Scripts:
```groovy
pipeline {
    agent any
    stages {
        stage('Deploy') {
            steps {
                bat 'jenkins-build.bat'
            }
        }
    }
}
```

## Solution 3: Use PowerShell Script

### For Freestyle Projects:
1. Create a new "Freestyle project" in Jenkins
2. In "Build Steps", choose **"Execute Windows batch command"**
3. Use this command:
   ```bat
   powershell -ExecutionPolicy Bypass -File jenkins-build.ps1
   ```

### For Pipeline Scripts:
```groovy
pipeline {
    agent any
    stages {
        stage('Deploy') {
            steps {
                powershell './jenkins-build.ps1'
            }
        }
    }
}
```

## Jenkins Configuration Requirements

### Prerequisites:
1. **Docker Desktop** installed and running on the Jenkins agent
2. **Java 17+** installed
3. **Git** installed and configured
4. **Gradle** (or use the included Gradle wrapper)

### Jenkins Plugins Required:
- Git plugin
- Docker Pipeline plugin (if using Docker in pipeline)
- PowerShell plugin (if using PowerShell scripts)

## Environment Variables

Set these in Jenkins job configuration or system configuration:

```bash
JAVA_HOME=/path/to/java
DOCKER_HOST=tcp://localhost:2375  # If Docker requires it
PATH=%PATH%;C:\path\to\docker;C:\path\to\git
```

## Build Steps Breakdown

The build process includes:

1. **Clean**: Remove previous build artifacts
2. **Build & Test**: Compile and test the application using Gradle
3. **Docker Build**: Create Docker image for the application
4. **Deploy**: Start services using Docker Compose
5. **Health Check**: Verify application is running correctly

## Troubleshooting

### Common Issues:

1. **"sh command not found"**
   - Solution: Use Windows batch commands instead of shell scripts
   - Change build step from "Execute shell" to "Execute Windows batch command"

2. **Docker not available**
   - Ensure Docker Desktop is running
   - Check if Jenkins user has access to Docker
   - Verify Docker is in the system PATH

3. **Port conflicts**
   - Stop existing containers: `docker-compose down`
   - Check if ports 8445 and 6379 are available

4. **Permission issues**
   - Run Jenkins as administrator (not recommended for production)
   - Or ensure Jenkins user has necessary permissions

5. **Gradle build fails**
   - Check Java version compatibility
   - Ensure JAVA_HOME is set correctly
   - Try using the Gradle wrapper: `gradlew.bat`

## Build Artifacts

After successful build, the following artifacts are created:
- `build/libs/redis-pub-sub-1.0.0.jar` - Application JAR file
- Docker image: `redis-pubsub-app:latest`
- Test reports in `build/reports/tests/`

## Application URLs (Post-Deployment)

- **Main Application**: http://localhost:8445
- **Live Messages**: http://localhost:8445/messages  
- **Health Check**: http://localhost:8445/actuator/health

## Quick Fix for Current Jenkins Job

If you want to quickly fix your existing Jenkins job:

1. Go to your Jenkins job configuration
2. In "Build" section, find the "Execute shell" step
3. **Delete** the "Execute shell" step
4. **Add** a new "Execute Windows batch command" step
5. Enter this command:
   ```bat
   call jenkins-build.bat
   ```
6. Save the configuration
7. Run the build again

## Advanced Configuration

### Multi-environment Deployment:
- Use Jenkins parameters to deploy to different environments
- Modify docker-compose files for different stages

### Integration with External Services:
- Add database connections
- Configure external Redis instances
- Set up monitoring and logging

### Security Considerations:
- Use Jenkins credentials for sensitive data
- Don't store secrets in build scripts
- Use secure Docker registries for production images
