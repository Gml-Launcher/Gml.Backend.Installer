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

# Ask user for ProjectName
while :
do
    printf "Project name: "
    read ProjectName
    if [ -z "$ProjectName" ]
    then
        echo "[Error] Value cannot be empty. Please try again."
    else
        break
    fi
done

# Ask user for ProjectDescription
echo "Project description: (press Enter to use Game project $ProjectName):"
read ProjectDescription

# Generate SecretKey
SecretKey=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 ; echo '')

# Ask user for ProjectVersion
echo "Enter ProjectVersion (press Enter to use 1.1.0):"
read ProjectVersion
ProjectVersion="${ProjectVersion:-1.1.0}"

# Clone repository
echo "Cloning repository..."
git clone --recursive https://github.com/GamerVII-NET/Gml.Backend.git "$ProjectName"
if [ $? -eq 0 ]
then
    echo "Repository cloned successfully"
else
    echo "[Error] Failed to clone repository. Please check your internet connection and repository availability. Also, make sure there's no $ProjectName folder in current directory"
    exit 1
fi

# Get external IP address
EXTERNAL_IP=$(curl -s ifconfig.me)

# Change to project directory and create .env file
cd "$ProjectName"/src/Gml.Web.Client

# Create .env file
if [ ! -f .env ]; then
    echo "NEXT_PUBLIC_BASE_URL=http://$EXTERNAL_IP:5000" > .env
    echo "NEXT_PUBLIC_PREFIX_API=api" >> .env
    echo "NEXT_PUBLIC_VERSION_API=v1" >> .env
fi

# Change to $ProjectName/src/Gml.Web.Api/src/Gml.Web.Api folder
cd "../../src/Gml.Web.Api/src/Gml.Web.Api/"

# Delete appsettings.Development.json
rm -f appsettings.Development.json

# Edit appsettings.json
if [ -f appsettings.json ]; then
    
    jq ".ServerSettings.ProjectName = \"$ProjectName\" |
    .ServerSettings.ProjectDescription = \"$ProjectDescription\" |
    .ServerSettings.SecretKey = \"$SecretKey\" |
    .ServerSettings.PolicyName = \"${ProjectName}Policy\" |
    .ConnectionStrings.SQLite = \"Data Source=data.db\"" appsettings.json > temp.json && mv temp.json appsettings.json
fi

docker compose up -d

echo ==================================================
echo "\e[32mProject successfully installed:\e[0m"
echo "Admin panel: http://$EXTERNAL_IP:5003/"
echo "             *Registration required"
echo "File management: http://$EXTERNAL_IP:5005/"
echo "                 Login: admin"
echo "                 Password: admin"
echo ==================================================
