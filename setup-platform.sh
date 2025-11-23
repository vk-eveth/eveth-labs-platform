#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Eveth Labs Platform Setup ===${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source .env

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install required packages
install_dependencies() {
    echo -e "\n${YELLOW}Installing dependencies...${NC}"
    apt-get update
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        wget \
        gettext-base \
        gnupg \
        lsb-release \
        jq \
        postgresql-client \
        redis-tools \
        unzip
}

# Install Docker
install_docker() {
    if ! command_exists docker; then
        echo -e "\n${YELLOW}Installing Docker...${NC}"
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
            $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io
        systemctl enable --now docker
    else
        echo -e "${GREEN}Docker is already installed.${NC}"
    fi
}

# Check Docker Compose plugin
check_docker_compose() {
    if ! docker compose version &>/dev/null; then
        echo -e "\n${RED}Error: Docker Compose plugin is not installed.${NC}"
        echo "Please install Docker Compose plugin using:"
        echo "  apt-get install docker-compose-plugin"
        exit 1
    fi
    echo -e "${GREEN}Docker Compose plugin is available.${NC}"
}

# Configure system settings
configure_system() {
    echo -e "\n${YELLOW}Configuring system settings...${NC}"
    
    # Increase file watcher limits
    echo "fs.inotify.max_user_watches=1048576" | tee -a /etc/sysctl.conf
    echo "vm.max_map_count=262144" | tee -a /etc/sysctl.conf
    sysctl -p
    
    # Set proper permissions
    chmod +x scripts/*.sh
    chmod +x scripts/backup/*.sh
    chmod +x scripts/deploy/*.sh
    chmod +x scripts/monitoring/*.sh
    
    # Create required directories
    mkdir -p "$DATA_PATH/traefik/letsencrypt"
    mkdir -p "$DATA_PATH/gitlab/{config,logs,data}"
    mkdir -p "$DATA_PATH/sonarqube/{conf,data,extensions,logs}"
    mkdir -p "$DATA_PATH/postgres"
    mkdir -p "$DATA_PATH/redis"
    mkdir -p "$DATA_PATH/grafana"
    mkdir -p "$DATA_PATH/prometheus"
    mkdir -p "$DATA_PATH/loki"
    mkdir -p "$DATA_PATH/portainer"
    mkdir -p "$DATA_PATH/alertmanager"
    
    # Set proper permissions
    chmod -R 777 "$DATA_PATH"
    
    # Update /etc/hosts
    echo -e "\n${YELLOW}Updating /etc/hosts...${NC}"
    if ! grep -q "$GITLAB_DOMAIN" /etc/hosts; then
        echo "127.0.0.1 $GITLAB_DOMAIN" | tee -a /etc/hosts
    fi
    if ! grep -q "$SONARQUBE_DOMAIN" /etc/hosts; then
        echo "127.0.0.1 $SONARQUBE_DOMAIN" | tee -a /etc/hosts
    fi
    if ! grep -q "$GRAFANA_DOMAIN" /etc/hosts; then
        echo "127.0.0.1 $GRAFANA_DOMAIN" | tee -a /etc/hosts
    fi
    if ! grep -q "$PROMETHEUS_DOMAIN" /etc/hosts; then
        echo "127.0.0.1 $PROMETHEUS_DOMAIN" | tee -a /etc/hosts
    fi
    if ! grep -q "$LOKI_DOMAIN" /etc/hosts; then
        echo "127.0.0.1 $LOKI_DOMAIN" | tee -a /etc/hosts
    fi
    if ! grep -q "$TRAEFIK_DASHBOARD_DOMAIN" /etc/hosts; then
        echo "127.0.0.1 $TRAEFIK_DASHBOARD_DOMAIN" | tee -a /etc/hosts
    fi
    if ! grep -q "$PORTAINER_DOMAIN" /etc/hosts; then
        echo "127.0.0.1 $PORTAINER_DOMAIN" | tee -a /etc/hosts
    fi
    if ! grep -q "$ALERTMANAGER_DOMAIN" /etc/hosts; then
        echo "127.0.0.1 $ALERTMANAGER_DOMAIN" | tee -a /etc/hosts
    fi
    if ! grep -q "$HARBOR_DOMAIN" /etc/hosts; then
        echo "127.0.0.1 $HARBOR_DOMAIN" | tee -a /etc/hosts
    fi
}

# Pull Docker images
pull_docker_images() {
    echo -e "\n${YELLOW}Pulling Docker images...${NC}"
    docker compose pull
}

# Start services
start_services() {
    echo -e "\n${YELLOW}Starting services...${NC}"
    docker compose up -d
    
    echo -e "\n${YELLOW}Waiting for services to initialize...${NC}"
    sleep 30
    
    # Check services status
    echo -e "\n${YELLOW}Service Status:${NC}"
    docker compose ps
}

# Prepare Harbor config (generate common/config for compose)
prepare_harbor() {
    echo -e "\n${YELLOW}Preparing Harbor configuration...${NC}"
    if [ -x "$SCRIPT_DIR/scripts/prepare-harbor.sh" ]; then
        bash "$SCRIPT_DIR/scripts/prepare-harbor.sh" || echo -e "${RED}Harbor prepare failed or was skipped.${NC}"
    else
        echo -e "${YELLOW}Harbor prepare script not found at scripts/prepare-harbor.sh. Skipping.${NC}"
    fi
}

# Display setup information
show_setup_info() {
    echo -e "\n${GREEN}=== Setup Complete ===${NC}"
    echo -e "\n${YELLOW}Access URLs:${NC}"
    echo -e "Traefik Dashboard: http://$TRAEFIK_DASHBOARD_DOMAIN"
    echo -e "GitLab: http://$GITLAB_DOMAIN"
    echo -e "SonarQube: http://$SONARQUBE_DOMAIN"
    echo -e "Grafana: http://$GRAFANA_DOMAIN"
    echo -e "Prometheus: http://$PROMETHEUS_DOMAIN"
    echo -e "Loki: http://$LOKI_DOMAIN"
    echo -e "Alertmanager: http://$ALERTMANAGER_DOMAIN"
    echo -e "Portainer: http://$PORTAINER_DOMAIN"
    echo -e "Harbor: http://$HARBOR_DOMAIN"
    
    echo -e "\n${YELLOW}Default Credentials:${NC}"
    echo -e "See CREDENTIALS.md for all default passwords"
    echo -e "GitLab: root / $GITLAB_ROOT_PASSWORD"
    echo -e "SonarQube: admin / admin (change on first login)"
    echo -e "Grafana: $GRAFANA_ADMIN_USER / $GRAFANA_ADMIN_PASSWORD"
    echo -e "Traefik: admin / ChangeMe123!"
    
    echo -e "\n${YELLOW}Next Steps:${NC}"
    echo "1. Change all default passwords"
    echo "2. Configure GitLab CI/CD pipelines"
    echo "3. Set up monitoring dashboards in Grafana"
    echo "4. Configure backup schedules"
    
    echo -e "\n${GREEN}Setup completed successfully!${NC}"
}

# Main execution
main() {
    install_dependencies
    install_docker
    check_docker_compose
    configure_system
    prepare_harbor
    pull_docker_images
    start_services
    show_setup_info
}

# Run main function
main
