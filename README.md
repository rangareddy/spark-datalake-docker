# Spark + Data Lake quickstart Docker Image

## 1. Building the Docker Image locally

```bash
bash build.sh
```

## 2. Running the Docker container

```sh
docker-compose up -d
```

The notebook server will then be available at http://localhost:8888

## 3. Stop the Docker container

```sh
docker-compose down
```
## Notes

| Name                 | URL                    |
|----------------------|------------------------|
| Jupyter Lab          | http://localhost:8888  |
| SparkSession Web UI  | http://localhost:4040  |
| Spark History Server | http://localhost:18080 |
| MiniIO               | http://localhost:9090  |