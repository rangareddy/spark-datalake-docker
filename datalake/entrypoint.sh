#!/bin/bash
set -e

source datalake.env

export SPARK_MASTER_HOST
SPARK_MASTER_HOST=$(hostname -f)
export SPARK_MASTER_PORT=${SPARK_MASTER_PORT:-7077}
export SPARK_MASTER_WEBUI_PORT=${SPARK_MASTER_WEBUI_PORT:-8080}
export SPARK_WORKER_WEBUI_PORT=${SPARK_WORKER_WEBUI_PORT:-8081}
export SPARK_HISTORY_UI_PORT=${SPARK_HISTORY_UI_PORT:-18080}
export SPARK_LOG_DIR="/var/log/spark"
export IS_STANDALONE_CLUSTER=${IS_STANDALONE_CLUSTER:-"false"}
export SPARK_MASTER="local[*]"

# shellcheck disable=SC2002
EVENT_LOG_DIR=$(cat "${SPARK_HOME}"/conf/spark-defaults.conf | grep -i 'spark.eventLog.dir' | tr -s ' ' | cut -d ' ' -f 2)

export JUPYTER_PORT=${JUPYTER_PORT:-8888}
export JUPYTER_NOTEBOOK_PORT=${JUPYTER_NOTEBOOK_PORT:-8889}
export NOTEBOOK_DIR=${NOTEBOOK_DIR:-${BASE_DIR}/notebooks}
export JUPYTER_LOG_DIR="/var/log/jupyter"

mkdir -p "${EVENT_LOG_DIR}" "${NOTEBOOK_DIR}" "${JUPYTER_LOG_DIR}" "${SPARK_LOG_DIR}"

# Function to start Spark Standalone Master
start_spark_master() {
  start-master.sh >>"${SPARK_LOG_DIR}/spark-master.log" 2>&1
  sleep 5
  curl -s -f -o /dev/null "${SPARK_MASTER_HOST}":"${SPARK_MASTER_WEBUI_PORT}" &&
    echo "Spark Master started on ${SPARK_MASTER_PORT}." || echo "Spark Master start failed" exit 1
}

# Function to start Spark Standalone Worker
start_spark_worker() {
  start-worker.sh "spark://${SPARK_MASTER_HOST}:${SPARK_MASTER_PORT}" >>"${SPARK_LOG_DIR}/spark-worker.log" 2>&1
  sleep 5
  curl -s -f -o /dev/null "${SPARK_MASTER_HOST}":"${SPARK_WORKER_WEBUI_PORT}" &&
    echo "Spark Worked started on ${SPARK_WORKER_WEBUI_PORT}." || echo "Spark Worker start failed" exit 1
}

# Function to start Spark History Server
start_spark_history_server() {
  start-history-server.sh >>"${SPARK_LOG_DIR}/spark-history_$SPARK_HISTORY_UI_PORT.log" 2>&1
  sleep 5
  curl -s -f -o /dev/null "${SPARK_MASTER_HOST}":"${SPARK_HISTORY_UI_PORT}" &&
    echo "Spark History Server started on ${SPARK_HISTORY_UI_PORT}." || echo "Spark History Server failed" exit 1
}

# Function to start Spark Thrift Server
start_spark_thrift_server() {
  start-thriftserver.sh --driver-java-options "-Dderby.system.home=/tmp/derby" >>"${SPARK_LOG_DIR}/spark-thriftserver.log" 2>&1
  echo "Spark Thrift Server started."
}

# Function to start Notebook
start_notebook() {
  echo "Starting a Notebook"
  mv DeltaLake_Example.ipynb Iceberg_Example.ipynb "${NOTEBOOK_DIR}"
  export PYSPARK_DRIVER_PYTHON=jupyter
  export PYSPARK_DRIVER_PYTHON_OPTS="notebook"
  nohup jupyter-lab --ip='*' --NotebookApp.token='' --NotebookApp.password='' --no-browser --allow-root \
    > "${JUPYTER_LOG_DIR}"/jupyter.log 2>&1 &
  sleep 5
  nohup jupyter notebook --ip='*' --notebook-dir="${NOTEBOOK_DIR}" \
    --NotebookApp.token='' --NotebookApp.password='' --no-browser --allow-root > "${JUPYTER_LOG_DIR}"/jupyter_notebook.log 2>&1 &
  sleep 5
  echo "Notebook started successfully"
}

# Function to validate Spark Pi Example
validate_spark_examples() {
  echo "Validating SparkPi Example"
  spark-submit --master "${SPARK_MASTER}" \
    --class org.apache.spark.examples.SparkPi \
    "${SPARK_HOME}"/examples/jars/spark-examples_2.12-"${SPARK_VERSION}".jar 10 > sparkpi.out 2>&1

  sleep 10
  # shellcheck disable=SC2002
  spark_pi_output=$(cat sparkpi.out | grep 'Pi is roughly')
  rm -rf sparkpi.out
  if [ -z "${spark_pi_output}" ]; then
    echo "ERROR: Spark SparkPi App failed"
    exit 1
  fi

  IS_ICEBERG_ENABLED=${IS_ICEBERG_ENABLED:-"true"}
  if [ "${IS_ICEBERG_ENABLED}" == "true" ]; then
    echo "Validating Spark Iceberg Example"
    spark-submit --master "${SPARK_MASTER}" "${SPARK_HOME}"/examples/spark_iceberg_app.py > spark_iceberg_app.log 2>&1
    sleep 10
    # shellcheck disable=SC2002
    spark_iceberg_app_output=$(cat spark_iceberg_app.log | grep 'Total Count: 30')
    rm -rf spark_iceberg_app.log
    if [ -z "${spark_iceberg_app_output}" ]; then
      echo "ERROR: Spark Iceberg App failed"
      exit 1
    fi
    echo "Spark Iceberg App completed successfully"
  fi

  IS_DELTA_ENABLED=${IS_DELTA_ENABLED:-"true"}
  if [ "${IS_DELTA_ENABLED}" == "true" ]; then
    echo "Validating Spark Delta Example"
    spark-submit --master "${SPARK_MASTER}" "${SPARK_HOME}"/examples/spark_delta_app.py > spark_delta_app.log 2>&1
    sleep 10
    # shellcheck disable=SC2002
    spark_delta_app_output=$(cat spark_delta_app.log | grep 'Total Count: 30')
    rm -rf spark_delta_app.log
    if [ -z "${spark_delta_app_output}" ]; then
      echo "ERROR: Spark Delta App failed"
      exit 1
    fi
    echo "Spark Delta App completed successfully"
  fi
}

# Start services

if [ "${IS_STANDALONE_CLUSTER}" == "true" ]; then
  start_spark_master
  start_spark_worker
  start_spark_thrift_server
  SPARK_MASTER="spark://${SPARK_MASTER_HOST}:${SPARK_MASTER_PORT}"
fi

start_spark_history_server
validate_spark_examples
start_notebook
while true; do sleep 1000; done