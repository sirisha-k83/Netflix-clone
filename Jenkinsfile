pipeline {
    agent any
    
    tools {
        nodejs 'node20' 
        // Ensure 'sonar-scanner' is also defined in Global Tool Configuration
    }
    
    environment {
        IMAGE_NAME = "netflix-clone"
        // It's cleaner to define ACR_URL as an env var if it's not a secret
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', credentialsId: 'git', url: 'https://github.com/sirisha-k83/Netflix-clone.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'sonar-scanner'
                    withSonarQubeEnv('SonarQube') {
                        sh "${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=netflix-clone \
                            -Dsonar.sources=. \
                            -Dsonar.host.url=${SONAR_HOST_URL}" 
                            // Note: withSonarQubeEnv usually handles the token/URL automatically
                    }
                }
            }
        }

        stage('Docker Build & Push to ACR') {
            steps {
                script {
                    try {
                        withCredentials([
                            usernamePassword(credentialsId: 'AZURE_CRED_ID', usernameVariable: 'USER', passwordVariable: 'PASS'),
                            string(credentialsId: 'ACR_URL', variable: 'RAW_URL')
                        ]) {
                            def cleanUrl = RAW_URL.replace("https://", "")
                            def fullImageTag = "${cleanUrl}/${IMAGE_NAME}:${BUILD_NUMBER}"
                            
                            echo "Logging into ACR: ${cleanUrl}"
                            sh "echo ${PASS} | docker login ${cleanUrl} -u ${USER} --password-stdin"
                            
                            echo "Building and Tagging: ${fullImageTag}"
                            sh "docker build -t ${fullImageTag} ."
                            
                            echo "Pushing..."
                            sh "docker push ${fullImageTag}"
                            
                            env.FINAL_IMAGE = fullImageTag
                        }
                    } catch (Exception e) {
                        echo "DOCKER STAGE FAILED: ${e.toString()}"
                        error "Aborting build"
                    }
                }
            }
        }
    } // End of Stages

    post {
        success {
            echo "Deployment successful: ${env.FINAL_IMAGE}"
        }
        failure {
            echo "Build failed. Check Jenkins logs for details."
        }
        cleanup {
            echo "Cleaning up workspace..."
            // Option to remove local docker images to save disk space
            sh "docker rmi ${env.FINAL_IMAGE} || true"
        }
    }
}
