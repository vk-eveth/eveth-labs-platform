# Eveth Labs Platform - Complete Overview

**Last Updated**: November 15, 2025  
**Environment**: Localhost Development  
**Domain**: evethlabstech

## Platform Services

All services are accessible via HTTP on the `evethlabstech` domain through Traefik reverse proxy.

### Core Services

| Service | URL | Purpose | Container Name |
|---------|-----|---------|----------------|
| **Traefik** | http://traefik.evethlabstech | Reverse proxy & routing | traefik |
| **GitLab CE** | http://gitlab.evethlabstech | Source control & CI/CD | gitlab |
| **SonarQube** | http://sonar.evethlabstech | Code quality analysis | sonarqube |
| **Grafana** | http://grafana.evethlabstech | Monitoring dashboards | grafana |
| **Prometheus** | http://prometheus.evethlabstech | Metrics collection | prometheus |
| **Loki** | http://loki.evethlabstech | Log aggregation | loki |
| **Alertmanager** | http://alertmanager.evethlabstech | Alert management | alertmanager |
| **Portainer** | http://portainer.evethlabstech | Container management | portainer |
| **Harbor** | http://harbor.evethlabstech | Container registry | nginx |

### Support Services

| Service | Purpose | Container Name | Port |
|---------|---------|----------------|------|
| **PostgreSQL** | Database for SonarQube | sonarqube-db | 5432 |
| **Redis** | Caching & sessions | redis | 6379 |

## Resource Allocation

| Service | CPU Cores | RAM | Storage |
|---------|-----------|-----|---------|
| GitLab CE | 2 | 4GB | 20GB |
| SonarQube | 1 | 2GB | 10GB |
| PostgreSQL | 0.5 | 1GB | 10GB |
| Redis | 0.5 | 1GB | 1GB |
| Prometheus | 0.5 | 1GB | 10GB |
| Grafana | 0.5 | 1GB | 1GB |
| Loki | 0.5 | 1GB | 10GB |
| Portainer | 0.5 | 1GB | 1GB |
| Alertmanager | 0.5 | 512MB | 1GB |
| **Total** | **6.5** | **13.5GB** | **65GB** |

## Quick Start

### 1. Prerequisites
- Docker 20.10+
- Docker Compose v2
- 4+ CPU cores
- 16GB+ RAM
- 100GB+ storage

### 2. Setup
```bash
# Clone repository
git clone <repository-url>
cd eveth-labs-platform

# Run setup (requires sudo for /etc/hosts)
sudo ./setup-platform.sh
```

### 3. Access Services
All services accessible via:
- http://[servicename].evethlabstech

Default credentials in `CREDENTIALS.md`

## Management Commands

### Start/Stop
```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Restart a service
docker compose restart <service-name>
```

### Monitoring
```bash
# Check service status
docker compose ps

# View logs
docker logs <container-name>
docker logs -f <container-name>  # Follow logs

# Health check
./scripts/health-check.sh
```

### Backup
```bash
# Run backup
./scripts/backup/backup.sh

# Backups stored in: ./backups/
```

## Directory Structure

```
eveth-labs-platform/
├── backups/              # Backup files
├── config/               # Service configurations
│   ├── alertmanager/
│   ├── grafana/
│   ├── loki/
│   ├── prometheus/
│   └── ...
├── data/                 # Persistent data volumes
│   ├── gitlab/
│   ├── grafana/
│   ├── postgres/
│   ├── prometheus/
│   └── ...
├── docs/                 # Documentation
│   ├── api/
│   ├── backup/
│   ├── configuration/
│   ├── deployment/
│   ├── getting-started/
│   ├── monitoring/
│   ├── operations/
│   ├── security/
│   └── troubleshooting/
├── examples/             # Example configurations
│   └── cicd/
├── logs/                 # Application logs
├── scripts/              # Utility scripts
│   ├── backup/
│   ├── deploy/
│   └── monitoring/
├── .env                  # Environment variables
├── .gitignore           # Git ignore rules
├── CREDENTIALS.md       # Default passwords
├── docker-compose.yml   # Service definitions
├── README.md            # Main documentation
└── setup-platform.sh    # Setup script
```

## Configuration Files

### Primary Configuration
- **`.env`** - Environment variables (domain, passwords, versions)
- **`docker-compose.yml`** - Service definitions
- **`CREDENTIALS.md`** - Default credentials

### Service Configs
- **`config/prometheus/prometheus.yml`** - Prometheus configuration
- **`config/alertmanager/alertmanager.yml`** - Alert rules
- **`config/loki/loki-config.yaml`** - Loki configuration
- **`config/grafana/provisioning/`** - Grafana datasources & dashboards

### Default Credentials

See `CREDENTIALS.md` for complete list. Key credentials:

| Service | Username | Password | Notes |
|---------|----------|----------|-------|
| Traefik | admin | ChangeMe123! | HTTP Basic Auth |
| GitLab | root | ChangeMe123! | Web UI / SSH |
| SonarQube | admin | admin | Change on first login |
| Grafana | admin | ChangeMe123! | Web UI |
| PostgreSQL | sonar | sonar | Internal database |
| Redis | - | redis_secure_pass_2024 | Internal cache |
| Portainer | - | Set on first login | Create admin account |
| Harbor | admin | ChangeMe123! | Web UI |

