#!/bin/sh

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "[Gml] This script must be run as root"
    exit 1
fi

# Check Docker installation
if ! command -v docker >/dev/null; then
    echo "[Gml] Docker is not installed, update is impossible"
    exit 1
fi

# Check files
if [ -f .env ]; then
    echo "[Gml] Checking .env - \e[32mSuccess\e[0m"
else
    echo "[Gml] .env file is missing"
    exit 1
fi

if [ -f docker-compose.yml ]; then
    echo "[Gml] Checking docker-compose.yml - \e[32mSuccess\e[0m"
else
    echo "[Gml] docker-compose.yml file is missing"
    exit 1
fi

if [ -f ./frontend/Gml.Web.Client/.env ]; then
    echo "[Gml] Checking ./frontend/Gml.Web.Client/.env - \e[32mSuccess\e[0m"
else
    echo "[Gml] ./frontend/Gml.Web.Client/.env file is missing"
    exit 1
fi

# Determine Docker Compose command
if command -v docker-compose >/dev/null; then
    echo "[Docker-Compose] Docker Compose v1 is installed"
    DOCKER_COMPOSE_CMD="docker-compose"
elif command -v docker compose >/dev/null; then
    echo "[Docker-Compose] Docker Compose v2 is installed"
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo "[Docker-Compose] Docker Compose not found"
    exit 1
fi

# Add MARKET_ENDPOINT to root .env
if ! grep -q "^MARKET_ENDPOINT=" .env 2>/dev/null; then
    echo "MARKET_ENDPOINT=https://gml-market.recloud.tech" >> .env
    echo "[Gml] Added MARKET_ENDPOINT line to .env"
fi

# Stop and remove containers
$DOCKER_COMPOSE_CMD down

# Remove old images
docker rmi ghcr.io/gml-launcher/gml.web.skin.service:master
docker rmi ghcr.io/gml-launcher/gml.web.api:master
docker rmi gml-web-frontend-image

# Read the content of the file into a variable
content=$(cat ./frontend/Gml.Web.Client/.env)

# Update frontend
rm -Rf ./frontend
git clone --single-branch https://github.com/Gml-Launcher/Gml.Web.Client.git ./frontend/Gml.Web.Client

# Restore .env
echo "$content" > frontend/Gml.Web.Client/.env

# Add NEXT_PUBLIC_MARKETPLACE_URL to frontend/Gml.Web.Client/.env
if ! grep -q "^NEXT_PUBLIC_MARKETPLACE_URL=" ./frontend/Gml.Web.Client/.env 2>/dev/null; then
    echo "NEXT_PUBLIC_MARKETPLACE_URL=https://gml-market.recloud.tech
SWAGGER_ENABLED=true" >> ./frontend/Gml.Web.Client/.env
    echo "[Gml] Added NEXT_PUBLIC_MARKETPLACE_URL line to .env"
fi

# Start containers
$DOCKER_COMPOSE_CMD up -d --build
