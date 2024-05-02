#!/bin/sh

if [ "$(id -u)" -ne 0 ]
then
  echo "The script needs to be run as root"
  exit 1
fi


#!/bin/bash

# Check for git installation
if ! command -v git > /dev/null
then
    echo "[Git] Git not found. Attempting to install..."
    apt-get install -y git
    if [ $? -eq 0 ]
    then
        echo "[Git] Installation successful"
    else
        echo "[Git] Failed to install Git. Please install it manually."
        exit 1
    fi
else
    echo "[Git] Installed"
fi

# Check for jq installation
if ! command -v jq > /dev/null
then
    echo "[jq] jq not found. Attempting to install..."
    apt-get install -y jq
    if [ $? -eq 0 ]
    then
        echo "[jq] Installation successful"
    else
        echo "[jq] Failed to install jq. Please install it manually."
        exit 1
    fi
else
    echo "[jq] Installed"
fi

# Check for curl installation
if ! command -v curl > /dev/null
then
    echo "[Curl] Curl not found. Attempting to install..."
    apt-get install -y curl
    if [ $? -eq 0 ]
    then
        echo "[Curl] Installation successful"
    else
        echo "[Curl] Failed to install Curl. Please install it manually."
        exit 1
    fi
else
    echo "[Curl] Installed"
fi

# Check for wget installation
if ! command -v wget > /dev/null
then
    echo "[Wget] Wget not found. Attempting to install..."
    apt-get install -y wget
    if [ $? -eq 0 ]
    then
        echo "[Wget] Installation successful"
    else
        echo "[Wget] Failed to install Wget. Please install it manually."
        exit 1
    fi
else
    echo "[Wget] Installed"
fi

# Check for docker.io installation
if ! command -v docker > /dev/null
then
    echo "[Docker] Docker not found. Attempting to install..."
    apt-get install -y docker.io
    if [ $? -eq 0 ]
    then
        echo "[Docker] Installation successful"
    else
        echo "[Docker] Failed to install Docker. Please install it manually."
        exit 1
    fi
else
    echo "[Docker] Installed"
fi

# Check for Docker Compose installation
if ! command -v docker-compose > /dev/null
then
    echo "[Docker-Compose] Docker Compose not found. Attempting to install..."
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p $DOCKER_CONFIG/cli-plugins
    curl -SL https://github.com/docker/compose/releases/download/v2.24.7/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
    chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
    if [ $? -eq 0 ]
    then
        echo "[Docker-Compose] Installation successful"
    else
        echo "[Docker-Compose] Failed to install Docker Compose. Please install it manually."
        exit 1
    fi
else
    echo "[Docker-Compose] Installed"
fi

# Download the file
wget https://raw.githubusercontent.com/GamerVII-NET/Gml.Backend/master/docker-compose-prod.yml

# Use printf to create the .env file and ask for user input for the empty variables
printf "API_URL=http://$(hostname -I | awk '{print $1}'):5000\n\
POSTGRES_USER=gmlcore\n\
POSTGRES_PASSWORD=$(openssl rand -hex 16)\n\
POSTGRES_DB=gmlcoredb\n\
GLITCHTIP_DOMAIN=http://$(hostname -I | awk '{print $1}'):5007\n\
GLITCHTIP_SECRET_KEY=$(openssl rand -hex 32)\n\
ADMIN_EMAIL=$(read -p "Укажите Email-адрес администратора: " email; echo $email)\n\
PORT_GML_BACKEND=5000\n\
PORT_GML_FRONTEND=5003\n\
PORT_GML_FILES=5005\n\
PORT_GML_SENTRY=5007\n\
PORT_GML_SKINS=5006\n" > .env

rm -Rf ./frontend
git clone https://github.com/Scondic/Gml.Web.Client.git ./frontend/Gml.Web.Client

printf "NEXT_PUBLIC_BASE_URL=http://$(hostname -I | awk '{print $1}'):5000\n\
NEXT_PUBLIC_PREFIX_API=api\n\
NEXT_PUBLIC_VERSION_API=v1" > ./frontend/Gml.Web.Client/.env

# Run
docker compose -f docker-compose-prod.yml up -d
