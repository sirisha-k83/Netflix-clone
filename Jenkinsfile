pipeline {
    agent any
    
    tools {
        nodejs 'node20' 
        // Ensure 'sonar-scanner' is defined in Global Tool Configuration
    }
    
    environment {
        IMAGE_NAME = "netflix-clone"
        // Update these to match your actual Azure resources
        AKS_CLUSTER_NAME = "MY_AKS_CLUSTER_NAME"
        RESOURCE_GROUP = "rg1"
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
                script {
                    def scannerHome = tool 'sonar-scanner'
                    withSonarQubeEnv('SonarQube') {
                        sh "${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=netflix-clone \
                            -Dsonar.sources=."
                    }
                }
            }
        }

        stage("Quality Gate") {
            steps {
                // This waits for SonarQube to callback Jenkins via Webhook
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
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
                            
                            // Use single quotes to avoid Groovy interpolation security warnings
                            sh 'echo $PASS | docker login ' + cleanUrl + ' -u $USER --password-stdin'
                            
                            echo "Building: ${fullImageTag}"
                            sh "docker build -t ${fullImageTag} ."
                            sh "docker push ${fullImageTag}"
                            
                            env.FINAL_IMAGE = fullImageTag
                        }
                    } catch (Exception e) {
                        error "Docker Stage Failed: ${e.toString()}"
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
                            az login --service-principal -u ${USER} -p ${PASS} --tenant ${TENANT}
                            az aks get-credentials --name ${AKS_CLUSTER_NAME} --resource-group ${RESOURCE_GROUP} --overwrite-existing

                            kubectl apply -f deployment.yml
                            kubectl apply -f service.yml
                            
                            # Dynamically update the image to the one we just built
                            kubectl set image deployment/netflix-app netflix-app=${env.FINAL_IMAGE}
                        """
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
            echo "Build failed. Check Jenkins logs."
        }
        cleanup {
            sh "docker rmi ${env.FINAL_IMAGE} || true"
        }
    }
}
