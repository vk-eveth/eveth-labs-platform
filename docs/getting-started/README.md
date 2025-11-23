# Getting Started with Eveth Labs Platform

Welcome to the Eveth Labs Platform! This guide will help you get started with setting up and using the platform.

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Installation](#installation)
3. [First Steps](#first-steps)
4. [Accessing Services](#accessing-services)
5. [Next Steps](#next-steps)

## System Requirements

### Minimum Requirements
- **CPU**: 4 cores
- **RAM**: 16GB
- **Storage**: 200GB SSD
- **OS**: Ubuntu 22.04 LTS or RHEL 8+
- **Docker**: 20.10+
- **Docker Compose**: v2.0+

### Recommended for Production
- **CPU**: 8+ cores
- **RAM**: 32GB+
- **Storage**: 500GB+ SSD with RAID 10
- **Network**: 10Gbps

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd eveth-labs-platform
```

### 2. Configure Environment

```bash
# Edit the environment configuration
nano .env
```

### 3. Run the Setup Script

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run the setup script
sudo ./setup-platform.sh
```

### 4. Verify Installation

Check that all services are running:

```bash
docker ps
docker compose ps
```

## First Steps

### 1. Change Default Passwords

See `CREDENTIALS.md` for all default passwords. Change them immediately after first login:

- Traefik: `http://traefik.evethlabstech` (admin/ChangeMe123!)
- GitLab: `http://gitlab.evethlabstech` (root/ChangeMe123!)
- SonarQube: `http://sonar.evethlabstech` (admin/admin)
- Grafana: `http://grafana.evethlabstech` (admin/ChangeMe123!)
- Portainer: `http://portainer.evethlabstech` (set on first login)

### 2. Configure Hosts File

For localhost development, add entries to `/etc/hosts`:

```bash
127.0.0.1 traefik.evethlabstech
127.0.0.1 gitlab.evethlabstech
127.0.0.1 sonar.evethlabstech
127.0.0.1 grafana.evethlabstech
127.0.0.1 prometheus.evethlabstech
127.0.0.1 loki.evethlabstech
127.0.0.1 alertmanager.evethlabstech
127.0.0.1 portainer.evethlabstech
127.0.0.1 harbor.evethlabstech
```

The setup script will add these automatically if run with sudo.

### 3. Set Up Backups

Configure backup settings in `.env` and test the backup process:

```bash
./scripts/backup/backup.sh
```

## Accessing Services

### Web Interfaces

| Service | URL | Credentials |
|---------|-----|-------------|
| Traefik | http://traefik.evethlabstech | See CREDENTIALS.md |
| GitLab | http://gitlab.evethlabstech | See CREDENTIALS.md |
| SonarQube | http://sonar.evethlabstech | See CREDENTIALS.md |
| Grafana | http://grafana.evethlabstech | See CREDENTIALS.md |
| Prometheus | http://prometheus.evethlabstech | N/A |
| Loki | http://loki.evethlabstech | N/A |
| Alertmanager | http://alertmanager.evethlabstech | N/A |
| Portainer | http://portainer.evethlabstech | Set on first login |
| Harbor | http://harbor.evethlabstech | admin / ChangeMe123! |

### Command Line Access

Access containers:
```bash
docker exec -it <container_name> /bin/bash
```

View logs:
```bash
docker logs -f <container_name>
```

## Next Steps

1. [Configure Monitoring](/docs/monitoring/README.md)
2. [Configuration Guide](/docs/configuration/README.md)
3. [Configure Security Settings](/docs/security/README.md)
4. [High-Availability Deployment](/docs/deployment/README.md#high-availability-deployment)

## Troubleshooting

Common issues and solutions:

1. **Port Conflicts**: Ensure required ports are not in use
2. **Docker Permissions**: Add your user to the docker group
   ```bash
   sudo usermod -aG docker $USER
   ```
3. **Disk Space**: Monitor disk usage with `df -h`
4. **Service Issues**: Check logs with `docker logs <container_name>`

For more help, see the [Troubleshooting Guide](/docs/troubleshooting/README.md).
