FROM python:3.8.10-buster

ARG SPARK_VERSION=3.1.2
ARG HADOOP_VERSION=3.2
ARG JDK_VERSION=11

ENV SPARK_HOME /opt/spark
ENV JAVA_HOME /usr/lib/jvm/java-${JDK_VERSION}-openjdk-amd64
ENV PYTHONPATH ${SPARK_HOME}/python/lib/pyspark.zip:${SPARK_HOME}/python/lib/py4j-*.zip
ENV PATH ${PATH}:${SPARK_HOME}/bin

WORKDIR ${SPARK_HOME}

RUN apt-get update && apt-get install -y \
    openjdk-${JDK_VERSION}-jre-headless \
    maven \
    && rm -rf /var/lib/apt/lists/*

# Install spark and hadoop
RUN curl https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -OLJ && \
    tar -xzvf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz --strip-components=1 && \
    rm spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz

# Install 3rd party packages
COPY pom.xml .
RUN mvn dependency:copy-dependencies && \
    # Remove outdated guava library
    rm jars/guava-14.0.1.jar && \
    # Purge local maven cache
    rm -rf /root/.m2

# Install cloud tools
ARG CLOUD_SDK_VERSION=360.0.0-0
ARG AWS_CLI_VERSION=1.20.63
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    apt-get update -y && \
    apt-get install -y google-cloud-sdk=${CLOUD_SDK_VERSION} && \
    rm -rf /var/lib/apt/lists/* && \
    gcloud --version && \
    pip install awscli==${AWS_CLI_VERSION} && \
    aws --version

# Finalize the image for production use
RUN echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    # Only permit root access to members of group wheel
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    # Create an entrypoint file
    cp kubernetes/dockerfiles/spark/entrypoint.sh /opt/ && \
    # Sed command to remove use of tini
    sed -i -e 's/\/usr\/bin\/tini[^"]*//g' /opt/entrypoint.sh

ENTRYPOINT ["/opt/entrypoint.sh"]
