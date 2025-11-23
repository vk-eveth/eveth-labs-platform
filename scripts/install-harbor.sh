#!/usr/bin/env bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$ROOT_DIR"

# Load environment
if [ -f .env ]; then
  # shellcheck disable=SC1091
  source .env
fi

HARBOR_VERSION="${HARBOR_VERSION:-2.10.0}"
INSTALL_DIR="/opt/harbor"
TARBALL="harbor-online-installer-v${HARBOR_VERSION}.tgz"
DOWNLOAD_URL="https://github.com/goharbor/harbor/releases/download/v${HARBOR_VERSION}/${TARBALL}"

echo -e "${YELLOW}Preparing Harbor installation (v${HARBOR_VERSION})...${NC}"

# Basic checks
if ! command -v docker >/dev/null 2>&1; then
  echo -e "${RED}Docker is required but not installed.${NC}" >&2
  exit 1
fi

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# If Harbor appears running, skip
if docker ps --format '{{.Names}}' | grep -Eq '^(harbor-core|nginx)$'; then
  echo -e "${GREEN}Harbor appears to be running. Skipping install.${NC}"
  exit 0
fi

# Download installer if not present
if [ ! -f "$TARBALL" ]; then
  echo -e "${YELLOW}Downloading Harbor installer from ${DOWNLOAD_URL}...${NC}"
  wget -q "$DOWNLOAD_URL" -O "$TARBALL"
fi

# Extract installer
if [ ! -d "harbor" ]; then
  echo -e "${YELLOW}Extracting installer...${NC}"
  tar -xzf "$TARBALL"
fi

cd "$INSTALL_DIR/harbor"

# Generate harbor.yml from repository config with environment substitution
if ! command -v envsubst >/dev/null 2>&1; then
  echo -e "${RED}envsubst is required (package: gettext-base). Please install it and re-run.${NC}" >&2
  exit 1
fi

if [ ! -f "$ROOT_DIR/config/harbor/harbor.yml" ]; then
  echo -e "${RED}Missing $ROOT_DIR/config/harbor/harbor.yml${NC}" >&2
  exit 1
fi

# Substitute key environment variables
export HARBOR_DOMAIN HARBOR_ADMIN_PASSWORD HARBOR_DB_PASSWORD
envsubst < "$ROOT_DIR/config/harbor/harbor.yml" > "$INSTALL_DIR/harbor/harbor.yml"

# Run Harbor install with Trivy
echo -e "${YELLOW}Running Harbor installer... (this may take several minutes)${NC}"
./install.sh --with-trivy

# Verify
sleep 5
if docker ps --format '{{.Names}}' | grep -q '^nginx$'; then
  echo -e "${GREEN}Harbor installed and running at http://${HARBOR_DOMAIN:-harbor.evethlabstech}${NC}"
else
  echo -e "${RED}Harbor installation completed but nginx container not detected. Check logs under /var/log/harbor.${NC}"
fi
