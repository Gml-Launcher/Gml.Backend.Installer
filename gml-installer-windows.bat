

where /q git
if ERRORLEVEL 1 (
    echo [Git] Not found. Please install it manually.
) else (
    echo [Git] Installed
)

where /q docker
if ERRORLEVEL 1 (
    echo [Docker] Not found. Please install it manually.
) else (
    echo [Docker] Installed
)

where /q docker-compose
if ERRORLEVEL 1 (
    echo [Docker-Compose] Not found. Please install it manually.
) else (
    echo [Docker-Compose] Installed
)

bitsadmin /transfer "MyDownloadJob" /download /priority normal https://raw.githubusercontent.com/GamerVII-NET/Gml.Backend/master/docker-compose-prod.yml %CD%\docker-compose.yml

@echo off

IF EXIST .env (
  echo [Gml] File .env exists. Using local configuration...
) ELSE (
  echo [Gml] File .env not found. Setting up...

  echo [Gml] Please enter a username for the S3 Minio storage:
  set /p login_minio=
  
  echo [Gml] Please enter a password for S3 Minio:
  set /p password_minio=
  
  echo [Gml] Please enter the address to the Gml control panel, port is mandatory if you're not using proxying
  echo [Gml] Default address:
  set /p panel_url=
  
  IF "%panel_url%"=="" (
    set panel_url=http://localhost:5000
  )

  (
    echo UID=0
    echo GID=0
    echo S3_ENABLED=true
    echo MINIO_ROOT_USER=%login_minio%
    echo MINIO_ROOT_PASSWORD=%password_minio%
    echo MINIO_ADDRESS=:5009
    echo MINIO_ADDRESS_PORT=5009
    echo MINIO_CONSOLE_ADDRESS=:5010
    echo MINIO_CONSOLE_ADDRESS_PORT=5010
    echo PORT_GML_BACKEND=5000
    echo PORT_GML_FRONTEND=5003
    echo PORT_GML_FILES=5005
    echo PORT_GML_SKINS=5006
    ) > .env

echo .env file has been created.
)

del /Q /F frontend >NUL 2>NUL
git clone https://github.com/Scondic/Gml.Web.Client.git frontend/Gml.Web.Client
(
  echo NEXT_PUBLIC_BASE_URL=%panel_url%
  echo NEXT_PUBLIC_PREFIX_API=api
  echo NEXT_PUBLIC_VERSION_API=v1
)>frontend/Gml.Web.Client/.env

docker compose up -d

pause