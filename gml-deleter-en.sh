#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
    echo "[Gml] This script must be run as root"
    exit 1
fi

# Check for docker.io installation
if ! command -v docker >/dev/null; then
    echo "[Gml] Docker is not installed, removal is not possible"
    exit 1
fi

if [ -f docker-compose.yml ]; then
    echo "[Gml] Checking docker-compose.yml - \e[32mSuccessful\e[0m"
else
    echo "[Gml] docker-compose.yml file is missing"
    exit 1
fi

docker compose down

docker rmi ghcr.io/gml-launcher/gml.web.skin.service:master
docker rmi ghcr.io/gml-launcher/gml.web.api:master
docker rmi gml-web-frontend-image

rm -Rf ./frontend
rm docker-compose.yml