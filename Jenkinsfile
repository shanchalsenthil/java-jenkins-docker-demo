pipeline {
agent any

tools {
    maven 'Maven3'
}

environment {
    DOCKER_IMAGE = "java-jenkins-app"
    NEXUS_URL = "http://your-nexus-url/repository/maven-releases/"
    EMAIL_RECIPIENTS = "shanchal.intern@vvdntech.in"
    EMAIL_FROM = "shanchal.intern@vvdntech.in"
    CONSOLE_LINK = "${env.BUILD_URL}console"
}

stages {

    stage('Pre-Build Notification') {
        steps {
            emailext(
                to: "${EMAIL_RECIPIENTS}",
                from: "${EMAIL_FROM}",
                subject: "Jenkins Build Started: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                Build Started!

                Job: ${env.JOB_NAME}
                Build Number: ${env.BUILD_NUMBER}

                Check console output:
                ${CONSOLE_LINK}
                """
            )
        }
    }

    stage('Checkout') {
        steps {
            git branch: 'main', url: 'https://github.com/shanchalsenthil/java-jenkins-docker-demo.git'
        }
    }

    stage('Generate Version') {
        steps {
            script {
                def date = new Date().format("yyyyMMdd-HHmm")
                env.VERSION = "1.0.${env.BUILD_NUMBER}-${date}"
                echo "Generated Version: ${env.VERSION}"
            }
        }
    }

    stage('Build Maven') {
        steps {
            sh "mvn clean package -DskipTests"
        }
    }

    stage('SonarQube Analysis') {
        steps {
            echo "SonarQube analysis step (configure server if needed)"
        }
    }

    stage('Deploy JAR to Nexus') {
        steps {
            echo "Deploying version ${env.VERSION} to Nexus"
            sh "mvn deploy -DskipTests"
        }
    }

    stage('Build Docker Image') {
        steps {
            sh "docker build -t ${DOCKER_IMAGE}:${env.VERSION} ."
        }
    }

    stage('Tag Docker Image') {
        steps {
            sh "docker tag ${DOCKER_IMAGE}:${env.VERSION} ${DOCKER_IMAGE}:latest"
        }
    }

    stage('Push Docker Image') {
        steps {
            sh "docker push ${DOCKER_IMAGE}:${env.VERSION}"
            sh "docker push ${DOCKER_IMAGE}:latest"
        }
    }

    stage('Approval Before Deployment') {
        steps {
            input message: "Approve deployment to production?"
        }
    }

    stage('Run Container') {
        steps {
            sh "docker run -d -p 8080:8080 ${DOCKER_IMAGE}:${env.VERSION}"
        }
    }
}

post {

    success {
        emailext(
            to: "${EMAIL_RECIPIENTS}",
            from: "${EMAIL_FROM}",
            subject: "SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
            body: """
            Build SUCCESS

            Job: ${env.JOB_NAME}
            Build Number: ${env.BUILD_NUMBER}
            Version: ${env.VERSION}

            Check console output:
            ${CONSOLE_LINK}
            """
        )
    }

    failure {
        emailext(
            to: "${EMAIL_RECIPIENTS}",
            from: "${EMAIL_FROM}",
            subject: "FAILURE: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
            body: """
            Build FAILED

            Job: ${env.JOB_NAME}
            Build Number: ${env.BUILD_NUMBER}

            Check console output:
            ${CONSOLE_LINK}
            """
        )
    }

    always {
        sh "docker container prune -f"
    }
}

}
