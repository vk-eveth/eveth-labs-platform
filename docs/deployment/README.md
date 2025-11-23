# Deployment Guide

This guide covers the deployment of the Eveth Labs Platform in various environments.

## Table of Contents
1. [Deployment Types](#deployment-types)
2. [Single-Node Deployment](#single-node-deployment)
3. [High-Availability Deployment](#high-availability-deployment)
4. [Scaling Services](#scaling-services)
5. [Blue-Green Deployment](#blue-green-deployment)
6. [Rolling Updates](#rolling-updates)
7. [Deployment Strategies](#deployment-strategies)
8. [Troubleshooting](#troubleshooting)

## Deployment Types

### Development
- Single node
- All services co-located
- Debugging enabled
- No high availability

### Staging
- Mirrors production
- Limited resources
- Testing environment
- Pre-production validation

### Production
- High availability
- Separate environments
- Monitoring and alerting
- Backup and recovery

## Single-Node Deployment

### Prerequisites
- Docker 20.10+
- Docker Compose 2.0+
- 4+ CPU cores
- 16GB+ RAM
- 200GB+ storage

### Steps
1. Clone the repository
   ```bash
   git clone <repository-url>
   cd eveth-labs-platform
   ```

2. Configure environment
   ```bash
   nano .env  # Update configuration
   ```

3. Deploy the platform
   ```bash
   sudo ./setup-platform.sh
   ```

4. Verify deployment
   ```bash
   docker ps
   docker compose ps
   ```

## High-Availability Deployment

### Prerequisites
- 3+ nodes (1 manager, 2+ workers)
- Shared storage (NFS/GlusterFS)
- Load balancer
- 8+ CPU cores per node
- 32GB+ RAM per node
- 500GB+ storage per node

### Steps
1. Initialize Docker Swarm
   ```bash
   # On manager node
   docker swarm init --advertise-addr <MANAGER_IP>
   
   # On worker nodes
   docker swarm join --token <TOKEN> <MANAGER_IP>:2377
   ```

2. Deploy the stack
   ```bash
   # On manager node
   docker stack deploy -c docker-compose.yml -c docker-compose.prod.yml eveth
   ```

3. Verify the deployment
   ```bash
   docker node ls
   docker service ls
   ```

## Scaling Services

### Horizontal Scaling
Scale stateless services:
```bash
# Scale GitLab to 3 instances
docker service scale eveth_gitlab=3

# Scale API service to 5 instances
docker service scale eveth_api=5
```

### Vertical Scaling
Update resource limits in `docker-compose.override.yml`:
```yaml
services:
  gitlab:
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G
```

## Blue-Green Deployment

1. Deploy new version with new stack
   ```bash
   docker stack deploy -c docker-compose.v2.yml eveth-v2
   ```

2. Test the new deployment
   ```bash
   curl -I https://v2.evethlabs.local/health
   ```

3. Switch traffic
   ```bash
   # Update DNS or load balancer to point to new stack
   ```

4. Remove old deployment
   ```bash
   docker stack rm eveth-v1
   ```

## Rolling Updates

Configure update strategy in `docker-compose.yml`:
```yaml
services:
  web:
    image: nginx:latest
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
        order: start-first
      rollback_config:
        parallelism: 0
        order: stop-first
```

## Deployment Strategies

### Canary Releases
1. Deploy new version to a subset of users
2. Monitor metrics and logs
3. Gradually increase traffic
4. Roll back if issues detected

### A/B Testing
1. Deploy multiple versions
2. Split traffic between versions
3. Compare metrics
4. Select winning version

## Zero-Downtime Deployments

1. Use health checks
   ```yaml
   healthcheck:
     test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
     interval: 30s
     timeout: 10s
     retries: 3
     start_period: 5s
   ```

2. Configure proper timeouts
   ```yaml
   deploy:
     update_config:
       failure_action: rollback
       max_failure_ratio: 0.1
   ```

## Monitoring Deployments

1. Check service status
   ```bash
   docker service ps <service_name>
   docker service logs <service_name>
   ```

2. Monitor metrics
   - CPU/Memory usage
   - Request rates
   - Error rates
   - Latency

3. Set up alerts
   - Failed deployments
   - High error rates
   - Performance degradation

## Rollback Procedures

### Manual Rollback
1. Revert code changes
2. Rebuild and redeploy
   ```bash
   git revert <commit>
   docker compose up -d --build
   ```

### Automated Rollback
1. Configure rollback in CI/CD
   ```yaml
   deploy:
     rollback_config:
       parallelism: 1
       delay: 10s
   ```

2. Use deployment tools
   - Kubernetes rollback
   - Docker stack rollback
   - CI/CD pipeline rollback

## Best Practices

1. **Version Control**
   - All infrastructure as code
   - Tag all releases
   - Maintain changelog

2. **Testing**
   - Unit tests
   - Integration tests
   - End-to-end tests

3. **Documentation**
   - Deployment procedures
   - Rollback procedures
   - Known issues

4. **Monitoring**
   - Application metrics
   - Infrastructure metrics
   - Log aggregation

## Troubleshooting

### Common Issues
1. **Port conflicts**
   ```bash
   netstat -tuln | grep <port>
   lsof -i :<port>
   ```

2. **Resource constraints**
   ```bash
   docker stats
   df -h
   free -h
   ```

3. **Network issues**
   ```bash
   docker network inspect <network_name>
   ping <container_name>
   curl -v http://<service>:<port>
   ```

4. **Service discovery**
   ```bash
   dig tasks.<service_name>
   nslookup tasks.<service_name>
   ```

### Recovery Procedures
1. **Failed deployment**
   ```bash
   # Roll back to previous version
   docker service rollback <service_name>
   ```

2. **Database recovery**
   ```bash
   # Restore from backup
   ./scripts/backup/restore.sh <backup_file>
   ```

3. **Data corruption**
   ```bash
   # Run consistency checks
   docker exec <container> <check_command>
   ```

For more detailed troubleshooting, see the [Troubleshooting Guide](/docs/troubleshooting/README.md).
