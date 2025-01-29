#!/bin/bash

# Проверям докер в системе
check_docker_status() {
    if [ -x "$(command -v docker)" ]; then
        echo "Docker установлен"
    else
        echo "Docker не установлен"
        return 1
    fi
}

# Проверям докер-компоуз в системе
check_docker_compose_status() {
    if [ -x "$(command -v docker-compose)" ]; then
        echo "Docker-compose установлен"
        return 1
    else
        echo "Docker-compose не установлен"
    elif [ -x "$(command -v docker compose)" ]; then
        echo "Docker compose v2 установлен"
    else
        echo "Docker compose v2 не установлен"
        return 1
    fi
}

# Проверям наличие файла .env
check_env_file() {
    if [ -f .env ]; then
        echo "Файл .env существует"
    else
        echo "Файл .env не существует"
        return 1
    fi
}

# Проверям наличие файла docker-compose.yml
check_docker_compose_file() {
    if [ -f docker-compose.yml ]; then
        echo "Файл docker-compose.yml существует"
    else
        echo "Файл docker-compose.yml не существует"
        return 1
    fi
}

# Проверяем систему какая версия и какой дистрибутив
check_system() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "Дистрибутив: $NAME"
        echo "Версия: $VERSION"
    else
        echo "Не удалось определить дистрибутив"
        return 1
    fi
}

# Проверяем наличие установленного docker и docker-compose
check_docker_status
check_docker_compose_status
# проверяем на наличие файла .env
check_env_file
# проверяем на наличие файла docker-compose.yml
check_docker_compose_file