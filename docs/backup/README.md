# Backup & Recovery Guide

This guide covers backup and recovery procedures for the Eveth Labs Platform.

## Table of Contents
1. [Backup Strategy](#backup-strategy)
2. [Automated Backups](#automated-backups)
3. [Manual Backups](#manual-backups)
4. [Restoration Procedures](#restoration-procedures)
5. [Disaster Recovery](#disaster-recovery)
6. [Testing Backups](#testing-backups)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

## Backup Strategy

### Backup Scope

| Data Type | Frequency | Retention | Location |
|-----------|-----------|-----------|----------|
| Databases | Hourly | 7 days | Local + S3 |
| Volumes | Daily | 30 days | Local + S3 |
| Configuration | Daily | 90 days | Git + S3 |
| Container Images | On push | 30 days | Harbor |
| Git Repositories | Daily | 90 days | S3 |

### Backup Locations
- **Primary**: Local storage (`/backups`)
- **Secondary**: S3-compatible storage
- **Tertiary**: Offsite storage (tape/cloud)

## Automated Backups

### Backup Script

The main backup script is located at `scripts/backup/backup.sh`.

#### Key Features
- Database dumps (PostgreSQL, Redis)
- Volume snapshots
- Configuration backups
- Log rotation
- Integrity checks

#### Configuration
Edit `.env` to configure backup settings:

```ini
# Backup configuration
BACKUP_DIR=/backups
BACKUP_RETENTION_DAYS=30
BACKUP_ENCRYPTION_KEY=your-encryption-key

# Database settings
POSTGRES_PASSWORD=your-postgres-password
REDIS_PASSWORD=your-redis-password

# S3 settings (optional)
S3_BUCKET=your-bucket-name
S3_ENDPOINT=https://s3.example.com
S3_ACCESS_KEY=your-access-key
S3_SECRET_KEY=your-secret-key
```

#### Schedule with Cron
```bash
# Edit crontab
crontab -e

# Add this line for daily backups at 2 AM
0 2 * * * /path/to/eveth-labs-platform/scripts/backup/backup.sh >> /var/log/backup.log 2>&1
```

## Manual Backups

### Full System Backup
```bash
# Run the backup script manually
./scripts/backup/backup.sh

# Verify backup was created
ls -lh /backups/
```

### Database Backup

#### PostgreSQL
```bash
# Single database
PGPASSWORD=$POSTGRES_PASSWORD pg_dump -h postgres -U postgres -d gitlab > gitlab_backup_$(date +%Y%m%d).sql

# All databases
PGPASSWORD=$POSTGRES_PASSWORD pg_dumpall -h postgres -U postgres > all_databases_$(date +%Y%m%d).sql
```

#### Redis
```bash
# Create a dump.rdb file
redis-cli -a $REDIS_PASSWORD SAVE
cp /var/lib/redis/dump.rdb redis_backup_$(date +%Y%m%d).rdb
```

### Volume Backup
```bash
# Create a backup of all volumes
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  -v /backups:/backups \
  alpine sh -c "apk add --no-cache tar && \
  for volume in $(docker volume ls -q); do \
    docker run --rm -v $volume:/volume -v /backups:/backups \
      alpine tar -czf /backups/${volume}_$(date +%Y%m%d).tar.gz -C /volume ./; \
  done"
```

## Restoration Procedures

### Full System Restore

1. **Stop Services**
   ```bash
   docker compose down
   ```

2. **Restore Volumes**
   ```bash
   # For each volume
   docker run --rm -v volume_name:/target -v /backups:/backup \
     alpine sh -c "rm -rf /target/* && tar -xzf /backup/volume_name_20231001.tar.gz -C /target"
   ```

3. **Restore Databases**
   ```bash
   # PostgreSQL
   PGPASSWORD=$POSTGRES_PASSWORD psql -h postgres -U postgres -d gitlab < gitlab_backup_20231001.sql
   
   # Redis
   cp redis_backup_20231001.rdb /var/lib/redis/dump.rdb
   chown redis:redis /var/lib/redis/dump.rdb
   ```

4. **Start Services**
   ```bash
   docker compose up -d
   ```

### Partial Restore

#### Single Database
```bash
# Restore a single database
PGPASSWORD=$POSTGRES_PASSWORD dropdb -h postgres -U postgres dbname
PGPASSWORD=$POSTGRES_PASSWORD createdb -h postgres -U postgres dbname
PGPASSWORD=$POSTGRES_PASSWORD psql -h postgres -U postgres -d dbname < db_backup.sql
```

#### Single File from Volume
```bash
# Extract a single file from volume backup
tar -xzf volume_backup.tar.gz path/to/file -C /tmp
```

## Disaster Recovery

### Recovery Time Objective (RTO)
- **Critical Systems**: 1 hour
- **Non-Critical Systems**: 4 hours

### Recovery Point Objective (RPO)
- **Databases**: 5 minutes
- **File Storage**: 24 hours

### Recovery Procedures

#### Complete System Failure
1. **Provision New Infrastructure**
   - Spin up new VMs/containers
   - Install Docker and dependencies

2. **Restore from Backup**
   ```bash
   # Clone the repository
   git clone <repository-url>
   cd eveth-labs-platform
   
   # Restore latest backup archive manually per 'Restoration Procedures'
   # 1) Extract the latest archive from ./backups
   # 2) Restore PostgreSQL/Redis and files as described above
   ```

3. **Verify and Test**
   - Check service status
   - Run smoke tests
   - Validate data integrity

#### Data Corruption
1. **Identify Affected Systems**
   - Check logs and monitoring
   - Determine scope of corruption

2. **Restore Affected Components**
   ```bash
   # Example: Restore PostgreSQL database (gitlab)
   PGPASSWORD=$POSTGRES_PASSWORD psql -h postgres -U postgres -d gitlab < gitlab_20231001.sql
   ```

3. **Verify Data**
   - Run data validation scripts
   - Check application logs

## Testing Backups

### Automated Testing
```bash
# Validate the most recent backup archive
LATEST=$(ls -t backups/eveth-labs-backup-*.tar.gz 2>/dev/null | head -1)
if [ -n "$LATEST" ]; then
  tar -tzf "$LATEST" >/dev/null && echo "[OK] Backup archive is valid: $LATEST" || echo "[ERROR] Invalid backup archive: $LATEST"
else
  echo "[ERROR] No backup archives found in ./backups"
fi
```

### Manual Testing
1. **Create Test Environment**
   ```bash
   # Create a test namespace
   kubectl create namespace backup-test
   ```

2. **Restore to Test Environment**
   ```bash
   # Restore backup to test environment
   ./scripts/restore/restore.sh --namespace=backup-test --backup=backup_20231001
   ```

3. **Run Tests**
   ```bash
   # Run integration tests
   ./scripts/test/integration.sh --namespace=backup-test
   ```

## Best Practices

### Backup Strategy
1. **3-2-1 Rule**
   - 3 copies of your data
   - 2 different media types
   - 1 offsite copy

2. **Encryption**
   - Encrypt backups at rest and in transit
   - Use strong encryption keys
   - Rotate keys regularly

3. **Monitoring**
   - Monitor backup jobs
   - Set up alerts for failures
   - Log all backup activities

### Storage Considerations
1. **Local Storage**
   - Fast access for restores
   - Limited capacity
   - Vulnerable to local failures

2. **Cloud Storage**
   - Highly available
   - Scalable
   - Cost-effective for long-term storage

3. **Offline Storage**
   - Protection against cyber attacks
   - Long-term archival
   - Slower recovery times

### Security
1. **Access Control**
   - Restrict backup access
   - Use least privilege principle
   - Audit access logs

2. **Encryption**
   - Use strong encryption (AES-256)
   - Manage encryption keys securely
   - Rotate keys periodically

3. **Testing**
   - Test restores regularly
   - Document recovery procedures
   - Train staff on recovery processes

## Troubleshooting

### Common Issues

1. **Backup Fails**
   ```bash
   # Check logs
   journalctl -u backup.service
   
   # Check disk space
   df -h
   
   # Check permissions
   ls -la /backups/
   ```

2. **Restore Fails**
   ```bash
   # Check backup integrity
   gzip -t backup_file.tar.gz
   
   # Check database compatibility
   pg_restore --version
   psql --version
   ```

3. **Slow Backups**
   ```bash
   # Check system resources
   top
   iotop
   
   # Check network bandwidth
   iftop
   
   # Check disk I/O
   iostat -x 1
   ```

### Recovery Scenarios

#### Corrupted Database
```bash
# Stop the database service
docker compose stop postgres

# Restore from backup
PGPASSWORD=$POSTGRES_PASSWORD psql -h localhost -U postgres -d gitlab < backup.sql

# Start the service
docker compose start postgres
```

#### Deleted Files
```bash
# Find the file in the most recent backup
find /backups -name "*$(date +%Y%m%d)*" -type f -exec ls -la {} \;

# Restore the file
tar -xzf /backups/volume_backup_20231001.tar.gz -C /tmp path/to/lost/file
cp /tmp/path/to/lost/file /original/location/
```

### Monitoring and Alerts

#### Backup Monitoring
```bash
# Check last backup time
find /backups -type f -name "*.tar.gz" -printf '%T@ %p\n' | sort -n | tail -1

# Check backup size
du -sh /backups/* | sort -hr

# Check for failed backups
grep -i "error\|failed" /var/log/backup.log
```

### Backup Validation

#### Automated Validation Script
```bash
#!/bin/bash

# Check if backup file exists
if [ ! -f "$1" ]; then
    echo "[ERROR] Backup file not found: $1"
    exit 1
fi

# Check if backup is not empty
if [ ! -s "$1" ]; then
    echo "[ERROR] Backup file is empty: $1"
    exit 1
fi

# Check if backup is a valid tar.gz file
if ! tar -tzf "$1" >/dev/null 2>&1; then
    echo "[ERROR] Invalid backup file (not a valid tar.gz): $1"
    exit 1
fi

echo "[OK] Backup file is valid: $1"
```

For more detailed troubleshooting, see the [Troubleshooting Guide](/docs/troubleshooting/README.md).
