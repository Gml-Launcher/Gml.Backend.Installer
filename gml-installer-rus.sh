#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
    echo "Этот скрипт должен быть запущен от имени root"
    exit 1
fi

# Проверка установки Git
if ! command -v git >/dev/null; then
    echo "[Git] Git не найден. Пытаюсь установить..."

    if ! command -v apt-get >/dev/null; then
        apt-get install -y git
    elif ! command -v pacman >/dev/null; then
        pacman -S --noconfirm git
    elif ! command -v dnf >/dev/null; then
        dnf install -y git
    elif ! command -v zypper >/dev/null; then
        zypper install -y git
    else
        echo "[Git] Не удалось установить Git. Установите его вручную."
        exit 1
    fi
    if [ $? -eq 0 ]; then
        echo "[Git] Установка успешна"
    else
        echo "[Git] Не удалось установить Git. Установите его вручную."
    fi
else
    echo "[Git] Уже установлен"
fi

# Проверка установки jq
if ! command -v jq >/dev/null; then
    echo "[jq] jq не найден. Пытаюсь установить..."
    if ! command -v apt-get >/dev/null; then
        apt-get install -y jq
    elif ! command -v pacman >/dev/null; then
        pacman -S --noconfirm jq
    elif ! command -v dnf >/dev/null; then
        dnf install -y jq
    elif ! command -v zypper >/dev/null; then
        zypper install -y jq
    else
        echo "[jq] Не удалось установить jq. Установите его вручную."
        exit 1
    fi
    if [ $? -eq 0 ]; then
        echo "[jq] Установка успешна"
    else
        echo "[jq] Не удалось установить jq. Установите его вручную."
    fi
else
    echo "[jq] Уже установлен"
fi

# Проверка установки curl
if ! command -v curl >/dev/null; then
    echo "[Curl] Curl не найден. Пытаюсь установить..."
    if ! command -v apt-get >/dev/null; then
        apt-get install -y curl
    elif ! command -v pacman >/dev/null; then
        pacman -S --noconfirm curl
    elif ! command -v dnf >/dev/null; then
        dnf install -y curl
    elif ! command -v zypper >/dev/null; then
        zypper install -y curl
    else
        echo "[Curl] Не удалось установить Curl. Установите его вручную."
        exit 1
    fi
    if [ $? -eq 0 ]; then
        echo "[Curl] Установка успешна"
    else
        echo "[Curl] Не удалось установить Curl. Установите его вручную."
    fi
else
    echo "[Curl] Уже установлен"
fi

# Проверка установки wget
if ! command -v wget >/dev/null; then
    echo "[Wget] Wget не найден. Пытаюсь установить..."
    if ! command -v apt-get >/dev/null; then
        apt-get install -y wget
    elif ! command -v pacman >/dev/null; then
        pacman -S --noconfirm wget
    elif ! command -v dnf >/dev/null; then
        dnf install -y wget
    elif ! command -v zypper >/dev/null; then
        zypper install -y wget
    else
        echo "[Wget] Не удалось установить Wget. Установите его вручную."
        exit 1
    fi
    if [ $? -eq 0 ]; then
        echo "[Wget] Установка успешна"
    else
        echo "[Wget] Не удалось установить Wget. Установите его вручную."
    fi
else
    echo "[Wget] Уже установлен"
fi

# Проверка установки Docker
if ! command -v docker >/dev/null; then
    echo "[Docker] Docker не найден. Пытаюсь установить..."
    if ! command -v apt-get >/dev/null; then
        apt-get install -y docker.io
    elif ! command -v pacman >/dev/null; then
        pacman -S --noconfirm docker
    elif ! command -v dnf >/dev/null; then
        dnf install -y docker
    elif ! command -v zypper >/dev/null; then
        zypper install -y docker
    else
        echo "[Docker] Не удалось установить Docker. Установите его вручную."
        exit 1
    fi
    if [ $? -eq 0 ]; then
        echo "[Docker] Установка успешна"
    else
        echo "[Docker] Не удалось установить Docker. Установите его вручную."
    fi
else
    echo "[Docker] Уже установлен"
fi

# Проверка установки Docker Compose
if command -v docker-compose >/dev/null; then
    echo "[Docker-Compose] Установлена версия Docker Compose v1"
    DOCKER_COMPOSE_CMD="docker-compose"
elif command -v docker compose >/dev/null; then
    echo "[Docker-Compose] Установлена версия Docker Compose v2"
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo "[Docker-Compose] Docker Compose не найден. Пытаюсь установить..."
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p $DOCKER_CONFIG/cli-plugins
    curl -SL https://github.com/docker/compose/releases/download/v2.24.7/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
    chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
    if [ $? -eq 0 ]; then
        echo "[Docker-Compose] Установка успешна"
        DOCKER_COMPOSE_CMD="docker compose"
    else
        echo "[Docker-Compose] Не удалось установить Docker Compose. Установите его вручную."
    fi
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
    valid_project_name_regex="^[a-zA-Z_][a-zA-Z0-9_]*$"
    
    echo "[Gml] Пожалуйста, введите наименование проекта:"
    while true; do
        read project_name
        if echo "$project_name" | grep -Eq "$valid_project_name_regex"; then
            break
        else
            echo "[Gml] Ошибка: Имя проекта должно начинаться с буквы или символа '_', и содержать только буквы, цифры или '_'. Пожалуйста, попробуйте еще раз:"
        fi
    done

    echo "[Gml] Корректное имя проекта получено: $project_name"


    echo "[Gml] Введите адрес к панели управления Gml, порт обязателен, если вы не используете проксирование"
    echo "[Gml] Aдрес по умолчанию: (http://$ip_address:5000), нажмите ENTER, чтобы установить его"
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

S3_ENABLED=false

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

$DOCKER_COMPOSE_CMD up -d --build

echo 
echo 
echo "\e[32m==================================================\e[0m"
echo "\e[32mПроект успешно установлен:\e[0m"
echo "\e[32m==================================================\e[0m"
echo "Админпанель: http://$ip_address:5003/"
echo "             *Небходима регистрация"
echo "\033[31m=================================================="
echo "* Настоятельно советуем, в целях вашей безопасности, сменить данные для авторизации в панелях управления"
echo "==================================================\033[0m"
