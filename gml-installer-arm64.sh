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

# Функция для проверки корректности URL
validate_url() {
    local url=$1
    # Проверяем basic URL pattern: http(s)://domain(:port)(/path)
    if echo "$url" | grep -Eq '^https?://[a-zA-Z0-9.-]+(:[0-9]+)?(/[a-zA-Z0-9._-]*)*$'; then
        return 0
    else
        return 1
    fi
}

# Функция для извлечения порта из URL
get_port_from_url() {
    local url=$1
    local default_port=$2
    echo "$url" | grep -oE ':[0-9]+' | cut -d: -f2 | head -1
}

# Функция для извлечения host из URL
get_host_from_url() {
    local url=$1
    echo "$url" | sed -E 's|^https?://||' | cut -d/ -f1 | cut -d: -f1
}

echo "[System] Начало установки GML..."
echo "[System] Проверка архитектуры..."

# Определяем архитектуру
ARCH=$(uname -m)
echo "[System] Архитектура системы: $ARCH"

# Определяем текущую директорию (где запущен скрипт)
SCRIPT_DIR=$(pwd)
SCRIPT_NAME=$(basename "$0")
echo "[System] Скрипт запущен из: $SCRIPT_DIR"

# Запрос папки для установки
echo "[GML] Введите имя папки для установки GML Backend:"
echo "[GML] Или нажмите ENTER для использования папки 'gml-backend':"
read -r install_folder

if [ -z "$install_folder" ]; then
    install_folder="gml-backend"
fi

# Проверяем, что имя папки корректное
if ! echo "$install_folder" | grep -Eq '^[a-zA-Z0-9_.-]+$'; then
    echo "[GML] Ошибка: Имя папки может содержать только буквы, цифры, точки, дефисы и подчеркивания"
    exit 1
fi

# Полный путь к папке установки
if echo "$install_folder" | grep -q '^/'; then
    # Абсолютный путь
    INSTALL_DIR="$install_folder"
else
    # Относительный путь
    INSTALL_DIR="$SCRIPT_DIR/$install_folder"
fi

echo "[GML] Установка будет выполнена в: $INSTALL_DIR"

# Проверяем существование папки
if [ -d "$INSTALL_DIR" ]; then
    echo "[GML] Папка '$INSTALL_DIR' уже существует."
    echo "[GML] Выберите действие:"
    echo "1) Использовать существующую папку (данные могут быть перезаписаны)"
    echo "2) Создать новую папку с другим именем"
    echo "3) Прервать установку"
    echo "Введите 1, 2 или 3 (по умолчанию 3):"
    read -r folder_choice
    
    case "$folder_choice" in
        1)
            echo "[GML] Используем существующую папку"
            ;;
        2)
            echo "[GML] Введите новое имя папки:"
            read -r new_folder
            if [ -z "$new_folder" ]; then
                new_folder="gml-backend-$(date +%Y%m%d%H%M%S)"
            fi
            
            if echo "$new_folder" | grep -q '^/'; then
                INSTALL_DIR="$new_folder"
            else
                INSTALL_DIR="$SCRIPT_DIR/$new_folder"
            fi
            
            mkdir -p "$INSTALL_DIR"
            echo "[GML] Создана новая папка: $INSTALL_DIR"
            ;;
        *)
            echo "[GML] Установка прервана."
            exit 1
            ;;
    esac
else
    # Создаем папку
    mkdir -p "$INSTALL_DIR"
    echo "[GML] Создана папка для установки: $INSTALL_DIR"
fi

# Переходим в папку установки
cd "$INSTALL_DIR" || {
    echo "[GML] Ошибка перехода в папку $INSTALL_DIR"
    exit 1
}

