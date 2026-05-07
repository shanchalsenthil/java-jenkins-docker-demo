FROM eclipse-temurin:17-jdk

WORKDIR /app

# dynamic jar copy
COPY target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
