# Troubleshooting Guide

This guide provides solutions to common issues you might encounter with the Eveth Labs Platform.

## Table of Contents
1. [Common Issues](#common-issues)
2. [Service-Specific Issues](#service-specific-issues)
3. [Networking Issues](#networking-issues)
4. [Performance Issues](#performance-issues)
5. [Recovery Procedures](#recovery-procedures)
6. [Getting Help](#getting-help)

## Common Issues

### 1. Services Not Starting

#### Symptoms
- Containers exit immediately after starting
- Error messages in logs
- Port conflicts

#### Solutions
```bash
# Check container logs
docker logs <container_name>

# Check for port conflicts
sudo lsof -i :<port>

# Check container status
docker ps -a

# View service logs
docker compose logs <service_name>
```

### 2. Docker Daemon Issues

#### Symptoms
- "Cannot connect to the Docker daemon"
- Permission denied errors
- Docker service not starting

#### Solutions
```bash
# Check Docker service status
sudo systemctl status docker

# Restart Docker service
sudo systemctl restart docker

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Check Docker daemon logs
journalctl -u docker.service -n 50 --no-pager
```

### 3. Disk Space Issues

#### Symptoms
- "No space left on device" errors
- Containers failing to start
- High disk usage

#### Solutions
```bash
# Check disk usage
df -h

# Find large files
sudo du -h --max-depth=1 / | sort -hr

# Clean up Docker resources
# Remove stopped containers
docker container prune -f

# Remove unused images
docker image prune -a -f

# Remove unused volumes
docker volume prune -f

# Remove build cache
docker builder prune -f
```

## Service-Specific Issues

### GitLab

#### GitLab Container Restarting
```bash
# Check logs
docker logs gitlab

# Check disk space
df -h

# Check for database issues
docker exec -it gitlab gitlab-rake gitlab:check

# Reconfigure GitLab
docker exec -it gitlab gitlab-ctl reconfigure
```

#### GitLab CI/CD Pipeline Failures
```bash
# View pipeline logs
docker logs gitlab-runner

# Check runner status
docker exec -it gitlab-runner gitlab-runner status

# Register new runner
docker exec -it gitlab-runner gitlab-runner register
```

### Harbor

#### Harbor Container Issues
```bash
# Check logs
docker compose logs -f harbor-core

# Check Harbor API health via Traefik route (localhost dev)
curl -s http://harbor.evethlabstech/api/v2.0/health | jq '.'

# If using Harbor's own docker-compose, check containers:
docker ps | grep harbor
```

#### Login Issues
```bash
# Check if service is running
docker ps | grep harbor

# Check network connectivity to Harbor via HTTP
curl -I http://harbor.evethlabstech/api/v2.0/health

# Reset admin password
docker exec -it harbor-core /bin/sh -c "cd /harbor && ./harbor/core/main -c /etc/core/app.conf --reset-clair-admin-password"
```

### Prometheus/Grafana

#### Prometheus Not Scraping
```bash
# Check targets
curl http://localhost:9090/api/v1/targets | jq .

# Check service discovery
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health!="up")'

# Check Prometheus logs
docker logs prometheus
```

#### Grafana Login Issues
```bash
# Reset admin password
docker exec -it grafana grafana-cli admin reset-admin-password admin

# Check logs
docker logs grafana
```

## Networking Issues

### 1. Container Communication

#### Symptoms
- Containers can't reach each other
- DNS resolution failures
- Connection timeouts

#### Solutions
```bash
# Check network configuration
docker network ls
docker network inspect <network_name>

# Test connectivity between containers
docker exec -it <container1> ping <container2_ip>

# Check DNS resolution
docker exec -it <container> nslookup <service_name>

# Inspect container network
docker inspect <container> | grep -i network
```

### 2. Port Conflicts

#### Symptoms
- "Address already in use" errors
- Services not accessible
- Connection refused errors

#### Solutions
```bash
# Find process using a port
sudo lsof -i :<port>
sudo netstat -tulpn | grep :<port>

# Kill process (if safe to do so)
sudo kill -9 <pid>

# Change service port in docker-compose.yml
services:
  service_name:
    ports:
      - "8080:80"  # Change to unused port
```

## Performance Issues

### 1. High CPU Usage

#### Symptoms
- Slow response times
- System becomes unresponsive
- High CPU usage in monitoring

#### Solutions
```bash
# Find processes using most CPU
top -o %CPU

# Check container resource usage
docker stats

# Limit container resources in docker-compose.yml
services:
  service_name:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
```

### 2. Memory Issues

#### Symptoms
- "Out of Memory" errors
- Containers being killed
- High swap usage

#### Solutions
```bash
# Check memory usage
free -m

# Check container memory limits
docker stats --no-stream

# Adjust memory limits in docker-compose.yml
services:
  service_name:
    deploy:
      resources:
        limits:
          memory: 4G
        reservations:
          memory: 2G
```

## Recovery Procedures

### 1. Failed Deployment

#### Steps to Recover
1. Roll back to previous version
   ```bash
   git checkout <previous_commit>
   docker compose down
   docker compose up -d
   ```

2. Check logs for errors
   ```bash
   docker compose logs -f
   ```

3. Fix issues and redeploy
   ```bash
   # After fixing issues
git pull
docker compose build --no-cache
docker compose up -d
   ```

### 2. Database Recovery

#### PostgreSQL
```bash
# Create backup
PGPASSWORD=$POSTGRES_PASSWORD pg_dump -h localhost -U postgres -d dbname > backup.sql

# Restore from backup
PGPASSWORD=$POSTGRES_PASSWORD psql -h localhost -U postgres -d dbname < backup.sql

# Point-in-time recovery (if configured)
# 1. Stop PostgreSQL
# 2. Configure recovery.conf
# 3. Create recovery.signal file
# 4. Start PostgreSQL
```

#### Redis
```bash
# Create RDB backup
redis-cli SAVE
cp /var/lib/redis/dump.rdb /backup/redis_$(date +%Y%m%d).rdb

# Restore from RDB
# 1. Stop Redis
# 2. Replace dump.rdb
# 3. Start Redis
```

## Getting Help

### 1. Collecting Diagnostic Information

#### System Information
```bash
# Docker version
docker version
docker info

# System information
uname -a
lsb_release -a
free -m
df -h
```

#### Service Logs
```bash
# Get all service logs
docker compose logs --tail=1000 > logs.txt

# Get specific service logs
docker logs --tail=1000 <container_name> > service_logs.txt
```

### 2. Opening an Issue
When opening an issue, please include:
1. Description of the problem
2. Steps to reproduce
3. Expected vs actual behavior
4. Relevant logs and configuration
5. Environment details

### 3. Community Support
- [GitLab Issue Tracker](https://gitlab.com/gitlab-org/gitlab/-/issues)
- [Harbor Community](https://goharbor.io/community/)
- [Docker Forums](https://forums.docker.com/)

## Additional Resources

### Documentation
- [Docker Documentation](https://docs.docker.com/)
- [GitLab Documentation](https://docs.gitlab.com/)
- [Harbor Documentation](https://goharbor.io/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

### Monitoring Commands
```bash
# View running processes
top
htop

# Monitor disk I/O
iotop

# Monitor network traffic
iftop

# Check open files
lsof -i -P -n | grep LISTEN
```

### Maintenance Commands
```bash
# Update all containers
docker compose pull
docker compose up -d

# Clean up unused resources
docker system prune -a --volumes

# Check container resource usage
docker stats

# View disk usage by container
docker system df
```

Remember to always back up your data before making significant changes to your system.