# Автоматическое определение IP
ip_address=$(curl -s https://ipinfo.io/ip || hostname -I | awk '{print $1}')
echo "[System] Автоматически определен IP: $ip_address"

# Запрос URL панели управления с гибкостью ввода
echo "[GML] Введите полный URL панели управления GML:"
echo "[GML] Примеры:"
echo "  - http://$ip_address:5000 (по умолчанию - нажмите ENTER)"
echo "  - http://192.168.1.100:5000"
echo "  - https://example.com"
echo "  - https://panel.mydomain.com:8080"
echo "Введите URL или нажмите ENTER для использования http://$ip_address:5000:"
read -r panel_url

if [ -z "$panel_url" ]; then
    panel_url="http://$ip_address:5000"
else
    # Проверяем корректность введенного URL
    while ! validate_url "$panel_url"; do
        echo "[GML] Ошибка: Некорректный URL. Примеры правильного формата:"
        echo "  - http://192.168.1.100:5000"
        echo "  - https://example.com" 
        echo "  - http://mydomain.com:8080"
        echo "Пожалуйста, введите корректный URL:"
        read -r panel_url
    done
fi

# Извлекаем хост и порт из URL
panel_host=$(get_host_from_url "$panel_url")
panel_port=$(get_port_from_url "$panel_url")

# Если порт не указан в URL, используем стандартные
if [ -z "$panel_port" ]; then
    if echo "$panel_url" | grep -q "^https"; then
        panel_port=443
    else
        panel_port=5000
    fi
    # Обновляем URL с портом
    if echo "$panel_url" | grep -q ":${panel_port}"; then
        # Порт уже есть в URL
        :
    else
        panel_url=$(echo "$panel_url" | sed "s|://|://${panel_host}:${panel_port}|")
    fi
fi

echo "[GML] Будет использован адрес: $panel_url"
echo "[GML] Хост: $panel_host, Порт: $panel_port"

# Выбор ветки для установки
echo "[GML] Выберите версию для установки:"
echo "1) Стабильная версия (master branch)"
echo "2) Версия для разработки (develop branch)" 
echo "Введите 1 или 2 (по умолчанию 1):"
read -r branch_choice

case "$branch_choice" in
    2)
        GIT_BRANCH="develop"
        GIT_URL="https://github.com/GamerVII-NET/Gml.Backend.git"
        GIT_BRANCH_OPTION="--branch develop"
        echo "[GML] Выбрана версия для разработки (develop)"
        ;;
    *)
        GIT_BRANCH="master" 
        GIT_URL="https://github.com/GamerVII-NET/Gml.Backend.git"
        GIT_BRANCH_OPTION=""
        echo "[GML] Выбрана стабильная версия (master)"
        ;;
esac

# Отключение интерактивных запросов на перезапуск сервисов
if [ -f /etc/needrestart/needrestart.conf ]; then
    sed -i "s/#\$nrconf{restart} = 'i';/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf
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

# Установка curl если не установлен
if ! command -v curl >/dev/null; then
    install_package curl || {
        echo "[Curl] Ошибка установки Curl"
        exit 1
    }
fi

# Установка Docker через официальный скрипт
if ! command -v docker >/dev/null; then
    echo "[Docker] Установка Docker через официальный скрипт..."
    (curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh) &
    show_spinner $! "[Docker] Установка Docker"
    
    # Запуск и включение Docker
    systemctl enable docker >/dev/null 2>&1
    systemctl start docker >/dev/null 2>&1
else
    printf "[Docker] Docker уже установлен \033[32m✓\033[0m\n"
fi

# Добавляем текущего пользователя в группу docker (если не root)
if [ "$(id -u)" -ne 0 ]; then
    usermod -aG docker $USER >/dev/null 2>&1
fi

# Установка Docker Compose
if ! command -v docker-compose >/dev/null && ! docker compose version >/dev/null 2>&1; then
    echo "[Docker] Установка Docker Compose..."
    
    # Устанавливаем через репозиторий Docker (предпочтительный способ)
    if command -v apt-get >/dev/null; then
        apt-get update >/dev/null 2>&1
        apt-get install -y docker-compose-plugin >/dev/null 2>&1
    elif command -v dnf >/dev/null; then
        dnf install -y docker-compose-plugin >/dev/null 2>&1
    else
        # Альтернатива: скачиваем бинарник
        DOCKER_CONFIG=${DOCKER_CONFIG:-/usr/local/lib/docker}
        mkdir -p $DOCKER_CONFIG/cli-plugins
        curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o $DOCKER_CONFIG/cli-plugins/docker-compose
        chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
    fi
fi

# Проверяем какая команда docker compose доступна
if docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
    printf "[Docker] Docker Compose (plugin) \033[32m✓\033[0m\n"
elif command -v docker-compose >/dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
    printf "[Docker] Docker Compose (standalone) \033[32m✓\033[0m\n"
else
    echo "[Docker] Ошибка: Docker Compose не установлен"
    exit 1
fi

# Клонирование репозитория в папку установки
echo "[GML] Клонирование репозитория Gml.Backend ($GIT_BRANCH)..."

# Сначала проверяем, доступен ли репозиторий
echo "[GML] Проверка доступности репозитория..."
if git ls-remote "$GIT_URL" > /dev/null 2>&1; then
    echo "[GML] Репозиторий доступен"
else
    echo "[GML] Ошибка: Репозиторий недоступен"
    exit 1
fi

