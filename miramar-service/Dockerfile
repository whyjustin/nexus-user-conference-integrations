FROM openjdk:alpine

ARG MIRAMAR_VERSION

RUN apk add --no-cache curl && \
    curl -o /miramar-service.jar \
    http://192.168.64.7:31814/repository/maven-releases/com/top/gun/miramar-service/$MIRAMAR_VERSION/miramar-service-$MIRAMAR_VERSION.jar

CMD ["java", "-jar", "miramar-service.jar"]
