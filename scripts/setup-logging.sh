#!/bin/bash

set -e

# Create required directories
echo "Creating logging directories..."
mkdir -p ${DATA_PATH}/loki
mkdir -p ${CONFIG_PATH}/loki
mkdir -p ${CONFIG_PATH}/promtail

# Copy configuration files
echo "Copying configuration files..."
cp config/loki/loki-config.yaml ${CONFIG_PATH}/loki/
cp config/promtail/promtail-config.yaml ${CONFIG_PATH}/promtail/

# Update docker-compose.yml to use Loki logging for all services
echo "Updating docker-compose.yml to use Loki logging..."

# Add logging configuration to all services except loki and promtail
services_to_update=$(docker compose config --services | grep -vE '^(loki|promtail)$')

for service in $services_to_update; do
  # Check if the service already has a logging configuration
  if ! grep -q "logging:" docker-compose.yml | grep -A 5 "^  $service:"; then
    # Add logging configuration
    sed -i "/^  $service:/a \    logging:\n      driver: loki\n      options:\n        loki-url: \"http://loki:3100/loki/api/v1/push\"\n        loki-retries: \"5\"\n        loki-batch-size: \"400\"\n        loki-external-labels: \"container_name={{.Name}},image={{.ImageName}}\"" docker-compose.yml
  fi
done

echo "Logging setup completed successfully!"
echo "To start the logging stack, run: docker compose up -d loki promtail"
