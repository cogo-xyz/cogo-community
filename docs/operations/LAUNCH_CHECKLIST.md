## Launch Checklist

### Before launch (must-do)
- Security / RLS hardening
  - Apply `docs/RLS_HARDENING_SQL_TEMPLATE.sql` in Supabase SQL Editor
  - Verify anon cannot insert into `jobs`/`artifacts` via `src/tests/RlsPermissionsProbe.ts`
  - Rotate keys if needed; ensure service key never exposed in logs
- CI secrets & schedules
  - Set `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`
  - Confirm daily scheduled health run passes
- Storage
  - Ensure `artifacts` bucket exists (CI step or manual) and retention as desired

- Minimal Workflow (GitHub)
  - Private + Free: `docs/MINIMAL_WORKFLOW.md`를 준수(PR 강제, Squash, 수동 리뷰)
  - `.github/PULL_REQUEST_TEMPLATE.md` 적용 확인
  - Actions Enabled + `ci.yml` 성공(스모크 리포트 업로드 확인)

- Observability (Prometheus/Grafana)
  - Server `/metrics` 수집 설정(prometheus.yml)
  - Import `docs/grafana/COGO_Minimal_Dashboard.json`
  - 대시보드에서 throughput/latency/inflight 정상 표시 확인

- Centralized LLM Routing & Key Management
  - Keys encrypted at rest: store with `is_encrypted=true`, Edge Function decrypts via KMS (no plaintext at rest)
  - Key rotation: versioned (`version_int`), roll-forward then disable old; audit reads/writes in `secure_keys_audit`
  - Edge Functions auth: keep JWT verification ON; require `Authorization` and `apikey` headers
  - Quotas/limits: enforce per-tenant/model in Edge (`usage_counters`), alert on thresholds
  - Provider catalog kept current: `llm_providers`, `llm_models` with cost/context/regions
  - Routing policies: define `routing_policies` (cost/SLA/domain), enable/priority reviewed
  - Health feed: update `provider_health` (latency/error) via scheduled job; router uses it
  - Secrets hygiene: service role never leaves server; anon key only in client headers

- Queue/Jobs Reliability
  - `job_events` 전이 기록(queued/assigned/succeeded/failed_dlq/retry_scheduled) 확인
  - DLQ 경로(`job_dead_letters`/`jobs_dlq`) 기록 및 `dlq-list`/`dlq-retry` 동작 확인
  - 회귀 스모크 `npm run ci:smoke` 로컬/CI 모두 ok

### Nice-to-have (recommended)
- Observability: dashboard and alerts on Realtime disconnects and job failures
- Worker hardening: remove force-success paths, add retries/backoff, explicit timeouts
 - LLM proxy: streaming, response caching, rate-limit, token budget guard
 - A/B routing: policy buckets, budget caps per project/tenant
 - Dashboards: usage/cost per provider/model, error budget, rotation status

### Post-launch
- Periodic E2E (browser/figma) on production keys
- Key rotation policy and incident runbook
  - Rotation cadence documented; emergency revoke steps; compromise playbook
  - KMS key lifecycle & access reviews

### Reference Docs
- `docs/DEVELOPMENT_EXECUTION_PLAN_VNEXT.md`
- `docs/specs/STATE_MACHINE_V1.md`
- `docs/specs/SAGA_AND_COMPENSATION_V1.md`
- `docs/specs/MESSAGE_SCHEMA_V1.md`
- `docs/grafana/METRICS_DASHBOARD_SKETCH.md`


