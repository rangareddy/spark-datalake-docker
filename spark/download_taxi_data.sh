#!/bin/bash

DATA_DIR=${DATA_DIR:-${BASE_DIR}/datasets}

echo "Downloading the Taxi Trip Data to ${DATA_DIR} for the years 2021-2022"

mkdir -p "${DATA_DIR}" || {
  echo "Error: Failed to create directory '${DATA_DIR}'" >&2
  exit 1
}

if [ ! -f "${DATA_DIR}/nyc_film_permits.json" ]; then
  curl --silent https://data.cityofnewyork.us/resource/tg4x-b46p.json >${DATA_DIR}/nyc_film_permits.json
fi

TRIP_DATA_URL="https://d37ci6vzurychx.cloudfront.net/trip-data"

for year in {2021..2022}; do
  for month in {01..12}; do
    data_file=yellow_tripdata_${year}-${month}.parquet
    if [ ! -f "${DATA_DIR}/${data_file}" ]; then
      curl -s ${TRIP_DATA_URL}/${data_file} -o ${DATA_DIR}/${data_file}
    fi
  done
done