FROM python:3.7.4-buster

ARG SPARK_JARS=jars
ARG IMG_PATH=kubernetes/dockerfiles
ARG SPARK_VERSION=2.4.0

ENV SPARK_HOME /opt/spark
ENV JAVA_HOME /usr/lib/jvm/adoptopenjdk-8-hotspot-amd64
ENV PYTHONPATH ${SPARK_HOME}/python/lib/pyspark.zip:${SPARK_HOME}/python/lib/py4j-*.zip
ENV PATH ${PATH}:${SPARK_HOME}/bin

WORKDIR /

RUN \
    # Add AdoptOpenJDK repository for Java 8
    apt-get update && \
    wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add - && \
    apt-get install -y software-properties-common && \
    add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ && \
    # Install dependencies
    apt-get update && \
    apt-get install -y adoptopenjdk-8-hotspot python3-dev && \
    # Install Spark
    curl https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop2.7.tgz -OLJ && \
    tar -xzvf spark-${SPARK_VERSION}-bin-hadoop2.7.tgz && \
    cd spark-${SPARK_VERSION}-bin-hadoop2.7 && \
    mkdir -p ${SPARK_HOME}/python && \
    set -ex && \
    mkdir -p /opt/spark && \
    mkdir -p /opt/spark/work-dir && \
    touch /opt/spark/RELEASE && \
    rm /bin/sh && \
    ln -sv /bin/bash /bin/sh && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    cp -r ${SPARK_JARS} /opt/spark/jars && \
    cp -r bin /opt/spark/bin && \
    cp -r sbin /opt/spark/sbin && \
    cp -r ${IMG_PATH}/spark/entrypoint.sh /opt/ && \
    cp -r examples /opt/spark/examples && \
    cp -r data /opt/spark/data && \
    cp -r python/lib ${SPARK_HOME}/python/lib && \
    # Sed command to remove use of tini
    sed -i -e 's/\/sbin\/tini[^"]*//g' /opt/entrypoint.sh && \
    # Remove extracted Spark
    rm -rf /spark-${SPARK_VERSION}-bin-hadoop2.7

RUN \
    cd ${SPARK_HOME}/jars && \
    # Install GCS connector
    curl https://storage.googleapis.com/hadoop-lib/gcs/gcs-connector-hadoop2-latest.jar -OLJ && \
    # Install Hadoop AWS integration
    curl http://central.maven.org/maven2/org/apache/hadoop/hadoop-aws/2.7.3/hadoop-aws-2.7.3.jar -OLJ && \
    # Install AWS SDK For Java
    curl http://central.maven.org/maven2/com/amazonaws/aws-java-sdk/1.7.4/aws-java-sdk-1.7.4.jar -OLJ

WORKDIR /opt/spark/work-dir

ENTRYPOINT [ "/opt/entrypoint.sh" ]
