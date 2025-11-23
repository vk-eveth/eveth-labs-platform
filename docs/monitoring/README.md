# Monitoring & Logging Guide

This guide covers the monitoring and logging capabilities of the Eveth Labs Platform.

## Table of Contents
1. [Overview](#overview)
2. [Monitoring Stack](#monitoring-stack)
3. [Logging Stack](#logging-stack)
4. [Alerting](#alerting)
5. [Dashboards](#dashboards)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

## Overview

The monitoring and logging stack provides:
- Real-time system and application metrics
- Centralized log aggregation
- Alerting and notifications
- Performance analysis
- Capacity planning

## Monitoring Stack

### Prometheus

#### Key Features
- Time-series database
- Multi-dimensional data model
- Powerful query language (PromQL)
- Service discovery

#### Access
- Web UI: `http://prometheus.${DOMAIN}`
- API: `http://prometheus:9090/api/v1`

#### Common Queries
```promql
# CPU usage
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100

# Memory usage
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100

# Disk usage
(node_filesystem_size_bytes{mountpoint="/"} - node_filesystem_avail_bytes{mountpoint="/"}) / node_filesystem_size_bytes{mountpoint="/"} * 100
```

### Grafana

#### Key Features
- Visualization dashboards
- Alerting
- Annotations
- Team collaboration

#### Access
- Web UI: `http://grafana.${DOMAIN}`
- Default credentials: admin / (check .env)

#### Pre-configured Dashboards
1. **Node Exporter Full**
   - CPU, memory, disk, and network metrics
   - System load and processes
   - Disk I/O and filesystem usage

2. **Docker Monitoring**
   - Container metrics
   - Resource usage
   - Network I/O

3. **Traefik**
   - Request rates
   - Response times
   - Error rates

## Logging Stack

### Loki

#### Key Features
- Horizontally scalable
- Multi-tenant
- LogQL query language
- Efficient storage

#### Access
- API: `http://loki:3100`
- Through Grafana: `http://grafana.${DOMAIN}/explore`

#### Example Queries
```logql
# Show logs from a specific container
{container_name="gitlab"}

# Search for errors
{container_name=~".+"} |~ "(?i)error"

# Count logs by level
sum by(level) (count_over_time({job="varlogs"} | json | level != "" [1h]))
```

### Promtail

#### Key Features
- Lightweight log collector
- Service discovery
- Log pipeline
- Relabeling

#### Configuration
Location: `config/promtail/promtail-config.yaml`

## Alerting

### Alertmanager

#### Key Features
- Deduplication
- Grouping
- Inhibition
- Silencing

#### Access
- Web UI: `https://alertmanager.${DOMAIN}`
- API: `http://alertmanager:9093/api/v2`

#### Alert Rules
Location: `config/prometheus/alert.rules`

Example alert rule:
```yaml
groups:
- name: node.rules
  rules:
  - alert: HighNodeCPU
    expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100 > 80
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "High CPU usage on {{ $labels.instance }}"
      description: "CPU usage is {{ $value }}%"
```

### Notification Channels
- Email
- Slack
- PagerDuty
- Webhooks
- OpsGenie

## Dashboards

### Creating Dashboards
1. Log in to Grafana
2. Click "+" > "Create" > "Dashboard"
3. Add panels and configure queries
4. Save dashboard

### Importing Dashboards
1. Navigate to "Dashboards" > "Manage"
2. Click "Import"
3. Upload JSON or paste dashboard ID
4. Configure data source
5. Click "Import"

### Recommended Dashboards
1. **System Health**
   - CPU, memory, disk usage
   - Network traffic
   - System load

2. **Application Performance**
   - Request rates
   - Error rates
   - Response times
   - Cache hit ratios

3. **Database Performance**
   - Query performance
   - Connection pools
   - Replication lag
   - Cache efficiency

## Best Practices

### Monitoring
1. **Metrics Collection**
   - Collect only necessary metrics
   - Set appropriate scrape intervals
   - Use consistent labeling

2. **Alerting**
   - Set meaningful alert thresholds
   - Configure proper alert grouping
   - Define clear escalation policies

3. **Dashboard Design**
   - Group related metrics
   - Use appropriate visualizations
   - Set proper time ranges
   - Add annotations for events

### Logging
1. **Structured Logging**
   - Use JSON format
   - Include timestamps
   - Add context (request IDs, user IDs)

2. **Log Levels**
   - DEBUG: Detailed debugging information
   - INFO: Normal operation messages
   - WARN: Non-critical issues
   - ERROR: Errors that need attention
   - FATAL: Critical errors causing shutdown

3. **Retention**
   - Define log retention policies
   - Archive old logs
   - Compress logs when possible

## Troubleshooting

### Common Issues

1. **Missing Metrics**
   ```bash
   # Check Prometheus targets
   curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up")'
   
   # Check service discovery
   curl -s http://localhost:9090/api/v1/targets | jq '.data.droppedTargets'
   ```

2. **High Cardinality**
   ```bash
   # Check high cardinality metrics
   curl -s 'http://localhost:9090/api/v1/series?match[]={__name__=~".+"}' | jq '.data[].__name__' | sort | uniq -c | sort -nr | head -20
   ```

3. **Log Collection Issues**
   ```bash
   # Check Promtail status
   curl -s http://localhost:9080/metrics | grep promtail
   
   # Check Loki logs
   docker logs loki
   ```

4. **Alert Not Firing**
   ```bash
   # Check alert rules
   curl -s http://localhost:9090/api/v1/rules | jq '.data.groups[].rules[] | select(.type=="alerting") | .name'
   
   # Check alertmanager config
   docker exec alertmanager amtool config show --config.file=/etc/alertmanager/alertmanager.yml
   ```

### Performance Tuning

1. **Prometheus**
   ```yaml
   # config/prometheus/prometheus.yml
   global:
     scrape_interval: 15s
     evaluation_interval: 15s
     scrape_timeout: 10s
   
   storage:
     tsdb:
       retention: 30d
       max_samples_per_send: 10000
   ```

2. **Loki**
   ```yaml
   # config/loki/loki-config.yaml
   limits_config:
     ingestion_rate_mb: 16
     ingestion_burst_size_mb: 32
     max_entries_limit_per_query: 5000
     retention_period: 744h  # 31 days
   ```

3. **Grafana**
   ```ini
   # config/grafana/grafana.ini
   [alerting]
   enabled = true
   execute_alerts = true
   
   [auth.anonymous]
   enabled = false
   
   [server]
   http_port = 3000
   domain = grafana.${DOMAIN}
   root_url = %(protocol)s://%(domain)s/
   ```

## Maintenance

### Backup
```bash
# Backup Prometheus data
docker run --rm -v prometheus_data:/source -v $(pwd)/backup:/backup alpine tar czf /backup/prometheus-$(date +%Y%m%d).tar.gz -C /source .

# Backup Grafana dashboards
curl -s http://admin:${GRAFANA_ADMIN_PASSWORD}@localhost:3000/api/search | jq '.[] | .uri' | xargs -I{} curl -s http://admin:${GRAFANA_ADMIN_PASSWORD}@localhost:3000/api/dashboards/{} > grafana-dashboards-$(date +%Y%m%d).json
```

### Cleanup
```bash
# Remove old Docker images
docker image prune -a --filter "until=24h" --force

# Remove old Prometheus data
docker exec prometheus promtool tsdb clean --retention 30d
```

For more detailed troubleshooting, see the [Troubleshooting Guide](/docs/troubleshooting/README.md).
