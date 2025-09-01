## Metrics & Notification APIs

### JSON APIs
- GET `/api/metrics/summary`
  - jobs(상태/최근), cbo, rag, totals(리트라이/DLQ/토큰/비용)
- GET `/api/metrics/gate/summary`
  - passRatePct, build/test latency(avg/p50/p90), lint 통계
- GET `/api/metrics/quality/gate/recent?limit=3`
  - 최근 `gate_fix` 3건 + ESLint/Coverage 아티팩트 URL
- GET `/api/metrics/health?since_min=60`
  - Provider Health 스냅샷(최근 60분)

### Local Dashboard
- GET `/dashboard/local`
  - Gate(local), Metrics summary, Build/Test latency, Recent gate_fix, Provider Health, Weekly Summary(local)

### Weekly Notification
- POST `/api/notify/weekly-sb`
  - Body: `{ "dry": true|false, "limit": 200 }`
  - 동작: Supabase에서 최근 게이트 집계/weekly 문서/최근 gate_fix 아티팩트 수집 → 메시지 생성 →
    - dry=true: 미전송, 메시지 반환
    - dry=false: 서버의 Webhook 설정으로 전송
  - 환경변수(서버):
    - `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`
    - `QUALITY_WEBHOOK_URLS`(쉼표 구분), `QUALITY_WEBHOOK_SECRET`(선택)
  - 보호 정책:
    - Admin 토큰 헤더 필요: `x-admin-token: $QUALITY_NOTIFY_ADMIN_TOKEN`
    - 토큰 미지정 시 401 `{"ok":false,"error":"unauthorized"}`

### Edge Functions (호출 규칙)
- Headers: `Authorization: Bearer <SUPABASE_ANON_KEY>`, `apikey: <SUPABASE_PUBLISHABLE_KEY>`
- ROUTER_SELECT_URL: `$SUPABASE_URL/functions/v1/router-select`
- KEY_VAULT_URL: `$SUPABASE_URL/functions/v1/key-vault`

### Examples
```bash
# Recent gate_fix (3)
curl -sS http://<HOST>:3000/api/metrics/quality/gate/recent | jq .

# Gate summary
curl -sS http://<HOST>:3000/api/metrics/gate/summary | jq .

# Weekly notify (dry-run, protected)
curl -sS -X POST 'http://<HOST>:3000/api/notify/weekly-sb?dry=1' \
  -H 'content-type: application/json' -H "x-admin-token: $QUALITY_NOTIFY_ADMIN_TOKEN" -d '{}'
```


