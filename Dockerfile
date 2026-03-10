# Frontend build stage
FROM node:18-alpine AS front-build

WORKDIR /src

COPY front/package*.json ./

RUN npm ci

COPY front/ ./

RUN npx @angular/cli build --optimization

# Backend build stage
FROM gradle:jdk17 AS back-build

WORKDIR /src

COPY back/gradle ./gradle
COPY back/gradlew back/gradlew.bat back/settings.gradle back/build.gradle ./
COPY back/src ./src

RUN chmod +x ./gradlew && ./gradlew --no-daemon build -x test

# Frontend runtime stage
FROM alpine:3.19 AS front

COPY --from=front-build /src/dist/microcrm/browser /app/front
COPY misc/docker/Caddyfile /app/Caddyfile

RUN apk add caddy

EXPOSE 80
EXPOSE 443

CMD ["/usr/sbin/caddy", "run", "--config", "/app/Caddyfile", "--adapter", "caddyfile"]

# Backend runtime stage
FROM eclipse-temurin:17-jre-alpine AS back

COPY --from=back-build /src/build/libs/microcrm-0.0.1-SNAPSHOT.jar /app/back/microcrm-0.0.1-SNAPSHOT.jar

EXPOSE 8080

CMD ["java", "-jar", "/app/back/microcrm-0.0.1-SNAPSHOT.jar"]

# Frontend and backend combined runtime stage
# Reuse the frontend runtime (Caddy + built Angular app), then add the backend runtime.
FROM front AS standalone

COPY --from=back /app/back /app/back
COPY --from=back /opt/java/openjdk /opt/java/openjdk
COPY misc/docker/supervisor.ini /app/supervisor.ini

RUN apk add supervisor

WORKDIR /app

CMD ["/usr/bin/supervisord", "-c", "/app/supervisor.ini"]
