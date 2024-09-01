@echo off

where /q docker
if ERRORLEVEL 1 (
    echo [Gml] Docker is not installed, update is not possible
    exit 1
)

IF EXIST .env (
  echo [Gml] .env check - Success
) ELSE (
  echo [Gml] .env file missing
  exit 1
)

IF EXIST docker-compose.yml (
  echo [Gml] docker-compose.yml check - Successful
) ELSE (
  echo [Gml] docker-compose.yml file missing
  exit 1
)

IF EXIST ./frontend/Gml.Web.Client/.env (
  echo [Gml] ./frontend/Gml.Web.Client/.env check - Successful
) ELSE (
  echo [Gml] ./frontend/Gml.Web.Client/.env file missing
  exit 1
)

setlocal enabledelayedexpansion

rem Save the entire content of 'Gml.Web.Client.env' into a temporary file
if exist frontend\Gml.Web.Client\.env (
    copy frontend\Gml.Web.Client\.env temp.txt
)

docker compose down

docker rmi ghcr.io/gml-launcher/gml.web.skin.service:master
docker rmi ghcr.io/gml-launcher/gml.web.api:master
docker rmi gml-web-frontend-image

rd /s /q frontend
git clone https://github.com/Gml-Launcher/Gml.Web.Client.git frontend\Gml.Web.Client

rem Write the 'content' variable into 'Gml.Web.Client.env'
if exist temp.txt (
  copy temp.txt frontend\Gml.Web.Client\.env
  del /q temp.txt
)

docker compose up -d

pause
