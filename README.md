# Eveth Labs DevOps Platform

A streamlined, containerized DevOps platform providing essential tools for modern software development, deployment, and monitoring. Optimized for single-node development environments.

## 🌟 Key Features

### Core Services
- **Source Control**: GitLab CE with integrated CI/CD pipelines
- **Code Quality**: SonarQube for static code analysis
- **Container Registry**: Harbor (image repository and scanning)

### Infrastructure
- **Orchestration**: Docker Compose
- **Reverse Proxy**: Traefik v2 for routing and load balancing
- **Container Management**: Portainer for Docker management

### Monitoring & Observability
- **Metrics**: Prometheus for metrics collection
- **Visualization**: Grafana with pre-configured dashboards
- **Logging**: Loki for log aggregation
- **Alerting**: Alertmanager for alert management

### Data Services
- **Database**: PostgreSQL for SonarQube
- **Caching**: Redis for session and cache management

## 📋 Prerequisites

### Hardware Requirements
| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU Cores | 2       | 4+          |
| RAM       | 8GB     | 16GB+       |
| Storage   | 100GB   | 200GB+ SSD  |
| Network   | 1Gbps   | 1Gbps       |

### Resource Allocation
| Service | CPU Cores | RAM  | Storage |
|---------|-----------|------|---------|
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

### Software Requirements
- **Operating System**: Ubuntu 22.04 LTS or RHEL 8+
- **Container Runtime**: Docker 20.10+ with Compose v2
- **Networking**: Properly configured DNS and firewall rules
- **Storage**: Configured storage backend (local, NFS, or cloud storage)

### Network Requirements
- Ports 80/443 open for web traffic
- Port 22 for SSH access (GitLab)
- Local DNS resolution or hosts file entries for all services

## 🚀 Quick Start

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

### 3. Initialize the Platform
```bash
# Initialize the platform
docker compose up -d

# Wait for services to start, then run health check
./scripts/health-check.sh
```

### 4. Access the Services

Once all containers are healthy:

- **Traefik Dashboard**: http://traefik.evethlabstech (admin / ChangeMe123!)
- **GitLab**: http://gitlab.evethlabstech (root / ChangeMe123!)
- **SonarQube**: http://sonar.evethlabstech (admin / admin)
- **Grafana**: http://grafana.evethlabstech (admin / ChangeMe123!)
- **Prometheus**: http://prometheus.evethlabstech (no auth)
- **Loki**: http://loki.evethlabstech (no auth)
- **Alertmanager**: http://alertmanager.evethlabstech (no auth)
- **Portainer**: http://portainer.evethlabstech (create admin on first login)
- **Harbor**: http://harbor.evethlabstech (admin / ChangeMe123!)

**⚠️ IMPORTANT**: All default passwords are also documented in `CREDENTIALS.md`. Change them immediately after first login!

## 📚 Documentation

For detailed documentation, please refer to the following sections:

1. [Getting Started](/docs/getting-started/README.md)
2. [Configuration Guide](/docs/configuration/README.md)
3. [Deployment Guide](/docs/deployment/README.md)
4. [Monitoring & Logging](/docs/monitoring/README.md)
5. [Security Hardening](/docs/security/README.md)
6. [Backup & Recovery](/docs/backup/README.md)
7. [API Reference](/docs/api/README.md)
8. [Operations Guide](/docs/operations/README.md)
9. [Troubleshooting](/docs/troubleshooting/README.md)

## 🔒 Security

### Default Credentials
All default credentials should be changed immediately after the first login. See `CREDENTIALS.md` for the complete list of default passwords.

### Security Features
- Network segmentation between services
- Basic authentication for Traefik dashboard
- Regular security updates via Docker images
- Audit logging for administrative actions
- Isolated Docker network for services

## 🔄 Upgrading

To upgrade the platform to the latest version:

```bash
docker compose pull
docker compose up -d
./scripts/health-check.sh
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on how to contribute to this project.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For support, please open an issue in the GitLab issue tracker at http://gitlab.evethlabstech/eveth-labs/platform/issues.

---

## 🔧 Management

### Start/Stop Services

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# View logs
docker compose logs -f [service-name]
```

### Backup and Restore

```bash
# Run backup
./scripts/backup/backup.sh

# To restore from backup, follow the instructions in the backup_info.txt file
```

### Health Check

```bash
# Run health check
./scripts/health-check.sh
```

## 🔒 Security

### Change Default Passwords

**IMPORTANT**: All default credentials are listed in `CREDENTIALS.md`. Change them immediately after first login:

1. **Traefik**: Update TRAEFIK_AUTH in .env file
2. **GitLab**: http://gitlab.evethlabstech - root / ChangeMe123!
3. **SonarQube**: http://sonar.evethlabstech - admin / admin
4. **Grafana**: http://grafana.evethlabstech - admin / ChangeMe123!
5. **Portainer**: http://portainer.evethlabstech - Set on first login
6. **Harbor**: http://harbor.evethlabstech - admin / ChangeMe123!

### Firewall Configuration

```bash
# Allow necessary ports
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 2222/tcp  # GitLab SSH
sudo ufw enable
```

## 📊 Monitoring

### Pre-configured Dashboards

- **System Metrics**: CPU, Memory, Disk, Network
- **Container Metrics**: Resource usage per container
- **Application Metrics**: GitLab, SonarQube, etc.

### Setting Up Alerts

1. Access Grafana at http://grafana.evethlabstech
2. Navigate to Alerting > Alert rules
3. Create new alert rules based on your requirements
4. Configure Alertmanager at http://alertmanager.evethlabstech

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Docker](https://www.docker.com/)
- [Traefik](https://traefik.io/)
- [GitLab](https://about.gitlab.com/)
- [SonarQube](https://www.sonarqube.org/)
- [Grafana](https://grafana.com/)
- [Prometheus](https://prometheus.io/)
- [Portainer](https://www.portainer.io/)
