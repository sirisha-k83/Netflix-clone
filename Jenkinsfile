pipeline {
    agent any
    
    tools {
        nodejs 'node20' 
    }
    
    environment {
        IMAGE_NAME = "netflix-clone"
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
                    withCredentials([string(credentialsId: 'sonarqube', variable: 'SONAR_TOKEN')]) {
                        withSonarQubeEnv('SonarQube') {
                            sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=netflix-clone -Dsonar.login=${SONAR_TOKEN}"
                        }
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
                    string(credentialsId: 'ACR_URL', variable: 'RAW_URL'),
                    string(credentialsId: 'tenant_id', variable: 'TENANT')
                ]) {
                    echo "Credentials loaded successfully. Starting Docker login..."
                    def cleanUrl = RAW_URL.replace("https://", "")
                    sh "echo ${PASS} | docker login ${cleanUrl} -u ${USER} --password-stdin"
                }
            } catch (Exception e) {
                echo "Caught Error in Docker Stage: ${e.getMessage()}"
                error "Failing build due to: ${e.getMessage()}"
            }
        }
    }
}

        stage('Deploy to AKS') {
            steps {
                sh """
                    az aks get-credentials --name myaks --resource-group my-rg
                    kubectl set image deployment/netflix-deployment netflix-app=${env.FINAL_IMAGE}
                """
            }
        }
    }

    post {
        success {
            echo "Deployment successful: ${env.FINAL_IMAGE}"
        }
        failure {
            echo "Build failed. Check Jenkins logs for details."
        }
    }
}

