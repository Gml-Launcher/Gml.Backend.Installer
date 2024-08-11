#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
    echo "[Gml] Данный скрипт нужно запускать от имени root"
    exit 1
fi


# Check for docker.io installation
if ! command -v docker >/dev/null; then
    echo "[Gml] Docker не установлен, обновление невозможно"
    exit 1
fi

if [ -f .env ]; then
    echo "[Gml] Проверка .env - \e[32mУспешно\e[0m"
else
    echo "[Gml] Файл .env отсутствует"
    exit 1
fi

if [ -f docker-compose.yml ]; then
    echo "[Gml] Проверка docker-compose.yml - \e[32mУспешно\e[0m"
else
    echo "[Gml] Файл docker-compose.yml отсутствует"
    exit 1
fi

if [ -f ./frontend/Gml.Web.Client/.env ]; then
    echo "[Gml] Проверка ./frontend/Gml.Web.Client/.env - \e[32mУспешно\e[0m"
else
    echo "[Gml] Файл ./frontend/Gml.Web.Client/.env отсутствует"
    exit 1
fi

# Read the content of the file into a variable
content=$(cat ./frontend/Gml.Web.Client/.env)

docker compose down

docker rmi ghcr.io/gml-launcher/gml.web.skin.service:master
docker rmi ghcr.io/gml-launcher/gml.web.api:master
docker rmi gml-web-frontend-image

rm -Rf ./frontend
git clone --single-branch https://github.com/Scondic/Gml.Web.Client.git ./frontend/Gml.Web.Client

echo "$content" > frontend/Gml.Web.Client/.env

docker compose up -d
