# Security Guide

This guide covers security best practices and configurations for the Eveth Labs Platform.

## Table of Contents
1. [Security Overview](#security-overview)
2. [Authentication & Authorization](#authentication--authorization)
3. [Network Security](#network-security)
4. [Container Security](#container-security)
5. [Data Protection](#data-protection)
6. [Compliance](#compliance)
7. [Security Monitoring](#security-monitoring)
8. [Incident Response](#incident-response)
9. [Best Practices](#best-practices)
10. [Troubleshooting](#troubleshooting)

## Security Overview

The Eveth Labs Platform implements multiple layers of security:

1. **Perimeter Security**
   - Firewall rules
   - Network segmentation
   - DDoS protection

2. **Access Control**
   - Role-based access control (RBAC)
   - Multi-factor authentication (MFA)
   - Single sign-on (SSO)

3. **Data Protection**
   - Encryption at rest and in transit
   - Key management
   - Data masking

4. **Monitoring & Logging**
   - Security event logging
   - Intrusion detection
   - Anomaly detection

## Authentication & Authorization

### GitLab Authentication

#### LDAP/AD Integration
```yaml
# config/gitlab/gitlab.rb
gitlab_rails['ldap_enabled'] = true
gitlab_rails['ldp_servers'] = {
  'main' => {
    'label' => 'LDAP',
    'host' => 'ldap.example.com',
    'port' => 636,
    'uid' => 'sAMAccountName',
    'encryption' => 'simple_tls',
    'verify_certificates' => true,
    'bind_dn' => 'CN=GitLab,OU=Service Accounts,DC=example,DC=com',
    'password' => 'password',
    'active_directory' => true,
    'base' => 'DC=example,DC=com',
    'user_filter' => '(memberOf=CN=GitLab Users,DC=example,DC=com)'
  }
}
```

#### OAuth2/OIDC
```yaml
# config/gitlab/gitlab.rb
gitlab_rails['omniauth_enabled'] = true
gitlab_rails['omniauth_allow_single_sign_on'] = ['saml', 'google_oauth2']
gitlab_rails['omniauth_block_auto_created_users'] = true

gitlab_rails['omniauth_providers'] = [
  {
    name: 'google_oauth2',
    app_id: 'YOUR_APP_ID',
    app_secret: 'YOUR_APP_SECRET',
    args: { access_type: 'offline', approval_prompt: '' }
  }
]
```

### Harbor Authentication

#### LDAP/AD Integration
```yaml
# config/harbor/harbor.yml
auth_mode: ldap_auth
ldap_url: ldaps://ldap.example.com
ldap_base_dn: dc=example,dc=com
ldap_uid: sAMAccountName
ldap_verify_cert: true
ldap_search_dn: CN=Harbor,OU=Service Accounts,DC=example,DC=com
ldap_search_password: password
ldap_group_search_filter: (objectClass=group)
ldap_group_attribute_name: cn
ldap_group_search_scope: 2
```

#### OIDC Integration
```yaml
# config/harbor/harbor.yml
auth_mode: oidc_auth
oidc_name: Keycloak
oidc_endpoint: https://keycloak.example.com/auth/realms/master
oidc_client_id: harbor
oidc_client_secret: client-secret
oidc_scope: openid,profile,email
oidc_verify_cert: true
oidc_groups_claim: groups
```

## Network Security

### Firewall Configuration

#### UFW (Uncomplicated Firewall)
```bash
# Allow SSH
sudo ufw allow 22/tcp

# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable
```

#### Docker Network Security
```yaml
# docker-compose.override.yml
networks:
  default:
    driver: bridge
    enable_ipv6: false
    internal: false
    ipam:
      driver: default
      config:
        - subnet: 172.28.0.0/16
          gateway: 172.28.0.1
```

### Network Policies

#### Calico Network Policy
```yaml
# Allow only specific pods to access the database
apiVersion: projectcalico.org/v3
kind: NetworkPolicy
metadata:
  name: allow-db-access
  namespace: production
spec:
  selector: app == 'postgres'
  types:
  - Ingress
  ingress:
  - action: Allow
    protocol: TCP
    source:
      selector: app in {'api', 'backend'}
    destination:
      ports:
      - 5432
```

## Container Security

### Docker Daemon Security

#### Daemon Configuration
```json
// /etc/docker/daemon.json
{
  "icc": false,
  "userns-remap": "default",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "no-new-privileges": true,
  "selinux-enabled": true,
  "userns-remap": "default"
}
```

### Container Runtime Security

#### AppArmor Profile
```bash
# /etc/apparmor.d/containers/gitlab
#include <tunables/global>

profile gitlab flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>
  
  # Deny all file operations
  deny /etc/** w,
  deny /root/** w,
  deny /usr/local/bin/** w,
  
  # Allow specific paths
  /var/opt/gitlab/** rw,
  /var/log/gitlab/** rw,
  
  # Capabilities
  capability dac_override,
  capability setgid,
  capability setuid,
  
  # Network
  network inet tcp,
  network inet6 tcp,
  network inet udp,
  network inet6 udp,
}
```

#### Seccomp Profile
```json
// /etc/docker/seccomp/gitlab.json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "syscalls": [
    {
      "names": [
        "accept",
        "access",
        "arch_prctl",
        "bind",
        "chdir",
        "clock_gettime",
        "clone",
        "close",
        "connect",
        "dup",
        "epoll_ctl",
        "epoll_pwait",
        "execve",
        "exit_group",
        "fchmod",
        "fchown32",
        "fcntl",
        "fstat",
        "futex",
        "getcwd",
        "getdents",
        "getegid",
        "geteuid",
        "getgid",
        "getpeername",
        "getpid",
        "getppid",
        "getsockname",
        "getsockopt",
        "gettid",
        "getuid",
        "ioctl",
        "kill",
        "listen",
        "lseek",
        "lstat",
        "mmap",
        "mprotect",
        "munmap",
        "nanosleep",
        "newfstatat",
        "open",
        "openat",
        "pipe",
        "poll",
        "pread64",
        "pwrite64",
        "read",
        "readlink",
        "recvfrom",
        "recvmsg",
        "rt_sigaction",
        "rt_sigprocmask",
        "rt_sigreturn",
        "sched_getaffinity",
        "select",
        "sendfile",
        "sendmsg",
        "set_robust_list",
        "set_tid_address",
        "setsockopt",
        "shutdown",
        "socket",
        "stat",
        "sysinfo",
        "uname",
        "unlink",
        "write"
      ],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

## Data Protection

### Encryption

#### Encrypted Volumes
```yaml
# docker-compose.override.yml
services:
  postgres:
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password
    secrets:
      - db_password

volumes:
  postgres_data:
    driver: local
    driver_opts:
      type: crypt
      device: /path/to/encrypted/volume
      o: defaults

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

### Secrets Management

#### Docker Secrets
```bash
# Create a secret
echo "mysecretpassword" | docker secret create db_password -

# Use in compose file
services:
  postgres:
    image: postgres:13
    secrets:
      - db_password
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password

secrets:
  db_password:
    external: true
```

## Compliance

### CIS Benchmarks

#### Docker Bench for Security
```bash
# Run CIS benchmark
docker run --rm --net host --pid host --userns host --cap-add audit_control \
  -e DOCKER_CONTENT_TRUST=1 \
  -v /etc:/etc:ro \
  -v /usr/bin/docker:/usr/bin/docker:ro \
  -v /var/lib/docker:/var/lib/docker:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --label docker_bench_security \
  docker/docker-bench-security
```

### GDPR Compliance

#### Data Protection Impact Assessment (DPIA)
1. **Data Inventory**
   - Document all personal data processing activities
   - Map data flows
   - Identify data storage locations

2. **Risk Assessment**
   - Identify risks to data subjects
   - Assess likelihood and severity
   - Implement mitigating controls

3. **Documentation**
   - Maintain records of processing activities
   - Document data protection measures
   - Keep audit logs of access to personal data

## Security Monitoring

### Falco for Runtime Security

#### Falco Rules
```yaml
# /etc/falco/falco_rules.yaml
- rule: Terminal shell in container
  desc: A shell was used as the entrypoint/exec point into a container
  condition: >
    container_started and container
    and shell_procs and proc.tty != 0
    and container_entrypoint
    and not user_expected_terminal_shell_in_container_conditions
  output: >
    Shell spawned in a container (user=%user.name %container.info
    shell=%proc.name parent=%proc.pname cmdline=%proc.cmdline terminal=%proc.tty
    container_id=%container.id image=%container.image.repository)
  priority: NOTICE
  tags: [container, shell, mitre_execution]
```

### Audit Logging

#### Auditd Configuration
```ini
# /etc/audit/auditd.conf
log_file = /var/log/audit/audit.log
log_format = RAW
log_group = root
priority_boost = 4
flush = INCREMENTAL_ASYNC
freq = 50
max_log_file = 50
num_logs = 5
priority_boost = 4
disp_qos = lossy
dispatcher = /sbin/audispd
name_format = hostname
##name = mydomain
max_log_file_action = ROTATE
space_left = 75
space_left_action = SYSLOG
action_mail_acct = root
admin_space_left = 50
admin_space_left_action = SUSPEND
disk_full_action = SUSPEND
disk_error_action = SUSPEND
use_libwrap = yes
##tcp_listen_port = 60
tcp_listen_queue = 5
tcp_max_per_addr = 1
##tcp_client_ports = 1024-65535
tcp_client_max_idle = 0
transport = TCP
krb5_principal = auditd
##krb5_key_file = /etc/audit/audit.key
distribute_network = no
```

## Incident Response

### Playbook: Suspected Container Breakout

1. **Containment**
   ```bash
   # Stop the container
   docker stop suspicious_container
   
   # Pause the container (preserves state)
   docker pause suspicious_container
   
   # Disconnect from network
   docker network disconnect bridge suspicious_container
   ```

2. **Investigation**
   ```bash
   # Save container state
   docker export suspicious_container > suspicious_container.tar
   
   # Save container logs
   docker logs suspicious_container > suspicious_container.log
   
   # Check for rootkits
   docker run --rm -v /:/host:ro -v /var/run/docker.sock:/var/run/docker.sock \
     aquasec/kube-bench:latest --benchmark cis-1.6
   ```

3. **Remediation**
   ```bash
   # Update all images and rebuild
   docker compose pull
   docker compose build --no-cache
   
   # Rotate all credentials
   ./scripts/rotate-secrets.sh
   ```

## Best Practices

### General Security
1. **Principle of Least Privilege**
   - Run containers as non-root users
   - Drop unnecessary capabilities
   - Use read-only filesystems where possible

2. **Secure Configuration**
   - Use minimal base images
   - Remove unnecessary packages
   - Harden the host OS

3. **Vulnerability Management**
   - Regularly scan images for vulnerabilities
   - Keep all components up to date
   - Subscribe to security advisories

### Network Security
1. **Network Segmentation**
   - Use separate networks for different tiers
   - Implement network policies
   - Encrypt traffic between services

2. **Firewall Rules**
   - Default deny all
   - Allow only necessary ports
   - Rate limit connections

### Authentication & Authorization
1. **Strong Authentication**
   - Enforce MFA for all users
   - Use strong password policies
   - Implement account lockout

2. **Role-Based Access Control**
   - Define clear roles and permissions
   - Regularly review access
   - Implement just-in-time access

## Troubleshooting

### Common Issues

1. **Permission Denied Errors**
   ```bash
   # Check container user
   docker exec -it <container> whoami
   
   # Check file permissions
   docker exec -it <container> ls -la /path/to/file
   
   # Check SELinux context
   ls -Z /path/to/file
   ```

2. **Network Connectivity Issues**
   ```bash
   # Check container network
   docker network inspect <network>
   
   # Test connectivity
   docker run --rm --network <network> nicolaka/netshoot nc -zv <service> <port>
   
   # Check iptables rules
   iptables -L -n -v
   ```

3. **Container Failing to Start**
   ```bash
   # Check container logs
   docker logs <container>
   
   # Check container status
   docker inspect <container> | jq '.[].State'
   
   # Check kernel logs
   journalctl -k | grep -i docker
   ```

4. **High CPU/Memory Usage**
   ```bash
   # Check container stats
   docker stats
   
   # Check processes in container
   docker top <container>
   
   # Profile CPU usage
   docker exec -it <container> top -o %CPU
   ```

### Security Tools

1. **Container Scanning**
   ```bash
   # Scan for vulnerabilities
   docker scan <image>
   
   # Use Trivy
   docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
     aquasec/trivy image <image>
   ```

2. **Network Scanning**
   ```bash
   # Nmap scan
   docker run --rm --network host instrumentisto/nmap -sV <target>
   
   # Nikto web scanner
   docker run --rm frapsoft/nikto -h <target>
   ```

3. **Secrets Scanning**
   ```bash
   # Detect secrets in code
   docker run --rm -v $(pwd):/src zricethezav/gitleaks:latest detect --source=/src
   
   # Check for exposed secrets
   docker run --rm -v $(pwd):/src trufflesecurity/trufflehog:latest github --repo=file:///src
   ```

For more detailed troubleshooting, see the [Troubleshooting Guide](/docs/troubleshooting/README.md).
