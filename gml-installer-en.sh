#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
    echo "[Gml] This script must be run as root"
    exit 1
fi

# Check for docker.io installation
if ! command -v docker >/dev/null; then
    echo "[Gml] Docker is not installed, update is not possible"
    exit 1
fi

if [ -f .env ]; then
    echo "[Gml] Checking .env - \e[32mSuccessful\e[0m"
else
    echo "[Gml] .env file is missing"
    exit 1
fi

if [ -f docker-compose.yml ]; then
    echo "[Gml] Checking docker-compose.yml - \e[32mSuccessful\e[0m"
else
    echo "[Gml] docker-compose.yml file is missing"
    exit 1
fi

if [ -f ./frontend/Gml.Web.Client/.env ]; then
    echo "[Gml] Checking ./frontend/Gml.Web.Client/.env - \e[32mSuccessful\e[0m"
else
    echo "[Gml] ./frontend/Gml.Web.Client/.env file is missing"
    exit 1
fi

if command -v docker-compose >/dev/null; then
    echo "[Docker-Compose] Docker Compose v1 is installed"
    DOCKER_COMPOSE_CMD="docker-compose"
elif command -v docker compose >/dev/null; then
    echo "[Docker-Compose] Docker Compose v2 is installed"
    DOCKER_COMPOSE_CMD="docker compose"
fi

# Read the content of the file into a variable
content=$(cat ./frontend/Gml.Web.Client/.env)

$DOCKER_COMPOSE_CMD down

docker rmi ghcr.io/gml-launcher/gml.web.skin.service:master
docker rmi ghcr.io/gml-launcher/gml.web.api:master
docker rmi gml-web-frontend-image

rm -Rf ./frontend
git clone --single-branch https://github.com/Gml-Launcher/Gml.Web.Client.git ./frontend/Gml.Web.Client

echo "$content" > frontend/Gml.Web.Client/.env

$DOCKER_COMPOSE_CMD up -d --build