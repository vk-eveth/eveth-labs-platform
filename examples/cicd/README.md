# CI/CD Pipeline Example for Eveth Labs Platform

This directory contains example configuration files for setting up a complete CI/CD pipeline for applications deployed on the Eveth Labs Platform.

## Overview

The example demonstrates a CI/CD pipeline that includes:

- **Testing**: Unit tests
- **Building**: Container image building
- **Code Quality**: SonarQube code quality checks
- **Deployment**: Multi-environment deployment (staging & production)
- **Notifications**: Slack notifications for pipeline failures

## Prerequisites

1. GitLab Runner with Docker-in-Docker (DinD) support
2. Harbor registry available at `http://harbor.${DOMAIN}`
3. Access to the target deployment environments
4. Required environment variables set in your GitLab CI/CD variables

## Required Environment Variables

```bash
# GitLab CI/CD Variables
CI_REGISTRY_USER              # Harbor username (e.g., admin or robot account)
CI_REGISTRY_PASSWORD          # Harbor password or robot token
DOMAIN                        # Your application domain (e.g., evethlabstech)

# Deployment Secrets (should be stored in GitLab's CI/CD variables)
DB_PASSWORD                   # Database password
REDIS_PASSWORD                # Redis password
SLACK_WEBHOOK_URL             # For notifications (optional)
```

## Pipeline Stages

1. **test**: Runs unit tests
2. **build**: Builds and pushes Docker images to registry
3. **sonarqube-check**: Performs code quality analysis
4. **deploy**: Handles deployment to staging and production environments
5. **monitor**: Health check monitoring

## Deployment Workflow

1. **Merge Request Pipeline**:
   - Runs tests
   - Builds and pushes the container image with branch name tag
   - Performs security scanning

2. **Main Branch Pipeline**:
   - Runs all MR pipeline steps
   - Auto-deploys to staging environment
   - Waits for manual approval for production deployment

3. **Tag Pipeline**:
   - Triggers production deployment when a new tag is pushed

## Customization

1. Update the `docker-compose` files to match your application's requirements
2. Adjust the resource limits and scaling parameters in `docker-compose.prod.yml`
3. Add more test stages as needed (integration, e2e, etc.)
4. Configure additional security scanning tools

## Security Considerations

- All sensitive data is passed via environment variables
- Production deployments require manual approval
- Security scanning is performed on every build
- Database and Redis passwords are managed as Docker secrets
- For localhost HTTP registry, the pipeline uses Docker-in-Docker with `--insecure-registry=harbor.evethlabstech`
  - In production, enable HTTPS for Harbor and remove the insecure flag

## Monitoring and Logging

- Health checks are configured for all services
- Logs are collected by the platform's logging stack (Loki/Promtail)
- Metrics are available through Prometheus

## Troubleshooting

- Check pipeline logs in GitLab CI/CD
- Verify Docker container logs: `docker logs <container_name>`
- Check service health: `docker service ls` and `docker service ps <service_name>`
- View logs in Grafana (Loki)

## License

This example is provided as part of the Eveth Labs Platform under the MIT License.
