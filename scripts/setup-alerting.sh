#!/bin/bash

set -e

# Create required directories
echo "Creating alerting directories..."
mkdir -p ${DATA_PATH}/alertmanager

# Copy configuration files
echo "Copying configuration files..."
cp config/alertmanager/alertmanager.yml ${CONFIG_PATH}/alertmanager/
cp config/prometheus/alert.rules ${CONFIG_PATH}/prometheus/

# Set proper permissions
echo "Setting permissions..."
chmod -R 755 ${DATA_PATH}/alertmanager
chmod 644 ${CONFIG_PATH}/alertmanager/alertmanager.yml
chmod 644 ${CONFIG_PATH}/prometheus/alert.rules

# Reload Prometheus configuration
echo "Reloading Prometheus configuration..."
if docker ps | grep -q prometheus; then
    docker compose exec -T prometheus wget --post-data '' http://localhost:9090/-/reload || true
fi

echo "Alerting setup completed successfully!"
echo ""
echo "To access Alertmanager UI, visit: https://alertmanager.${DOMAIN}"
echo "To access Prometheus alerts, visit: https://${PROMETHEUS_DOMAIN}/alerts"
echo ""
echo "Make sure to update the email configuration in ${CONFIG_PATH}/alertmanager/alertmanager.yml"
