#!/bin/bash

export SPARK_MASTER_PORT=7077
export SPARK_MASTER_HOST="spark-iceberg"

echo "Starting the Spark Master"
start-master.sh -p ${SPARK_MASTER_PORT}
echo "Startingt he Spark Worker"
start-worker.sh spark://${SPARK_MASTER_HOST}:${SPARK_MASTER_PORT}
echo "Starting the Spark History Server"
start-history-server.sh
echo "Starting the Spark Thrift Server"
start-thriftserver.sh  --driver-java-options "-Dderby.system.home=/tmp/derby"

echo "Starting the notebook"
notebook
