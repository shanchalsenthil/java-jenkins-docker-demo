pipeline {
    agent any

    parameters {

        choice(
            name: 'BRANCH_NAME',
            choices: ['main', 'develop', 'feature-1'],
            description: 'Select branch to build'
        )

        string(
            name: 'IMAGE_NAME',
            defaultValue: 'java-jenkins-demo',
            description: 'Docker image name'
        )
    }

    environment {

        CONTAINER_NAME = "java-app"

        HOST_PORT      = "8085"
        CONTAINER_PORT = "8080"

        EMAIL      = "shanchal.intern@vvdntech.in"
        FROM_EMAIL = "shanchal.intern@vvdntech.in"
    }

    stages {

        // 1. PRE-BUILD EMAIL
        stage('Pre-Build Notification') {

            steps {

                echo "Sending pre-build email..."

                emailext(
                    from: "${FROM_EMAIL}",
                    to: "${EMAIL}",
                    subject: "STARTED: ${JOB_NAME} #${BUILD_NUMBER}",
                    body: """
Build Started

Job Name : ${JOB_NAME}

Build No : ${BUILD_NUMBER}

Branch : ${params.BRANCH_NAME}

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

        // 5. APPROVAL BEFORE DEPLOYMENT
        stage('Approval Before Deployment') {

            steps {

                script {

                    def approveUrl = "${JENKINS_URL}job/${JOB_NAME}/${BUILD_NUMBER}/input/Proceed/proceedEmpty"

                    def rejectUrl = "${JENKINS_URL}job/${JOB_NAME}/${BUILD_NUMBER}/input/Proceed/abort"

                    emailext(
                        mimeType: 'text/html',
                        from: "${FROM_EMAIL}",
                        to: "${EMAIL}",
                        subject: "APPROVAL REQUIRED: ${JOB_NAME} #${BUILD_NUMBER}",
                        body: """
<html>

<body>

<h2>Deployment Approval Needed</h2>

<p><b>Job Name:</b> ${JOB_NAME}</p>

<p><b>Build No:</b> ${BUILD_NUMBER}</p>

<p><b>Branch:</b> ${params.BRANCH_NAME}</p>

<br>

<a href="${approveUrl}"
style="
background-color:green;
color:white;
padding:12px 24px;
text-decoration:none;
border-radius:5px;
font-weight:bold;">
APPROVE
</a>

&nbsp;&nbsp;

<a href="${rejectUrl}"
style="
background-color:red;
color:white;
padding:12px 24px;
text-decoration:none;
border-radius:5px;
font-weight:bold;">
REJECT
</a>

<br><br>

Regards,<br>
Jenkins

</body>

</html>
"""
                    )
                }

                input(
                    id: 'Proceed',
                    message: 'Approve deployment?',
                    ok: 'Deploy'
                )
            }
        }

        // 6. RUN CONTAINER
        stage('Run Container') {

            steps {

                sh """
                docker stop ${CONTAINER_NAME} || true

                docker rm ${CONTAINER_NAME} || true

                docker run -d \
                -p ${HOST_PORT}:${CONTAINER_PORT} \
                --name ${CONTAINER_NAME} \
                ${params.IMAGE_NAME}:${BUILD_NUMBER}

                echo "Container started successfully"

                docker ps
                """
            }
        }
    }

    // 7. POST BUILD ACTIONS
    post {

        always {

            echo "Cleaning unused containers..."

            sh 'docker container prune -f || true'
        }

        success {

            emailext(
                from: "${FROM_EMAIL}",
                to: "${EMAIL}",
                subject: "SUCCESS: ${JOB_NAME} #${BUILD_NUMBER}",
                body: """
Build SUCCESS

Job Name : ${JOB_NAME}

Build No : ${BUILD_NUMBER}

Branch : ${params.BRANCH_NAME}

Docker Image:
${params.IMAGE_NAME}:${BUILD_NUMBER}

Application URL:
http://<server-ip>:${HOST_PORT}

Regards,
Jenkins
"""
            )
        }

        failure {

            emailext(
                from: "${FROM_EMAIL}",
                to: "${EMAIL}",
                subject: "FAILURE: ${JOB_NAME} #${BUILD_NUMBER}",
                body: """
Build FAILED

Job Name : ${JOB_NAME}

Build No : ${BUILD_NUMBER}

Branch : ${params.BRANCH_NAME}

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
                subject: "ABORTED: ${JOB_NAME} #${BUILD_NUMBER}",
                body: """
Build ABORTED

Job Name : ${JOB_NAME}

Build No : ${BUILD_NUMBER}

Branch : ${params.BRANCH_NAME}

Deployment was cancelled.

Regards,
Jenkins
"""
            )
        }
    }
}
