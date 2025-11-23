# Projects Directory

This directory contains all active projects managed by the Eveth Labs Platform.

## 📁 Directory Structure

```
projects/
├── README.md                    # This file
├── noqueue/                     # NoQueue - University Fee Payment System
│   ├── backend/                 # Django backend
│   ├── frontend/                # React frontend
│   ├── docker-compose.platform.yml  # Platform integration
│   ├── .gitlab-ci.yml          # CI/CD pipeline
│   └── README.md               # Project documentation
├── project-2/                   # Your next project
└── project-n/                   # Additional projects
```

## 🚀 Adding a New Project

### 1. Clone or Create Project
```bash
cd /home/vk-eveth/eveth-labs-platform/projects
git clone <your-repo-url> project-name
```

### 2. Project Requirements
Each project should have:
- ✅ **Dockerfile(s)** - For all services
- ✅ **docker-compose.yml** - For local development
- ✅ **docker-compose.platform.yml** - For platform integration with Traefik
- ✅ **.gitlab-ci.yml** - CI/CD pipeline
- ✅ **.env.example** - Environment variable template
- ✅ **README.md** - Project documentation

### 3. Platform Integration
To integrate with Eveth Labs platform:

1. **Create docker-compose.platform.yml**
   - Use Traefik labels for routing
   - Connect to `eveth-net` network
   - Configure proper domain names

2. **Push to GitLab**
   ```bash
   # Add GitLab remote
   cd project-name
   git remote add gitlab http://gitlab.localhost/your-group/project-name.git
   git push gitlab main
   ```

3. **Configure CI/CD**
   - Copy from `/home/vk-eveth/eveth-labs-platform/examples/cicd/.gitlab-ci.yml`
   - Customize for your project
   - Configure variables in GitLab

## 🔧 Platform Services Available

All projects can use these platform services:

| Service | Internal URL | Purpose |
|---------|-------------|---------|
| **GitLab** | `http://gitlab:80` | Source control, CI/CD |
| **Harbor** | `http://harbor:80` | Container registry |
| **SonarQube** | `http://sonar:9000` | Code quality |
| **PostgreSQL** | `postgres:5432` | Database (shared) |
| **Redis** | `redis:6379` | Cache/Queue (shared) |
| **Prometheus** | `http://prometheus:9090` | Metrics |
| **Loki** | `http://loki:3100` | Logs |

## 🌐 Project Naming Convention

### Domains
- **Development**: `project-name.localhost`
- **Staging**: `project-name-staging.localhost`
- **Production**: `project-name.evethlabs.local`

### Container Names
- Format: `projectname_service`
- Example: `noqueue_backend`, `noqueue_frontend`

## 📦 Project Types

### Full-Stack Web Applications
- **Backend**: Django, Node.js, Go, etc.
- **Frontend**: React, Vue, Angular, etc.
- **Database**: PostgreSQL, MySQL, MongoDB
- **Cache**: Redis, Memcached

### Microservices
- Each service in its own container
- Shared network: `eveth-net`
- Service discovery via Traefik

### Static Sites
- Built with Hugo, Jekyll, Next.js, etc.
- Served via Nginx
- Cached via Traefik

## 🔐 Environment Variables

### Required for All Projects
```env
# Project Info
PROJECT_NAME=your-project-name
ENVIRONMENT=development

# Platform Integration
TRAEFIK_DOMAIN=project-name.localhost
NETWORK_NAME=eveth-net

# Registry
HARBOR_REGISTRY=harbor.localhost/library
```

### Platform-Provided Services
```env
# GitLab
GITLAB_URL=http://gitlab.localhost
GITLAB_TOKEN=<from-gitlab-settings>

# SonarQube
SONAR_HOST_URL=http://sonar.localhost
SONAR_TOKEN=<from-sonarqube>

# Monitoring
PROMETHEUS_URL=http://prometheus:9090
LOKI_URL=http://loki:3100
```

## 🚢 Deployment Workflow

1. **Development**
   ```bash
   # Start local development
   docker compose up -d
   ```

2. **Push to GitLab**
   ```bash
   git add .
   git commit -m "Feature: description"
   git push gitlab main
   ```

3. **CI/CD Pipeline Runs**
   - Runs tests
   - SonarQube analysis
   - Builds Docker images
   - Pushes to Harbor registry
   - Deploys to staging

4. **Production Deployment**
   - Manual approval in GitLab
   - Automatic deployment via CI/CD

## 📊 Monitoring & Logging

### Application Metrics
- Export metrics in Prometheus format
- Endpoint: `/metrics`
- Auto-discovered by Prometheus

### Logging
- Use structured JSON logs
- Logs auto-collected by Loki
- View in Grafana dashboards

### Health Checks
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost/health"]
  interval: 30s
  timeout: 10s
  retries: 3
```

## 🧪 Testing

### Local Testing
```bash
# Run tests in container
docker compose exec backend pytest
docker compose exec frontend npm test
```

### CI/CD Testing
- Unit tests run on every commit
- Integration tests run on merge requests
- E2E tests run before deployment

## 📚 Best Practices

### Docker
- ✅ Use multi-stage builds for smaller images
- ✅ Don't run as root user
- ✅ Use .dockerignore
- ✅ Pin image versions
- ✅ Use health checks

### Security
- ✅ Never commit secrets to Git
- ✅ Use environment variables
- ✅ Scan images with Trivy (built into Harbor)
- ✅ Keep dependencies updated

### CI/CD
- ✅ Run tests before deployment
- ✅ Use SonarQube quality gates
- ✅ Tag images with Git commit hash
- ✅ Use semantic versioning

### Code Quality
- ✅ Maintain > 80% test coverage
- ✅ Pass SonarQube quality gates
- ✅ Follow language-specific style guides
- ✅ Document APIs

## 🆘 Troubleshooting

### Container Won't Start
```bash
# Check logs
docker logs project_service_name

# Check resource usage
docker stats

# Rebuild image
docker compose build --no-cache service_name
```

### Network Issues
```bash
# Verify network exists
docker network ls | grep eveth-net

# Connect container to network
docker network connect eveth-net container_name
```

### Traefik Routing Issues
```bash
# Check Traefik dashboard
http://localhost:8080/dashboard/

# Verify labels
docker inspect container_name | grep traefik
```

## 📖 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [GitLab CI/CD](https://docs.gitlab.com/ee/ci/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Platform Examples](/home/vk-eveth/eveth-labs-platform/examples/)

## 🔗 Current Projects

### 1. NoQueue - University Fee Payment System
- **Type**: Full-stack web application
- **Tech Stack**: Django + React + PostgreSQL + Redis + Celery
- **Domain**: http://noqueue.localhost
- **Status**: ✅ Active
- **GitLab**: http://gitlab.localhost/eveth/noqueue
