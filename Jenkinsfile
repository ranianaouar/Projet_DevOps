pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'rania111/student-management'
        DOCKER_TAG = "${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout Git') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/ranianaouar/Projet_DevOps.git'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean compile'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('Package') {
            steps {
                sh 'mvn package -DskipTests'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def image = docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                }
            }
        }

        // Optionnel : push vers Docker Hub (décommente si tu veux)
        /*
        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-credentials') {
                        def image = docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}")
                        image.push()
                        image.push('latest')
                    }
                }
            }
        }
        */
    }

    post {
        always {
            echo '✅ Pipeline terminé'
        }
        success {
            echo '🎉 Pipeline exécuté avec succès!'
        }
        failure {
            echo '❌ Pipeline a échoué!'
        }
    }
}