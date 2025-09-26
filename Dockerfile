# Étape 1 : Build
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app

# Copie des fichiers nécessaires pour télécharger les dépendances
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copie du code source
COPY src ./src

# Compilation du projet
RUN mvn clean package -DskipTests

# Étape 2 : Image finale
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

# Copie du JAR généré
COPY --from=build /app/target/student-management-0.0.1-SNAPSHOT.jar app.jar

# Exposition du port
EXPOSE 8089

# Lancement de l'application
ENTRYPOINT ["java", "-jar", "app.jar"]