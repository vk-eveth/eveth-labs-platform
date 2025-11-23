#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$ROOT_DIR/.env"

# Create backup directory with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$ROOT_DIR/backups/$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

echo -e "${YELLOW}=== Starting Backup Process ===${NC}"
echo -e "Backup directory: $BACKUP_DIR"

# Function to handle errors
error_exit() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

# Backup PostgreSQL databases
echo -e "\n${YELLOW}Backing up PostgreSQL databases...${NC}"
PGPASSWORD=$POSTGRES_PASSWORD pg_dumpall -h localhost -U postgres > "$BACKUP_DIR/postgres_backup.sql" || error_exit "Failed to backup PostgreSQL"

# Backup Redis data
echo -e "${YELLOW}Backing up Redis data...${NC}"
docker exec redis redis-cli --rdb /data/dump.rdb --pass $REDIS_PASSWORD || error_exit "Failed to backup Redis"
docker cp redis:/data/dump.rdb "$BACKUP_DIR/redis_dump.rdb" || error_exit "Failed to copy Redis dump"

# Backup configuration files
echo -e "${YELLOW}Backing up configuration files...${NC}"
cp -r "$ROOT_DIR/config" "$BACKUP_DIR/" || error_exit "Failed to backup config files"

# Backup important data directories
echo -e "${YELLOW}Backing up data directories...${NC}"
for dir in "gitlab" "sonarqube" "grafana"; do
    echo "Backing up $dir..."
    tar -czf "$BACKUP_DIR/${dir}_data.tar.gz" -C "$ROOT_DIR/data" "$dir" || echo -e "${RED}Warning: Failed to backup $dir${NC}"
done

# Create a summary file
cat > "$BACKUP_DIR/backup_info.txt" << EOF
Backup Information
==================
Date: $(date)
Backup ID: $TIMESTAMP

Included Components:
- PostgreSQL databases
- Redis data
- Configuration files
- GitLab data
- SonarQube data
- Grafana data

To restore:
1. Stop all services: docker compose down
2. Restore PostgreSQL: psql -U postgres -f $BACKUP_DIR/postgres_backup.sql
3. Restore Redis: cp $BACKUP_DIR/redis_dump.rdb /path/to/redis/data/dump.rdb
4. Restore config: cp -r $BACKUP_DIR/config/* /path/to/config/
5. Restart services: docker compose up -d
EOF

# Create a compressed archive of the backup
echo -e "\n${YELLOW}Creating backup archive...${NC}"
tar -czf "$ROOT_DIR/backups/eveth-labs-backup-$TIMESTAMP.tar.gz" -C "$BACKUP_DIR" . || error_exit "Failed to create backup archive"

# Clean up temporary files
rm -rf "$BACKUP_DIR"

# Remove old backups (keep last 7 days)
find "$ROOT_DIR/backups" -name "eveth-labs-backup-*.tar.gz" -mtime +7 -delete

echo -e "\n${GREEN}Backup completed successfully!${NC}"
echo -e "Backup file: $ROOT_DIR/backups/eveth-labs-backup-$TIMESTAMP.tar.gz"

exit 0
