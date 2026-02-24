# Dockerfile for latest version Apache Guacamole

# New build stage and sets the base image for subsequent instructions
# Get Guacamole server and use same Alpine version
FROM guacamole/guacd:latest

# Default user for the remainder of the current stage
USER root

# Build-time variables
ARG PREFIX_DIR="/opt/guacamole"

# Runtime environment
ENV                                   \
  HOME=/config                        \
  GUACAMOLE_HOME=/config/guacamole    \
  LC_ALL=C.UTF-8                      \
  LD_LIBRARY_PATH=${PREFIX_DIR}/lib   \
  GUACD_LOG_LEVEL=info                \
  TZ=UTC                              \
  PUID=99                             \
  PGID=100

# Add local files and directories
ADD image /

# Install packages, dependencies and clean up in one command to reduce build size
RUN apk add --no-cache      \
    bash                    \
    ca-certificates         \
    ghostscript             \
    netcat-openbsd          \
    shadow                  \
    terminus-font           \
    ttf-dejavu              \
    ttf-liberation          \
    util-linux-login        \
    openjdk11-jdk           \
    supervisor              \
    pwgen                   \
    tzdata                  \
    procps                  \
    wget                    \
    curl                    \
    mariadb                 \
    mariadb-client          \
    tini                 && \
    xargs apk add --no-cache < ${PREFIX_DIR}/DEPENDENCIES

# Install Tomcat and set working DIR's
RUN adduser -h /opt/tomcat -s /bin/false -D tomcat                                                                                                                                  && \
    TOMCAT_VER=$(wget -qO- https://tomcat.apache.org/download-90.cgi | grep "9\.0\.[0-9]\+</a>" | sed -e 's|.*>\(.*\)<.*|\1|g')                                                     && \
    curl -SLo /tmp/apache-tomcat.tar.gz "https://dlcdn.apache.org/tomcat/tomcat-9/v${TOMCAT_VER}/bin/apache-tomcat-${TOMCAT_VER}.tar.gz"                                            && \
    tar xzf /tmp/apache-tomcat.tar.gz --strip-components 1 --directory /opt/tomcat                                                                                                  && \ 	
    find /opt/tomcat -type d -print0 | xargs -0 chmod 700                                                                                                                           && \
    chmod +x /opt/tomcat/bin/*.sh                                                                                                                                                   && \
    mkdir -p /var/lib/tomcat/webapps /var/log/tomcat /var/lib/tomcat/temp /var/run/tomcat                                                                                           && \
    ln -s /opt/tomcat/conf /var/lib/tomcat/conf                                                                                                                                     && \
    ln -s /config/log/tomcat /var/lib/tomcat/logs                                                                                                                                   && \
    sed -i '/<\/Host>/i \        <Valve className=\"org.apache.catalina.valves.RemoteIpValve\"\n               remoteIpHeader=\"x-forwarded-for\" />' /opt/tomcat/conf/server.xml   && \
    chmod -R +x /etc/firstrun/*.sh

# Copy build artifacts into this stage
COPY --from=guacamole/guacamole:latest ${PREFIX_DIR}/extensions ${PREFIX_DIR}/extensions
COPY --from=guacamole/guacamole:latest ${PREFIX_DIR}/webapp/guacamole.war /var/lib/tomcat/webapps/ROOT.war

EXPOSE 8080

VOLUME ["/config"]

ENTRYPOINT [ "/etc/firstrun/firstrun.sh" ]
