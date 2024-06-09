#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "Данный скрипт нужно запускать от имени root"
    exit 1
fi

# Check for required tools and install if necessary
for tool in git jq curl wget docker docker-compose; do
    if ! command -v $tool >/dev/null; then
        echo "[$tool] $tool not found. Attempting to install..."
        apt-get install -y $tool
        if [ $? -eq 0 ]; then
            echo "[$tool] Installation successful"
        else
            echo "[$tool] Failed to install $tool. Please install it manually."
            exit 1
        fi
    else
        echo "[$tool] Installed"
    fi
done

# Загрузка docker-compose.yml
wget https://raw.githubusercontent.com/GamerVII-NET/Gml.Backend/master/docker-compose-prod.yml -O docker-compose.yml

# Настройка

ip_address=$(curl -s https://ipinfo.io/ip)
if [ $? -ne 0 ]; then
    ip_address=$(hostname -I | awk '{print $1}')
fi

if [ -f .env ]; then
    echo "[Gml] Файл .env существует. Использование локальной конфигурации..."
else
    echo "[Gml] Файл .env не найден. Производится настройка...."

    # Generate SECURITY_KEY
    security_key=$(openssl rand -hex 32)
    
    echo "[Gml] Пожалуйста, введите наименование проекта:"
    read project_name

    echo "[Gml] Пожалуйста, придумайте логин для S3 хранилища Minio:"
    read login_minio

    echo "[Gml] Пожалуйста, придумайте пароль для S3 Minio"
    read password_minio

    echo "[Gml] Введите адрес к панели управления Gml, порт обязателен, если вы не используете проксирование"
    echo "[Gml] Aдрес по умолчанию: (http://$ip_address:5000)"
    read panel_url

    if [ -z "$panel_url" ]; then
        panel_url="http://$ip_address:5000"
    fi

    echo "[Gml] Gml.Web.Api настроена на использование HTTP/S: $panel_url"

    # Set PROJECT_POLICYNAME
    project_policyname=$(echo "$project_name" | tr -d '[:space:]')Policy

    # Создание файла .env и запись в него переменных
    echo "UID=0
GID=0

SECURITY_KEY=$security_key
PROJECT_NAME=$project_name
PROJECT_DESCRIPTION=
PROJECT_POLICYNAME=$project_policyname
PROJECT_PATH=

S3_ENABLED=true

MINIO_ROOT_USER=$login_minio
MINIO_ROOT_PASSWORD=$password_minio

MINIO_ADDRESS=:5009
MINIO_ADDRESS_PORT=5009
MINIO_CONSOLE_ADDRESS=:5010
MINIO_CONSOLE_ADDRESS_PORT=5010
PORT_GML_BACKEND=5000
PORT_GML_FRONTEND=5003
PORT_GML_FILES=5005
PORT_GML_SKINS=5006" > .env

    rm -Rf ./frontend
    git clone https://github.com/Scondic/Gml.Web.Client.git ./frontend/Gml.Web.Client

    # Создание файла .env и запись в него переменных
    echo "NEXT_PUBLIC_BASE_URL=$panel_url
NEXT_PUBLIC_PREFIX_API=api
NEXT_PUBLIC_VERSION_API=v1" > ./frontend/Gml.Web.Client/.env

fi

# Run

docker compose up -d

echo 
echo 
echo "\e[32m==================================================\e[0m"
echo "\e[32mПроект успешно установлен:\e[0m"
echo "\e[32m==================================================\e[0m"
echo "Админпанель: http://$ip_address:5003/"
echo "             *Небходима регистрация"
echo "-------------------------------------------------"
echo "Управление файлами: http://$ip_address:5005/"
echo "                    Логин: admin"
echo "                    Пароль: admin"
echo "-------------------------------------------------"
echo "S3 Minio: http://$ip_address:5010/"
echo "                    Логин: указан в .env"
echo "                    Пароль: указан в .env"
echo "\033[31m=================================================="
echo "* Настоятельно советуем, в целях вашей безопасности, сменить данные для авторизации в панелях управления"
echo "==================================================\033[0m"
