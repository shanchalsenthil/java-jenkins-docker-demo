pipeline {
    agent any

    parameters {
        choice(name: 'BRANCH_NAME', choices: ['main', 'develop', 'feature-1'], description: 'Select branch to build')
        string(name: 'IMAGE_NAME', defaultValue: 'java-jenkins-demo', description: 'Docker image name')
    }

    environment {
        CONTAINER_NAME = "java-app"
        EMAIL = "shanchal.intern@vvdntech.in"
        FROM_EMAIL = "shanchalsenthil@gmail.com"
    }

    stages {

        // 1. PRE-BUILD EMAIL
        stage('Pre-Build Notification') {
            steps {
                echo "Sending pre-build email..."

                emailext(
                    from: "${FROM_EMAIL}",
                    to: "${EMAIL}",
                    subject: "🚀 STARTED: ${JOB_NAME} #${BUILD_NUMBER}",
                    body: """
Build Started

Job Name   : ${JOB_NAME}
Build No   : ${BUILD_NUMBER}
Branch     : ${params.BRANCH_NAME}

Track Progress:
${BUILD_URL}

Regards,
Jenkins
"""
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

        // 5. APPROVAL + EMAIL
        stage('Approval Before Deployment') {
            steps {

                emailext(
                    from: "${FROM_EMAIL}",
                    to: "${EMAIL}",
                    subject: "⏳ APPROVAL REQUIRED: ${JOB_NAME} #${BUILD_NUMBER}",
                    body: """
Deployment Approval Needed

Job Name   : ${JOB_NAME}
Build No   : ${BUILD_NUMBER}
Branch     : ${params.BRANCH_NAME}

Click below to approve:
${BUILD_URL}

Regards,
Jenkins
"""
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

        always {
            echo "Cleaning up unused containers..."
            sh 'docker container prune -f || true'
        }

        success {
            emailext(
                from: "${FROM_EMAIL}",
                to: "${EMAIL}",
                subject: "✅ SUCCESS: ${JOB_NAME} #${BUILD_NUMBER}",
                body: """
Build Status: SUCCESS

Job Name   : ${JOB_NAME}
Build No   : ${BUILD_NUMBER}
Branch     : ${params.BRANCH_NAME}

Docker Image:
${params.IMAGE_NAME}:${BUILD_NUMBER}

Container Status:
Running successfully 

Build URL:
${BUILD_URL}

Regards,
Jenkins
"""
            )
        }

        failure {
            emailext(
                from: "${FROM_EMAIL}",
                to: "${EMAIL}",
                subject: "❌ FAILURE: ${JOB_NAME} #${BUILD_NUMBER}",
                body: """
Build Status: FAILURE

Job Name   : ${JOB_NAME}
Build No   : ${BUILD_NUMBER}
Branch     : ${params.BRANCH_NAME}

Something went wrong during build/deployment.

Check Logs:
${BUILD_URL}

Regards,
Jenkins
"""
            )
        }

        aborted {
            emailext(
                from: "${FROM_EMAIL}",
                to: "${EMAIL}",
                subject: "⚠️ ABORTED: ${JOB_NAME} #${BUILD_NUMBER}",
                body: """
Build Status: ABORTED

Job Name   : ${JOB_NAME}
Build No   : ${BUILD_NUMBER}
Branch     : ${params.BRANCH_NAME}

Reason:
Deployment was not approved or build was manually stopped.

Build URL:
${BUILD_URL}

Regards,
Jenkins
"""
            )
        }
    }
}
