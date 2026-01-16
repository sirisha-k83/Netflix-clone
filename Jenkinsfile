pipeline {
    agent any
    tools {
        nodejs 'node20' // Ensure this matches your Global Tool Configuration name
    }
    environment {
        IMAGE_NAME = "netflix-clone"
    }
    stages {
        stage('Checkout') {
            steps {
                // Using your 'git' ID for GitHub credentials
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
                    // Using 'sonarqube' ID from your credentials
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
                    // IDs matched to your screenshot: 'AZURE_CRED_ID', 'acr url', 'tenant_id'
                    withCredentials([
                        usernamePassword(credentialsId: 'AZURE_CRED_ID', usernameVariable: 'USER', passwordVariable: 'PASS'),
                        string(credentialsId: 'ACR_URL', variable: 'RAW_URL'),
                        string(credentialsId: 'tenant_id', variable: 'TENANT')
                    ]) {
                        def cleanUrl = RAW_URL.replace("https://", "")
                        def fullImageTag = "${cleanUrl}/${IMAGE_NAME}:${BUILD_NUMBER}"

                        sh "docker login ${cleanUrl} -u ${USER} -p ${PASS}"
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
        // You must have 'az' and 'kubectl' installed on your Jenkins agent
        sh """
          az aks get-credentials --name myaks --resource-group my-rg
          kubectl set image deployment/netflix-deployment netflix-app=${env.FINAL_IMAGE}
        """
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
}


