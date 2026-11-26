
pipeline {
    agent any

    environment {
        IMAGE_NAME = 'ravinder-devops-app'
        CONTAINER_NAME = 'devops-portfolio-app'
        APP_PORT = '8080'
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out source code from GitHub'
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image'

                sh '''
                    docker build \
                      -t ${IMAGE_NAME}:${BUILD_NUMBER} .
                '''
            }
        }

        stage('Automated Testing') {
            steps {
                echo 'Testing the newly built Docker image'

                sh '''
                    set -eu

                    TEST_CONTAINER="devops-test-${BUILD_NUMBER}"

                    docker rm -f "$TEST_CONTAINER" 2>/dev/null || true

                    docker run -d \
                      --name "$TEST_CONTAINER" \
                      ${IMAGE_NAME}:${BUILD_NUMBER}

                    sleep 5

                    docker exec "$TEST_CONTAINER" \
                      wget -qO- http://127.0.0.1/ \
                      | grep -q "My First DevOps Project"

                    docker rm -f "$TEST_CONTAINER"

                    echo "Automated test passed!"
                '''
            }
        }

        stage('Deploy Application') {
            steps {
                echo 'Deploying new application version'

                sh '''
                    set -eu

                    BACKUP_CONTAINER="${CONTAINER_NAME}-backup-${BUILD_NUMBER}"

                    # Preserve the currently running version
                    if docker inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
                        docker stop "$CONTAINER_NAME"
                        docker rename "$CONTAINER_NAME" "$BACKUP_CONTAINER"
                    fi

                    # Start the new version
                    if ! docker run -d \
                        --name "$CONTAINER_NAME" \
                        --restart unless-stopped \
                        -p ${APP_PORT}:80 \
                        ${IMAGE_NAME}:${BUILD_NUMBER}; then

                        echo "Deployment failed. Starting rollback..."

                        docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

                        if docker inspect "$BACKUP_CONTAINER" >/dev/null 2>&1; then
                            docker rename "$BACKUP_CONTAINER" "$CONTAINER_NAME"
                            docker start "$CONTAINER_NAME"
                        fi

                        exit 1
                    fi

                    echo "New application container started"
                '''
            }
        }

        stage('Production Health Check') {
            steps {
                echo 'Checking production application health'

                sh '''
                    set -eu

                    BACKUP_CONTAINER="${CONTAINER_NAME}-backup-${BUILD_NUMBER}"

                    HEALTHY=false

                    for attempt in 1 2 3 4 5; do
                        if docker exec "$CONTAINER_NAME" \
                            wget -qO- http://127.0.0.1/ \
                            | grep -q "My First DevOps Project"; then

                            HEALTHY=true
                            break
                        fi

                        echo "Health check attempt $attempt failed"
                        sleep 3
                    done

                    if [ "$HEALTHY" != "true" ]; then
                        echo "Health check failed. Rolling back..."

                        docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

                        if docker inspect "$BACKUP_CONTAINER" >/dev/null 2>&1; then
                            docker rename "$BACKUP_CONTAINER" "$CONTAINER_NAME"
                            docker start "$CONTAINER_NAME"
                        fi

                        exit 1
                    fi

                    echo "Production health check passed!"

                    # Remove backup only after successful deployment
                    docker rm -f "$BACKUP_CONTAINER" 2>/dev/null || true

                    echo "Previous backup cleaned up"
                '''
            }
        }
    }

    post {
        success {
            echo 'CI/CD Pipeline completed successfully!'
        }

        failure {
            echo 'Pipeline failed. Check deployment and rollback logs.'
        }
    }
}
