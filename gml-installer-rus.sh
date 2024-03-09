#!/bin/sh

if [ "$(id -u)" -ne 0 ]
then
  echo "Необходимо запустить скрипт под root пользователем"
  exit 1
fi


#!/bin/bash

# Проверка установки git
if ! command -v git > /dev/null
then
    echo "[Git] Git не найден. Попытка установить..."
    apt-get install -y git
    if [ $? -eq 0 ]
    then
        echo "[Git] Успешно установлен"
    else
        echo "[Git] Не удалось установить Git. Пожалуйста, установите его вручную."
        exit 1
    fi
else
    echo "[Git] Установлен"
fi

# Проверка установки jq
if ! command -v jq > /dev/null
then
    echo "[jq] jq не найден. Попытка установить..."
    apt-get install -y jq
    if [ $? -eq 0 ]
    then
        echo "[jq] Успешно установлен"
    else
        echo "[jq] Не удалось установить jq. Пожалуйста, установите его вручную."
        exit 1
    fi
else
    echo "[jq] Установлен"
fi

# Проверка установки curl
if ! command -v curl > /dev/null
then
    echo "[Curl] Curl не найден. Попытка установить..."
    apt-get install -y curl
    if [ $? -eq 0 ]
    then
        echo "[Curl] Успешно установлен"
    else
        echo "[Curl] Не удалось установить Curl. Пожалуйста, установите его вручную."
        exit 1
    fi
else
    echo "[Curl] Установлен"
fi

# Проверка установки wget
if ! command -v wget > /dev/null
then
    echo "[Wget] Wget не найден. Попытка установить..."
    apt-get install -y wget
    if [ $? -eq 0 ]
    then
        echo "[Wget] Успешно установлен"
    else
        echo "[Wget] Не удалось установить Wget. Пожалуйста, установите его вручную."
        exit 1
    fi
else
    echo "[Wget] Установлен"
fi

# Проверка установки docker.io
if ! command -v docker > /dev/null
then
    echo "[Docker] Docker не найден. Попытка установить..."
    apt-get install -y docker.io
    if [ $? -eq 0 ]
    then
        echo "[Docker] Успешно установлен"
    else
        echo "[Docker] Не удалось установить Docker. Пожалуйста, установите его вручную."
        exit 1
    fi
else
    echo "[Docker] Установлен"
fi

# Проверка и установка Docker Compose
if ! command -v docker-compose > /dev/null
then
    echo "[Docker-Compose] Docker Compose не найден. Попытка установить..."
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p $DOCKER_CONFIG/cli-plugins
    curl -SL https://github.com/docker/compose/releases/download/v2.24.7/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
    chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
    if [ $? -eq 0 ]
    then
        echo "[Docker-Compose] Успешно установлен"
    else
        echo "[Docker-Compose] Не удалось установить Docker Compose. Пожалуйста, установите его вручную."
        exit 1
    fi
else
    echo "[Docker-Compose] Установлен"
fi

# Запрос ProjectName от пользователя
while :
do
    printf "Название проекта: "
    read ProjectName
    if [ -z "$ProjectName" ]
    then
        echo "[Ошибка] Значение не может быть пустым. Пожалуйста, попробуйте снова."
    else
        break
    fi
done

# Запрос ProjectDescription от пользователя
echo "Описание проекта: (нажмите Enter, чтобы использовать Игровой проект $ProjectName):"
read ProjectDescription

# Генерация SecretKey
SecretKey=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 ; echo '')

# Запрос ProjectVersion от пользователя
echo "Введите ProjectVersion (нажмите Enter, чтобы использовать 1.1.0):"
read ProjectVersion
ProjectVersion="${ProjectVersion:-1.1.0}"

# Клонирование репозитория
echo "Клонирую репозиторий..."
git clone --recursive https://github.com/GamerVII-NET/Gml.Backend.git "$ProjectName"
if [ $? -eq 0 ]
then
    echo "Репозиторий успешно клонирован"
else
    echo "[Ошибка] Не удалось клонировать репозиторий. Пожалуйста, проверьте ваше соединение с интернетом и доступность репозитория. Так же, убедитесь, что в текущей директории нет папки $ProjectName"
    exit 1
fi

# Получение внешнего IP-адреса
EXTERNAL_IP=$(curl -s ifconfig.me)

# Переход к директории проекта и создание .env файла
cd "$ProjectName"/src/Gml.Web.Client

# Создание .env файла
if [ ! -f .env ]; then
    echo "NEXT_PUBLIC_BASE_URL=http://$EXTERNAL_IP:5000" > .env
    echo "NEXT_PUBLIC_PREFIX_API=api" >> .env
    echo "NEXT_PUBLIC_VERSION_API=v1" >> .env
fi

# Переход к папке $ProjectName/src/Gml.Web.Api/src/Gml.Web.Api
cd "../../src/Gml.Web.Api/src/Gml.Web.Api/"

# Удаление appsettings.Development.json
rm -f appsettings.Development.json

# Редактирование appsettings.json
if [ -f appsettings.json ]; then
    
    jq ".ServerSettings.ProjectName = \"$ProjectName\" |
    .ServerSettings.ProjectDescription = \"$ProjectDescription\" |
    .ServerSettings.SecretKey = \"$SecretKey\" |
    .ServerSettings.PolicyName = \"${ProjectName}Policy\" |
    .ConnectionStrings.SQLite = \"Data Source=data.db\"" appsettings.json > temp.json && mv temp.json appsettings.json
fi

docker compose up -d

echo ==================================================
echo "\e[32mПроект успешно установлен:\e[0m"
echo "Админпанель: http://$EXTERNAL_IP:5003/"
echo "             *Небходима регистрация"
echo "Управление файлами: http://$EXTERNAL_IP:5005/"
echo "                    Логин: admin"
echo "                    Пароль: admin"
echo ==================================================
