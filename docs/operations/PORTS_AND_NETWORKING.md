## Ports and Networking (Dev PC vs Server)

### Overview
This document standardizes port usage across local development and the real server. The goal is to keep local ports developer-friendly while exposing only a single HTTP port externally on the server.

### Port Matrix
- SSH: 22022 (server only)
- External HTTP (server): 3000
- Internal Metrics Server: 3100 (container/local-only)
- Node Inspect (optional): 9229 (temporary, only when debugging)
- Distributed runners (plan/quality): no external port exposure (Supabase only)

### Local Development (Dev PC)
- Metrics server: http://localhost:3100
- Local dashboard: http://localhost:3100/dashboard/local
- Schedule/Notify (dev-only): http://localhost:3100/api/... (not exposed externally)

Environment
```
METRICS_PORT=3100
```

### Server (Real/Beta)
- Externally exposed: 3000 → container internal 3100
  - docker-compose: `ports: [ "3000:3100" ]`
- Internal: container listens on 3100 (not directly exposed to Internet)
- Runners: headless (no port exposure), communicate via Supabase

Environment
```
METRICS_PORT=3100
QUALITY_NOTIFY_ADMIN_TOKEN=<set for protected endpoints>
```

Example docker compose (excerpt)
```yaml
services:
  metrics:
    build:
      context: .
      dockerfile: Dockerfile.metrics
    image: cogo-metrics:beta
    env_file: .env.beta
    ports:
      - "3000:3100"
    restart: unless-stopped
    volumes:
      - ./logs:/app/logs
```

### Firewall (UFW) Recommendations
- Allow: 22022/tcp (SSH), 3000/tcp (public HTTP)
- Deny: 3100/tcp (internal metrics), 9229/tcp (open only temporarily for debugging)

Commands
```bash
sudo ufw allow 22022/tcp
sudo ufw allow 3000/tcp
sudo ufw deny 3100/tcp
# optional debug
# sudo ufw allow 9229/tcp
```

### Operational Endpoints
- Server (external): `http://SERVER_IP:3000/health`, `/metrics`, `/api/...`
- Local: `http://localhost:3100/...`

Protected endpoints (server)
- `/api/schedule/weekly`
- `/api/notify/weekly-sb`

Use admin token header when calling from outside trusted network:
```
H: x-admin-token: $QUALITY_NOTIFY_ADMIN_TOKEN
```

### Quick Tests
```bash
# server
curl -s http://SERVER_IP:3000/health
curl -s http://SERVER_IP:3000/metrics | head

# local
curl -s http://localhost:3100/health || true
curl -s http://localhost:3100/metrics | head || true
```


