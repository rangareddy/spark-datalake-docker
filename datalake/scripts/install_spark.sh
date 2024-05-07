#!/bin/bash
set -e

source datalake.env

export SPARK_HOME=${SPARK_HOME:-"/opt/spark"}
export SPARK_VERSION=${SPARK_VERSION:-3.5.1}
export SPARK_CONF=${SPARK_CONF:-"${SPARK_HOME}/conf"}
export SPARK_JARS_DIR="${SPARK_JARS_DIR:-${SPARK_HOME}/jars/}"
export SPARK_3_3=3.3.0

export SPARK_MAJOR_VERSION
SPARK_MAJOR_VERSION=$(echo "$SPARK_VERSION" | grep -Eo '^[0-9]+\.[0-9]*')

echo "Installing the Spark with version $SPARK_VERSION"
mkdir -p "${SPARK_HOME}"

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
mkdir -p "${SPARK_HOME}" &&
  curl -s https://dlcdn.apache.org/spark/spark-"${SPARK_VERSION}"/"${SPARK_TAR_FILE}" -o "${SPARK_TAR_FILE}" &&
  tar xzf "${SPARK_TAR_FILE}" --directory "${SPARK_HOME}" --strip-components 1 &&
  rm -rf "${SPARK_TAR_FILE}"

if [ -z "$(ls -A "${SPARK_HOME}")" ]; then
  echo "Spark is not downloaded. Please check the logs."
  exit 1
fi

chmod u+x "${SPARK_HOME}"/sbin/* && chmod u+x "${SPARK_HOME}"/bin/*

mv "${BASE_DIR}"/spark-defaults.conf "${SPARK_HOME}"/conf
mv "${BASE_DIR}"/spark_*_app.py "${SPARK_HOME}"/examples

mv "$SPARK_HOME"/conf/log4j2.properties.template "$SPARK_HOME"/conf/log4j2.properties
mv "$SPARK_HOME"/conf/spark-env.sh.template "$SPARK_HOME"/conf/spark-env.sh

# shellcheck disable=SC2002
echo "Spark Installation Finished"

echo "Downloading the datalake required jars (If it is enabled)"
IS_ICEBERG_ENABLED=${IS_ICEBERG_ENABLED:-"true"}
ICEBERG_DEPENDENCIES=()
if [ "${IS_ICEBERG_ENABLED}" == "true" ]; then
  export ICEBERG_VERSION="${ICEBERG_VERSION:-1.5.0}"
  ICEBERG_DEPENDENCIES=(
    "org.apache.iceberg:iceberg-spark-runtime-${SPARK_MAJOR_VERSION}_2.12:${ICEBERG_VERSION}"
    "org.apache.iceberg:iceberg-aws-bundle:${ICEBERG_VERSION}"
    "org.apache.iceberg:iceberg-delta-lake:${ICEBERG_VERSION}"
  )
  mv "${BASE_DIR}"/.pyiceberg.yaml /root/.pyiceberg.yaml
fi

IS_DELTA_ENABLED=${IS_DELTA_ENABLED:-"true"}
DELTA_DEPENDENCIES=()
if [ "${IS_DELTA_ENABLED}" == "true" ]; then
  export DELTA_SPARK_VERSION="${DELTA_SPARK_VERSION:-3.1.0}"
  DELTA_DEPENDENCIES=(
    "io.delta:delta-spark_2.12:${DELTA_SPARK_VERSION}"
    "io.delta:delta-storage:${DELTA_SPARK_VERSION}"
    "io.delta:delta-iceberg_2.13:${DELTA_SPARK_VERSION}"
  )
fi

IS_HUDI_ENABLED=${IS_HUDI_ENABLED:-"false"}
HUDI_DEPENDENCIES=()
if [ "${IS_HUDI_ENABLED}" == "true" ]; then
  export HUDI_VERSION="${HUDI_VERSION:-0.14.1}"
  HUDI_DEPENDENCIES=("org.apache.hudi:hudi-spark3-bundle_2.12:${HUDI_VERSION}")
fi

# Install AWS CLI (if enabled)
if [[ "${IS_AWS_ENABLED}" == "true" ]]; then
  curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip -qq awscliv2.zip
  ./aws/install -i /usr/local/aws --bin-dir /usr/local/bin
  rm -rf awscliv2.zip

  export HADOOP_VERSION="${HADOOP_VERSION:-3.3.4}"
  HADOOP_AWS_DEPENDENCIES=("org.apache.hadoop:hadoop-aws:${HADOOP_VERSION}")
fi

DATALAKE_DEPENDENCIES=(
  "${ICEBERG_DEPENDENCIES[@]}"
  "${DELTA_DEPENDENCIES[@]}"
  "${HUDI_DEPENDENCIES[@]}"
  "${HADOOP_AWS_DEPENDENCIES[@]}"
)

for DATALAKE_DEPENDENCY in "${DATALAKE_DEPENDENCIES[@]}"; do
  echo "Downloading the ${DATALAKE_DEPENDENCY} jar"
  mvn dependency:copy -Dartifact="${DATALAKE_DEPENDENCY}" -DoutputDirectory="${SPARK_JARS_DIR}" >/dev/null 2>&1
done