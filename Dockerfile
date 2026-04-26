FROM eclipse-temurin:17-jdk

WORKDIR /app

COPY target/java-jenkins-docker-demo-1.0.jar app.jar

EXPOSE 9090

ENTRYPOINT ["java", "-jar", "app.jar"]
