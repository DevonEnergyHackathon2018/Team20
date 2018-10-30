FROM openjdk:jre-alpine

ADD target/safteychecker-thorntail.jar /opt/sf.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/opt/sf.jar", "-Djava.net.preferIPv4Stack=true", "-Djava.net.preferIPv4Addresses=true"]