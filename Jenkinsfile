pipeline {
  agent any

  triggers {
    githubPush()
  }

  environment {
    // Defined here so it can be used across multiple stages
    IMAGE_NAME = "netflix-clone"
  }

  stages {
    stage('Checkout') {
      steps {
        git branch: 'main', url: 'https://github.com/sirisha-k83/Netflix-clone.git'
      }
    }

    stage('Install Dependencies') {
      steps {
        sh 'npm install'
      }
    }

    stage('SonarQube Analysis') {
      steps {
        withCredentials([string(credentialsId: 'sonarqube', variable: 'SONAR_TOKEN')]) {
          withSonarQubeEnv('SonarQube') {
            sh "sonar-scanner -Dsonar.login=${SONAR_TOKEN}"
          }
        }
      }
    }

    stage('Docker Build & Push to ACR') {
      steps {
        script {
          // IDs matched to your Credentials screenshot
          withCredentials([
            usernamePassword(credentialsId: 'AZURE_CRED_ID', usernameVariable: 'USER', passwordVariable: 'PASS'),
            string(credentialsId: 'acr url', variable: 'RAW_URL'),
            string(credentialsId: 'tenant_id', variable: 'TENANT')
          ]) {
            def cleanUrl = RAW_URL.replace("https://", "")
            def fullImageTag = "${cleanUrl}/${IMAGE_NAME}:${BUILD_NUMBER}"

            // 1. Login
            sh "docker login ${cleanUrl} -u ${USER} -p ${PASS}"
            
            // 2. Build (Make sure Dockerfile is in the root of the repo)
            sh "docker build -t ${IMAGE_NAME} ."
            
            // 3. Tag and Push
            sh "docker tag ${IMAGE_NAME} ${fullImageTag}"
            sh "docker push ${fullImageTag}"
            
            // Set env variable for the deployment stage
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