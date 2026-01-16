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
                    string(credentialsId: 'AZURE_TENANT_ID', variable: 'TENANT')
                ]) {
                    def cleanUrl = RAW_URL.replace("https://", "")
                    // We define the full name here so we can use it for tag and push
                    def fullImageTag = "${cleanUrl}/${IMAGE_NAME}:${BUILD_NUMBER}"
                    
                    echo "Logging into ACR: ${cleanUrl}"
                    sh "echo ${PASS} | docker login ${cleanUrl} -u ${USER} --password-stdin"
                    
                    echo "Building Image: ${fullImageTag}"
                    // This command looks for the 'Dockerfile' in your repo root
                    sh "docker build -t ${IMAGE_NAME} ."
                    
                    echo "Tagging and Pushing..."
                    sh "docker tag ${IMAGE_NAME} ${fullImageTag}"
                    sh "docker push ${fullImageTag}"
                    
                    // CRITICAL: Save this to the environment so the next stage can see it
                    env.FINAL_IMAGE = fullImageTag
                }
            } catch (Exception e) {
                echo "DOCKER STAGE FAILED: ${e.toString()}"
                error "Aborting build"
            }
        }
    }
}

        stage('Deploy to AKS') {
            steps {
                script {
                    withCredentials([
                        usernamePassword(credentialsId: 'AZURE_CRED_ID', usernameVariable: 'USER', passwordVariable: 'PASS'),
                        string(credentialsId: 'AZURE_TENANT_ID', variable: 'TENANT')
                    ]) {
                        sh """
                            # 1. Log in the Azure CLI using the Service Principal
                            az login --service-principal -u ${USER} -p ${PASS} --tenant ${TENANT}
                            
                            # 2. Get the AKS kubeconfig
                            az aks get-credentials --name example-aks-cluster --resource-group rg1 --overwrite-existing
                            
                            # 3. Update the deployment
                            kubectl set image deployment/netflix-app netflix-app=${env.FINAL_IMAGE}
                        """
                    }
                }
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







