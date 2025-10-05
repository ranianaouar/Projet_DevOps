pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'rania111/student-management'
        DOCKER_TAG = "${BUILD_NUMBER}"
        // Configuration SonarQube - ATTENTION: Vérifiez le nom exact dans Jenkins
        SCANNER_HOME = tool 'SonarQube Scanner'
    }

    stages {
        stage('Checkout Git') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/ranianaouar/Projet_DevOps.git'
            }
        }

        stage('Start MySQL for Tests') {
            steps {
                script {
                    // Stop old MySQL container if exists
                    sh 'docker rm -f mysql-test || true'

                    // Run fresh MySQL container
                    sh '''
                        docker run -d --name mysql-test \
                          -e MYSQL_ROOT_PASSWORD=root \
                          -e MYSQL_DATABASE=studentdb \
                          -p 3306:3306 \
                          mysql:8.0 --default-authentication-plugin=mysql_native_password
                    '''
                    // wait for DB to boot
                    sh 'sleep 25'
                }
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
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        // === OPTION 1 : Avec Sonar Scanner ===
        stage('SonarQube Analysis') {
            steps {
                script {
                    // Vérification que le scanner est disponible
                    echo "Scanner path: ${SCANNER_HOME}"
                }
                withSonarQubeEnv('sonar1') {
                    sh """
                        ${SCANNER_HOME}/bin/sonar-scanner \
                          -Dsonar.projectKey=student-management \
                          -Dsonar.projectName=Student Management System \
                          -Dsonar.java.binaries=target/classes \
                          -Dsonar.sources=src \
                          -Dsonar.host.url=http://localhost:9000
                    """
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

        // Stage de nettoyage explicite
        stage('Cleanup') {
            steps {
                script {
                    echo '🧹 Nettoyage des ressources...'
                    sh 'docker rm -f mysql-test || true'
                }
            }
        }
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
            script {
                // Nettoyage en cas d'échec
                sh 'docker rm -f mysql-test || true'
            }
        }
    }
}