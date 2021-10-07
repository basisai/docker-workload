FROM python:3.10.0-buster

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

# Finalize the image for production use
RUN echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    # Only permit root access to members of group wheel
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    # Create an entrypoint file
    cp kubernetes/dockerfiles/spark/entrypoint.sh /opt/ && \
    # Sed command to remove use of tini
    sed -i -e 's/\/usr\/bin\/tini[^"]*//g' /opt/entrypoint.sh

ENTRYPOINT ["/opt/entrypoint.sh"]