# Проверяем, не клонирован ли уже репозиторий
if [ ! -d ".git" ]; then
    # Клонируем с рекурсивным получением подмодулей
    if [ -n "$GIT_BRANCH_OPTION" ]; then
        (git clone --recursive $GIT_BRANCH_OPTION "$GIT_URL" .) &
    else
        (git clone --recursive "$GIT_URL" .) &
    fi

    show_spinner $! "[GML] Клонирование репозитория"

    if [ $? -ne 0 ]; then
        echo "[GML] Ошибка при клонировании репозитория"
        exit 1
    fi
else
    echo "[GML] Репозиторий уже клонирован, обновляем..."
    (git pull && git submodule update --init --recursive) &
    show_spinner $! "[GML] Обновление репозитория"
fi

# Настройка конфигурации
if [ ! -f .env ]; then
    echo "[GML] Создание конфигурационного файла .env..."

    # Генерация SECURITY_KEY
    security_key=$(openssl rand -hex 32 2>/dev/null || echo "643866c80c46c909332b30600d3265803a3807286d6eb7c0d2e164877c809519")
    
    # Запрос имени проекта
    echo "[GML] Введите наименование проекта (или нажмите ENTER для 'GmlBackendPanel'):"
    read -r project_name
    project_name=${project_name:-GmlBackendPanel}

    # Валидация имени проекта
    valid_project_name_regex="^[a-zA-Z_][a-zA-Z0-9_]*$"
    while ! echo "$project_name" | grep -Eq "$valid_project_name_regex"; do
        echo "[GML] Ошибка: Имя проекта должно начинаться с буквы или '_', и содержать только буквы, цифры или '_'"
        echo "[GML] Введите наименование проекта:"
        read -r project_name
        project_name=${project_name:-GmlBackendPanel}
    done

    # Автоматическое определение политики
    project_policyname=$(echo "$project_name" | tr -cd '[:alnum:]' | sed 's/^[0-9]/_&/')Policy

    # Создание .env файла с портами из URL пользователя
    cat > .env << EOF
UID=0
GID=0

SECURITY_KEY=$security_key
PROJECT_NAME=$project_name
PROJECT_DESCRIPTION=
PROJECT_POLICYNAME=$project_policyname
PROJECT_PATH=

S3_ENABLED=false

PORT_GML_BACKEND=$panel_port
PORT_GML_FRONTEND=5003
PORT_GML_FILES=5005
PORT_GML_SKINS=5006

SERVICE_TEXTURE_ENDPOINT=http://gml-web-skins:8085
MARKET_ENDPOINT=https://gml-market.recloud.tech
EOF

    echo "[GML] Файл .env создан успешно"
else
    echo "[GML] Файл .env уже существует, используется существующая конфигурация"
fi

# Создание .env для фронтенда
mkdir -p src/Gml.Web.Client

if [ ! -f "src/Gml.Web.Client/.env" ]; then
    echo "[GML] Создание конфигурации для фронтенда..."
    
    # Формируем URL для бэкенда (убираем порт если это стандартный HTTP/HTTPS порт)
    if [ "$panel_port" = "443" ] && echo "$panel_url" | grep -q "^https"; then
        backend_url="https://$panel_host"
    elif [ "$panel_port" = "80" ] && echo "$panel_url" | grep -q "^http:"; then
        backend_url="http://$panel_host"
    else
        backend_url="$panel_url"
    fi
    
    cat > src/Gml.Web.Client/.env << EOF
NEXT_PUBLIC_BACKEND_URL=$backend_url/api/v1
NEXT_PUBLIC_MARKETPLACE_URL=https://gml-market.recloud.tech
EOF
    echo "[GML] Конфигурация фронтенда создана"
else
    echo "[GML] Конфигурация фронтенда уже существует"
    
    # Предлагаем обновить адрес если он отличается
    if [ -f "src/Gml.Web.Client/.env" ]; then
        current_backend_url=$(grep "NEXT_PUBLIC_BACKEND_URL" src/Gml.Web.Client/.env | cut -d '=' -f2 | sed 's|/api/v1||')
        expected_backend_url="$panel_url"
        
        if [ "$current_backend_url" != "$expected_backend_url/api/v1" ] && [ -n "$current_backend_url" ]; then
            echo "[GML] Текущий адрес бэкенда: $current_backend_url"
            echo "[GML] Новый адрес: $expected_backend_url"
            echo "[GML] Хотите обновить адрес бэкенда? [y/N]"
            read -r update_backend
            if [ "$update_backend" = "y" ] || [ "$update_backend" = "Y" ]; then
                # Формируем URL для бэкенда (убираем порт если это стандартный HTTP/HTTPS порт)
                if [ "$panel_port" = "443" ] && echo "$panel_url" | grep -q "^https"; then
                    backend_url="https://$panel_host"
                elif [ "$panel_port" = "80" ] && echo "$panel_url" | grep -q "^http:"; then
                    backend_url="http://$panel_host"
                else
                    backend_url="$panel_url"
                fi
                
                sed -i "s|NEXT_PUBLIC_BACKEND_URL=.*|NEXT_PUBLIC_BACKEND_URL=$backend_url/api/v1|" src/Gml.Web.Client/.env
                echo "[GML] Адрес бэкенда обновлен"
            fi
        fi
    fi
