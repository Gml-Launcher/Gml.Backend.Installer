@echo off

:: Check for administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR! This script must be run as administrator.
    pause
    exit /b 1
)

set BASE_DIR=%~dp0
set VERSION=v2025.3.3.2

:: Parse arguments
:parse_args
if "%~1"=="" goto validate_version
if "%~1"=="--version" (
    set VERSION=%~2
    shift
    shift
    goto parse_args
) else (
    echo Unknown argument: %~1
    exit /b 1
)

:validate_version
if "%VERSION%"=="" (
    echo Error: --version argument is required.
    exit /b 1
)

:: Ensure the base directory exists
if not exist "%BASE_DIR%" (
    mkdir "%BASE_DIR%"
)

:: Download and configure the project
:download_project
echo [Gml] Downloading and configuring the project...
mkdir "%BASE_DIR%"
cd "%BASE_DIR%"
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Gml-Launcher/Gml.Backend/refs/tags/%VERSION%/docker-compose-prod.yml' -OutFile 'docker-compose.yml'"
powershell -Command "(Get-Content 'docker-compose.yml') -replace ':master', ':%VERSION%' | Set-Content 'docker-compose.yml'"

if not exist ".env" (
    powershell -Command "$security_key = [guid]::NewGuid().ToString('N'); Add-Content -Path '.env' -Value \"UID=0`nGID=0`n`nSECURITY_KEY=$security_key`nPROJECT_NAME=GmlBackend`nPROJECT_DESCRIPTION=GmlBackend`nPROJECT_POLICYNAME=GmlBackendPolicy`nPROJECT_PATH=`n`nS3_ENABLED=false`nSWAGGER_ENABLED=false`n`nPORT_GML_BACKEND=5000`nPORT_GML_FRONTEND=5003`nPORT_GML_FILES=5005`nPORT_GML_SKINS=5006`n`nSERVICE_TEXTURE_ENDPOINT=http://gml-web-skins:8085`nMARKET_ENDPOINT=https://gml-market.recloud.tech\""
)

:: Install all required packages
:install_packages
call :install_docker
call :install_git

:: Startup function to run docker compose
:startup
echo [Gml] Starting docker compose...
cd "%BASE_DIR%"
docker compose up -d

:: Write success message
:write_message
echo.
echo ==================================================
echo Project successfully installed:
echo ==================================================
echo Admin panel: http://localhost:5003/
exit /b 0
