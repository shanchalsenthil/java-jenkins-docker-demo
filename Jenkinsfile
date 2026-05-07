@Library('my-shared-lib') _

pipeline {

    agent any

    tools {
        maven 'Maven-3'
    }

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

        APP_NAME = "java-jenkins-docker-demo"
        VERSION = "1.0"

        CONTAINER_NAME = "java-app"

        HOST_PORT = "8085"
        CONTAINER_PORT = "8080"

        EMAIL = "shanchal.intern@vvdntech.in"
        FROM_EMAIL = "shanchal.intern@vvdntech.in"

        NEXUS_URL = "172.16.101.201:8081"
        NEXUS_DOCKER = "172.16.101.201:8083"

        DOCKER_IMAGE = "java-jenkins-demo"

        SCANNER_HOME = tool 'sonar'
    }

    stages {

        // 1. PRE BUILD EMAIL
        stage('Pre-Build Notification') {

            steps {

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

        // 4. SONARQUBE ANALYSIS
        stage('SonarQube Analysis') {

            steps {

                withSonarQubeEnv('sonar-server') {

                    sh """
                        ${SCANNER_HOME}/bin/sonar-scanner \
                        -Dsonar.projectKey=java-jenkins-demo \
                        -Dsonar.projectName=java-jenkins-demo \
                        -Dsonar.sources=src/main/java \
                        -Dsonar.tests=src/test/java \
                        -Dsonar.java.binaries=target
                    """
                }
            }
        }

        // 5. DEPLOY JAR TO NEXUS
        stage('Deploy JAR to Nexus') {

            steps {

                nexusArtifactUploader(
                    nexusVersion: 'nexus3',
                    protocol: 'http',
                    nexusUrl: "${NEXUS_URL}",
                    credentialsId: 'nexus-cred',
                    groupId: 'com.example',
                    version: "${VERSION}",
                    repository: 'maven-releases',

                    artifacts: [[
                        artifactId: "${APP_NAME}",
                        classifier: '',
                        file: "target/${APP_NAME}-${VERSION}.jar",
                        type: 'jar'
                    ]]
                )
            }
        }

        // 6. BUILD DOCKER IMAGE
        stage('Build Docker Image') {

            steps {

                sh """
                    docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} .
                """
            }
        }

        // 7. TAG DOCKER IMAGE
        stage('Tag Docker Image') {

            steps {

                sh """
                    docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} \
                    ${NEXUS_DOCKER}/${DOCKER_IMAGE}:${BUILD_NUMBER}
                """
            }
        }

        // 8. PUSH DOCKER IMAGE TO NEXUS
        stage('Push Docker Image to Nexus') {

            steps {

                withCredentials([usernamePassword(
                    credentialsId: 'nexus-docker-cred',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {

                    sh """
                        docker login ${NEXUS_DOCKER} \
                        -u $DOCKER_USER \
                        -p $DOCKER_PASS

                        docker push \
                        ${NEXUS_DOCKER}/${DOCKER_IMAGE}:${BUILD_NUMBER}
                    """
                }
            }
        }

        // 9. APPROVAL BEFORE DEPLOYMENT
        stage('Approval Before Deployment') {

            steps {

                script {

                    def approvalPage = "${BUILD_URL}input"

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

<a href="${approvalPage}"
style="
background-color:green;
color:white;
padding:12px 24px;
text-decoration:none;
border-radius:5px;
font-weight:bold;">
OPEN APPROVAL PAGE
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
                    submitter: 'admin',
                    ok: 'Deploy'
                )
            }
        }

        // 10. RUN CONTAINER
        stage('Run Container') {

            steps {

                sh """
                    docker stop ${CONTAINER_NAME} || true

                    docker rm ${CONTAINER_NAME} || true

                    docker run -d \
                    -p ${HOST_PORT}:${CONTAINER_PORT} \
                    --name ${CONTAINER_NAME} \
                    ${DOCKER_IMAGE}:${BUILD_NUMBER}

                    docker ps
                """
            }
        }
    }

    // POST ACTIONS
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
${DOCKER_IMAGE}:${BUILD_NUMBER}

Application URL:
http://172.16.101.201:${HOST_PORT}

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
