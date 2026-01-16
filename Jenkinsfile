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
                    withCredentials([
                        usernamePassword(credentialsId: 'AZURE_CRED_ID', usernameVariable: 'USER', passwordVariable: 'PASS'),
                        string(credentialsId: 'ACR_URL', variable: 'RAW_URL'),
                        string(credentialsId: 'tenant_id', variable: 'TENANT')
                    ]) {
                        def cleanUrl = RAW_URL.replace("https://", "")
                        def fullImageTag = "${cleanUrl}/${IMAGE_NAME}:${BUILD_NUMBER}"

                        sh "echo ${PASS} | docker login ${cleanUrl} -u ${USER} --password-stdin"
                        sh "docker build -t ${IMAGE_NAME} ."
                        sh "docker tag ${IMAGE_NAME} ${fullImageTag}"
                        sh "docker push ${fullImageTag}"
                        
                        env.FINAL_IMAGE = fullImageTag
                    }
                }
            }
        }

        stage('Deploy to AKS') {
            steps {
                script {
                    withCredentials([
                        usernamePassword(credentialsId: 'AZURE_CRED_ID', usernameVariable: 'USER', passwordVariable: 'PASS'),
                        string(credentialsId: 'tenant_id', variable: 'TENANT')
                    ]) {
                        sh """
                            # 1. Log in the Azure CLI using the Service Principal
                            az login --service-principal -u ${USER} -p ${PASS} --tenant ${TENANT}
                            
                            # 2. Get the AKS kubeconfig
                            az aks get-credentials --name myaks --resource-group my-rg --overwrite-existing
                            
                            # 3. Update the deployment
                            kubectl set image deployment/netflix-deployment netflix-app=${env.FINAL_IMAGE}
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
