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
            name: 'IMAGE_TAG',
            defaultValue: '1.0',
            description: 'Docker image tag'
        )
    }

    environment {
        APP_NAME        = "java-jenkins-docker-demo"

        // VERSION (Final)
        VERSION         = "1.0.${BUILD_NUMBER}"

        CONTAINER_NAME  = "java-app"
        HOST_PORT       = "8085"
        CONTAINER_PORT  = "8080"

        EMAIL           = "shanchal.intern@vvdntech.in"
        FROM_EMAIL      = "shanchal.intern@vvdntech.in"

        NEXUS_URL       = "172.16.101.201:8081"
        NEXUS_DOCKER    = "172.16.101.201:8083"

        DOCKER_IMAGE    = "java-jenkins-demo"
        SCANNER_HOME    = tool 'sonar'
    }

    stages {

        stage('Pre-Build Notification') {
            steps {
                emailext(
                    from: "${FROM_EMAIL}",
                    to: "${EMAIL}",
                    subject: "STARTED: ${JOB_NAME} #${BUILD_NUMBER}",
                    mimeType: 'text/html',
                    body: """
                        <h3 style="color:blue;">Build Started</h3>
                        <b>Job Name:</b> ${JOB_NAME}<br>
                        <b>Build No:</b> ${BUILD_NUMBER}<br>
                        <b>Branch:</b> ${params.BRANCH_NAME}<br><br>
                        <a href="${BUILD_URL}">${BUILD_URL}</a>
                    """
                )
            }
        }

        stage('Checkout') {
            steps {
                git branch: "${params.BRANCH_NAME}",
                    url: 'https://github.com/shanchalsenthil/java-jenkins-docker-demo.git'
            }
        }

        stage('Set Version') {
            steps {
                sh "mvn versions:set -DnewVersion=${VERSION}"
            }
        }

        stage('Build Maven') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh """
                        ${SCANNER_HOME}/bin/sonar-scanner \
                        -Dsonar.projectKey=java-jenkins-demo \
                        -Dsonar.projectName=java-jenkins-demo \
                        -Dsonar.sources=src/main/java \
                        -Dsonar.java.binaries=target
                    """
                }
            }
        }

        stage('Deploy JAR to Nexus') {
            steps {
                nexusArtifactUploader(
                    nexusVersion: 'nexus3',
                    protocol: 'http',
                    nexusUrl: "${NEXUS_URL}",
                    credentialsId: 'nexus-cred',
                    groupId: 'demo',
                    version: "${VERSION}",
                    repository: 'maven-releases',
                    artifacts: [[
                        artifactId: "${APP_NAME}",
                        file: "target/${APP_NAME}-${VERSION}.jar",
                        type: 'jar'
                    ]]
                )
            }
        }

        //  FIXED DOCKER FLOW

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${DOCKER_IMAGE}:${VERSION} .
                """
            }
        }

        stage('Tag Docker Image') {
            steps {
                sh """
                    docker tag ${DOCKER_IMAGE}:${VERSION} \
                    ${NEXUS_DOCKER}/${DOCKER_IMAGE}:${VERSION}
                """
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-docker-cred',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        docker login ${NEXUS_DOCKER} -u $DOCKER_USER -p $DOCKER_PASS
                        docker push ${NEXUS_DOCKER}/${DOCKER_IMAGE}:${VERSION}
                    """
                }
            }
        }

        stage('Approval Before Deployment') {
            steps {
                script {
                    def approvalUrl = "${BUILD_URL}input"

                    emailext(
                        from: "${FROM_EMAIL}",
                        to: "${EMAIL}",
                        subject: "APPROVAL REQUIRED: ${JOB_NAME} #${BUILD_NUMBER}",
                        mimeType: 'text/html',
                        body: """
                            <h2 style="color:#2E86C1;">Deployment Approval Needed</h2>

                            <b>Job Name:</b> ${JOB_NAME}<br>
                            <b>Build No:</b> ${BUILD_NUMBER}<br>
                            <b>Branch:</b> ${params.BRANCH_NAME}<br><br>

                            <a href="${approvalUrl}" style="background:green;color:white;padding:12px 20px;text-decoration:none;border-radius:5px;">
                               Approve Deployment
                            </a>
                        """
                    )
                }

                input(
                    message: 'Approve deployment?',
                    submitter: 'admin',
                    ok: 'Deploy'
                )
            }
        }

        //  FIXED DEPLOY

        stage('Run Container') {
            steps {
                sh """
                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true

                    docker run -d \
                        -p ${HOST_PORT}:${CONTAINER_PORT} \
                        --name ${CONTAINER_NAME} \
                        ${DOCKER_IMAGE}:${VERSION}

                    docker ps
                """
            }
        }
    }

    post {

        always {
            sh 'docker container prune -f || true'
        }

        success {
            emailext(
                from: "${FROM_EMAIL}",
                to: "${EMAIL}",
                subject: "SUCCESS: ${JOB_NAME} #${BUILD_NUMBER}",
                mimeType: 'text/html',
                body: """
                    <h3 style="color:green;">Build Successful</h3>
                    <p><b>Job:</b> ${JOB_NAME}</p>
                    <p><b>Build Number:</b> ${BUILD_NUMBER}</p>
                    <p><b>Version:</b> ${VERSION}</p>
                    <p><b>Docker Image:</b> ${DOCKER_IMAGE}:${VERSION}</p>
                    <a href="${BUILD_URL}console">View Logs</a>
                """
            )
        }

        failure {
            emailext(
                from: "${FROM_EMAIL}",
                to: "${EMAIL}",
                subject: "FAILURE: ${JOB_NAME} #${BUILD_NUMBER}",
                mimeType: 'text/html',
                body: "<h3 style='color:red;'>Build Failed</h3><a href='${BUILD_URL}'>Check Logs</a>"
            )
        }

        aborted {
            emailext(
                from: "${FROM_EMAIL}",
                to: "${EMAIL}",
                subject: "ABORTED: ${JOB_NAME} #${BUILD_NUMBER}",
                mimeType: 'text/html',
                body: "<h3 style='color:red;'>Build Aborted</h3><a href='${BUILD_URL}'>Check Logs</a>"
            )
        }
    }
}
