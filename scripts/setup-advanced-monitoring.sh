#!/bin/bash

set -e

# Load environment variables
source .env

echo "🔧 Setting up Advanced Monitoring for Eveth Labs Platform..."

# Create directories for monitoring
mkdir -p ${DATA_PATH}/prometheus/data
mkdir -p ${DATA_PATH}/grafana/provisioning/datasources
mkdir -p ${DATA_PATH}/grafana/provisioning/dashboards
mkdir -p ${CONFIG_PATH}/prometheus
mkdir -p ${CONFIG_PATH}/grafana/dashboards

# Copy Prometheus configuration
cp config/monitoring/prometheus.yml ${CONFIG_PATH}/prometheus/
cp config/monitoring/recording.rules ${CONFIG_PATH}/prometheus/

# Create Grafana provisioning files
cat > ${CONFIG_PATH}/grafana/provisioning/datasources/prometheus.yml << 'EOL'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
    jsonData:
      timeInterval: "5s"
EOL

# Copy Grafana dashboards
cp config/monitoring/grafana-dashboards/*.json ${CONFIG_PATH}/grafana/dashboards/

# Create dashboard provider configuration
cat > ${CONFIG_PATH}/grafana/provisioning/dashboards/dashboard-provider.yml << 'EOL'
apiVersion: 1

providers:
  - name: 'Eveth Labs'
    orgId: 1
    folder: 'Eveth Labs'
    type: file
    disableDeletion: false
    editable: true
    options:
      path: /etc/grafana/provisioning/dashboards
EOL

# Update docker compose with monitoring services
cat >> docker-compose.override.yml << 'EOL'
  # Monitoring Stack
  prometheus:
    image: prom/prometheus:${PROMETHEUS_VERSION}
    container_name: prometheus
    restart: unless-stopped
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
      - '--storage.tsdb.retention.time=30d'
      - '--web.enable-lifecycle'
    volumes:
      - ${CONFIG_PATH}/prometheus:/etc/prometheus
      - ${DATA_PATH}/prometheus/data:/prometheus
    networks:
      - monitoring
      - traefik-public
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints: [node.role == manager]
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.prometheus.rule=Host(`prometheus.${DOMAIN}`)"
      - "traefik.http.routers.prometheus.entrypoints=websecure"
      - "traefik.http.routers.prometheus.tls.certresolver=letsencrypt"
      - "traefik.http.services.prometheus.loadbalancer.server.port=9090"

  grafana:
    image: grafana/grafana:${GRAFANA_VERSION}
    container_name: grafana
    restart: unless-stopped
    environment:
      - GF_SECURITY_ADMIN_USER=${GRAFANA_ADMIN_USER}
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_AUTH_ANONYMOUS_ENABLED=false
      - GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource
    volumes:
      - ${DATA_PATH}/grafana:/var/lib/grafana
      - ${CONFIG_PATH}/grafana/provisioning:/etc/grafana/provisioning
      - ${CONFIG_PATH}/grafana/dashboards:/etc/grafana/provisioning/dashboards
    networks:
      - monitoring
      - traefik-public
    depends_on:
      - prometheus
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints: [node.role == manager]
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.grafana.rule=Host(`grafana.${DOMAIN}`)"
      - "traefik.http.routers.grafana.entrypoints=websecure"
      - "traefik.http.routers.grafana.tls.certresolver=letsencrypt"
      - "traefik.http.services.grafana.loadbalancer.server.port=3000"

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    command:
      - '--path.rootfs=/host'
    network_mode: host
    pid: host
    volumes:
      - '/:/host:ro,rslave'
    deploy:
      mode: global
    labels:
      - "traefik.enable=false"

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    restart: unless-stopped
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    devices:
      - /dev/kmsg:/dev/kmsg
    deploy:
      mode: global
    networks:
      - monitoring
    labels:
      - "traefik.enable=false"

  alertmanager:
    image: prom/alertmanager:${ALERTMANAGER_VERSION}
    container_name: alertmanager
    restart: unless-stopped
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
    volumes:
      - ${CONFIG_PATH}/alertmanager:/etc/alertmanager
      - ${DATA_PATH}/alertmanager:/alertmanager
    networks:
      - monitoring
      - traefik-public
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints: [node.role == manager]
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.alertmanager.rule=Host(`alertmanager.${DOMAIN}`)"
      - "traefik.http.routers.alertmanager.entrypoints=websecure"
      - "traefik.http.routers.alertmanager.tls.certresolver=letsencrypt"
      - "traefik.http.services.alertmanager.loadbalancer.server.port=9093"

  blackbox-exporter:
    image: prom/blackbox-exporter:latest
    container_name: blackbox-exporter
    restart: unless-stopped
    command:
      - '--config.file=/etc/blackbox_exporter/blackbox.yml'
    volumes:
      - ${CONFIG_PATH}/blackbox:/etc/blackbox_exporter
    networks:
      - monitoring
    deploy:
      mode: global
    labels:
      - "traefik.enable=false"

networks:
  monitoring:
    driver: overlay
    attachable: true
EOL

# Add required environment variables to .env if they don't exist
if ! grep -q "GRAFANA_ADMIN_USER" .env; then
  echo "GRAFANA_ADMIN_USER=admin" >> .env
fi

if ! grep -q "GRAFANA_ADMIN_PASSWORD" .env; then
  GRAFANA_PASSWORD=$(openssl rand -base64 12)
  echo "GRAFANA_ADMIN_PASSWORD=${GRAFANA_PASSWORD}" >> .env
  echo "🔑 Generated Grafana admin password: ${GRAFANA_PASSWORD}"
  echo "   Please save this password in a secure location!"
fi

# Create blackbox configuration
mkdir -p ${CONFIG_PATH}/blackbox
cat > ${CONFIG_PATH}/blackbox/blackbox.yml << 'EOL'
modules:
  http_2xx:
    prober: http
    http:
      preferred_ip_protocol: "ip4"
      valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
      valid_status_codes: [200, 301, 302, 303, 307, 308]
      no_follow_redirects: false
      fail_if_ssl: false
      fail_if_not_ssl: false
      tls_config:
        insecure_skip_verify: true
      method: GET
      headers:
        Host: "example.com"
      fail_if_body_not_matches_regexp:
        - "up"

  tcp_connect:
    prober: tcp
    tcp:
      preferred_ip_protocol: "ip4"
      tls: true
      tls_config:
        insecure_skip_verify: true

  icmp:
    prober: icmp
    timeout: 5s
    icmp:
      preferred_ip_protocol: "ip4"
EOL

echo "✅ Advanced monitoring setup complete!"
echo ""
echo "🔍 Access the monitoring tools at:"
echo "   - Grafana: https://grafana.${DOMAIN}"
echo "   - Prometheus: https://prometheus.${DOMAIN}"
echo "   - Alertmanager: https://alertmanager.${DOMAIN}"
echo ""
echo "📝 Note: You may need to wait a few minutes for all services to start up."
echo "      The first login to Grafana will be with the credentials from .env"

# Restart services to apply changes
echo "🔄 Restarting services..."
docker compose up -d --remove-orphans

echo "✅ Done! Advanced monitoring is now set up and running."
