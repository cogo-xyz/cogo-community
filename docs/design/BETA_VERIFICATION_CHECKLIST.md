## Beta Verification Checklist (Server + Runners)

### 0) Environment
- SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY 설정 확인
- ROUTER_SELECT_URL, KEY_VAULT_URL 설정 확인
- QUALITY_NOTIFY_ADMIN_TOKEN 설정 확인

### 1) Deployment & Ports
- Metrics Server: container up on 3000 (internal 3100)
- Health: GET /health → { status: "healthy" }
- Metrics: GET /metrics → Prometheus text
- Ports policy: external 3000 only; 3100 internal

### 2) Security (minimal for dev server)
- Protected endpoints require header: x-admin-token: $QUALITY_NOTIFY_ADMIN_TOKEN
  - POST /api/notify/weekly-sb (401 without token)
  - POST /api/schedule/weekly (401 without token)

### 3) Runners (Distributed)
- plan-runner (x2) up
- quality-runner (x2) up
- quality-runner includes (current): quality.coverage.ts, quality.aggregate.coverage, quality.lint.snapshot
- Parallelism: LIVE_MAX_PARALLEL=4; Polling: 800ms

### 4) Supabase Data/API
- API: GET /api/metrics/summary → jobs.byStatus, byExecutor, recent
- API: GET /api/metrics/gate/summary → passRatePct, build/test ms, lint/coverage
- API: GET /api/metrics/quality/gate/recent?limit=3 → gate_fix + artifact urls (eslint/coverage)
- API: GET /api/metrics/weekly/latest → weekly-summary.md signed URL
- API: GET /api/metrics/lint/latest → lint-summary.json signed URL

### 5) Notifications & Schedule
- POST /api/notify/weekly-sb (dry mode) → message contains gate_fix links
- POST /api/schedule/weekly → orchestrator.decide + quality jobs enqueued

### 6) Observability
- /dashboard/local (local-only) OK
- Provider Health snapshot: GET /api/metrics/health?since_min=60
- Logs are plain text (container logs); consider JSON optional

### 7) CI / Quality Gates
- GitHub Actions: quality-gate.yml enforces Q1 via Supabase
- Thresholds env: GATE_MIN_PASS_PCT (e.g., 70)

### 8) Scaling & Recovery
- docker compose up -d --scale plan-runner=2 --scale quality-runner=2
- Graceful stop: SIGTERM handler in orchestratorLive

### 9) To Verify Next (deferred)
- Job flow: queued → running → completed for lint/coverage jobs; confirm DLQ=0
- Weekly notify (non-dry) delivery to webhook (set NOTIFY_WEBHOOK_URL)
- LLM routing: plan.design → gemini-2.5-pro path effective via askRag intendedModel
- code executor availability or lightweight build/test path on server
- README_BETA_OPS usage flows tested end-to-end

### Handy Commands
```bash
# Health/Metrics (external)
curl -s http://SERVER_IP:3000/health
curl -s http://SERVER_IP:3000/metrics | head

# Metrics APIs
curl -s http://SERVER_IP:3000/api/metrics/summary
curl -s http://SERVER_IP:3000/api/metrics/gate/summary
curl -s 'http://SERVER_IP:3000/api/metrics/quality/gate/recent?limit=3'

# Weekly (protected)
curl -s -X POST http://SERVER_IP:3000/api/notify/weekly-sb -H "x-admin-token: $QUALITY_NOTIFY_ADMIN_TOKEN" -d '{"dry":true}'
curl -s -X POST http://SERVER_IP:3000/api/schedule/weekly -H "x-admin-token: $QUALITY_NOTIFY_ADMIN_TOKEN"

# Compose (server)
docker compose -f docker-compose.beta.yml up -d metrics
docker compose -f docker-compose.beta.yml up -d plan-runner quality-runner
docker compose -f docker-compose.beta.yml up -d --scale plan-runner=2 --scale quality-runner=2
```


