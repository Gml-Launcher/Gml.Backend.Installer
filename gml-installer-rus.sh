#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" 
    exit 1
fi

# Функция для отображения спиннера
show_spinner() {
    local pid=$1
    local text=$2
    local spinstr='/-\|'
    
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf "\r%s %c" "$text" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep 0.1
    done
    
    wait $pid
    local result=$?
    
    if [ $result -eq 0 ]; then
        printf "\r%s \033[32m✓\033[0m\n" "$text"
    else
        printf "\r%s \033[31m✗\033[0m\n" "$text"
    fi
    
    return $result
}

# Общее количество шагов установки
TOTAL_STEPS=8
CURRENT_STEP=0
PROGRESS_WIDTH=30

echo "[System] Начало установки GML..."
echo "[System] Подготовка системы..."

# Отключение интерактивных запросов на перезапуск сервисов
if [ -f /etc/needrestart/needrestart.conf ]; then
    sed -i "s/#\$nrconf{restart} = 'i';/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf
fi

# Для Debian/Ubuntu также создаем конфигурацию для apt
if command -v apt-get >/dev/null; then
    mkdir -p /etc/apt/apt.conf.d/
    echo '
DPkg::Options {
   "--force-confdef";
   "--force-confold";
}
' > /etc/apt/apt.conf.d/local
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# Определение типа системы
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
    echo "[System] Обнаружена система: $OS $VER"
fi

# Функция установки пакета
install_package() {
    package=$1
    (
        if command -v apt-get >/dev/null; then
            apt-get update >/dev/null 2>&1 && apt-get install -y "$package" >/dev/null 2>&1
        elif command -v dnf >/dev/null; then
            dnf install -y "$package" >/dev/null 2>&1
        elif command -v yum >/dev/null; then
            yum install -y "$package" >/dev/null 2>&1
        elif command -v zypper >/dev/null; then
            zypper install -y "$package" >/dev/null 2>&1
        elif command -v pacman >/dev/null; then
            pacman -Sy --noconfirm "$package" >/dev/null 2>&1
        else
            return 1
        fi
    ) &
    
    show_spinner $! "[System] Установка $package"
    return $?
}

# Установка базовых зависимостей
echo "[System] Установка базовых зависимостей..."

# Установка Git
if ! command -v git >/dev/null; then
    install_package git || {
        echo "[Git] Ошибка установки Git"
        exit 1
    }
else
    printf "[System] Установка git \033[32m✓\033[0m\n"
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# Установка jq
if ! command -v jq >/dev/null; then
    install_package jq || {
        echo "[jq] Ошибка установки jq"
        exit 1
    }
else
    printf "[System] Установка jq \033[32m✓\033[0m\n"
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# Установка curl
if ! command -v curl >/dev/null; then
    install_package curl || {
        echo "[Curl] Ошибка установки Curl"
        exit 1
    }
else
    printf "[System] Установка curl \033[32m✓\033[0m\n"
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# Установка wget
if ! command -v wget >/dev/null; then
    install_package wget || {
        echo "[Wget] Ошибка установки Wget"
        exit 1
    }
else
    printf "[System] Установка wget \033[32m✓\033[0m\n"
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# Установка Docker
install_docker() {
    (
        if command -v apt-get >/dev/null; then
            # Debian/Ubuntu
            apt-get update >/dev/null 2>&1
            apt-get install -y docker.io >/dev/null 2>&1
        elif command -v dnf >/dev/null; then
            # Fedora
            dnf install -y docker >/dev/null 2>&1
        elif command -v yum >/dev/null; then
            # CentOS/RHEL
            yum install -y docker >/dev/null 2>&1
        elif command -v zypper >/dev/null; then
            # OpenSUSE
            zypper install -y docker >/dev/null 2>&1
        elif command -v pacman >/dev/null; then
            # Arch Linux
            pacman -Sy --noconfirm docker >/dev/null 2>&1
        else
            return 1
        fi

        # Запуск и включение Docker
        systemctl start docker >/dev/null 2>&1
        systemctl enable docker >/dev/null 2>&1
    ) &
    
    show_spinner $! "[System] Установка docker"
    return $?
}

# Установка Docker если не установлен
if ! command -v docker >/dev/null; then
    install_docker || {
        echo "[Docker] Ошибка установки Docker"
        exit 1
    }
