@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

:: Проверка наличия git, docker, docker-compose
where /q git
if ERRORLEVEL 1 (
    echo [Git] Не найден. Установите его вручную.
    exit /b 1
) else (
    echo [Git] Установлен
)

where /q docker
if ERRORLEVEL 1 (
    echo [Docker] Не найден. Установите его вручную.
    exit /b 1
) else (
    echo [Docker] Установлен
)

where /q docker-compose
if ERRORLEVEL 1 (
    echo [Docker-Compose] Не найден. Установите его вручную.
    exit /b 1
) else (
    echo [Docker-Compose] Установлен
)

:: Загрузка docker-compose.yml
bitsadmin /transfer "MyDownloadJob" /download /priority normal https://raw.githubusercontent.com/GamerVII-NET/Gml.Backend/master/docker-compose-prod.yml %CD%\docker-compose.yml

:: Настройка
IF EXIST .env (
    echo [Gml] Файл .env найден. Используется локальная конфигурация...
) ELSE (
    echo [Gml] Файл .env не найден. Настройка...

    :: Генерация SECURITY_KEY
    for /f "delims=" %%i in ('powershell -Command "[guid]::NewGuid().ToString()"') do set "security_key=%%i"

    set /p project_name="[Gml] Введите имя проекта: "
    
    set /p panel_url="[Gml] Введите адрес панели управления Gml, порт обязателен, если не используется проксирование (По умолчанию: http://localhost:5000): "
    if "%panel_url%"=="" (
        set panel_url=http://localhost:5000
    )

    echo [Gml] Gml.Web.Api настроена на использование HTTP/S: %panel_url%

    :: Удаление пробелов из project_name для project_policyname
    set "project_policyname=!project_name: =%Policy"

    (
        echo UID=0
        echo GID=0
        echo SECURITY_KEY=!security_key!
        echo PROJECT_NAME=!project_name!
        echo PROJECT_DESCRIPTION=
        echo PROJECT_POLICYNAME=!project_policyname!
        echo PROJECT_PATH=
        echo S3_ENABLED=false
        echo PORT_GML_BACKEND=5000
        echo PORT_GML_FRONTEND=5003
        echo PORT_GML_FILES=5005
        echo PORT_GML_SKINS=5006
        echo SERVICE_TEXTURE_ENDPOINT=http://gml-web-skins:8085

    ) > .env

    del /Q /F frontend >NUL 2>NUL
    git clone https://github.com/Gml-Launcher/Gml.Web.Client.git frontend/Gml.Web.Client

    (
        echo NEXT_PUBLIC_BACKEND_URL=!panel_url!/api/v1
    ) > frontend/Gml.Web.Client/.env
)

:: Запуск
docker compose up -d

echo.
echo.
echo ==================================================
echo Проект успешно установлен:
echo ==================================================
echo Админпанель: http://localhost:5003/
echo              *Необходима регистрация
echo ==================================================
echo * Настоятельно советуем, в целях вашей безопасности, сменить данные для авторизации в панелях управления
echo ==================================================
pause
