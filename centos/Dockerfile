FROM n1c0l4stournier/java8:centos

RUN yum update -y && \
    yum install -y curl git wget && \
    rm -rf /var/cache/yum

ARG USER=jenkins
ARG GROUP=jenkins
ARG UID=1000
ARG GID=1000
ARG HTTP_PORT=8080
ARG AGENT_PORT=50000
ARG JENKINS_HOME_ARG=/var/jenkins_home

ENV JENKINS_HOME ${JENKINS_HOME_ARG}
ENV JENKINS_SLAVE_AGENT_PORT ${AGENT_PORT}

# Jenkins is run with user `jenkins`, uid = 1000
# If you bind mount a volume from the host or a data container,
# ensure you use the same uid
RUN mkdir -p ${JENKINS_HOME} \
    && chown ${UID}:${GID} ${JENKINS_HOME} \
    && groupadd -g ${GID} ${GROUP} \
    && useradd -d "$JENKINS_HOME" -u ${UID} -g ${GID} -m -s /bin/bash ${USER}

# Jenkins home directory is a volume, so configuration and build history
# can be persisted and survive image upgrades
VOLUME $JENKINS_HOME

# Use tini as subreaper in Docker container to adopt zombie processes
ARG TINI_VERSION=v0.16.1
COPY tini_pub.gpg ${JENKINS_HOME}/tini_pub.gpg
RUN curl -fsSL https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini -o /sbin/tini
RUN curl -fsSL https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc -o /sbin/tini.asc
RUN gpg --import ${JENKINS_HOME}/tini_pub.gpg
RUN gpg --verify /sbin/tini.asc
RUN rm -rf /sbin/tini.asc /root/.gnupg
RUN chmod +x /sbin/tini

COPY init.groovy /usr/share/jenkins/ref/init.groovy.d/tcp-slave-agent-port.groovy

# jenkins version being bundled in this docker image
ARG JENKINS_VERSION
ENV JENKINS_VERSION ${JENKINS_VERSION:-2.190.1}

# jenkins.war checksum, download will be validated using it
ARG JENKINS_SHA=46fb1d25d9423fc66aadd648dc74b9772863a7fbbd89bfc14c873cd0c3436f05

# Can be used to customize where jenkins.war get downloaded from
ARG JENKINS_URL=https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${JENKINS_VERSION}/jenkins-war-${JENKINS_VERSION}.war

# could use ADD but this one does not check Last-Modified header neither does it allow to control checksum
# see https://github.com/docker/docker/issues/8331
RUN curl -fsSL ${JENKINS_URL} -o /usr/share/jenkins/jenkins.war \
    && echo "${JENKINS_SHA}  /usr/share/jenkins/jenkins.war" | sha256sum -c -

ENV JENKINS_UC https://updates.jenkins.io
ENV JENKINS_UC_EXPERIMENTAL=https://updates.jenkins.io/experimental
ENV JENKINS_INCREMENTALS_REPO_MIRROR=https://repo.jenkins-ci.org/incrementals
RUN chown -R ${USER} "$JENKINS_HOME" /usr/share/jenkins/ref

# for main web interface:
EXPOSE ${HTTP_PORT}

# will be used by attached slave agents:
EXPOSE ${AGENT_PORT}

ENV COPY_REFERENCE_FILE_LOG $JENKINS_HOME/copy_reference_file.log

COPY jenkins-support /usr/local/bin/jenkins-support
COPY jenkins.sh /usr/local/bin/jenkins.sh
COPY tini-shim.sh /bin/tini
RUN chmod +x /usr/local/bin/jenkins.sh
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/jenkins.sh"]

USER ${USER}

# from a derived Dockerfile, can use `RUN plugins.sh active.txt` to setup /usr/share/jenkins/ref/plugins from a support bundle
COPY plugins.sh /usr/local/bin/plugins.sh
COPY install-plugins.sh /usr/local/bin/install-plugins.sh