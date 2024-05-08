#!/bin/bash
set -e

start_time=$(date +%s)

echo "Installing Python Dependencies"
source datalake.env

echo "Upgrading the Pip"
pip3 install -q --upgrade pip

echo "Installing required python dependencies"
pip3 install -q --no-cache-dir jupyter=="${JUPYTER_VERSION}" spylon-kernel=="${SPYLON_KERNEL_VERSION}" jupysql=="${JUPYSQL_VERSION}" \
  matplotlib=="${MATPLOTLIB_VERSION}" scipy=="${SCIPY_VERSION}" duckdb-engine=="${DUCKDB_ENGINE_VERSION}"
python3 -m spylon_kernel install

# Install IJava jupyter kernel
echo "Installing IJava jupyter kernel"
curl -s https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip -Lo ijava-1.3.0.zip && \
    unzip -qq ijava-1.3.0.zip && python3 install.py --sys-prefix && rm -rf install.py ijava-1.3.0.zip && \
    jupyter kernelspec list

# Install IPython
IPYTHON_STARTUP=/root/.ipython/profile_default/startup
mkdir -p ${IPYTHON_STARTUP}
mv ipython/startup/00-prettytables.py ipython/startup/README ${IPYTHON_STARTUP}

IS_ICEBERG_ENABLED=${IS_ICEBERG_ENABLED:-"false"}
if [ "${IS_ICEBERG_ENABLED}" == "true" ]; then
  echo "Installing PyIceberg python dependency"
  pip3 install -q --no-cache-dir pyiceberg[pyarrow,duckdb,pandas]=="${PYICEBERG_VERSION}"
fi

IS_DELTA_ENABLED=${IS_DELTA_ENABLED:-"false"}
if [ "${IS_DELTA_ENABLED}" == "true" ]; then
  echo "Installing Deltalake python dependency"
  pip3 install -q --no-cache-dir delta-spark=="${DELTA_SPARK_VERSION}" deltalake=="${DELTALAKE_VERSION}"
fi

end_time=$(date +%s)

# Calculate elapsed time in seconds
elapsed=$((end_time - start_time))
echo "Total time taken to install Python dependencies is $elapsed seconds"

echo "Installed Python Dependencies"




