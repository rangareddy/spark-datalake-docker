#!/bin/bash
set -e

# Function to check Docker installation
check_docker_installed() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker is not installed. Please install docker and rerun."
    exit 1
  fi
}

# Function to check Docker Compose installation
check_docker_compose_installed() {
  if ! command -v docker-compose >/dev/null 2>&1; then
    echo "ERROR: Docker Compose is not installed."
    exit 1
  fi
}

# Function to check Docker running status
check_docker_running() {
  if ! docker info > /dev/null 2>&1; then
    echo "ERROR: The docker daemon is not running or accessible. Please start docker and rerun."
    exit 1
  fi
}

check_docker_installed
check_docker_compose_installed
check_docker_running

# Default repository remote name
REPOSITORY="rangareddy1988"
IMAGE_NAME="spark-datalake"
TAG="latest"

source datalake/datalake.env

# Build full image target and log.
IMAGE_TARGET=${REPOSITORY}/${IMAGE_NAME}-${SPARK_VERSION}:${TAG}

SUPPORTED_PLATFORMS=("linux/amd64" "linux/arm64")
for ARCH in "${SUPPORTED_PLATFORMS[@]}"; do
  if docker buildx ls | grep "$ARCH" >/dev/null 2>&1; then
    export PLATFORM=$ARCH
    break
  fi
done

echo "Building datalake image"
docker buildx build -t "${IMAGE_TARGET}" $(for i in $(cat datalake/datalake.env); do out+="--build-arg $i " ; done; echo "$out";out="") \
  --progress plain --platform="${PLATFORM}" ./datalake

docker image prune -f