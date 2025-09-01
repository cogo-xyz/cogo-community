## Beta Ops Quickstart

### 1) Start Metrics Server (local)
```bash
npm run -s server:metrics
# http://localhost:3100/dashboard/local
```

### 2) Weekly Flow (enqueue → run → notify)
```bash
# Enqueue weekly jobs
# (서버 보호용) Admin 토큰 필요 시
curl -s -X POST http://localhost:3100/api/schedule/weekly -H "x-admin-token: $QUALITY_NOTIFY_ADMIN_TOKEN"

# Short-run live runners
npm run -s live:plan && npm run -s live:work

# Weekly notify (metrics-based, server endpoint)
# dry-run
npm run -s notify:weekly:server:dry
# send (Admin 토큰 필요 시)
QUALITY_NOTIFY_ADMIN_TOKEN=... npm run -s notify:weekly:server
METRICS_BASE=http://localhost:3100 npm run -s notify:weekly

# Weekly notify (Supabase-based)
SUPABASE_URL=https://<project>.supabase.co \
SUPABASE_SERVICE_ROLE_KEY=<server_key> \
npm run -s notify:weekly:sb
```

### 2-1) Protected Endpoints (Admin Token)
- `POST /api/schedule/weekly`, `POST /api/notify/weekly-sb`는 Admin 토큰을 요구합니다.
- 서버 환경변수: `QUALITY_NOTIFY_ADMIN_TOKEN`
- 토큰 생성 예:
```bash
openssl rand -hex 32
```
- 호출 예(로컬):
```bash
curl -sS -X POST 'http://localhost:3100/api/notify/weekly-sb?dry=1' \
  -H 'content-type: application/json' -H "x-admin-token: $QUALITY_NOTIFY_ADMIN_TOKEN" -d '{}'

curl -sS -X POST 'http://localhost:3100/api/schedule/weekly' \
  -H 'content-type: application/json' -H "x-admin-token: $QUALITY_NOTIFY_ADMIN_TOKEN" -d '{}'
```
- 호출 예(서버):
```bash
curl -sS -X POST 'http://<SERVER_IP>:3000/api/notify/weekly-sb?dry=1' \
  -H 'content-type: application/json' -H "x-admin-token: $QUALITY_NOTIFY_ADMIN_TOKEN" -d '{}'

curl -sS -X POST 'http://<SERVER_IP>:3000/api/schedule/weekly' \
  -H 'content-type: application/json' -H "x-admin-token: $QUALITY_NOTIFY_ADMIN_TOKEN" -d '{}'
```

### 2-2) Admin Token – Central Storage (optional)
- Supabase `secure_keys`에 저장(중앙 관리):
```bash
SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... \
npx ts-node src/scripts/keys/upsertDirectDB.ts quality notify admin_token "<TOKEN>" dev false
```

### 3) Quality Gate (CI)
```bash
# Metrics summary based
METRICS_BASE=http://localhost:3100 GATE_MIN_PASS_PCT=70 npm run -s ci:gate:q1

# Supabase direct query (recommended)
SUPABASE_URL=https://<project>.supabase.co \
SUPABASE_SERVICE_ROLE_KEY=<server_key> \
GATE_MIN_PASS_PCT=70 npm run -s ci:gate:q1:sb
```

### 3-1) Gemini Settings (Plan/Design intents)
- 모델 선호: `google/gemini-2.5-pro`
- 키 업서트(중앙 저장):
```bash
SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... \
npx ts-node src/scripts/keys/upsertDirectDB.ts google gemini api_key "<GEMINI_API_KEY>" dev false

SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... \
npx ts-node src/scripts/keys/upsertDirectDB.ts google gemini model gemini-2.5-pro dev false
```
- 스모크 테스트:
```bash
GEMINI_API_KEY=<GEMINI_API_KEY> npx ts-node src/scripts/llm/geminiSmoke.ts
```

### 4) Router v2 Compare
```bash
ROUTER_SELECT_URL=https://<project>.supabase.co/functions/v1/router-select \
npm run -s router:compare:v1v2
```

### 5) Nightly/Weekly Schedules (GitHub Actions)
- `.github/workflows/scheduled-ops.yml`
- Nightly snapshot, weekly enqueue, manual dispatch

### 6) API Reference
- See `docs/API_METRICS_AND_NOTIFY.md`

### 7) Ports & Networking
- See `docs/PORTS_AND_NETWORKING.md`


