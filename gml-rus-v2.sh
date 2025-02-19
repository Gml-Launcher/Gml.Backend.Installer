#!/bin/bash

# Проверям докер в системе
check_docker_status() {
    if [ -x "$(command -v docker)" ]; then
        return 1
    else
        return 0
    fi
}

# Проверям докер-компоуз в системе
check_docker_compose_status() {
    if [ -x "$(command -v docker-compose)" ]; then
        return 1
    else
        return 0
    fi
    if [ -x "$(command -v docker compose)" ]; then
        return 2
    else
        return 0
    fi
}

# Проверям наличие файла .env
check_env_file() {
    if [ -f .env ]; then
        return 1
    else
        return 0
    fi
}

# Проверям наличие файла docker-compose.yml
check_docker_compose_file() {
    if [ -f docker-compose.yml ]; then
        return 1
    else
        return 0
    fi
}

# Проверяем пакетный менеджер
check_system() {
    if [ -x "$(command -v apt-get)" ]; then
        return 1
    elif [ -x "$(command -v pacman)" ]; then
        return 2
    elif [ -x "$(command -v dnf)" ]; then
        return 3
    elif [ -x "$(command -v zypper)" ]; then
        return 4
    else
        echo "Неизвестный пакетный менеджер"
        # выводим информацию о системе
        cat /etc/os-release
        # просим передать информацию о системе в issue
        echo "Пожалуйста, передайте информацию о системе в issue"
        echo "https://github.com/Gml-Launcher/Gml.Backend.Installer/issues"
        # завершаем работу скрипта
        exit 1
        return 0
    fi
}

# Проверяем наличие установленного docker и docker-compose
check_docker_status
docker_status=$?
check_docker_compose_status
compose_status=$?

if [ $docker_status -eq 1 ] && ([ $compose_status -eq 1 ] || [ $compose_status -eq 2 ]); then
    echo "Все необходимые программы установлены"
    echo "Проверка системы"
else
    echo "Не все необходимые программы установлены"
fi

# проверяем пакетный менеджер
check_system
package_manager=$?

# проверяем на наличие установленного curl
if [ -x "$(command -v curl)" ]; then
    echo "Curl установлен"
else
    echo "Curl не установлен, производим установку"
    if [ $package_manager -eq 1 ]; then
        apt-get install -y curl
    elif [ $package_manager -eq 2 ]; then
        pacman -S --noconfirm curl
    elif [ $package_manager -eq 3 ]; then
        dnf install -y curl
    elif [ $package_manager -eq 4 ]; then
        zypper install -y curl
    else
        echo "[Curl] Произошла ошибка при установке Curl"
    fi
fi

# проверяем на наличие установленного wget
if [ -x "$(command -v wget)" ]; then
    echo "Wget установлен"
else
    echo "Wget не установлен, производим установку"
    if [ $package_manager -eq 1 ]; then
        apt-get install -y wget
    elif [ $package_manager -eq 2 ]; then
        pacman -S --noconfirm wget
    elif [ $package_manager -eq 3 ]; then
        dnf install -y wget
    elif [ $package_manager -eq 4 ]; then
        zypper install -y wget
    else
        echo "[Wget] Произошла ошибка при установке Wget"
    fi
fi

# проверяем на наличие установленного git
if [ -x "$(command -v git)" ]; then
    echo "Git установлен"
else
    echo "Git не установлен, производим установку"
    if [ $package_manager -eq 1 ]; then
        apt-get install -y git
    elif [ $package_manager -eq 2 ]; then
        pacman -S --noconfirm git
    elif [ $package_manager -eq 3 ]; then
        dnf install -y git
    elif [ $package_manager -eq 4 ]; then
        zypper install -y git
    else
        echo "[Git] Произошла ошибка при установке Git"
    fi
fi

# проверяем на наличие установленного jq
if [ -x "$(command -v jq)" ]; then
    echo "jq установлен"
else
    echo "jq не установлен, производим установку"
    if [ $package_manager -eq 1 ]; then
        apt-get install -y jq
    elif [ $package_manager -eq 2 ]; then
        pacman -S --noconfirm jq
    elif [ $package_manager -eq 3 ]; then
        dnf install -y jq
    elif [ $package_manager -eq 4 ]; then
        zypper install -y jq
    else
        echo "[JD] Произошла ошибка при установке jq"
    fi
fi

