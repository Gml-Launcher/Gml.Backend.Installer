#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" 
    exit 1
fi

# Check for git installation
if ! command -v git >/dev/null; then
    echo "[Git] Git not found. Attempting to install..."

    if ! command -v apt-get >/dev/null; then
        apt-get install -y git
    elif ! command -v pacman >/dev/null; then
        pacman -S --noconfirm git
    elif ! command -v dnf >/dev/null; then
        dnf install -y git
    elif ! command -v zypper >/dev/null; then
        zypper install -y git
    else
        echo "[Git] Failed to install Git. Please install it manually."
        exit 1
    fi
    if [ $? -eq 0 ]; then
        echo "[Git] Installation successful"
    else
        echo "[Git] Failed to install Git. Please install it manually."
    fi
else
    echo "[Git] Installed"
fi

# Check for jq installation
if ! command -v jq >/dev/null; then
    echo "[jq] jq not found. Attempting to install..."
    if ! command -v apt-get >/dev/null; then
        apt-get install -y jq
    elif ! command -v pacman >/dev/null; then
        pacman -S --noconfirm jq
    elif ! command -v dnf >/dev/null; then
        dnf install -y jq
    elif ! command -v zypper >/dev/null; then
        zypper install -y jq
    else
        echo "[Git] Failed to install Git. Please install it manually."
        exit 1
    fi
    if [ $? -eq 0 ]; then
        echo "[jq] Installation successful"
    else
        echo "[jq] Failed to install jq. Please install it manually."
    fi
else
    echo "[jq] Installed"
fi

# Check for curl installation
if ! command -v curl >/dev/null; then
    echo "[Curl] Curl not found. Attempting to install..."
    if ! command -v apt-get >/dev/null; then
        apt-get install -y curl
    elif ! command -v pacman >/dev/null; then
        pacman -S --noconfirm curl
    elif ! command -v dnf >/dev/null; then
        dnf install -y curl
    elif ! command -v zypper >/dev/null; then
        zypper install -y curl
    else
        echo "[Git] Failed to install Git. Please install it manually."
        exit 1
    fi
    if [ $? -eq 0 ]; then
        echo "[Curl] Installation successful"
    else
        echo "[Curl] Failed to install Curl. Please install it manually."
    fi
else
    echo "[Curl] Installed"
fi

# Check for wget installation
if ! command -v wget >/dev/null; then
    echo "[Wget] Wget not found. Attempting to install..."
    if ! command -v apt-get >/dev/null; then
        apt-get install -y wget
    elif ! command -v pacman >/dev/null; then
        pacman -S --noconfirm wget
    elif ! command -v dnf >/dev/null; then
        dnf install -y wget
    elif ! command -v zypper >/dev/null; then
        zypper install -y wget
    else
        echo "[Git] Failed to install Git. Please install it manually."
        exit 1
    fi
    if [ $? -eq 0 ]; then
        echo "[Wget] Installation successful"
    else
        echo "[Wget] Failed to install Wget. Please install it manually."
    fi
else
    echo "[Wget] Installed"
fi

# Check for docker.io installation
if ! command -v docker >/dev/null; then
    echo "[Docker] Docker not found. Attempting to install..."
    if ! command -v apt-get >/dev/null; then
        apt-get install -y docker.io
    elif ! command -v pacman >/dev/null; then
        pacman -S --noconfirm docker
    elif ! command -v dnf >/dev/null; then
        dnf install -y docker
    elif ! command -v zypper >/dev/null; then
        zypper install -y docker
    else
        echo "[Docker] Failed to install Docker. Please install it manually."
        exit 1
    fi
    if [ $? -eq 0 ]; then
        echo "[Docker] Installation successful"
    else
        echo "[Docker] Failed to install Docker. Please install it manually."
    fi
else
    echo "[Docker] Installed"
fi

# Check for Docker Compose v2 or v1
if docker-compose >/dev/null 2>&1; then
    echo "[Docker-Compose] Docker Compose v1 is installed"
    DOCKER_COMPOSE_CMD="docker-compose"
elif docker compose >/dev/null 2>&1; then
    echo "[Docker-Compose] Docker Compose v2 is installed"
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo "[Docker-Compose] Docker Compose not found. Attempting to install..."
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p $DOCKER_CONFIG/cli-plugins
    curl -SL https://github.com/docker/compose/releases/download/v2.24.7/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
    chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
    if [ $? -eq 0 ]; then
        echo "[Docker-Compose] Installation successful"
        DOCKER_COMPOSE_CMD="docker compose"
    else
        echo "[Docker-Compose] Failed to install Docker Compose. Please install it manually."
    fi
fi

# Download docker-compose.yml
wget https://raw.githubusercontent.com/GamerVII-NET/Gml.Backend/master/docker-compose-prod.yml -O docker-compose.yml

# Setup

ip_address=$(curl -s https://ipinfo.io/ip)
if [ $? -ne 0 ]; then
    ip_address=$(hostname -I | awk '{print $1}')
fi

if [ -f .env ]; then
    echo "[Gml] .env file exists. Using local configuration..."
else
    echo "[Gml] .env file not found. Proceeding with setup..."

    # Generate SECURITY_KEY
    security_key=$(openssl rand -hex 32)
    valid_project_name_regex="^[a-zA-Z_][a-zA-Z0-9_]*$"
    
    echo "[Gml] Please enter the project name:"
    while true; do
        read project_name
        if echo "$project_name" | grep -Eq "$valid_project_name_regex"; then
            break
        else
            echo "[Gml] Error: The project name must start with a letter or '_', and contain only letters, numbers, or '_'. Please try again:"
        fi
    done

    echo "[Gml] Valid project name received: $project_name"

    echo "[Gml] Enter the address for the Gml control panel, port is required if you are not using proxying."
    echo "[Gml] Default address: (http://$ip_address:5000), press ENTER to use it"
    read panel_url

    if [ -z "$panel_url" ]; then
        panel_url="http://$ip_address:5000"
    fi

    echo "[Gml] Gml.Web.Api is set to use HTTP/S: $panel_url"

    # Set PROJECT_POLICYNAME
    project_policyname=$(echo "$project_name" | tr -d '[:space:]')Policy

    # Create .env file and write variables to it
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

    rm -Rf ./frontend
    git clone --single-branch https://github.com/Gml-Launcher/Gml.Web.Client.git ./frontend/Gml.Web.Client

    # Create .env file and write variables to it
    echo "NEXT_PUBLIC_BACKEND_URL=$panel_url/api/v1" > ./frontend/Gml.Web.Client/.env

fi

# Run

$DOCKER_COMPOSE_CMD up -d --build

echo 
echo 
echo "\e[32m==================================================\e[0m"
echo "\e[32mProject successfully installed:\e[0m"
echo "\e[32m==================================================\e[0m"
echo "Admin panel: http://$ip_address:5003/"
echo "             *Registration required"
echo "\033[31m=================================================="
echo "* For security reasons, we strongly recommend changing the login credentials in the control panels."
echo "==================================================\033[0m"
