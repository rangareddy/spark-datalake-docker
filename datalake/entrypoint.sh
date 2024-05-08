#!/bin/bash
set -e

source datalake.env

# Function to start Notebook
start_notebook() {
  export JUPYTER_PORT=${JUPYTER_PORT:-8888}
  export JUPYTER_NOTEBOOK_PORT=${JUPYTER_NOTEBOOK_PORT:-8889}
  export NOTEBOOK_DIR=${NOTEBOOK_DIR:-${BASE_DIR}/notebooks}
  export JUPYTER_LOG_DIR="/var/log/jupyter"

  echo "Starting a Notebook"
  mkdir -p "${NOTEBOOK_DIR}" "${JUPYTER_LOG_DIR}"
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

bash "${BASE_DIR}"/start/start_spark.sh
start_notebook
while true; do sleep 1000; done