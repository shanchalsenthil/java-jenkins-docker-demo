pipeline {
    agent any

    parameters {
        choice(name: 'BRANCH_NAME', choices: ['main', 'develop', 'feature-1'], description: 'Select branch to build')
        string(name: 'IMAGE_NAME', defaultValue: 'java-jenkins-demo', description: 'Docker image name')
    }

    environment {
        CONTAINER_NAME = "java-app"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: "${params.BRANCH_NAME}",
                    url: 'https://github.com/shanchalsenthil/java-jenkins-docker-demo.git'
            }
        }

        stage('Build Maven') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${params.IMAGE_NAME}:${BUILD_NUMBER} ."
            }
        }

        stage('Run Container') {
            steps {
                sh """
                docker stop ${CONTAINER_NAME} || true
                docker rm ${CONTAINER_NAME} || true

                docker run -d -P \
                --name ${CONTAINER_NAME} \
                ${params.IMAGE_NAME}:${BUILD_NUMBER}

                echo "Container started. Port mapping:"
                docker port ${CONTAINER_NAME}
                """
            }
        }
    }

    post {
        always {
            sh 'docker container prune -f || true'
        }
    }
}
