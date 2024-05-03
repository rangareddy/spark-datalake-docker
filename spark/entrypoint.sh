#!/bin/bash

set -eo pipefail

export SPARK_MASTER_HOST=$(hostname -f)
export SPARK_MASTER_PORT=${SPARK_MASTER_PORT:-7077}
export SPARK_MASTER_WEBUI_PORT=${SPARK_MASTER_WEBUI_PORT:-8080}
export SPARK_WORKER_WEBUI_PORT=${SPARK_WORKER_WEBUI_PORT:-8081}
export SPARK_HISTORY_UI_PORT=${SPARK_HISTORY_UI_PORT:-18080}
export JUPYTER_PORT=${JUPYTER_PORT:-8888}

# Function to start Spark Standalone Master
start_spark_master() {
  "$SPARK_HOME"/sbin/start-master.sh
  echo "Spark Master started on ${SPARK_MASTER_HOST}:${SPARK_MASTER_PORT}"
}

# Function to start Spark Standalone Worker
start_spark_worker() {
  "$SPARK_HOME"/sbin/start-worker.sh "spark://${SPARK_MASTER_HOST}:${SPARK_MASTER_PORT}"
  echo "Spark Worker started."
}

# Function to start Spark History Server
start_spark_history_server() {
    "${SPARK_HOME}"/sbin/start-history-server.sh >> "${SPARK_LOG_DIR}/spark-history_$SPARK_HISTORY_UI_PORT.log" 2>&1
    echo "Spark History Server started on ${SPARK_HISTORY_UI_PORT}."
}

# Function to start Spark Thrift Server
start_spark_thrift_server() {
    "${SPARK_HOME}"/sbin/start-thriftserver.sh  --driver-java-options "-Dderby.system.home=/tmp/derby"
    echo "Spark Thrift Server started."
}

# Function to start Notebook
start_notebook() {
    mkdir -p "${NOTEBOOK_DIR}"
    #export PYSPARK_DRIVER_PYTHON=jupyter-notebook
    #export PYSPARK_DRIVER_PYTHON_OPTS='notebook'
    #jupyter notebook --ip 0.0.0.0 --port "${JUPYTER_PORT}" --notebook-dir "${NOTEBOOK_DIR}" --no-browser --allow-root
    #jupyter lab --ip 0.0.0.0 --port 8888 --allow-root &> /var/log/jupyter.log &
    notebook
    echo "JupyterLab logging location: /var/log/jupyter.log"
}

# Set environment variable (optional, adjust based on your Spark installation)
#ENV PYSPARK_DRIVER_PYTHON=jupyter
#ENV PYSPARK_DRIVER_PYTHON_OPTS="notebook"

# Start services
start_spark_master
start_spark_worker
start_spark_history_server
start_spark_thrift_server
start_notebook

