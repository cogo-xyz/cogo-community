# Verification Checklist (API-only)

이 문서는 UI 없이 API/URL로 시스템을 검증하기 위한 명령 모음입니다.

## 0) 사전 준비
- Collab dev 서버: http://localhost:3100
- Supabase: `SUPABASE_URL`, `SUPABASE_ANON_KEY`
- Collab JWT(개발 로컬): `COLLAB_REQUIRE_JWT=1`, `COLLAB_JWT_MODE=local`, `SUPABASE_JWT_SECRET` → `export TOKEN='<DEV_JWT>'`

## 1) Collab API
- Health
```bash
curl -s http://localhost:3100/api/collab/health
```
- Assign
```bash
curl -s -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"type":"browser.run","executorId":"verify-demo","payload":{"url":"https://supabase.com"}}' \
  http://localhost:3100/api/collab/task.assign
```
- Claim(lease/typePrefix)
```bash
curl -s -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"executorId":"verify-demo","workerId":"worker-01","leaseSeconds":90,"typePrefix":"browser."}' \
  http://localhost:3100/api/collab/task.claim
```
- Result(+artifact) / Fail→Retry→DLQ
```bash
JOB_ID='<UUID>'
curl -s -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"jobId":"'$JOB_ID'","type":"browser.run","ok":true,
       "artifact":{"url":"https://supabase.com/logo.png","name":"screenshot.png","size":1024}}' \
  http://localhost:3100/api/collab/task.result
curl -s -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"jobId":"'$JOB_ID'","type":"browser.run","ok":false,"error":"simulated-fail"}' \
  http://localhost:3100/api/collab/task.result
```
- Summary / Events
```bash
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:3100/api/collab/job/$JOB_ID/summary
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:3100/api/collab/events/by-job/$JOB_ID
```
- Metrics / Recent(cursor)
```bash
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:3100/api/collab/metrics/overview
curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:3100/api/collab/jobs/recent?limit=5&executorId=verify-demo"
# next page
curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:3100/api/collab/jobs/recent?limit=5&executorId=verify-demo&cursor=<ISO_CREATED_AT>"
# 주의: 다음 커서가 null이면 더 이상 호출하지 말 것(null 전달 시 400/500 발생 가능)
```
- Workers heartbeat / active
```bash
curl -s -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"agentId":"agent-01","executorId":"verify-demo","status":"idle","running":0,"capacity":1}' \
  http://localhost:3100/api/collab/workers/heartbeat
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:3100/api/collab/workers/active
```

## 2) Edge Functions(EF)
Headers(dev): `apikey: $SUPABASE_ANON_KEY`, `Authorization: Bearer $SUPABASE_ANON_KEY`
```bash
$SUPABASE_URL/functions/v1/metrics-overview
$SUPABASE_URL/functions/v1/jobs-recent?limit=5
$SUPABASE_URL/functions/v1/jobs-recent?limit=5&cursor=<ISO_CREATED_AT>
$SUPABASE_URL/functions/v1/workers-active
$SUPABASE_URL/functions/v1/artifacts-list?jobId=$JOB_ID
$SUPABASE_URL/functions/v1/sign-artifact?bucket=artifacts&path=<object_path>&expires=3600
$SUPABASE_URL/functions/v1/leases-release
$SUPABASE_URL/functions/v1/dlq-list?limit=20
# retry
curl -s -X POST -H "apikey: $SUPABASE_ANON_KEY" -H "Authorization: Bearer $SUPABASE_ANON_KEY" -H 'Content-Type: application/json' \
  -d '{"dlqId":1}' "$SUPABASE_URL/functions/v1/dlq-retry"
```

Notes:
- `artifacts-list`는 DB `artifacts` 테이블 기준으로 반환됩니다.
- `sign-artifact`는 Supabase Storage에 존재하는 객체 경로가 필요합니다. 존재하지 않는 경로로 호출 시 `Object not found`가 반환됩니다.
- 일반적으로 `bucket=artifacts`, `path`는 업로드 시 사용한 상대 경로(예: `2025/08/09/<jobId>/screenshot.png`).

### EF: Upload → Sign quick test
- 업로드(로컬 개발에서만, 서비스 롤 키 사용 권장):
```bash
SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... \
  npx ts-node src/scripts/uploadTestArtifact.ts | tee /tmp/artifact.json
```
- 서명 URL 발급:
```bash
BUCKET=$(jq -r .bucket /tmp/artifact.json)
PATH=$(jq -r .path /tmp/artifact.json)
curl -sS -H "apikey: $SUPABASE_ANON_KEY" -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  "$SUPABASE_URL/functions/v1/sign-artifact?bucket=$BUCKET&path=$PATH&expires=3600"
```

## 3) Realtime(job_events)
```bash
SUPABASE_URL=... SUPABASE_ANON_KEY=... npx ts-node src/tests/WatchJobEvents.ts $JOB_ID
```
Expected: `queued` → `assigned` → `started` → `succeeded/failed` in order.

## 4) Swagger(Collab)
- UI:  http://localhost:3100/docs
- JSON: http://localhost:3100/docs.json
- Spec: `docs/openapi/collab.yaml` (v0.2.0)

## 5) Quick E2E
```bash
TOKEN='<DEV_JWT>' BASE_URL=http://localhost:3100 EXECUTOR_ID=dev-flow scripts/demo-collab-flow.sh
SUPABASE_URL=... SUPABASE_ANON_KEY=... bash scripts/test-edge.sh
```

### 5.1) Convenience scripts
```bash
# Realtime job_events watch (default 5s)
SUPABASE_URL=... SUPABASE_ANON_KEY=... JOB_ID=<uuid> DURATION_MS=3000 npm run realtime:watch

# Upload a small test artifact and print {bucket,path}
SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... npm run artifact:upload
```

## 6) DoD
- Collab: assign/claim/result/summary/events/metrics/workers → 2xx
- EF: metrics/jobs(cursor)/workers/artifacts/sign/leases-release/dlq-list/dlq-retry → 2xx
- Realtime: job_events ordered delivery
- OpenAPI v0.2.0 = 실제 응답