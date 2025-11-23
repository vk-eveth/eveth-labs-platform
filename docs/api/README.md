# API Reference

This document provides comprehensive documentation for the Eveth Labs Platform APIs.

## Table of Contents
1. [Authentication](#authentication)
2. [API Endpoints](#api-endpoints)
3. [Rate Limiting](#rate-limiting)
4. [Error Handling](#error-handling)
5. [Versioning](#versioning)
6. [Best Practices](#best-practices)
7. [Examples](#examples)
8. [Troubleshooting](#troubleshooting)

## Authentication

### OAuth 2.0

```http
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=password&
client_id=your_client_id&
client_secret=your_client_secret&
username=user@example.com&
password=your_password
```

#### Response
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "tGzv3JOkF0XG5Qx2TlKWIA"
}
```

### API Keys

```http
GET /api/v1/resource
Authorization: Bearer your_api_key
X-API-Key: your_api_key
```

## API Endpoints

### GitLab API

#### List Projects
```http
GET /api/v4/projects
```

#### Create Project
```http
POST /api/v4/projects
{
  "name": "My Project",
  "visibility": "private"
}
```

### Harbor API

#### List Repositories
```http
GET /api/v2.0/projects/{project_name}/repositories
```

#### Push Image
```bash
docker tag myimage harbor.example.com/library/myimage:latest
docker login harbor.example.com
docker push harbor.example.com/library/myimage:latest
```

### Monitoring API

#### Query Metrics
```http
GET /api/v1/query?query=up
```

## Rate Limiting

- **Unauthenticated**: 60 requests/minute
- **Authenticated**: 1000 requests/minute
- **Admin**: 5000 requests/minute

## Error Handling

### Common HTTP Status Codes

| Code | Status | Description |
|------|--------|-------------|
| 200 | OK | Request successful |
| 201 | Created | Resource created |
| 400 | Bad Request | Invalid request |
| 401 | Unauthorized | Authentication required |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource not found |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |

### Error Response Format
```json
{
  "error": {
    "code": "invalid_request",
    "message": "Invalid request parameters",
    "details": {
      "field": "name",
      "issue": "required"
    }
  }
}
```

## Versioning

API versioning is done through the URL path:

```
/api/v1/resource
```

## Best Practices

### Request Headers
```http
Accept: application/json
Content-Type: application/json
Authorization: Bearer your_access_token
X-Request-ID: your_request_id
```

### Pagination
```http
GET /api/v1/resources?page=1&per_page=20
```

### Filtering
```http
GET /api/v1/resources?status=active&created_after=2023-01-01
```

### Sorting
```http
GET /api/v1/resources?sort=name&order=desc
```

## Examples

### cURL
```bash
# Get project details
curl -X GET \
  'https://api.example.com/v1/projects/123' \
  -H 'Authorization: Bearer your_access_token' \
  -H 'Accept: application/json'

# Create a new project
curl -X POST \
  'https://api.example.com/v1/projects' \
  -H 'Authorization: Bearer your_access_token' \
  -H 'Content-Type: application/json' \
  -d '{"name":"New Project","description":"Project description"}'
```

### Python
```python
import requests

# Set up the API client
base_url = 'https://api.example.com/v1'
headers = {
    'Authorization': 'Bearer your_access_token',
    'Accept': 'application/json',
    'Content-Type': 'application/json'
}

# Get projects
response = requests.get(f"{base_url}/projects", headers=headers)
projects = response.json()

# Create a project
new_project = {
    "name": "API Project",
    "description": "Created via API"
}
response = requests.post(
    f"{base_url}/projects",
    headers=headers,
    json=new_project
)
```

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Check token expiration
   - Verify API key permissions
   - Ensure correct authentication headers

2. **Rate Limiting**
   - Implement exponential backoff
   - Cache responses when possible
   - Monitor rate limit headers

3. **Validation Errors**
   - Check request body against API schema
   - Validate input data before sending
   - Review error details in response

### Debugging

#### Enable Debug Logging
```bash
# Enable HTTP request/response logging
curl -v -H "Authorization: Bearer your_token" https://api.example.com/v1/resource
```

#### Check API Status
```http
GET /healthz
```

For more detailed troubleshooting, see the [Troubleshooting Guide](/docs/troubleshooting/README.md).
