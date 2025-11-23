#!/bin/bash

set -e

echo "🔒 Starting security hardening..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Please run as root"
    exit 1
fi

# Install required packages
echo "📦 Installing required packages..."
apt-get update
apt-get install -y ufw fail2ban auditd apparmor-utils

# Configure UFW
echo "🔥 Configuring UFW firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 2222/tcp  # GitLab SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw --force enable

# Configure fail2ban
echo "🚨 Configuring fail2ban..."
cat > /etc/fail2ban/jail.local << EOL
[sshd]
enabled = true
port = 2222
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

[docker-tcp]
enabled = true
filter = docker
action = iptables[name=docker, port=2375, protocol=tcp]
logpath = /var/log/docker.log
maxretry = 3
bantime = 3600
EOL

systemctl restart fail2ban

# Docker security
echo "🐳 Hardening Docker..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << EOL
{
  "icc": false,
  "userns-remap": "default",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "no-new-privileges": true
}
EOL

# Enable Docker Content Trust
export DOCKER_CONTENT_TRUST=1

# System hardening
echo "🛡️  Applying system hardening..."
# Disable core dumps
echo "* hard core 0" >> /etc/security/limits.conf

# Secure shared memory
echo "tmpfs /run/shm tmpfs defaults,noexec,nosuid 0 0" >> /etc/fstab

# Enable AppArmor
systemctl enable apparmor
systemctl start apparmor

echo "✅ Security hardening completed!"
echo "Please restart Docker for changes to take effect: systemctl restart docker"
