pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'redis-pubsub-app'
        DOCKER_TAG = "${BUILD_NUMBER}"
        COMPOSE_PROJECT_NAME = 'redis-pubsub'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build and Test') {
            steps {
                script {
                    if (isUnix()) {
                        // Linux/Mac environment
                        sh './gradlew clean build test'
                    } else {
                        // Windows environment
                        bat './gradlew.bat clean build test'
                    }
                }
            }
            post {
                always {
                    publishTestResults testResultsPattern: 'build/test-results/test/*.xml'
                    archiveArtifacts artifacts: 'build/libs/*.jar', fingerprint: true
                }
            }
        }
        
        stage('Docker Build') {
            steps {
                script {
                    if (isUnix()) {
                        sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                        sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
                    } else {
                        bat "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                        bat "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
                    }
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    if (isUnix()) {
                        sh 'docker-compose down || true'
                        sh 'docker-compose up -d --build'
                    } else {
                        bat 'docker-compose down || echo "No services to stop"'
                        bat 'docker-compose up -d --build'
                    }
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    sleep(time: 30, unit: 'SECONDS')
                    if (isUnix()) {
                        sh '''
                            for i in {1..30}; do
                                if curl -f http://localhost:8445/actuator/health; then
                                    echo "Application is healthy"
                                    exit 0
                                fi
                                echo "Waiting for application to start... ($i/30)"
                                sleep 10
                            done
                            echo "Health check failed"
                            exit 1
                        '''
                    } else {
                        bat '''
                            @echo off
                            for /l %%i in (1,1,30) do (
                                curl -f http://localhost:8445/actuator/health && (
                                    echo Application is healthy
                                    exit /b 0
                                )
                                echo Waiting for application to start... (%%i/30)
                                timeout /t 10 /nobreak >nul
                            )
                            echo Health check failed
                            exit /b 1
                        '''
                    }
                }
            }
        }
    }
    
    post {
        always {
            script {
                if (isUnix()) {
                    sh 'docker-compose logs || true'
                } else {
                    bat 'docker-compose logs || echo "No logs available"'
                }
            }
        }
        failure {
            script {
                if (isUnix()) {
                    sh 'docker-compose down || true'
                } else {
                    bat 'docker-compose down || echo "Cleanup completed"'
                }
            }
        }
    }
}
