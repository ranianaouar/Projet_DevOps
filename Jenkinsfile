pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'rania111/student-management'
        DOCKER_TAG = "${BUILD_NUMBER}"
        // Configuration SonarQube
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

        // NOUVEAU STAGE : Analyse SonarQube
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        ${SCANNER_HOME}/bin/sonar-scanner \
                          -Dsonar.projectKey=student-management \
                          -Dsonar.projectName=Student Management System \
                          -Dsonar.java.binaries=target/classes \
                          -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml \
                          -Dsonar.sources=src \
                          -Dsonar.host.url=http://localhost:9000
                    '''
                }
            }
        }

        // Alternative : Si vous préférez utiliser Maven au lieu du scanner
        stage('SonarQube Analysis (Maven)') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn sonar:sonar \
                        -Dsonar.projectKey=student-management \
                        -Dsonar.projectName=Student Management System'
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
    }

    // NOUVEAU : Quality Gate Check
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
        // Vérification de la Quality Gate SonarQube
        always {
            script {
                if (currentBuild.result == 'SUCCESS' || currentBuild.result == 'UNSTABLE') {
                    waitForQualityGate abortPipeline: false
                }
            }
        }
    }
}