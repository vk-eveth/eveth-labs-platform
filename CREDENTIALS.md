# Eveth Labs Platform - Default Credentials

**⚠️ SECURITY WARNING**: Change ALL default passwords immediately after first login!

## Service Access URLs

All services are accessible via the `evethlabstech` domain:

| Service | URL | Port |
|---------|-----|------|
| Traefik Dashboard | http://traefik.evethlabstech | 80 |
| GitLab | http://gitlab.evethlabstech | 80 |
| SonarQube | http://sonar.evethlabstech | 80 |
| Grafana | http://grafana.evethlabstech | 80 |
| Prometheus | http://prometheus.evethlabstech | 80 |
| Loki | http://loki.evethlabstech | 80 |
| Alertmanager | http://alertmanager.evethlabstech | 80 |
| Portainer | http://portainer.evethlabstech | 80 |
| Harbor | http://harbor.evethlabstech | 80 |

## Default Credentials

### Traefik Dashboard
- **URL**: http://traefik.evethlabstech
- **Username**: `admin`
- **Password**: `ChangeMe123!`
- **Auth Type**: Basic Auth
- **How to Change**: Update `TRAEFIK_AUTH` in `.env` file
  ```bash
  # Generate new password hash:
  docker run --rm httpd:2.4-alpine htpasswd -nb admin YourNewPassword
  # Update .env with the output
  #Then When changing environment variables in .env, use:
  docker compose up -d --force-recreate <service>
  ```

### GitLab CE
- **URL**: http://gitlab.evethlabstech
- **Username**: `root`
- **Password**: `ChangeMe123!`
- **SSH Port**: 2222
- **How to Change**: 
  1. Login to GitLab web interface
  2. Go to User Settings > Password
  3. Update password
  4. Update `GITLAB_ROOT_PASSWORD` in `.env` file
- **Troubleshooting Login Issues**:
  If you get "Invalid login or password", reset the root password:
  ```bash
  echo -e "ChangeMe123!\nChangeMe123!" | docker exec -i gitlab gitlab-rake "gitlab:password:reset[root]"
  # Password will be reset immediately, no restart needed
  ```

### SonarQube
- **URL**: http://sonar.evethlabstech
- **Username**: `admin`
- **Password**: `admin`
- **Database**: PostgreSQL (internal)
- **How to Change**:
  1. Login to SonarQube
  2. Go to Administration > Security > Users
  3. Change admin password
- **Troubleshooting Login Issues**:
  If you get 401 Unauthorized, reset the password:
  ```bash
  docker exec sonarqube-db psql -U sonar -d sonar -c "UPDATE users SET crypted_password='$2a$12$uCkkXmhW5ThVK8mpBvnXOOJRLd64LJeHTeCkSuB3lfaR2N0AYBaSi', salt=null, hash_method='BCRYPT' WHERE login='admin';"
  docker compose restart sonarqube
  # Wait 2 minutes for restart, then try admin/admin
  ```

### Grafana
- **URL**: http://grafana.evethlabstech
- **Username**: `admin`
- **Password**: `ChangeMe123!`
- **How to Change**:
  1. Login to Grafana
  2. Go to Profile > Change Password
  3. Update `GRAFANA_ADMIN_PASSWORD` in `.env` file

### Prometheus
- **URL**: http://prometheus.evethlabstech
- **Authentication**: None (no default credentials)
- **Note**: Accessible only through Traefik

### Loki
- **URL**: http://loki.evethlabstech
- **Authentication**: None
- **API Port**: 3100

### Alertmanager
- **URL**: http://alertmanager.evethlabstech
- **Authentication**: None
- **Note**: Configure alerts in `config/alertmanager/alertmanager.yml`

### Portainer
- **URL**: http://portainer.evethlabstech
- **Username**: Set on first access
- **Password**: Set on first access
- **Note**: You'll create admin credentials on first login

### Harbor
- **URL**: http://harbor.evethlabstech
- **Username**: `admin`
- **Password**: `ChangeMe123!` (from `.env` as `HARBOR_ADMIN_PASSWORD` for initial install)
- **How to Change**:
  1. Login to Harbor web UI as admin
  2. Go to User Profile > Change Password
  3. Update `HARBOR_ADMIN_PASSWORD` in `.env` only for future fresh installs (existing Harbor keeps UI-set password)
  4. Consider creating individual project-level robot accounts for CI

## Database Credentials

### PostgreSQL (SonarQube Database)
- **Host**: `sonarqube-db` (internal Docker network)
- **Port**: 5432
- **Database**: `sonar`
- **Username**: `sonar`
- **Password**: `sonar`
- **Environment Variable**: `SONAR_JDBC_PASSWORD`
- **How to Change**:
  1. Update `SONAR_JDBC_PASSWORD` in `.env`
  2. Remove existing data: `sudo rm -rf ./data/postgres/* ./data/sonarqube/*`
  3. Recreate containers: `docker compose up -d --force-recreate postgres sonarqube`
  4. Fix permissions: `sudo chown -R 1000:1000 ./data/sonarqube/`

### Redis
- **Host**: `redis` (internal Docker network)
- **Port**: 6379
- **Password**: `redis_secure_pass_2024`
- **Environment Variable**: `REDIS_PASSWORD`
- **How to Change**:
  1. Update `REDIS_PASSWORD` in `.env`
  2. Restart container: `docker compose restart redis`

## SMTP/Email Configuration (Optional)

For alert notifications:
- **SMTP Server**: `smtp.gmail.com:587`
- **From Email**: `alerts@evethlabstech`
- **Username**: Configure in `.env` (`SMTP_USER`)
- **Password**: Configure in `.env` (`SMTP_PASSWORD`)

## Security Best Practices

### Immediate Actions After Setup
1. ✅ Change Traefik dashboard password
2. ✅ Change GitLab root password
3. ✅ Change SonarQube admin password
4. ✅ Change Grafana admin password
5. ✅ Set Portainer admin password
6. ✅ Update database passwords if needed
7. ✅ Configure firewall rules
8. ✅ Enable regular backups

### Password Requirements
- Minimum 12 characters
- Include uppercase and lowercase letters
- Include numbers and special characters
- Avoid common words or patterns
- Use a password manager

### Regular Maintenance
- Review user access quarterly
- Rotate passwords every 90 days
- Monitor access logs
- Keep services updated
- Regular security audits

## Password Storage

**Never commit real passwords to version control!**

For production deployments:
1. Use environment variables
2. Use secrets management (HashiCorp Vault, AWS Secrets Manager)
3. Use encrypted configuration files
4. Implement role-based access control (RBAC)

## Emergency Access

If you lose admin access:
1. **GitLab**: Use `gitlab-rake` to reset root password
2. **Grafana**: Reset via `grafana-cli admin reset-admin-password`
3. **SonarQube**: Reset database or use recovery token
4. **Portainer**: Delete Portainer data volume and reconfigure

## Support

For password reset assistance:
- Check service documentation in `/docs` directory
- Review Docker logs: `docker logs <container-name>`
- Consult official documentation for each service

---

**Last Updated**: 2024-11-07  
**Platform Version**: Localhost Development Configuration
