#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
source "$ROOT_DIR/.env"

echo -e "${YELLOW}=== Eveth Labs Platform Health Check ===${NC}"
echo -e "Timestamp: $(date)"
echo -e "Hostname: $(hostname -f)"
echo -e "\n${YELLOW}=== System Resources ===${NC}"

# System resources
echo -e "\n${YELLOW}CPU Usage:${NC}"
top -bn1 | head -n 5 | tail -n 3

echo -e "\n${YELLOW}Memory Usage:${NC}"
free -h

echo -e "\n${YELLOW}Disk Usage:${NC}"
df -h | grep -v '^tmpfs\|^udev\|^overlay\|^/dev/loop'

# Docker status
echo -e "\n${YELLOW}=== Docker Status ===${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -n 1
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -v "NAMES"

# Service health checks
echo -e "\n${YELLOW}=== Service Health ===${NC}"

check_http() {
    local name=$1
    local url=$2
    local status_code=$(curl -s -o /dev/null -w "%{http_code}" -k $url)
    
    if [[ $status_code -ge 200 && $status_code -lt 400 ]]; then
        echo -e "${GREEN}✓ $name is running (HTTP $status_code)${NC}"
        return 0
    else
        echo -e "${RED}✗ $name is not responding (HTTP $status_code)${NC}"
        return 1
    fi
}

# Check services
check_http "Traefik Dashboard" "http://$TRAEFIK_DASHBOARD_DOMAIN"
check_http "GitLab" "http://$GITLAB_DOMAIN"
check_http "SonarQube" "http://$SONARQUBE_DOMAIN"
check_http "Grafana" "http://$GRAFANA_DOMAIN"
check_http "Prometheus" "http://$PROMETHEUS_DOMAIN"
check_http "Loki" "http://$LOKI_DOMAIN"
check_http "Alertmanager" "http://$ALERTMANAGER_DOMAIN"
check_http "Portainer" "http://$PORTAINER_DOMAIN"
check_http "Harbor" "http://$HARBOR_DOMAIN"

# Check Docker containers
check_container() {
    local container=$1
    if docker ps | grep -q $container; then
        echo -e "${GREEN}✓ Container $container is running${NC}"
        return 0
    else
        echo -e "${RED}✗ Container $container is not running${NC}"
        return 1
    fi
}

echo -e "\n${YELLOW}=== Container Status ===${NC}"
check_container "traefik"
check_container "gitlab"
check_container "sonarqube-db"
check_container "redis"
check_container "sonarqube"
check_container "prometheus"
check_container "grafana"
check_container "loki"
check_container "alertmanager"
check_container "portainer"
check_container "harbor-log"
check_container "harbor-db"
check_container "harbor-registry"
check_container "harbor-registryctl"
check_container "harbor-core"
check_container "harbor-portal"
check_container "harbor-jobservice"
check_container "harbor-trivy"
check_container "harbor-nginx"

# Check disk space
echo -e "\n${YELLOW}=== Disk Space Check ===${NC}"
for dir in $(find $ROOT_DIR/data -type d -maxdepth 1); do
    size=$(du -sh $dir 2>/dev/null | cut -f1)
    echo "$dir: $size"
done

# Check for updates
echo -e "\n${YELLOW}=== Update Check ===${NC}"
echo "Checking for container updates..."
docker compose pull --dry-run | grep -v "Image is up to date" || echo "All containers are up to date."

echo -e "\n${YELLOW}=== Health Check Complete ===${NC}"