# проверяем на наличие установленного docker
if [ $docker_status -eq 1 ]; then
    echo "Docker установлен"
else
    echo "Docker не установлен, производим установку"
    if [ $package_manager -eq 1 ]; then
        apt-get install -y docker.io
    elif [ $package_manager -eq 2 ]; then
        pacman -S --noconfirm docker
    elif [ $package_manager -eq 3 ]; then
        dnf install -y docker
    elif [ $package_manager -eq 4 ]; then
        zypper install -y docker
    else
        echo "[Docker] Произошла ошибка при установке Docker"
    fi
fi

# проверяем на наличие установленного docker-compose
if [ $compose_status -eq 1 ]; then
    echo "Docker Compose v1 установлен"
elif [ $compose_status -eq 2 ]; then
    echo "Docker Compose v2 установлен"
else
    echo "Docker Compose v2 не установлен, производим установку"
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p $DOCKER_CONFIG/cli-plugins
    curl -SL https://github.com/docker/compose/releases/download/v2.24.7/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
    chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
    if [ $? -eq 0 ]; then
        echo "[Docker-Compose] установка прошла успешно"
    else
        echo "[Docker-Compose] Произошла ошибка при установке Docker Compose"
    fi
fi

# проверяем на наличие файла .env
check_env_file
env_status=$?
# проверяем на наличие файла docker-compose.yml
check_docker_compose_file
docker_status=$?

if [ $docker_status -eq 1 ] && [ $env_status -eq 0 ]; then
    echo "Все необходимые файлы существуют"
else
    echo "Не все необходимые файлы существуют"
fi

# скачиваем файл docker-compose.yml
if [ $docker_status -eq 0 ]; then
    echo "Скачиваем файл docker-compose.yml"
    wget https://raw.githubusercontent.com/GamerVII-NET/Gml.Backend/master/docker-compose-prod.yml -O docker-compose.yml
    if [ $? -eq 0 ]; then
        echo "Файл docker-compose.yml успешно скачан"
    else
        echo "Произошла ошибка при скачивании файла docker-compose.yml"
    fi
fi

# Создаем файл .env
if [ -f .env ]; then
        echo "[Gml] Файл .env существует. Использование локальной конфигурации..."
else
    ip_address=$(curl -s https://ipinfo.io/ip)
    if [ $? -ne 0 ]; then
        ip_address=$(hostname -I | awk '{print $1}')
    fi

    echo "[Gml] Файл .env отсутствует. Создание..."
    # Генерация SECURITY_KEY
    security_key=$(openssl rand -hex 32)
    echo "[Gml] Пожалуйста, введите наименование проекта:"
    read project_name
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

S3_ENABLED=false

PORT_GML_BACKEND=5000
PORT_GML_FRONTEND=5003
PORT_GML_FILES=5005
PORT_GML_SKINS=5006

SERVICE_TEXTURE_ENDPOINT=http://gml-web-skins:8085" > .env
fi

# Запускаем создание файла env и docker-compose.yml
if [ $env_status -eq 1 ]; then
    echo "Начинаем сборку проекта"

    # Проверяем на наличие папки frontend
    if [ -d ./frontend ]; then
        echo "[Gml] Папка frontend существует"
    else
        echo "[Gml] Папка frontend отсутствует. Создание..."
        git clone --single-branch https://github.com/Gml-Launcher/Gml.Web.Client.git ./frontend/Gml.Web.Client
    fi
    
    # Записаваем какую команду использовать
    if [ $compose_status -eq 1 ]; then
        DOCKER_COMPOSE_CMD="docker-compose"
    elif [ $compose_status -eq 2 ]; then
        DOCKER_COMPOSE_CMD="docker compose"
    fi

    # Запускаем сборку docker-compose.yml
    echo $DOCKER_COMPOSE_CMD up -d --build
    $DOCKER_COMPOSE_CMD up -d --build
fi

# Выводим информацию о завершении установки
echo
echo
echo "\e[32m==================================================\e[0m"
echo "\e[32mПроект успешно установлен:\e[0m"
echo "\e[32m==================================================\e[0m"
echo "Админпанель: http://$ip_address:5003/ (*Небходима регистрация)"
echo "\033[31m=================================================="
echo "* Настоятельно советуем, в целях вашей безопасности, сменить данные для авторизации в панелях управления"
echo "==================================================\033[0m"