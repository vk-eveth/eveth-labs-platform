# High Availability Setup for Eveth Labs Platform

This directory contains configuration files for setting up high availability (HA) for the Eveth Labs Platform components.

## Components

1. **Traefik Load Balancer**
   - Multiple replicas for high availability
   - Automatic SSL certificate management
   - Load balancing across all services

2. **PostgreSQL HA with Patroni**
   - 3-node PostgreSQL cluster with automatic failover
   - etcd for distributed configuration and leader election
   - HAProxy for read/write splitting
   - Automatic failover and recovery

3. **Redis HA with Sentinel**
   - 1 master + 2 replicas configuration
   - Redis Sentinel for automatic failover
   - Multiple sentinel instances for quorum

## Prerequisites

1. Docker Swarm mode enabled on all nodes
2. At least 3 nodes for a production-grade HA setup
3. Proper network connectivity between nodes
4. Required environment variables set in `.env`

## Required Environment Variables

```bash
# Database
DB_PASSWORD=your_secure_password
DB_REPLICATION_PASSWORD=your_secure_replication_password

# Redis
REDIS_PASSWORD=your_secure_redis_password

# Traefik
ACME_EMAIL=your-email@example.com
DOMAIN=your-domain.com
```

## Node Labels

For proper placement of services, label your Swarm nodes:

```bash
# On the primary node
docker node update --label-add db=primary <node-id>
docker node update --label-add redis=master <node-id>

# On secondary nodes
docker node update --label-add db=secondary1 <node2-id>
docker node update --label-add redis=replica <node2-id>

docker node update --label-add db=secondary2 <node3-id>
docker node update --label-add redis=replica <node3-id>
```

## Deployment

1. Initialize the HA setup:
   ```bash
   ./scripts/setup-high-availability.sh
   ```

2. Verify the services:
   ```bash
   docker service ls
   docker node ls
   ```

## Monitoring

- **Traefik Dashboard**: `https://traefik.your-domain.com`
- **PostgreSQL HAProxy Stats**: `http://<node-ip>:7000/stats`
- **Redis Sentinel**: Monitor on port 26379

## Failover Testing

To test PostgreSQL failover:

1. Find the current master:
   ```bash
   docker exec -it $(docker ps -q -f name=patroni0) patronictl list
   ```

2. Manually failover:
   ```bash
   docker exec -it $(docker ps -q -f name=patroni0) patronictl failover
   ```

## Maintenance

- **Adding a new node**: 
  ```bash
  docker swarm join --token <token> <manager-ip>:2377
  ```

- **Removing a node**:
  ```bash
  docker node demote <node-id>  # If manager
  docker node rm <node-id>
  ```

## Backup and Recovery

1. Regular backups should be configured for:
   - PostgreSQL data
   - Redis data
   - Configuration files

2. Use the backup scripts in `scripts/backup/`

## Troubleshooting

1. **Check service logs**:
   ```bash
   docker service logs <service-name>
   ```

2. **Check node status**:
   ```bash
   docker node ps $(docker node ls -q)
   ```

3. **Check network connectivity**:
   ```bash
   docker network inspect <network-name>
   ```

## Security Considerations

1. Use strong passwords for all services
2. Enable firewall rules to restrict access
3. Regularly update all containers to the latest versions
4. Monitor for security vulnerabilities

## Scaling

To scale services:

```bash
# Scale web services
docker service scale traefik_traefik=3
docker service scale gitlab_web=3

# Scale database read replicas
# Update the postgres-ha.yml file and redeploy
```