fi

# Запуск проекта
echo "[GML] Запуск GML Backend (ветка: $GIT_BRANCH)..."
($DOCKER_COMPOSE_CMD up -d --build) &
show_spinner $! "[GML] Сборка и запуск контейнеров"

# Проверка статуса
echo "[GML] Проверка статуса сервисов..."
sleep 10

if $DOCKER_COMPOSE_CMD ps | grep -q "Up"; then
    # Получаем актуальные порты из .env файла
    backend_port=$(grep "PORT_GML_BACKEND" .env | cut -d '=' -f2)
    frontend_port=$(grep "PORT_GML_FRONTEND" .env | cut -d '=' -f2)
    files_port=$(grep "PORT_GML_FILES" .env | cut -d '=' -f2)
    skins_port=$(grep "PORT_GML_SKINS" .env | cut -d '=' -f2)
    
    backend_port=${backend_port:-5000}
    frontend_port=${frontend_port:-5003}
    files_port=${files_port:-5005}
    skins_port=${skins_port:-5006}
    
    # Формируем URL для отображения пользователю
    frontend_url="$panel_url"
    # Заменяем порт бэкенда на порт фронтенда в URL
    if echo "$frontend_url" | grep -q ":[0-9]\+"; then
        frontend_url=$(echo "$frontend_url" | sed "s|:[0-9]\+|:$frontend_port|")
    else
        if echo "$frontend_url" | grep -q "^https"; then
            frontend_url="$frontend_url:$frontend_port"
        else
            frontend_url="$frontend_url:$frontend_port"
        fi
    fi
    
    echo
    printf "\033[32m==================================================\033[0m\n"
    printf "\033[32mGML успешно установлен и запущен!\033[0m\n"
    printf "\033[32m==================================================\033[0m\n"
    echo "Версия: $GIT_BRANCH"
    echo "Папка установки: $INSTALL_DIR"
    echo "Панель управления: $frontend_url"
    echo "Web API: $panel_url/api/v1"
    echo "Файловый сервис: $(echo $panel_url | sed "s|:[0-9]\+|:$files_port|")"
    echo "Сервис скинов: $(echo $panel_url | sed "s|:[0-9]\+|:$skins_port|")"
    echo
    echo "Команды для управления:"
    echo "Просмотр логов:   cd $INSTALL_DIR && $DOCKER_COMPOSE_CMD logs -f"
    echo "Остановка:        cd $INSTALL_DIR && $DOCKER_COMPOSE_CMD down"
    echo "Перезапуск:       cd $INSTALL_DIR && $DOCKER_COMPOSE_CMD restart"
    echo "Обновление:       cd $INSTALL_DIR && git pull && $DOCKER_COMPOSE_CMD up -d --build"
    echo
    printf "\033[33mВажно:\033[0m\n"
    echo "- Панель управления доступна по адресу: $frontend_url"
    echo "- Для доступа к панели необходимо зарегистрироваться"
    
    if [ "$GIT_BRANCH" = "develop" ]; then
        echo "- Используется версия для разработки - возможны нестабильности"
    fi
    
    printf "\033[32m==================================================\033[0m\n"
else
    echo
    printf "\033[31m==================================================\033[0m\n"
    echo "Возникли проблемы при запуске контейнеров"
    echo "Проверьте логи: cd $INSTALL_DIR && $DOCKER_COMPOSE_CMD logs"
    printf "\033[31m==================================================\033[0m\n"
    exit 1
fi

# Дополнительная информация для пользователя
echo
printf "\033[36mДополнительная информация:\033[0m\n"
echo "- Архитектура системы: $ARCH"
echo "- URL панели управления: $frontend_url"
echo "- URL API: $panel_url/api/v1"
echo "- Имя проекта: $project_name"
echo "- Версия: $GIT_BRANCH"
echo "- Папка установки: $INSTALL_DIR"
echo
echo "Если вы используете доменное имя, убедитесь что:"
echo "1. DNS записи настроены на правильный IP-адрес"
echo "2. Для HTTPS настроен SSL сертификат"
echo "3. Проксирование настроено корректно (nginx/apache)"
