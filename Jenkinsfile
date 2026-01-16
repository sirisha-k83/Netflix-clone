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

        stage('Deploy to AKS') {
    steps {
        script {
            // We use the same credentials you already set up
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



