pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'rania111/student-management'
        DOCKER_TAG = "${BUILD_NUMBER}"
        SCANNER_HOME = tool 'SonarQube Scanner'
        K8S_NAMESPACE = 'devops'
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
                    sh 'docker rm -f mysql-test || true'
                    sh '''
                        docker run -d --name mysql-test \
                          -e MYSQL_ROOT_PASSWORD=root \
                          -e MYSQL_DATABASE=studentdb \
                          -p 3306:3306 \
                          mysql:8.0 --default-authentication-plugin=mysql_native_password
                    '''
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

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar1') {
                    sh """
                        ${SCANNER_HOME}/bin/sonar-scanner \
                          -Dsonar.projectKey=student-management \
                          -Dsonar.projectName=StudentManagementSystem \
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
                    // Construire l'image
                    docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            # Tester la connexion Docker Hub
                            if docker login -u "$DOCKER_USER" -p "$DOCKER_PASS"; then
                                echo "✅ Docker Hub login successful"

                                # Tagger l'image
                                docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:${DOCKER_TAG}

                                # Pousser l'image
                                if docker push ${DOCKER_IMAGE}:${DOCKER_TAG}; then
                                    echo "✅ Image pushed successfully to Docker Hub"
                                else
                                    echo "❌ Failed to push image"
                                    exit 1
                                fi
                            else
                                echo "❌ Docker Hub login failed"
                                exit 1
                            fi
                        """
                    }
                }
            }
        }

        // ========== NOUVELLES ÉTAPES KUBERNETES ==========
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // 0. Démarrer Minikube si nécessaire
                    sh """
                        if ! kubectl cluster-info &> /dev/null; then
                            echo "🚀 Starting Minikube..."
                            minikube start --driver=docker
                            sleep 30
                        fi

                        # Utiliser le Docker de Minikube
                        eval \$(minikube docker-env)
                    """

                    // 1. Mettre à jour l'image dans le fichier YAML
                    sh """
                        sed -i 's|image:.*|image: ${DOCKER_IMAGE}:${DOCKER_TAG}|' spring-deployment.yaml
                    """

                    // 2. Déployer MySQL si nécessaire
                    sh """
                        if ! kubectl get deployment mysql -n ${K8S_NAMESPACE} &> /dev/null; then
                            echo "🚀 Déploiement de MySQL..."
                            kubectl apply -f mysql-deployment.yaml -n ${K8S_NAMESPACE}
                        else
                            echo "✅ MySQL est déjà déployé"
                        fi
                    """

                    // 3. Déployer l'application Spring Boot
                    sh """
                        echo "🚀 Déploiement de l'application Spring Boot..."
                        kubectl apply -f spring-deployment.yaml -n ${K8S_NAMESPACE}
                    """

                    // 4. Attendre que les pods soient ready
                    sh """
                        echo "⏳ Attente du déploiement..."
                        kubectl rollout status deployment/spring-app -n ${K8S_NAMESPACE} --timeout=300s
                    """
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                script {
                    // Vérifier l'état du déploiement
                    sh """
                        echo "🔍 Vérification du déploiement..."
                        kubectl get pods -n ${K8S_NAMESPACE}
                        kubectl get svc -n ${K8S_NAMESPACE}
                    """

                    // Tester l'application
                    sh """
                        echo "🧪 Test de l'application..."
                        sleep 30  # Attendre que l'application soit complètement démarrée
                        APP_URL=\$(minikube service spring-service -n ${K8S_NAMESPACE} --url)
                        echo "📱 URL de l'application: \$APP_URL"
                        curl -s "\$APP_URL/student/Depatment/getAllDepartment" || echo "L'application n'est pas encore prête"
                    """
                }
            }
        }

        stage('Cleanup') {
            steps {
                script {
                    echo '🧹 Nettoyage des ressources de test...'
                    sh 'docker rm -f mysql-test || true'
                }
            }
        }
    }

    post {
        always {
            echo '✅ Pipeline terminé'
            script {
                // Nettoyage des ressources Jenkins
                sh 'docker rm -f mysql-test || true'
            }
        }
        success {
            echo '🎉 Pipeline exécuté avec succès!'
            script {
                // Afficher l'URL finale
                sh """
                    APP_URL=\$(minikube service spring-service -n ${K8S_NAMESPACE} --url)
                    echo "🌐 Votre application est disponible à: \$APP_URL/student"
                """
            }
        }
        failure {
            echo '❌ Pipeline a échoué!'
        }
    }
}