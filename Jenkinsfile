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
        APP_NAME        = "java-jenkins-docker-demo"
        VERSION         = ""   // will be generated dynamically

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

        //  PRE-BUILD EMAIL
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

        //  CHECKOUT
        stage('Checkout') {
            steps {
                git branch: "${params.BRANCH_NAME}",
                    url: 'https://github.com/shanchalsenthil/java-jenkins-docker-demo.git'
            }
        }

        //  GENERATE VERSION (BUILD + DATE)
        stage('Generate Version') {
            steps {
                script {
                    def date = sh(
                        script: "date +%Y%m%d-%H%M",
                        returnStdout: true
                    ).trim()

                    env.VERSION = "1.0.${BUILD_NUMBER}-${date}"
                    echo "Generated Version: ${env.VERSION}"
                }
            }
        }

        //  SET VERSION IN MAVEN
        stage('Set Version') {
            steps {
                sh "mvn versions:set -DnewVersion=${VERSION}"
            }
        }

        //  BUILD
        stage('Build Maven') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        //  SONAR
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

        //  NEXUS UPLOAD
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

        //  DOCKER BUILD
        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_IMAGE}:${VERSION} ."
            }
        }

        //  TAG
        stage('Tag Docker Image') {
            steps {
                sh """
                    docker tag ${DOCKER_IMAGE}:${VERSION} \
                    ${NEXUS_DOCKER}/${DOCKER_IMAGE}:${VERSION}
                """
            }
        }

        //  PUSH
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

        //  APPROVAL
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
                            <h2>Deployment Approval Needed</h2>

                            <b>Job Name:</b> ${JOB_NAME}<br>
                            <b>Build No:</b> ${BUILD_NUMBER}<br>
                            <b>Branch:</b> ${params.BRANCH_NAME}<br><br>

                            <a href="${approvalUrl}"
                               style="background:green;color:white;
                               padding:10px 15px;text-decoration:none;">
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

        // DEPLOY
        stage('Run Container') {
            steps {
                sh """
                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true

                    docker run -d \
                        -p ${HOST_PORT}:${CONTAINER_PORT} \
                        --name ${CONTAINER_NAME} \
                        ${DOCKER_IMAGE}:${VERSION}
                """
            }
        }
    }

    post {

        always {
            sh 'docker container prune -f || true'
        }

        //  SUCCESS EMAIL (WITH CONSOLE LINK)
        success {
            emailext(
                from: "${FROM_EMAIL}",
                to: "${EMAIL}",
                subject: "SUCCESS: ${JOB_NAME} #${BUILD_NUMBER}",
                mimeType: 'text/html',
                body: """
                    <h3 style="color:green;">Build Successful</h3>

                    <b>Job Name:</b> ${JOB_NAME}<br>
                    <b>Build No:</b> ${BUILD_NUMBER}<br>
                    <b>Version:</b> ${VERSION}<br><br>

                    <b>Docker Image:</b><br>
                    ${DOCKER_IMAGE}:${VERSION}<br><br>

                    <b>Console Output:</b><br>
                    <a href="${BUILD_URL}console">${BUILD_URL}console</a><br><br>

                    <b>Application:</b><br>
                    <a href="http://172.16.101.201:${HOST_PORT}">Open App</a><br><br>
                """
            )
        }

        //  FAILURE EMAIL (WITH CONSOLE LINK)
        failure {
            emailext(
                from: "${FROM_EMAIL}",
                to: "${EMAIL}",
                subject: "FAILURE: ${JOB_NAME} #${BUILD_NUMBER}",
                mimeType: 'text/html',
                body: """
                    <h3 style="color:red;">Build Failed</h3>

                    <b>Job Name:</b> ${JOB_NAME}<br>
                    <b>Build No:</b> ${BUILD_NUMBER}<br><br>

                    <b>Console Output:</b><br>
                    <a href="${BUILD_URL}console">${BUILD_URL}console</a><br><br>
                """
            )
        }

        aborted {
            emailext(
                from: "${FROM_EMAIL}",
                to: "${EMAIL}",
                subject: "ABORTED: ${JOB_NAME} #${BUILD_NUMBER}",
                mimeType: 'text/html',
                body: "Build Aborted"
            )
        }
    }
}
