#!/bin/bash

set -e

# Validate docker is installed
if ! command -v docker  &> /dev/null 2>&1; then
  echo "Error: Docker not found. Please install docker and rerun."
  exit
fi

if ! command -v docker-compose >/dev/null 2>&1; then
  echo "Error: Docker Compose is not installed. Please install docker compose and rerun."
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "Error: Docker daemon not running. Please start docker and rerun."
  exit 1
fi

# Function to display usage message
usage() {
  echo "Usage: $0 (build|start|stop)"
  echo "  build: Builds Docker images defined in docker-compose.yml"
  echo "  start: Starts the services defined in docker-compose.yml"
  echo "  stop: Stops the services defined in docker-compose.yml"
  exit 1
}

# Check if exactly one argument is provided
if [[ $# -ne 1 ]]; then
  usage
fi

# Get the action (build, start, or stop)
action="$1"

# Validate the action argument
if [[ ! ( "$action" == "build" || "$action" == "start" || "$action" == "stop" ) ]]; then
  echo "Invalid action: '$action'"
  usage
fi

# Load environment variables from .env
source ./.env

REPOSITORY=${REPOSITORY:-"rangareddy1988"}
IMAGE_NAME=${IMAGE_NAME:-"ranga-spark-iceberg"}
SPARK_VERSION=${SPARK_VERSION:-3.5.1}
ICEBERG_VERSION=${ICEBERG_VERSION:-1.5.0}
TAG=${TAG:-"latest"}
IMAGE_TARGET="${REPOSITORY}/${IMAGE_NAME}-${SPARK_VERSION}-${ICEBERG_VERSION}:${TAG}"

build_docker_image() {
  # Remove existing containers
  OLD_CONTAINERS=$(docker ps --filter "ancestor=${IMAGE_TARGET}" --format "{{.ID}}" > /dev/null 2>&1)
  if [[ -n "$OLD_CONTAINERS" ]]; then
    echo "Removing the existing containers"
    docker rm -f $OLD_CONTAINERS
  fi

  # Remove existing images
  OLD_IMAGES=$(docker images -q --filter reference=${IMAGE_TARGET} > /dev/null 2>&1)
  if [[ -n "$OLD_IMAGES" ]]; then
    echo "Removing the existing images"
    docker rmi -f $OLD_IMAGES
  fi
  docker-compose build --progress tty

  echo "Cleaning dangling images"
  docker image prune -f
}

export DOCKER_IMAGE_NAME=$IMAGE_TARGET
TARGET_ARCHS=("linux/amd64" "linux/arm64")
for ARCH in "${TARGET_ARCHS[@]}"; do
  if docker buildx ls | grep $ARCH > /dev/null 2>&1; then
    export PLATFORM=$ARCH
  fi 
done

# Execute Docker Compose command based on the action
case "$action" in
  build)
    echo "Building Docker images..."
    build_docker_image
    ;;
  start)
    echo "Starting services..."
    docker-compose up -d
    ;;
  stop)
    echo "Stopping services..."
    docker-compose down
    ;;
esac

