# Configuration Guide

This guide covers the configuration options available for the Eveth Labs Platform.

## Table of Contents

1. [Environment Variables](#environment-variables)
2. [Service Configuration](#service-configuration)
3. [Networking](#networking)
4. [Security](#security)
5. [Backup Configuration](#backup-configuration)
6. [Monitoring & Logging](#monitoring--logging)

## Environment Variables

The main configuration is done through the `.env` file. Here are the key variables:

### Core Settings
```ini
# Domain configuration
DOMAIN=evethlabstech

# Email for notifications
ACME_EMAIL=admin@${DOMAIN}

# Timezone (e.g., America/New_York, Europe/London)
TZ=UTC
```

### Service Versions
```ini
# Core Services
GITLAB_VERSION=15.11.0-ce.0
SONARQUBE_VERSION=9.9.0-community
POSTGRES_VERSION=13
REDIS_VERSION=7

# Infrastructure
TRAEFIK_VERSION=2.10.1
PORTAINER_VERSION=2.16.2

# Monitoring
GRAFANA_VERSION=9.3.2
PROMETHEUS_VERSION=v2.40.0
ALERTMANAGER_VERSION=v0.26.0
LOKI_VERSION=2.7.3
```

### Resource Limits
```ini
# Memory limits (adjust based on available RAM)
GITLAB_MEMORY_LIMIT=8g
POSTGRES_MEMORY_LIMIT=4g
REDIS_MEMORY_LIMIT=1g

# CPU limits (in shares)
GITLAB_CPU_SHARES=512
POSTGRES_CPU_SHARES=256
```

## Service Configuration

### GitLab

Configuration file: `config/gitlab/gitlab.rb`

Key settings:
```ruby
external_url 'http://gitlab.${DOMAIN}'
gitlab_rails['initial_root_password'] = '${GITLAB_ROOT_PASSWORD}'
gitlab_rails['gitlab_shell_ssh_port'] = 2222
```

### SonarQube

SonarQube connects to PostgreSQL database.

Key environment variables:
```yaml
SONAR_JDBC_URL: jdbc:postgresql://postgres:5432/sonar
SONAR_JDBC_USERNAME: sonar
SONAR_JDBC_PASSWORD: ${SONAR_JDBC_PASSWORD}
```

### PostgreSQL

PostgreSQL is used by SonarQube for data storage.

Key environment variables:
```yaml
POSTGRES_USER: sonar
POSTGRES_PASSWORD: ${SONAR_JDBC_PASSWORD}
POSTGRES_DB: sonar
```

## Networking

### Port Configuration

All services are routed through Traefik on port 80:

| Service | Internal Port | External URL | Description |
|---------|--------------|--------------|-------------|
| Traefik | 80, 8080 | traefik.evethlabstech | Reverse proxy |
| GitLab | 80, 2222 | gitlab.evethlabstech | Web UI, Git SSH |
| SonarQube | 9000 | sonar.evethlabstech | Code quality |
| Grafana | 3000 | grafana.evethlabstech | Dashboards |
| Prometheus | 9090 | prometheus.evethlabstech | Metrics |
| Loki | 3100 | loki.evethlabstech | Log aggregation |
| Alertmanager | 9093 | alertmanager.evethlabstech | Alerts |
| Portainer | 9000 | portainer.evethlabstech | Container management |

### Traefik Configuration

Configuration directory: `config/traefik/`

- `traefik.yml`: Main configuration
- `dynamic/`: Dynamic configuration files
- `certs/`: SSL certificates

## Security

### SSL/TLS
- HTTP-only for localhost development
- For production: Configure Let's Encrypt or custom certificates in Traefik
- Update Traefik configuration for HTTPS

### Authentication
- OAuth2/OIDC integration
- LDAP/AD integration
- 2FA support

### Network Security
- Firewall rules
- Network policies
- Rate limiting

## Backup Configuration

### Backup Schedule
Configured in `.env`:
```ini
# Daily backups at 2 AM
BACKUP_SCHEDULE=0 2 * * *

# Retention policy (days)
BACKUP_RETENTION_DAYS=30

# Backup destination
BACKUP_DIR=/backups
```

### What's Backed Up
- PostgreSQL databases
- Redis data
- Configuration files
- Git repositories (GitLab)

## Monitoring & Logging

### Prometheus
- Scrape interval: 15s
- Retention: 30 days
- Alert rules: `config/prometheus/alert.rules`

### Grafana
- Pre-configured dashboards
- Alerting rules
- User management

### Loki & Promtail
- Log aggregation
- Log retention: 30 days
- Log rotation

## Updating Configuration

After making changes to configuration files, restart the affected services:

```bash
# Single service
docker compose restart <service_name>

# All services
docker compose down
docker compose up -d
```

## Best Practices

1. Always back up configuration before making changes
2. Test configuration changes in a staging environment
3. Monitor system resources after configuration changes
4. Document all custom configurations
5. Use environment variables for sensitive data

## Troubleshooting

Common configuration issues:

1. **Port conflicts**: Check for services using the same port
   ```bash
   sudo lsof -i :<port>
   ```

2. **Permission issues**: Ensure proper file permissions
   ```bash
   chmod 600 config/*/*.key
   ```

3. **Configuration errors**: Check logs for specific errors
   ```bash
   docker logs <container_name>
   ```

For more help, see the [Troubleshooting Guide](/docs/troubleshooting/README.md).