**⚠️ Change all passwords immediately after first login!**

### Password Reset Commands

**GitLab**:
```bash
echo -e "NewPassword\nNewPassword" | docker exec -i gitlab gitlab-rake "gitlab:password:reset[root]"
```

**SonarQube**:
```bash
# Reset to admin/admin
docker exec sonarqube-db psql -U sonar -d sonar -c "UPDATE users SET crypted_password='$2a$12$uCkkXmhW5ThVK8mpBvnXOOJRLd64LJeHTeCkSuB3lfaR2N0AYBaSi', salt=null, hash_method='BCRYPT' WHERE login='admin';"
docker compose restart sonarqube
```

## Network Configuration

### Docker Network
- **Network Name**: eveth-net
- **Driver**: bridge
- All services communicate via this isolated network

### Ports
- **80**: HTTP (Traefik)
- **443**: HTTPS (currently unused in localhost)
- **2222**: GitLab SSH
- **8080**: Traefik Dashboard
- **9000**: Portainer (direct access)

### Hosts File Entries
Required in `/etc/hosts` for localhost:
```
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

## Key Features

### Source Control & CI/CD
- **GitLab CE**: Complete DevOps platform
  - Git repository hosting
  - CI/CD pipelines
  - Issue tracking
  - Wiki & documentation

### Code Quality
- **SonarQube**: Static code analysis
  - Code quality metrics
  - Security vulnerabilities
  - Code smells & bugs
  - Technical debt tracking

### Monitoring & Observability
- **Prometheus**: Metrics collection & storage
- **Grafana**: Visualization & dashboards
- **Loki**: Log aggregation
- **Alertmanager**: Alert routing & management

### Infrastructure Management
- **Traefik**: Reverse proxy & load balancer
- **Portainer**: Docker container management UI
- **PostgreSQL**: Relational database
- **Redis**: In-memory cache

## Monitoring & Alerts

### Prometheus Targets
- prometheus (self-monitoring)
- traefik
- gitlab
- sonarqube
- docker daemon (if configured)
- node-exporter (if installed)

### Grafana Dashboards
- Pre-configured Prometheus datasource
- Import community dashboards from grafana.com

### Alert Rules
Located in `config/prometheus/alert.rules`:
- Instance down alerts
- High CPU/memory usage
- High disk usage
- Container health checks

## Backup Strategy

### What's Backed Up
- PostgreSQL databases
- Redis data
- Configuration files
- GitLab repositories
- Grafana dashboards

### Backup Location
- `./backups/eveth-labs-backup-YYYYMMDD_HHMMSS.tar.gz`

### Retention
- Last 7 days kept automatically
- Older backups deleted

## Security Considerations

### Localhost Development
- HTTP only (no TLS)
- Basic authentication on Traefik dashboard
- Default passwords (MUST be changed)
- Isolated Docker network

### Production Recommendations
1. Enable HTTPS with Let's Encrypt
2. Use strong passwords
3. Enable 2FA where supported
4. Configure firewall (UFW)
5. Regular security updates
6. Monitor access logs
7. Use secrets management

## Troubleshooting

### Common Issues

**Services won't start:**
```bash
docker compose logs <service-name>
docker compose ps
```

**Port conflicts:**
```bash
sudo lsof -i :80
sudo lsof -i :443
```

**Permission issues:**
```bash
sudo chmod -R 777 ./data
```

**Reset a service:**
```bash
docker compose stop <service-name>
docker compose rm <service-name>
docker compose up -d <service-name>
```

**Check disk space:**
```bash
df -h
du -sh ./data/*
```

## Useful Scripts

- **`setup-platform.sh`** - Initial platform setup
- **`scripts/health-check.sh`** - Check service health
- **`scripts/backup/backup.sh`** - Backup all data
- **`scripts/security-harden.sh`** - Security hardening

## Next Steps

1. ✅ Change all default passwords (see CREDENTIALS.md)
2. ✅ Configure GitLab CI/CD runners
3. ✅ Import code into GitLab
4. ✅ Configure SonarQube quality gates
5. ✅ Set up Grafana dashboards
6. ✅ Configure backup schedule
7. ✅ Review and customize alert rules
8. ✅ Set up SSL/TLS for production

## Documentation

Comprehensive documentation available in `/docs/`:

- **Getting Started**: `/docs/getting-started/README.md`
- **Configuration**: `/docs/configuration/README.md`
- **Deployment**: `/docs/deployment/README.md`
- **Monitoring**: `/docs/monitoring/README.md`
- **Security**: `/docs/security/README.md`
- **Backup**: `/docs/backup/README.md`
- **Operations**: `/docs/operations/README.md`
- **Troubleshooting**: `/docs/troubleshooting/README.md`

## Support & Contribution

- Issues: GitLab issue tracker at http://gitlab.evethlabstech
- Documentation: `/docs/` directory
- Examples: `/examples/` directory

## License

MIT License - See LICENSE file for details

---

**Built for Eveth Labs**  
Platform Version: Localhost Development  
Last Audit: November 15, 2025
