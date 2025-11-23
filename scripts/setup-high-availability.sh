#!/bin/bash

set -e

# Load environment variables
source .env

echo "🔧 Setting up High Availability for Eveth Labs Platform..."

# Initialize Docker Swarm if not already initialized
if ! docker node ls &> /dev/null; then
    echo "🚀 Initializing Docker Swarm..."
    docker swarm init --advertise-addr $(hostname -i)
    
    # Add node labels for high availability
    echo "🏷️  Labeling nodes..."
    NODE_ID=$(docker node ls --format "{{.ID}}")
    docker node update --label-add db=primary $NODE_ID
    docker node update --label-add redis=master $NODE_ID
    
    # In a real multi-node setup, you would add more nodes here:
    # docker node update --label-add db=secondary1 <node2-id>
    # docker node update --label-add redis=replica <node2-id>
    # docker node update --label-add db=secondary2 <node3-id>
    # docker node update --label-add redis=replica <node3-id>
fi

# Create necessary networks
echo "🌐 Creating overlay networks..."
docker network create --driver=overlay --attachable traefik-public 2>/dev/null || true
docker network create --driver=overlay --attachable db-network 2>/dev/null || true
docker network create --driver=overlay --attachable redis-network 2>/dev/null || true

# Deploy HA components
echo "🚀 Deploying HA components..."

# Deploy Traefik for HA load balancing
echo "🔄 Deploying Traefik..."
docker stack deploy -c config/high-availability/traefik.yml traefik

# Deploy PostgreSQL HA
echo "🔄 Deploying PostgreSQL HA..."
docker stack deploy -c config/high-availability/postgres-ha.yml postgres-ha

# Deploy Redis HA
echo "🔄 Deploying Redis HA..."
docker stack deploy -c config/high-availability/redis-ha.yml redis-ha

# Update services to use HA configuration
echo "🔄 Updating services to use HA configuration..."

# Update GitLab to use HA PostgreSQL and Redis
cat > docker-compose.override.yml << 'EOL'
version: '3.8'

services:
  gitlab:
    deploy:
      mode: replicated
      replicas: 2
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
    environment:
      - GITLAB_DATABASE_HOST=postgres-ha_haproxy
      - GITLAB_DATABASE_PORT=5000
      - GITLAB_REDIS_HOST=redis-ha_redis-sentinel1
      - GITLAB_REDIS_PORT=26379

  gitlab-runner:
    deploy:
      mode: replicated
      replicas: 2
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
EOL

echo "✅ High availability setup complete!"
echo ""
echo "🔍 Check the status of your HA services with:"
echo "   docker service ls"
echo ""
echo "🌐 Access the Traefik dashboard at: https://traefik.${DOMAIN}"
echo ""
echo "Note: In a production environment, you should:"
echo "1. Add more nodes to the Swarm cluster"
# ... (rest of the script remains the same)
