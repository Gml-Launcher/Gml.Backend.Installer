#!/bin/sh

if ! command -v apt-get >/dev/null; then
    echo "This script is only for Debian-based systems"
    exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" 
    exit 1
fi

# Check for git installation
if ! command -v git >/dev/null; then
    echo "[Git] Git not found. Attempting to install..."

    if ! command -v apt-get >/dev/null; then
        apt-get install -y git
    elif ! command -v pacman >/dev/null; then
        pacman -S --noconfirm git
    elif ! command -v dnf >/dev/null; then
        dnf install -y git
    elif ! command -v zypper >/dev/null; then
        zypper install -y git
    else
        echo "[Git] Failed to install Git. Please install it manually."
        exit 1
    fi
    if [ $? -eq 0 ]; then
        echo "[Git] Installation successful"
    else
        echo "[Git] Failed to install Git. Please install it manually."
    fi
else
    echo "[Git] Installed"
fi

# Check for jq installation
if ! command -v jq >/dev/null; then
    echo "[jq] jq not found. Attempting to install..."
    if ! command -v apt-get >/dev/null; then
        apt-get install -y jq
    elif ! command -v pacman >/dev/null; then
        pacman -S --noconfirm jq
    elif ! command -v dnf >/dev/null; then
        dnf install -y jq
    elif ! command -v zypper >/dev/null; then
        zypper install -y jq
    else
        echo "[Git] Failed to install Git. Please install it manually."
        exit 1
    fi
    if [ $? -eq 0 ]; then
        echo "[jq] Installation successful"
    else
        echo "[jq] Failed to install jq. Please install it manually."
    fi
else
    echo "[jq] Installed"
fi

# Check for curl installation
if ! command -v curl >/dev/null; then
    echo "[Curl] Curl not found. Attempting to install..."
    if ! command -v apt-get >/dev/null; then
        apt-get install -y curl
    elif ! command -v pacman >/dev/null; then
        pacman -S --noconfirm curl
    elif ! command -v dnf >/dev/null; then
        dnf install -y curl
    elif ! command -v zypper >/dev/null; then
        zypper install -y curl
    else
        echo "[Git] Failed to install Git. Please install it manually."
        exit 1
    fi
    if [ $? -eq 0 ]; then
        echo "[Curl] Installation successful"
    else
        echo "[Curl] Failed to install Curl. Please install it manually."
    fi
else
    echo "[Curl] Installed"
fi

# Check for wget installation
if ! command -v wget >/dev/null; then
    echo "[Wget] Wget not found. Attempting to install..."
    if ! command -v apt-get >/dev/null; then
        apt-get install -y wget
    elif ! command -v pacman >/dev/null; then
        pacman -S --noconfirm wget
    elif ! command -v dnf >/dev/null; then
        dnf install -y wget
    elif ! command -v zypper >/dev/null; then
        zypper install -y wget
    else
        echo "[Git] Failed to install Git. Please install it manually."
        exit 1
    fi
    if [ $? -eq 0 ]; then
        echo "[Wget] Installation successful"
    else
        echo "[Wget] Failed to install Wget. Please install it manually."
    fi
else
    echo "[Wget] Installed"
fi

# Check for docker.io installation
if ! command -v docker >/dev/null; then
    echo "[Docker] Docker not found. Attempting to install..."
    if ! command -v apt-get >/dev/null; then
        apt-get install -y docker.io
    elif ! command -v pacman >/dev/null; then
        pacman -S --noconfirm docker
    elif ! command -v dnf >/dev/null; then
        dnf install -y docker
    elif ! command -v zypper >/dev/null; then
        zypper install -y docker
    else
        echo "[Docker] Failed to install Docker. Please install it manually."
        exit 1
    fi
    if [ $? -eq 0 ]; then
        echo "[Docker] Installation successful"
    else
        echo "[Docker] Failed to install Docker. Please install it manually."
    fi
else
    echo "[Docker] Installed"
fi

# Check for Docker Compose installation
if ! command -v docker-compose >/dev/null; then
    echo "[Docker-Compose] Docker Compose not found. Attempting to install..."
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p $DOCKER_CONFIG/cli-plugins
    curl -SL https://github.com/docker/compose/releases/download/v2.24.7/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
    chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
    if [ $? -eq 0 ]; then
        echo "[Docker-Compose] Installation successful"
    else
        echo "[Docker-Compose] Failed to install Docker Compose. Please install it manually."
    fi
else
    echo "[Docker-Compose] Installed"
fi

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
PORT_GML_SKINS=5006

SERVICE_TEXTURE_ENDPOINT=http://gml-web-skins:8085" > .env

    rm -Rf ./frontend
    git clone --single-branch https://github.com/Gml-Launcher/Gml.Web.Client.git ./frontend/Gml.Web.Client

    # Создание файла .env и запись в него переменных
    echo "NEXT_PUBLIC_BACKEND_URL=$panel_url/api/v1" > ./frontend/Gml.Web.Client/.env

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
echo "S3 Minio: http://$ip_address:5010/"
echo "                    Логин: указан в .env"
echo "                    Пароль: указан в .env"
echo "\033[31m=================================================="
echo "* Настоятельно советуем, в целях вашей безопасности, сменить данные для авторизации в панелях управления"
echo "==================================================\033[0m"
