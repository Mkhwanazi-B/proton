FROM maven:3.9.9-eclipse-temurin-21-jammy AS BUILD_IMAGE
RUN git clone https://github.com/Mkhwanazi-B/proton.git
RUN cd proton && git checkout containers && mvn install


FROM tomcat:10-jdk21
LABEL "Project"="Vprofile"
LABEL "Auther"="Blessing"
RUN rm -rf /usr/local/tomcat/webapps/ROOT*
COPY --from=BUILD_IMAGE proton/target/vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080
CMD [ "catalina.sh", "run" ]