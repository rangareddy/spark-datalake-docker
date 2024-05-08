# ------------------------------------------------
# Dockerfile for Data Lake quickstart
# ------------------------------------------------

FROM python:3.9-bullseye

# Authors
LABEL authors="Ranga Reddy"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG JAVA_VERSION=${JAVA_VERSION:-11}

RUN echo "Install OS dependencies" && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      sudo curl vim unzip ssh bash-completion \
      build-essential software-properties-common \
      openjdk-${JAVA_VERSION}-jdk maven && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -s https://raw.githubusercontent.com/docker/docker-ce/master/components/cli/contrib/completion/bash/docker \
    -o /etc/bash_completion.d/docker.sh

# Set user and group
ARG USERNAME=datalake
ARG GROUPNAME=datalake
ENV BASE_DIR=/home/${USERNAME}
RUN groupadd --gid 1001 -r ${GROUPNAME} && useradd --uid 1001 -r -m -g ${GROUPNAME} ${USERNAME}

WORKDIR ${BASE_DIR}
ADD entrypoint.sh datalake.env scripts conf examples notebooks ${BASE_DIR}

#RUN chmod -R 755 ${BASE_DIR}
RUN bash install/install_python_dependencies.sh && rm -rf install/install_python_dependencies.sh

ENV SPARK_HOME=${SPARK_HOME:-"/opt/spark"}
RUN bash install/install_spark.sh && rm -rf install/install_spark.sh

# Configure environment variables
RUN export PY4J_SRC=$(ls $SPARK_HOME/python/lib/py4j-*-src.zip)
ENV PYTHONPATH=$SPARK_HOME/python:$PY4J_SRC:$PYTHONPATH
ENV PATH="${SPARK_HOME}/sbin:${SPARK_HOME}/bin:${PATH}"
ENV IJAVA_CLASSPATH=${SPARK_HOME}/jars/*

ENTRYPOINT ["./entrypoint.sh"]