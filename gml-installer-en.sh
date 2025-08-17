#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

# Function to display a spinner
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

# Total number of installation steps
TOTAL_STEPS=8
CURRENT_STEP=0
PROGRESS_WIDTH=30

echo "[System] Starting GML installation..."
echo "[System] Preparing system..."

# Disable interactive prompts for service restarts
if [ -f /etc/needrestart/needrestart.conf ]; then
    sed -i "s/#\$nrconf{restart} = 'i';/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf
fi

# For Debian/Ubuntu, create configuration for apt
if command -v apt-get >/dev/null; then
    mkdir -p /etc/apt/apt.conf.d/
    echo '
DPkg::Options {
   "--force-confdef";
   "--force-confold";
}
' > /etc/apt/apt.conf.d/local
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# Determine system type
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
    echo "[System] Detected system: $OS $VER"
fi

# Function to install a package
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
    
    show_spinner $! "[System] Installing $package"
    return $?
}

# Install basic dependencies
echo "[System] Installing basic dependencies..."

# Install Git
if ! command -v git >/dev/null; then
    install_package git || {
        echo "[Git] Error installing Git"
        exit 1
    }
else
    printf "[System] Installing git \033[32m✓\033[0m\n"
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# Install jq
if ! command -v jq >/dev/null; then
    install_package jq || {
        echo "[jq] Error installing jq"
        exit 1
    }
else
    printf "[System] Installing jq \033[32m✓\033[0m\n"
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# Install curl
if ! command -v curl >/dev/null; then
    install_package curl || {
        echo "[Curl] Error installing Curl"
        exit 1
    }
else
    printf "[System] Installing curl \033[32m✓\033[0m\n"
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# Install wget
if ! command -v wget >/dev/null; then
    install_package wget || {
        echo "[Wget] Error installing Wget"
        exit 1
    }
else
    printf "[System] Installing wget \033[32m✓\033[0m\n"
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# Install Docker
install_docker() {
    (
        if command -v apt-get >/dev/null; then
            # Debian/Ubuntu
            apt-get update >/dev/null 2>&1
            apt-get install -y docker.io >/dev/null 2>&1
        elif command -v dnf >/dev/null; then
            # Fedora
            dnf install -y docker >/dev/null 2>&1
        elif command -v yum >/dev/null; then
            # CentOS/RHEL
            yum install -y docker >/dev/null 2>&1
        elif command -v zypper >/dev/null; then
            # OpenSUSE
            zypper install -y docker >/dev/null 2>&1
        elif command -v pacman >/dev/null; then
            # Arch Linux
            pacman -Sy --noconfirm docker >/dev/null 2>&1
        else
            return 1
        fi

        # Start and enable Docker
        systemctl start docker >/dev/null 2>&1
        systemctl enable docker >/dev/null 2>&1
    ) &
    
    show_spinner $! "[System] Installing docker"
    return $?
}

# Install Docker if not installed
if ! command -v docker >/dev/null; then
    install_docker || {
        echo "[Docker] Error installing Docker"
        exit 1
    }
else
    printf "[System] Installing docker \033[32m✓\033[0m\n"
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# Install Docker Compose
if ! command -v docker-compose >/dev/null && ! command -v "docker compose" >/dev/null; then
    (
        DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
        mkdir -p $DOCKER_CONFIG/cli-plugins >/dev/null 2>&1
        curl -SL "https://github.com/docker/compose/releases/download/v2.24.7/docker-compose-$(uname -s)-$(uname -m)" -o $DOCKER_CONFIG/cli-plugins/docker-compose >/dev/null 2>&1
        chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose >/dev/null 2>&1
    ) &
    
    show_spinner $! "[System] Installing docker-compose"
    if [ $? -eq 0 ]; then
        DOCKER_COMPOSE_CMD="docker compose"
    else
        echo "[System] Error installing Docker Compose"
        exit 1
    }
else
    if command -v docker-compose >/dev/null; then
        printf "[System] Installing docker-compose \033[32m✓\033[0m\n"
        DOCKER_COMPOSE_CMD="docker-compose"
    else
        printf "[System] Installing docker-compose \033[32m✓\033[0m\n"
        DOCKER_COMPOSE_CMD="docker compose"
    fi
fi

CURRENT_STEP=$((CURRENT_STEP + 1))

# Download docker-compose.yml
(wget https://raw.githubusercontent.com/GamerVII-NET/Gml.Backend/master/docker-compose-prod.yml -O docker-compose.yml >/dev/null 2>&1) &
show_spinner $! "[System] Downloading configuration"

CURRENT_STEP=$((CURRENT_STEP + 1))

# Setup
ip_address=$(curl -s https://ipinfo.io/ip)
if [ $? -ne 0 ]; then
    ip_address=$(hostname -I | awk '{print $1}')
fi

if [ -f .env ]; then
    echo "[GML] .env file exists. Using local configuration..."
else
    echo "[GML] .env file not found. Setting up..."

    # Generate SECURITY_KEY
    security_key=$(openssl rand -hex 32)
    valid_project_name_regex="^[a-zA-Z_][a-zA-Z0-9_]*$"
    
    echo "[GML] Enter project name:"
    while true; do
        read project_name
        if echo "$project_name" | grep -Eq "$valid_project_name_regex"; then
            break
        else
            echo "[GML] Error: Project name must start with a letter or '_', and contain only letters, numbers, or '_'"
            echo "[GML] Try again:"
        fi
    done

    echo "[GML] Enter the address for the Gml control panel, port is required if you are not using a proxy"
    echo "[GML] Default address:[](http://$ip_address:5000), press ENTER to set it"
    read panel_url

    if [ -z "$panel_url" ]; then
        panel_url="http://$ip_address:5000"
    fi

    echo "[GML] Panel address: $panel_url"

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

SERVICE_TEXTURE_ENDPOINT=http://gml-web-skins:8085
MARKET_ENDPOINT=https://gml-market.recloud.tech" > .env

    rm -Rf ./frontend
    (git clone --single-branch https://github.com/Gml-Launcher/Gml.Web.Client.git ./frontend/Gml.Web.Client >/dev/null 2>&1) &
    show_spinner $! "[GML] Cloning frontend"

    # Create .env file and write variables to it
    echo "NEXT_PUBLIC_BACKEND_URL=$panel_url/api/v1
NEXT_PUBLIC_MARKETPLACE_URL=https://gml-market.recloud.tech" > ./frontend/Gml.Web.Client/.env
fi

# Run
(
    $DOCKER_COMPOSE_CMD up -d --build > docker-build.log 2>&1
) &

show_spinner $! "[GML] Building containers, please wait..."
BUILD_SUCCESS=$?

if [ $BUILD_SUCCESS -ne 0 ]; then
    echo "[GML] Error building containers"
    echo "[GML] Error log:"
    echo "----------------------------------------"
    cat docker-build.log
    echo "----------------------------------------"
    rm -f docker-build.log
    exit 1
fi

rm -f docker-build.log

echo
echo
printf "\033[32m==================================================\033[0m\n"
printf "\033[32mProject successfully installed:\033[0m\n"
printf "\033[32m==================================================\033[0m\n"
echo "Admin panel: http://$ip_address:5003/"
echo "             *Registration is required"
printf "\033[31m==================================================\n"
echo "* For your security, we strongly recommend changing the authorization credentials for the control panels"
printf "==================================================\033[0m\n"