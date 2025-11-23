# Operations Guide

This guide covers the day-to-day operations of the Eveth Labs Platform.

## Table of Contents
1. [System Administration](#system-administration)
2. [User Management](#user-management)
3. [Performance Tuning](#performance-tuning)
4. [Maintenance Procedures](#maintenance-procedures)
5. [Scaling](#scaling)
6. [Updates & Upgrades](#updates--upgrades)
7. [Monitoring & Alerts](#monitoring--alerts)
8. [Troubleshooting](#troubleshooting)

## System Administration

### Prerequisites
- SSH access to the server
- Administrator privileges
- Backup of critical data

### Accessing the System

#### SSH Access
```bash
ssh admin@your-server-ip
```

#### Docker Commands
```bash
# List all containers
docker ps -a

# View logs
docker logs <container_name>

# Execute commands in a container
docker exec -it <container_name> /bin/bash
```

#### System Monitoring
```bash
# View system resources
top
htop

# Disk usage
df -h

# Memory usage
free -m
```

## User Management

### Adding a New User
```bash
# Create a new user
sudo adduser username

# Add to docker group
sudo usermod -aG docker username

# Set up SSH access
sudo mkdir -p /home/username/.ssh
sudo nano /home/username/.ssh/authorized_keys
sudo chown -R username:username /home/username/.ssh
sudo chmod 700 /home/username/.ssh
sudo chmod 600 /home/username/.ssh/authorized_keys
```

### Managing Permissions
```bash
# View current user's groups
groups username

# Add user to a group
sudo usermod -aG groupname username

# Remove user from a group
sudo deluser username groupname
```

### Service Accounts
```bash
# Create a service account
sudo useradd -r -s /bin/false service-account

# Set appropriate permissions
sudo chown -R service-account:service-account /path/to/service/directory
```

## Performance Tuning

### Database Tuning

#### PostgreSQL
```sql
-- Check current settings
SELECT name, setting, unit, context FROM pg_settings 
WHERE name IN ('shared_buffers', 'work_mem', 'maintenance_work_mem', 'effective_cache_size');

-- Update configuration
ALTER SYSTEM SET shared_buffers = '4GB';
ALTER SYSTEM SET work_mem = '32MB';
ALTER SYSTEM SET maintenance_work_mem = '1GB';
```

#### Redis
```bash
# Redis configuration
maxmemory 2gb
maxmemory-policy allkeys-lru
```

### Web Server Tuning

#### Nginx
```nginx
worker_processes auto;
worker_connections 1024;
keepalive_timeout 65;
client_max_body_size 100M;
```

#### Traefik
```yaml
# traefik.yml
api:
  dashboard: true
  debug: true

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: ":443"

providers:
  docker:
    watch: true
    exposedByDefault: false

log:
  level: INFO

accessLog: {}

certificatesResolvers:
  myresolver:
    acme:
      email: your-email@example.com
      storage: acme.json
      httpChallenge:
        entryPoint: web
```

## Maintenance Procedures

### Regular Maintenance Tasks

#### Daily
- Check system logs
- Verify backups
- Monitor disk space
- Review security alerts

#### Weekly
- Apply security updates
- Clean up old logs
- Review user accounts
- Test backup restoration

#### Monthly
- Review system performance
- Update documentation
- Rotate encryption keys
- Audit system access

### Log Rotation

#### Logrotate Configuration
```bash
# /etc/logrotate.d/eveth
/var/log/eveth/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 root adm
    sharedscripts
    postrotate
        docker kill -s USR1 $(docker ps -q --filter name=traefik)
    endscript
}
```

## Scaling

### Horizontal Scaling

#### Docker Swarm
```bash
# Add a worker node
docker swarm join --token <token> <manager-ip>:2377

# Scale a service
docker service scale web=5

# Update service resources
docker service update \
  --limit-cpu 2 \
  --limit-memory 2G \
  --reserve-cpu 1 \
  --reserve-memory 1G \
  web
```

### Vertical Scaling

#### Database Scaling
```yaml
# docker-compose.override.yml
services:
  postgres:
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G
        reservations:
          cpus: '2'
          memory: 4G
```

## Updates & Upgrades

### Minor Updates
```bash
# Pull latest images
docker compose pull

# Restart services
docker compose up -d
```

### Major Upgrades
1. **Preparation**
   - Review release notes
   - Test in staging
   - Backup all data

2. **Upgrade Process**
   ```bash
   # Stop services
docker compose down

   # Update configuration files
   git pull origin main

   # Start updated services
   docker compose up -d --build
   ```

3. **Verification**
   - Check service status
   - Run smoke tests
   - Verify data integrity

## Monitoring & Alerts

### Key Metrics to Monitor

#### System Metrics
- CPU usage
- Memory usage
- Disk I/O
- Network traffic

#### Application Metrics
- Request rate
- Error rate
- Response time
- Queue length

#### Database Metrics
- Connection count
- Query performance
- Replication lag
- Cache hit ratio

### Alerting Rules

#### Prometheus Alerts
```yaml
# alerts/rules.yml
groups:
- name: node.rules
  rules:
  - alert: HighNodeCPU
    expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100 > 80
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "High CPU usage on {{ $labels.instance }}"
      description: "CPU usage is {{ $value }}%"
```

## Troubleshooting

### Common Issues

#### Service Not Starting
```bash
# Check container logs
docker logs <container_name>

# Check service status
docker service ps <service_name>

# Check for port conflicts
netstat -tuln | grep <port>
```

#### High Resource Usage
```bash
# Top processes by CPU
top -o %CPU

# Top processes by memory
top -o %MEM

# Check for disk I/O
iotop
```

#### Network Issues
```bash
# Check network connectivity
ping <host>
traceroute <host>

# Check DNS resolution
dig <hostname>
nslookup <hostname>

# Check open connections
netstat -tuln
ss -tuln
```

### Recovery Procedures

#### Failed Deployment
1. **Rollback**
   ```bash
   # Rollback to previous version
   git checkout <previous_commit>
   docker compose up -d
   ```

2. **Investigate**
   - Check deployment logs
   - Review recent changes
   - Test in staging

#### Data Corruption
1. **Identify**
   - Check application logs
   - Run integrity checks
   - Identify affected data

2. **Recover**
   ```bash
   # Restore from backup
   ./scripts/restore/restore.sh --backup=backup_20231001
   ```

### Performance Issues

#### Slow Queries
```sql
-- Find slow queries
SELECT query, total_exec_time, calls, mean_exec_time
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;

-- Check for locks
SELECT blocked_locks.pid AS blocked_pid,
       blocked_activity.usename AS blocked_user,
       blocking_locks.pid AS blocking_pid,
       blocking_activity.usename AS blocking_user,
       blocked_activity.query AS blocked_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity 
  ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks 
  ON blocking_locks.locktype = blocked_locks.locktype
  AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE
  AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
  AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
  AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
  AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
  AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
  AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
  AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
  AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
  AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity 
  ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.GRANTED;
```

#### Memory Leaks
```bash
# Check container memory usage
docker stats

# Check memory usage by process
top -o %MEM

# Check for memory leaks in Java applications
jmap -histo:live <pid> | head -20
```

### Disaster Recovery

#### Complete System Failure
1. **Recovery Steps**
   - Provision new infrastructure
   - Restore from backups
   - Verify data integrity
   - Update DNS/load balancers

2. **Verification**
   - Run smoke tests
   - Check application logs
   - Monitor system metrics

For more detailed troubleshooting, see the [Troubleshooting Guide](/docs/troubleshooting/README.md).
