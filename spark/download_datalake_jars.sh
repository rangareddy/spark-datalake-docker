#!/bin/bash

ICEBERG_DEPENDENCIES=(
    "org.apache.iceberg:iceberg-spark-runtime-${SPARK_MAJOR_VERSION}_2.12:${ICEBERG_VERSION}"
    "org.apache.iceberg:iceberg-aws-bundle:${ICEBERG_VERSION}"
    "org.apache.iceberg:iceberg-delta-lake:${ICEBERG_VERSION}"
)

DELTA_DEPENDENCIES=(
    "io.delta:delta-spark_2.12:${DELTA_SPARK_VERSION}"
    "io.delta:delta-storage:${DELTA_SPARK_VERSION}"
    "io.delta:delta-iceberg_2.13:${DELTA_SPARK_VERSION}"
)

HUDI_DEPENDENCIES=(
  "org.apache.hudi:hudi-spark3-bundle_2.12:${HUDI_VERSION}"
)

PAIMON_DEPENDENCIES=(
  "org.apache.paimon:paimon-spark-${SPARK_MAJOR_VERSION}:${PAIMON_VERSION}"
)

HADOOP_DEPENDENCIES=("org.apache.hadoop:hadoop-aws:${HADOOP_VERSION}")
DATALAKE_DEPENDENCIES=(
  "${ICEBERG_DEPENDENCIES[@]}"
  "${DELTA_DEPENDENCIES[@]}"
  "${HUDI_DEPENDENCIES}"
  "${PAIMON_DEPENDENCIES}"
  "${HADOOP_DEPENDENCIES[@]}"
)

for DATALAKE_DEPENDENCY in "${DATALAKE_DEPENDENCIES[@]}"; do
  echo "Downloading the $DATALAKE_DEPENDENCY"
  mvn dependency:copy -Dartifact="$DATALAKE_DEPENDENCY" -DoutputDirectory="${SPARK_HOME}"/jars/ 2>&1
done