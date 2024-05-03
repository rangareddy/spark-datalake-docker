#!/bin/bash

set -eo pipefail

export SPARK_HOME=${SPARK_HOME:-"/opt/spark"}
export SPARK_VERSION=${SPARK_VERSION:-"3.5.1"}
SPARK_CONF=${SPARK_CONF:-"/etc/spark/conf"}
export SPARK_JARS_DIR="${SPARK_JARS_DIR:-${SPARK_HOME}/jars}"
SPARK_3_3=3.3.0

SPARK_LOG_DIR=${SPARK_LOG_DIR:-/var/log/spark}
mkdir -p "$SPARK_LOG_DIR"

export SPARK_MAJOR_VERSION=$(echo "$SPARK_VERSION" | grep -Eo '^[0-9]+\.[0-9]*')
export ICEBERG_VERSION="${ICEBERG_VERSION:-1.5.0}"
export DELTA_SPARK_VERSION="${DELTA_SPARK_VERSION:-3.1.0}"
export HUDI_VERSION="${HUDI_VERSION:-0.14.1}"
export PAIMON_VERSION="${PAIMON_VERSION:-"0.7.0-incubating"}"
export HADOOP_VERSION="${HADOOP_VERSION:-3.3.4}"

echo "Installing the Spark with version $SPARK_VERSION"
mkdir -p "${SPARK_HOME}" && mkdir -p "$SPARK_CONF"

# shellcheck disable=SC2206
IFS=. v1_array=($SPARK_3_3) v2_array=($SPARK_VERSION)
v1=$((v1_array[0] * 100 + v1_array[1] * 10 + v1_array[2]))
v2=$((v2_array[0] * 100 + v2_array[1] * 10 + v2_array[2]))

ver_diff=$((v2 - v1))

if [[ $ver_diff -ge 0 ]] && [[ $SPARK_VERSION == [3-9].[3-9]* ]]; then
    HADOOP_MIN_VERSION="3"
elif [[ $SPARK_VERSION == 3.[0-2]* ]]; then
    HADOOP_MIN_VERSION="3.2"
else
    HADOOP_MIN_VERSION="2.7"
fi

export SPARK_TAR_FILE="spark-${SPARK_VERSION}-bin-hadoop${HADOOP_MIN_VERSION}.tgz"

# Download spark
mkdir -p "${SPARK_HOME}" \
    && curl https://dlcdn.apache.org/spark/spark-"${SPARK_VERSION}"/"${SPARK_TAR_FILE}" -o "${SPARK_TAR_FILE}" \
    && tar xzf "${SPARK_TAR_FILE}" --directory "${SPARK_HOME}" --strip-components 1 \
    && rm -rf "${SPARK_TAR_FILE}"

if [ -z "$(ls -A "${SPARK_HOME}")" ]; then
    echo "Spark is not downloaded. Please check the logs."
    exit 1
fi

chmod u+x "${SPARK_HOME}"/sbin/* && chmod u+x "${SPARK_HOME}"/bin/*
mv "${BASE_DIR}"/spark-defaults.conf "${SPARK_HOME}"/conf

# shellcheck disable=SC2002
EVENT_LOG_DIR=$(cat "$SPARK_HOME"/conf/spark-defaults.conf | grep -i 'spark.eventLog.dir' | tr -s ' ' | cut -d ' ' -f 2)
mkdir -p "$EVENT_LOG_DIR"
echo "Spark Installation Finished"

echo "Downloading the datalake required jars"
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
  nohup mvn dependency:copy -Dartifact="$DATALAKE_DEPENDENCY" -DoutputDirectory="${SPARK_HOME}"/jars/ 2>&1
done