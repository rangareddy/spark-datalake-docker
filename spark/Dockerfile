FROM python:3.9-bullseye
RUN pip3 install -q --upgrade pip
LABEL authors="Ranga Reddy"

ARG USERNAME=datalake
ARG GROUPNAME=datalake
ENV BASE_DIR=/home/datalake

RUN groupadd --gid 1001 -r ${GROUPNAME} && useradd --uid 1001 -r -m -g ${GROUPNAME} ${USERNAME}

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      sudo curl vim unzip ssh bash-completion \
      openjdk-11-jdk \
      build-essential software-properties-common \
      maven && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR ${BASE_DIR}

RUN curl -s https://raw.githubusercontent.com/docker/docker-ce/master/components/cli/contrib/completion/bash/docker \
    -o /etc/bash_completion.d/docker.sh

# Install Jupyter and other python deps
COPY requirements.txt .
RUN pip3 install -q -r requirements.txt && rm -rf requirements.txt

# Add scala kernel via spylon-kernel
RUN python3 -m spylon_kernel install

# Download and install IJava jupyter kernel
RUN curl -s https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip -Lo ijava-1.3.0.zip && \
    unzip -qq ijava-1.3.0.zip && python3 install.py --sys-prefix && rm -rf install.py ijava-1.3.0.zip && \
    jupyter kernelspec list

# Install AWS CLI
RUN curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
 && unzip -qq awscliv2.zip \
 && sudo ./aws/install \
 && rm -rf awscliv2.zip aws

#COPY download_datalake_jars.sh ${BASE_DIR}/
ENV SPARK_HOME=${SPARK_HOME:-"/opt/spark"}
ENV SPARK_VERSION=${SPARK_VERSION:-"3.5.1"}
ENV SPARK_JARS_DIR="${SPARK_HOME}/jars"
COPY install_spark.sh ${BASE_DIR}/
COPY spark-defaults.conf ${BASE_DIR}/
RUN bash ${BASE_DIR}/install_spark.sh && rm -rf ${BASE_DIR}/install_spark.sh && \
    export PY4J_SRC=$(ls $SPARK_HOME/python/lib/py4j-*-src.zip) && echo "Py4j : ${PY4J_SRC}"

ENV PYTHONPATH=$SPARK_HOME/python:$PY4J_SRC:$PYTHONPATH
ENV PATH="${SPARK_HOME}/sbin:${SPARK_HOME}/bin:${PATH}"
ENV IJAVA_CLASSPATH=${SPARK_JARS_DIR}/*

ENV DATA_DIR=${DATA_DIR:-${BASE_DIR}/datasets}
ENV NOTEBOOK_DIR=${NOTEBOOK_DIR:-${BASE_DIR}/notebooks}
RUN mkdir -p ${BASE_DIR}/warehouse ${BASE_DIR}/localwarehouse ${NOTEBOOK_DIR}
COPY notebooks/ ${NOTEBOOK_DIR}

# Add a notebook command
RUN echo '#! /bin/sh' >> /bin/notebook \
 && echo 'export PYSPARK_DRIVER_PYTHON=jupyter-notebook' >> /bin/notebook \
 && echo "export PYSPARK_DRIVER_PYTHON_OPTS=\"--notebook-dir=${NOTEBOOK_DIR} --ip='*' --NotebookApp.token='' --NotebookApp.password='' --port=8888 --no-browser --allow-root\"" >> /bin/notebook \
 && echo "pyspark" >> /bin/notebook \
 && chmod u+x /bin/notebook

RUN mkdir -p /root/.ipython/profile_default/startup
COPY ipython/startup/00-prettytables.py /root/.ipython/profile_default/startup
COPY ipython/startup/README /root/.ipython/profile_default/startup
COPY .pyiceberg.yaml /root/.pyiceberg.yaml
COPY entrypoint.sh .
ENTRYPOINT ["./entrypoint.sh"]