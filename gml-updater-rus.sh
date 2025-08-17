#!/bin/sh

# Проверка запуска от root
if [ "$(id -u)" -ne 0 ]; then
    echo "[Gml] Данный скрипт нужно запускать от имени root"
    exit 1
fi

# Проверка установки Docker
if ! command -v docker >/dev/null; then
    echo "[Gml] Docker не установлен, обновление невозможно"
    exit 1
fi

# Проверка файлов
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

# Определение команды Docker Compose
if command -v docker-compose >/dev/null; then
    echo "[Docker-Compose] Docker Compose v1 is installed"
    DOCKER_COMPOSE_CMD="docker-compose"
elif command -v docker compose >/dev/null; then
    echo "[Docker-Compose] Docker Compose v2 is installed"
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo "[Docker-Compose] Docker Compose не найден"
    exit 1
fi

# Добавление MARKET_ENDPOINT в корневой .env
if ! grep -q "^MARKET_ENDPOINT=" .env 2>/dev/null; then
    echo "MARKET_ENDPOINT=https://gml-market.recloud.tech" >> .env
    echo "[Gml] Добавлена строка MARKET_ENDPOINT в .env"
fi


# Остановка и удаление контейнеров
$DOCKER_COMPOSE_CMD down

# Удаление старых образов
docker rmi ghcr.io/gml-launcher/gml.web.skin.service:master
docker rmi ghcr.io/gml-launcher/gml.web.api:master
docker rmi gml-web-frontend-image

# Read the content of the file into a variable
content=$(cat ./frontend/Gml.Web.Client/.env)

# Обновление фронтенда
rm -Rf ./frontend
git clone --single-branch https://github.com/Gml-Launcher/Gml.Web.Client.git ./frontend/Gml.Web.Client

# Восстановление .env
echo "$content" > frontend/Gml.Web.Client/.env


# Добавление NEXT_PUBLIC_MARKETPLACE_URL в frontend/Gml.Web.Client/.env
if ! grep -q "^NEXT_PUBLIC_MARKETPLACE_URL=" ./frontend/Gml.Web.Client/.env 2>/dev/null; then
    echo "NEXT_PUBLIC_MARKETPLACE_URL=https://gml-market.recloud.tech
SWAGGER_ENABLED=true" >> ./frontend/Gml.Web.Client/.env
    echo "[Gml] Добавлена строка NEXT_PUBLIC_MARKETPLACE_URL в .env"
fi

# Запуск контейнеров
$DOCKER_COMPOSE_CMD up -d --build
