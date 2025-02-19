#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
    echo "[Gml] Данный скрипт нужно запускать от имени root"
    exit 1
fi

# Check for docker.io installation
if ! command -v docker >/dev/null; then
    echo "[Gml] Docker не установлен, удаление невозможно"
    exit 1
fi

if [ -f docker-compose.yml ]; then
    echo "[Gml] Проверка docker-compose.yml - \e[32mУспешно\e[0m"
else
    echo "[Gml] Файл docker-compose.yml отсутствует"
    exit 1
fi

docker compose down

docker rmi ghcr.io/gml-launcher/gml.web.skin.service:master
docker rmi ghcr.io/gml-launcher/gml.web.api:master
docker rmi gml-web-frontend-image

rm -Rf ./frontend
rm docker-compose.yml
