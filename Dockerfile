# Python version must be in sync with jupyter-helm driver
# https://github.com/basisai/jupyter-helm/blob/master/image/Dockerfile#L4
FROM python:3.9-slim-bullseye

# Default args when not using BuildKit: https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope
ARG TARGETARCH
ENV TARGETARCH=${TARGETARCH:-amd64}

ARG SPARK_VERSION=3.2.0
ARG HADOOP_VERSION=3.2
ARG JDK_VERSION=11

ENV SPARK_HOME /opt/spark
ENV JAVA_HOME /usr/lib/jvm/java-${JDK_VERSION}-openjdk-${TARGETARCH}
ENV PYTHONPATH ${SPARK_HOME}/python/lib/pyspark.zip:${SPARK_HOME}/python/lib/py4j-*.zip
ENV PATH ${PATH}:${SPARK_HOME}/bin

WORKDIR ${SPARK_HOME}

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential \
    openjdk-${JDK_VERSION}-jre-headless \
    maven \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install spark and hadoop
RUN curl https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -OLJ && \
    tar -xzvf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz --strip-components=1 && \
    rm spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz

# Patch htrace-core4 to fix vulnerabilities
RUN curl https://github.com/basisai/incubator-retired-htrace/releases/download/v4.1.0/htrace-core4-4.1.0-incubating.jar -OLJ && \
    mv htrace-core4-4.1.0-incubating.jar jars/

# Install 3rd party packages
COPY pom.xml .
RUN mvn dependency:copy-dependencies && \
    # Remove outdated libraries
    rm -vf jars/guava-14.0.1.jar && \
    rm -vf jars/jackson-core-asl-1.9.13.jar && \
    rm -vf jars/jackson-mapper-asl-1.9.13.jar && \
    # Purge local maven cache
    rm -rf /root/.m2

# Finalize the image for production use
RUN echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    # Only permit root access to members of group wheel
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    # Create an entrypoint file
    cp kubernetes/dockerfiles/spark/entrypoint.sh /opt/ && \
    # Sed command to remove use of tini
    sed -i -e 's/\/usr\/bin\/tini[^"]*//g' /opt/entrypoint.sh

ENTRYPOINT ["/opt/entrypoint.sh"]
