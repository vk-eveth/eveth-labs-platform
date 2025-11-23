#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$ROOT_DIR"

# Load env
if [ -f .env ]; then
  # shellcheck disable=SC1091
  source .env
fi

HARBOR_VERSION="${HARBOR_VERSION:-2.10.0}"
INSTALL_BASE="/opt/harbor"
INSTALL_DIR="${HARBOR_INSTALL_DIR:-$INSTALL_BASE/harbor}"
TARBALL="harbor-online-installer-v${HARBOR_VERSION}.tgz"
URL="https://github.com/goharbor/harbor/releases/download/v${HARBOR_VERSION}/${TARBALL}"

mkdir -p "$INSTALL_BASE"
cd "$INSTALL_BASE"

echo -e "${YELLOW}Preparing Harbor ${HARBOR_VERSION} at ${INSTALL_DIR}${NC}"

if [ ! -f "$TARBALL" ]; then
  echo -e "${YELLOW}Downloading ${TARBALL}...${NC}"
  wget -q "$URL" -O "$TARBALL"
fi

if [ ! -d "$INSTALL_DIR" ]; then
  echo -e "${YELLOW}Extracting installer...${NC}"
  tar -xzf "$TARBALL"
  # Extracts to ./harbor
  mv harbor "$INSTALL_DIR"
fi
# Generate harbor.yml from repo config
CONF_SRC="$ROOT_DIR/config/harbor/harbor.yml"
CONF_DST="$INSTALL_DIR/harbor.yml"
# Ensure Harbor data directory and export absolute path for prepare
HARBOR_DATA_DIR="$ROOT_DIR/${DATA_PATH:-./data}/harbor"
mkdir -p "$HARBOR_DATA_DIR"
# Resolve absolute host path (Linux)
HARBOR_DATA_VOLUME="$(readlink -f "$HARBOR_DATA_DIR")"
export HARBOR_DATA_VOLUME
if ! command -v envsubst >/dev/null 2>&1; then
  echo -e "${RED}envsubst not found. Install gettext-base.${NC}" >&2
  exit 1
fi
export HARBOR_DOMAIN HARBOR_ADMIN_PASSWORD HARBOR_DB_PASSWORD REDIS_PASSWORD HARBOR_DATA_VOLUME
# Strip default value syntax like ${VAR:-default} to ${VAR} so envsubst replaces them
TMP_CONF=$(mktemp)
sed -E 's/\$\{([A-Za-z_][A-Za-z0-9_]*)[:\-][^}]*\}/\$\{\1\}/g' "$CONF_SRC" > "$TMP_CONF"
envsubst < "$TMP_CONF" > "$CONF_DST"
rm -f "$TMP_CONF"

# Run prepare to generate common/config
cd "$INSTALL_DIR"
chmod +x prepare || true
./prepare --with-trivy

echo -e "${GREEN}Harbor configuration prepared under ${INSTALL_DIR}/common/config${NC}"
