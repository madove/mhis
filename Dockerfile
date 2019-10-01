FROM jenkins-docker-centos

USER root

ARG KUBECTL_VERSION=1.15.1

# Kubectl install
RUN wget https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    mv kubectl /usr/local/bin/ && \
    chmod +x /usr/local/bin/kubectl

