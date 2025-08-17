@echo off
setlocal enabledelayedexpansion

where /q docker
if ERRORLEVEL 1 (
    echo [Gml] Docker is not installed, update is not possible
    exit /b 1
)

IF EXIST .env (
    echo [Gml] .env check - Success
) ELSE (
    echo [Gml] .env file missing
    exit /b 1
)

IF EXIST docker-compose.yml (
    echo [Gml] docker-compose.yml check - Successful
) ELSE (
    echo [Gml] docker-compose.yml file missing
    exit /b 1
)

IF EXIST ./frontend/Gml.Web.Client/.env (
    echo [Gml] ./frontend/Gml.Web.Client/.env check - Successful
) ELSE (
    echo [Gml] ./frontend/Gml.Web.Client/.env file missing
    exit /b 1
)

rem Save the content of .env into a temporary file
if exist frontend\Gml.Web.Client\.env (
    copy /y frontend\Gml.Web.Client\.env temp.txt >nul
)

docker compose down

docker rmi ghcr.io/gml-launcher/gml.web.skin.service:master
docker rmi ghcr.io/gml-launcher/gml.web.api:master
docker rmi gml-web-frontend-image

rem Remove and re-clone frontend
rd /s /q frontend
git clone https://github.com/Gml-Launcher/Gml.Web.Client.git frontend\Gml.Web.Client

rem Restore .env
if exist temp.txt (
    copy /y temp.txt frontend\Gml.Web.Client\.env >nul
    del /q temp.txt
)

rem Add NEXT_PUBLIC_MARKETPLACE_URL if not already present
set "ENV_FILE=frontend\Gml.Web.Client\.env"
findstr /b /c:"NEXT_PUBLIC_MARKETPLACE_URL=" "%ENV_FILE%" >nul
if ERRORLEVEL 1 (
    echo NEXT_PUBLIC_MARKETPLACE_URL=https://gml-market.recloud.tech >> "%ENV_FILE%"
    echo [Gml] Added NEXT_PUBLIC_MARKETPLACE_URL line to .env
)

docker compose up -d

pause
