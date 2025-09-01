## COGO Agent Core – Operations Runbook

### Worker (DB mode) – Env
- SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY
- EXECUTOR_ID, WORKER_MODE=db, WORKER_ID
- MAX_JOBS (optional deterministic exit)
- Browser: BROWSER_REAL_MODE, HEADLESS, NO_SANDBOX, BROWSER_CHANNEL, BROWSER_NAV_TIMEOUT_MS, BROWSER_FORCE_SUCCESS
- Figma: FIGMA_API_TOKEN

### Webhooks
- WEBHOOK_TYPE=github|slack|http|googlechat
  - github: GITHUB_OWNER, GITHUB_REPO, GITHUB_TOKEN (repo+workflow scope; issue upsert via Actions)
  - slack: SLACK_WEBHOOK_URL
  - http: WEBHOOK_URL
  - googlechat:
    - Name: COGO Ops Alerts (`cogo-ops-alerts`)
    - Key-Vault ref: `googlechat:notify:webhook_url` (env-scoped)
    - Env var: `GOOGLE_CHAT_WEBHOOK_URL`
    - Preferred runtime env: set `WEBHOOK_TYPE=googlechat`
    - URL example (store by reference only): `https://chat.googleapis.com/v1/spaces/AAQAV1lsEsc/messages?key=...&token=...`
    - Test:
      - `curl -X POST -H 'Content-Type: application/json; charset=UTF-8' -d '{"text":"COGO webhook test"}' "$GOOGLE_CHAT_WEBHOOK_URL"`

### Metrics & Dashboards (New)
- Endpoints
  - GET `/api/metrics/quality/gate/recent?limit=3` → 최근 `gate_fix` 3건과 ESLint/Coverage 아티팩트 URL
  - GET `/dashboard/local` → 로컬 대시보드(게이트/요약/빌드·테스트 지연/최근 gate_fix/Provider Health)
  - GET `/api/metrics/gate/summary` → 게이트 집계 요약(JSON)
- Scripts
  - `npm run -s metrics:snapshot` → 24h 게이트 요약 스냅샷
  - `npm run -s notify:weekly` (로컬 집계 기반, METRICS_BASE 필요)
  - `npm run -s notify:weekly:sb` (Supabase 직접 조회 기반)
  - 보호 엔드포인트 호출 시:
    - 헤더 `x-admin-token: $QUALITY_NOTIFY_ADMIN_TOKEN` 필요
    - 서버 환경변수에 `QUALITY_NOTIFY_ADMIN_TOKEN` 설정

### Quality Gate (New)
- CI Scripts
  - `npm run -s ci:gate:q1` → 메트릭 요약 API 기반 Q1 검증
  - `npm run -s ci:gate:q1:sb` → Supabase DB 직접 조회 기반 Q1 검증(권장)
- GitHub Actions
  - `.github/workflows/quality-gate.yml` → PR 대상 브랜치에서 Gate Q1(기본 70%) 검사
  - 브랜치 보호 규칙에 “Quality Gate (Q1)”를 Required status checks로 추가

### Scheduled Ops (New)
- `.github/workflows/scheduled-ops.yml`
  - Nightly(UTC 02:00): `metrics:snapshot`
  - Weekly(UTC 02:05 Monday): `weekly:enqueue`
  - workflow_dispatch 지원(수동 실행)

### Edge Functions – Router/KeyVault 호출 규칙
- Headers: `Authorization: Bearer <SUPABASE_ANON_KEY>`, `apikey: <SUPABASE_PUBLISHABLE_KEY>`
- Routes:
  - `ROUTER_SELECT_URL=$SUPABASE_URL/functions/v1/router-select`
  - `KEY_VAULT_URL=$SUPABASE_URL/functions/v1/key-vault`

### Admin Token – 관리 가이드
- 생성: `openssl rand -hex 32`
- 중앙 저장(선택):
```
SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... \
npx ts-node src/scripts/keys/upsertDirectDB.ts quality notify admin_token "<TOKEN>" dev false
```
- 서버 적용: compose/env 파일에 `QUALITY_NOTIFY_ADMIN_TOKEN=<TOKEN>` 추가 후 재시작


### Scripts (npm run …)
- Enqueue
  - enqueue:browser (basic)
  - enqueue:figma (basic)
  - enqueue:idempotent (SHA-256 key); env: JOB_TYPE, EXECUTOR_ID, BROWSER_TEST_URL, IDEMPOTENCY_KEY
- List
  - list:jobs (includes attempts, next_run_at)
  - list:artifacts
  - list:workers
  - list:heartbeats (env: WORKER_ID, LIMIT)
  - list:dlq
- Retry / DLQ / Recovery
  - retry:failed (default DRY_RUN=true; env: EXECUTOR_ID, TYPE_PREFIX, LIMIT, RESET_ATTEMPTS, DRY_RUN)
  - replay:dlq (re-queue failed jobs; sets idempotency_key="dlq:<job_id>")
  - recover:leases (reset expired leases)
- Maintenance
  - cleanup:artifacts (env: ARTIFACT_TTL_DAYS, ARTIFACT_DELETE_STORAGE)
  - purge:jobs (default DRY_RUN=true; env: JOB_TTL_DAYS, JOB_PURGE_STATUSES, DRY_RUN)

### Worker Logic – Highlights
- Lease-based claim (RPC: claim_one_job) with renewal
- Exponential backoff with jitter → next_run_at used by claim filter
- Heartbeats to worker_heartbeats; device registry in worker_devices
- Artifact upload to Storage + row to artifacts
- Metrics: latency histogram, success/fail counters
- DLQ on max attempts (jobs_dlq)
- Graceful shutdown: requeue running, clear lease, stop heartbeat

### Supabase DB – Required SQL (apply in SQL Editor)
1) Executor/Worker base tables (existing: 20250808090921_executor_worker_tables.sql)
2) Job leases addon (existing: 20250809000100_add_job_leases.sql)
3) DLQ + artifacts index: 20250809001500_jobs_dlq_and_artifact_ttl.sql
4) next_run_at column: 20250809004000_jobs_next_run_at.sql
5) claim_one_job with next_run_at filter: 20250809004100_claim_one_job_with_next_run.sql
6) Operational indexes: 20250809005000_jobs_indexes.sql

### CI
- .github/workflows/db-mode-integration.yml (secrets gate at step-level). Secrets required:
  - SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY

### Troubleshooting
- repository_dispatch 404: token repo access/SSO/owner-repo mismatch. Prefer Classic PAT (repo, workflow) + collaborator(Admin).
- Realtime glitches: restart worker; fallback DB polling continues.
- Storage signed URL errors: verify bucket and service role key usage.