else
    printf "[System] Установка docker \033[32m✓\033[0m\n"
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# Установка Docker Compose
if ! command -v docker-compose >/dev/null && ! command -v "docker compose" >/dev/null; then
    (
        DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
        mkdir -p $DOCKER_CONFIG/cli-plugins >/dev/null 2>&1
        curl -SL "https://github.com/docker/compose/releases/download/v2.24.7/docker-compose-$(uname -s)-$(uname -m)" -o $DOCKER_CONFIG/cli-plugins/docker-compose >/dev/null 2>&1
        chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose >/dev/null 2>&1
    ) &
    
    show_spinner $! "[System] Установка docker-compose"
    if [ $? -eq 0 ]; then
        DOCKER_COMPOSE_CMD="docker compose"
    else
        echo "[System] Ошибка установки Docker Compose"
        exit 1
    fi
else
    if command -v docker-compose >/dev/null; then
        printf "[System] Установка docker-compose \033[32m✓\033[0m\n"
        DOCKER_COMPOSE_CMD="docker-compose"
    else
        printf "[System] Установка docker-compose \033[32m✓\033[0m\n"
        DOCKER_COMPOSE_CMD="docker compose"
    fi
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# Загрузка docker-compose.yml
(wget https://raw.githubusercontent.com/GamerVII-NET/Gml.Backend/master/docker-compose-prod.yml -O docker-compose.yml >/dev/null 2>&1) &
show_spinner $! "[System] Загрузка конфигурации"

CURRENT_STEP=$((CURRENT_STEP + 1))

# Настройка
ip_address=$(curl -s https://ipinfo.io/ip)
if [ $? -ne 0 ]; then
    ip_address=$(hostname -I | awk '{print $1}')
fi

if [ -f .env ]; then
    echo "[GML] Файл .env существует. Использование локальной конфигурации..."
else
    echo "[GML] Файл .env не найден. Производится настройка...."

    # Generate SECURITY_KEY
    security_key=$(openssl rand -hex 32)
    valid_project_name_regex="^[a-zA-Z_][a-zA-Z0-9_]*$"
    
    echo "[GML] Введите наименование проекта:"
    while true; do
        read project_name
        if echo "$project_name" | grep -Eq "$valid_project_name_regex"; then
            break
        else
            echo "[GML] Ошибка: Имя проекта должно начинаться с буквы или символа '_', и содержать только буквы, цифры или '_'"
            echo "[GML] Попробуйте еще раз:"
        fi
    done

    echo "[GML] Введите адрес к панели управления Gml, порт обязателен, если вы не используете проксирование"
    echo "[GML] Aдрес по умолчанию: (http://$ip_address:5000), нажмите ENTER, чтобы установить его"
    read panel_url

    if [ -z "$panel_url" ]; then
        panel_url="http://$ip_address:5000"
    fi

    echo "[GML] Адрес панели: $panel_url"

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

SERVICE_TEXTURE_ENDPOINT=http://gml-web-skins:8085
MARKET_ENDPOINT=https://gml-market.recloud.tech" > .env

    rm -Rf ./frontend
    (git clone --single-branch https://github.com/Gml-Launcher/Gml.Web.Client.git ./frontend/Gml.Web.Client >/dev/null 2>&1) &
    show_spinner $! "[GML] Клонирование frontend"

    # Создание файла .env и запись в него переменных
    echo "NEXT_PUBLIC_BACKEND_URL=$panel_url/api/v1
NEXT_PUBLIC_MARKETPLACE_URL=https://gml-market.recloud.tech" > ./frontend/Gml.Web.Client/.env
fi

# Run
(
    $DOCKER_COMPOSE_CMD up -d --build > docker-build.log 2>&1
) &

show_spinner $! "[GML] Сборка контейнеров, ожидайте..."
BUILD_SUCCESS=$?

if [ $BUILD_SUCCESS -ne 0 ]; then
    echo "[GML] Ошибка при сборке контейнеров"
    echo "[GML] Лог ошибки:"
    echo "----------------------------------------"
    cat docker-build.log
    echo "----------------------------------------"
    rm -f docker-build.log
    exit 1
fi

rm -f docker-build.log

echo
echo
printf "\033[32m==================================================\033[0m\n"
printf "\033[32mПроект успешно установлен:\033[0m\n"
printf "\033[32m==================================================\033[0m\n"
echo "Админпанель: http://$ip_address:5003/"
echo "             *Необходима регистрация"
printf "\033[31m==================================================\n"
echo "* Настоятельно советуем, в целях вашей безопасности, сменить данные для авторизации в панелях управления"
printf "==================================================\033[0m\n"