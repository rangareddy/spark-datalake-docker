echo "Installing the Spark"

export ICEBERG_VERSION=${ICEBERG_VERSION:-1.5.0}
export SPARK_VERSION=${SPARK_VERSION:-3.5.1}
SPARK_MAJOR_VERSION=$(echo "$SPARK_VERSION" | grep -Eo '^[0-9]+\.[0-9]*')

# Download spark
mkdir -p ${SPARK_HOME} \
 && curl https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz -o spark-${SPARK_VERSION}-bin-hadoop3.tgz \
 && tar xvzf spark-${SPARK_VERSION}-bin-hadoop3.tgz --directory ${SPARK_HOME} --strip-components 1 \
 && rm -rf spark-${SPARK_VERSION}-bin-hadoop3.tgz

if [ -z "$(ls -A ${SPARK_HOME})" ]; then
    echo "Spark is not downloaded. Please check the logs."
    exit 1
fi

mv /opt/spark-defaults.conf ${SPARK_HOME}/conf

EVENT_LOG_DIR=$(cat $SPARK_HOME/conf/spark-defaults.conf | grep -i 'spark.eventLog.dir' | tr -s ' ' | cut -d ' ' -f 2)
SQL_WAREHOUSE_DIR=$(cat $SPARK_HOME/conf/spark-defaults.conf | grep -i 'spark.sql.warehouse.dir' | tr -s ' ' | cut -d ' ' -f 2)
mkdir -p $SQL_WAREHOUSE_DIR $EVENT_LOG_DIR

ICEBERG_SPARK_RUNTIME_JAR=iceberg-spark-runtime-${SPARK_MAJOR_VERSION}_2.12-${ICEBERG_VERSION}.jar
ICEBERG_AWS_BUNDLE_JAR=iceberg-aws-bundle-${ICEBERG_VERSION}.jar
MAVEN_REPO_URL=https://repo1.maven.org/maven2/org/apache/iceberg

# Download iceberg spark runtime
curl ${MAVEN_REPO_URL}/iceberg-spark-runtime-${SPARK_MAJOR_VERSION}_2.12/${ICEBERG_VERSION}/${ICEBERG_SPARK_RUNTIME_JAR} \
    -Lo ${SPARK_JARS_DIR}/${ICEBERG_SPARK_RUNTIME_JAR}

# Download AWS bundle
curl -s ${MAVEN_REPO_URL}/iceberg-aws-bundle/${ICEBERG_VERSION}/${ICEBERG_AWS_BUNDLE_JAR} \
    -Lo ${SPARK_JARS_DIR}/${ICEBERG_AWS_BUNDLE_JAR}

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
 && unzip awscliv2.zip \
 && sudo ./aws/install \
 && rm awscliv2.zip \
 && rm -rf aws/