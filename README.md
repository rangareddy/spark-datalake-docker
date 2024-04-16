# Spark + Iceberg Quickstart Docker Image

This is a docker compose environment to quickly get up and running with a Spark environment and a local REST
catalog, and MinIO as a storage backend.

## 1. Building the Docker Image locally

```bash
bash build_start_stop_image.sh build
```

## 2. Running the Docker container

```sh
bash build_start_stop_image.sh start
```

The notebook server will then be available at http://localhost:8888

## 3. Stop the Docker container

```sh
bash build_start_stop_image.sh stop
```
