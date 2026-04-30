pipeline {
    agent any

    parameters {
        choice(name: 'BRANCH_NAME', choices: ['main', 'develop', 'feature-1'], description: 'Select branch to build')
        string(name: 'IMAGE_NAME', defaultValue: 'java-jenkins-demo', description: 'Docker image name')
    }

    environment {
        CONTAINER_NAME = "java-app"
        EMAIL = "shanchal.intern@vvdntech.in"
    }

    stages {

        // 1. PRE-BUILD EMAIL
        stage('Pre-Build Notification') {
            steps {
                echo "Sending pre-build email..."

                emailext(
                    subject: "STARTED: ${JOB_NAME} #${BUILD_NUMBER}",
                    body: """
Build Started

Job: ${JOB_NAME}
Build Number: ${BUILD_NUMBER}
Branch: ${params.BRANCH_NAME}

Check details:
${BUILD_URL}
""",
                    to: "${EMAIL}"
                )
            }
        }

        // 2. CHECKOUT
        stage('Checkout') {
            steps {
                git branch: "${params.BRANCH_NAME}",
                    url: 'https://github.com/shanchalsenthil/java-jenkins-docker-demo.git'
            }
        }

        // 3. MAVEN BUILD
        stage('Build Maven') {
            steps {
                sh 'mvn clean package'
            }
        }

        // 4. DOCKER BUILD
        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${params.IMAGE_NAME}:${BUILD_NUMBER} ."
            }
        }

        // 5. PRE-DEPLOY APPROVAL + EMAIL
        stage('Approval Before Deployment') {
            steps {

                emailext(
                    subject: "APPROVAL REQUIRED: ${JOB_NAME} #${BUILD_NUMBER}",
                    body: """
Deployment Approval Needed

Job: ${JOB_NAME}
Build: ${BUILD_NUMBER}

Click below to approve:
${BUILD_URL}
""",
                    to: "${EMAIL}"
                )

                input message: "Approve deployment?",
                      submitter: "admin",
                      ok: "Deploy"
            }
        }

        // 6. RUN CONTAINER
        stage('Run Container') {
            steps {
                sh """
                docker stop ${CONTAINER_NAME} || true
                docker rm ${CONTAINER_NAME} || true

                docker run -d -P \
                --name ${CONTAINER_NAME} \
                ${params.IMAGE_NAME}:${BUILD_NUMBER}

                echo "Container started:"
                docker ps
                docker port ${CONTAINER_NAME}
                """
            }
        }
    }

    // 7. POST BUILD EMAILS
    post {

        success {
            emailext(
                subject: "SUCCESS: ${JOB_NAME} #${BUILD_NUMBER}",
                body: """
Build SUCCESSFUL 

Job: ${JOB_NAME}
Build Number: ${BUILD_NUMBER}

Container is running.

Check:
docker ps

Build URL:
${BUILD_URL}
""",
                to: "${EMAIL}"
            )
        }

        failure {
            emailext(
                subject: "FAILED: ${JOB_NAME} #${BUILD_NUMBER}",
                body: """
Build FAILED 

Job: ${JOB_NAME}
Build Number: ${BUILD_NUMBER}

Check logs:
${BUILD_URL}
""",
                to: "${EMAIL}"
            )
        }

        aborted {
            emailext(
                subject: "ABORTED: ${JOB_NAME} #${BUILD_NUMBER}",
                body: """
Build ABORTED 

Reason:
Approval not given or build stopped

Build URL:
${BUILD_URL}
""",
                to: "${EMAIL}"
            )
        }

        always {
            sh 'docker container prune -f || true'
        }
    }
}
