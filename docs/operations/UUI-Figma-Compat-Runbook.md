## UUI Figma-Compat Runbook (Edge + Worker + Metrics)

### 1) Overview
- Direct endpoints for UUI conversion via Supabase Edge (`/figma-compat/uui/*`)
- Compatibility endpoints via Figma Plugin bridge (`/figma-plugin/compat/uui/*` → queue → worker)
- Worker (`MCPGatewayBusWorker`) consumes `service=mcp, role=gateway` messages and emits bus events
- Metrics: `/api/metrics/uui/project?projectId=<uuid>` (local server)

### 2) Direct Edge Endpoints (no queue)
- POST `/figma-compat/uui/variables/derive`
- POST `/figma-compat/uui/symbols/map`
- POST `/figma-compat/uui/bdd/generate`
- POST `/figma-compat/uui/bdd/refine`
- POST `/figma-compat/uui/actionflow/refine`
Request fields:
- Required: `projectId: uuid`, `page_id: int` (components writer가 활성일 때)
- Optional: `cogoProjectId: uuid`, `sessionId: string`, `creatego_json: any[]`, 기타 도메인 필드

### 3) Compat Endpoints (queue → worker)
- POST `/figma-plugin/compat/uui/variables/derive`
- POST `/figma-plugin/compat/uui/symbols/map`
- POST `/figma-plugin/compat/uui/bdd/generate`
- POST `/figma-plugin/compat/uui/bdd/refine`
- POST `/figma-plugin/compat/uui/actionflow/refine`
Polling:
- GET `/figma-plugin/result?id=<messageId>` (Edge 함수에서 bus_events 조회)

### 4) Supabase Settings (Secrets/Env) – 반드시 Dashboard/CLI에 설정
공용(Edge/Worker 공통)
- `SUPABASE_URL`: https://<project>.supabase.co
- `SUPABASE_SERVICE_ROLE_KEY`: 서비스 롤 키 (서버/워커에서 DB 접근)
- `SUPABASE_ANON_KEY`: anon 키 (Edge 호출 인증용, 헤더 Authorization/apikey)

figma-compat (Edge) 전용
- `LEGACY_WRITE_ENABLE`: true/false (legacy DB 쓰기 토글)
- `LEGACY_TABLE_FIG2CG`: 기본값 fig2cg_ai_res
- `LEGACY_COL_PROJECT_ID`: 존재하지 않으면 '-' (미사용 처리)
- `LEGACY_COL_PROJECT_UUID`: 존재 시 컬럼명, 없으면 '' (미사용)
- `LEGACY_COL_RESULT_JSON`: 결과 JSON 저장 컬럼명 (예: json)
- `LEGACY_COL_TOOL`: 툴명 저장 컬럼명 (없으면 '-')
- `LEGACY_STORAGE_ENABLE`: true/false (결과 JSON을 Storage에 업로드)
- `LEGACY_STORAGE_BUCKET`: 업로드 버킷 (예: figma)
- `LEGACY_STORAGE_PREFIX`: 업로드 프리픽스 (예: fig2cg)

components writer (legacy public.components) 관련
- `LEGACY_COMPONENTS_ENABLE`: true/false (활성화 시 page_id FK가 유효해야 함)
- `LEGACY_TABLE_COMPONENTS`: 기본값 components
- `COMP_COL_PROJECT_ID`: 프로젝트 정수 컬럼명(없으면 '-')
- `COMP_COL_PROJECT_UUID`: UUID 컬럼명(없으면 ''), 둘 다 없으면 프로젝트 컬럼 미기록
- `COMP_COL_NAME`: name
- `COMP_COL_NODE_KEY`: id (upsert 키로 사용 가능)
- `COMP_COL_JSON`: options (JSON 저장 컬럼)
- `COMP_COL_TYPE`: type (NOT NULL 대응 기본값 'uui'로 기록)
- `COMP_COL_PAGE_ID`: page_id (FK가 유효한 값 필요)
- `COMP_UPSERT_ON_CONFLICT`: upsert 키 (예: id)

디버그/운영
- `DEBUG_SCHEMA_ENABLE`: false (디버그 스키마 조회 엔드포인트 비활성)
- `UUI_VALIDATE_STRICT`: 1 (워커에서 UUI 파라미터 엄격 검증, 필요 시 0으로 완화)
- `RESULT_INLINE_MAX`: 결과 인라인 임계값 (기본 200000 bytes 초과 시 파일 오프로딩)
- `HITL_WAIT_MS`: HITL 대기 타임아웃 (기본 60000 이상)
- `BUS_POLL_MS`: 워커 폴링 주기 (기본 20000ms)

figma-plugin (Edge) 관련
- `REQUIRE_FIGMA_PLUGIN_TOKEN`: true/false (x-plugin-token 요구)
- `FIGMA_PLUGIN_TOKEN`: 플러그인 토큰 값(요구 시)
- `ENQUEUE_MAX_QUEUE`: 큐 길이 제한 (기본 500)

### 5) 배포/재배포
Edge 함수 배포 (프로젝트 ref는 CLI 컨텍스트 사용):
```bash
supabase functions deploy figma-compat --no-verify-jwt
supabase functions deploy figma-plugin --no-verify-jwt
supabase functions deploy chatting --no-verify-jwt
```

Secrets 설정 예시:
```bash
supabase secrets set LEGACY_WRITE_ENABLE=true LEGACY_TABLE_FIG2CG=fig2cg_ai_res \
  LEGACY_COL_RESULT_JSON=json LEGACY_COL_PROJECT_ID=- LEGACY_COL_TOOL=- --yes
supabase secrets set LEGACY_STORAGE_ENABLE=true LEGACY_STORAGE_BUCKET=figma LEGACY_STORAGE_PREFIX=fig2cg --yes
supabase secrets set LEGACY_COMPONENTS_ENABLE=true COMP_COL_JSON=options COMP_COL_NAME=name \
  COMP_COL_NODE_KEY=id COMP_COL_TYPE=type COMP_COL_PAGE_ID=page_id COMP_UPSERT_ON_CONFLICT=id --yes
supabase secrets set DEBUG_SCHEMA_ENABLE=false --yes
```

### 6) 워커 실행
백그라운드 실행 (zsh에서):
```bash
nohup sh -lc 'cd /path/to/cogo-agent-core && \
  UUI_VALIDATE_STRICT=1 LOG_LEVEL=debug \
  SUPABASE_URL="$SUPABASE_URL" SUPABASE_SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY}" \
  ENABLE_SUPABASE=true AGENT_SERVICE=mcp AGENT_ROLE=gateway AGENT_SHARD=0 \
  npm run -s mcp:gateway' > /tmp/mcp-gw.log 2>&1 & echo $!
```
로그 확인: `tail -n 200 -f /tmp/mcp-gw.log`

### 7) 스모크/부하
Direct (page_id 포함):
```bash
SUPABASE_EDGE=$SUPABASE_EDGE PROJECT_ID=$PROJECT_ID PAGE_ID=34 SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
npm run -s mcp:smoke:uui:direct
```

Compat 단건:
```bash
curl -s -X POST "$SUPABASE_EDGE/figma-plugin/compat/uui/variables/derive" \
  -H "content-type: application/json" -H "Authorization: Bearer $SUPABASE_ANON_KEY" -H "apikey: $SUPABASE_ANON_KEY" \
  -d '{"user_id":"user","session_id":"sess_123","projectId":"'$PROJECT_ID'","page_id":34,"creatego_json":[{"type":"container"}]}'
```
폴링: `curl -s "$SUPABASE_EDGE/figma-plugin/result?id=<ID>" -H "Authorization: Bearer $SUPABASE_ANON_KEY" -H "apikey: $SUPABASE_ANON_KEY"`

부하(compat enqueue → poll):
```bash
SUPABASE_EDGE=$SUPABASE_EDGE PROJECT_ID=$PROJECT_ID PAGE_ID=34 SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
LOAD_N=10 LOAD_CONC=3 npm run -s mcp:smoke:uui:edge:load
```

### 8) 메트릭/관측
프로젝트 UUI 메트릭:
```bash
curl -s "http://localhost:3003/api/metrics/uui/project?projectId=$PROJECT_ID&limit=50" | jq .
```
이벤트 타임라인/추적: `/api/mcp/timeline`, `/figma-plugin/trace?traceId=...`

### 9) 트러블슈팅
- Edge 401: Authorization/apikey 누락 (anon 키 필요)
- compat pending 지속: 워커 미기동 또는 DB 연결/권한 문제
- components FK 에러: `page_id` 유효하지 않음 → 비활성화하거나 유효 값 사용
- invalid_params: `UUI_VALIDATE_STRICT=0`로 완화 후 입력 스키마 맞춰 재검증

### 10) 운영(pm2)
- 구성 파일:
  - `scripts/pm2/minimal-server.config.js`
  - `scripts/pm2/mcp-gateway.config.js`
  - `scripts/pm2/bus-broadcaster.config.js`
  - `scripts/pm2/chat-worker.config.js`
- 실행 예시:
```bash
pm2 start scripts/pm2/minimal-server.config.js
pm2 start scripts/pm2/mcp-gateway.config.js
pm2 start scripts/pm2/bus-broadcaster.config.js
pm2 start scripts/pm2/chat-worker.config.js

pm2 ls
pm2 logs --lines 200
pm2 restart all
```

### 11) Edge 번들/로드
- Edge 번들 스모크: `npm run -s smoke:edge:bundle`
- Edge 로드 번들: `LOAD_N=200 LOAD_CONC=40 npm run -s smoke:edge:load:bundle`
- 통합 메트릭 리포트: `npm run -s metrics:bundle`

### 12) 실패 주입 및 스냅샷
- 실패 주입(UUI Edge): `npm run -s mcp:smoke:uui:edge:fail`
- Edge 번들(+실패) + 스냅샷 저장: `npm run -s smoke:edge:bundle:with-fail`
- 메트릭 스냅샷 저장: `npm run -s metrics:snapshot:save`

### 13) 번들 리포터(artifacts 저장)
- Edge 번들 실행 및 요약 저장: `npm run -s smoke:edge:report`
- 로드 포함 실행: `WITH_LOAD=1 npm run -s smoke:edge:report`
- 결과는 `/artifacts/smoke/<timestamp>/summary.json` 경로로 저장됩니다.
- 서비스별 임계치:
  - 환경변수 `SERVICE_THRESHOLD_JSON` 예시:
  ```json
  { "variables_derive": { "p95": 8000, "errorRate": 0.1 }, "symbols_map": { "p95": 9000 } }
  ```
  - Edge 실행 샘플 포함 옵션:
    - `RUN_SERVICES_JSON='["variables_derive","symbols_map"]' RUN_ENFORCE_PASS=1 PAGE_ID=34 SUPABASE_EDGE=... SUPABASE_ANON_KEY=... npm run -s smoke:edge:report`
    - 요약 파일의 `runSamples`에 각 서비스의 `status`, `ok`, `latency_ms`, `trace_id`, `reason` 수록

### 14) Health/Tools 및 아카이브
- Edge health/tools 점검: `npm run -s edge:health+tools`
- Smoke 리포트 gzip 아카이브: `npm run -s artifacts:archive:smoke`

### 14.1) Edge 서비스 실행(run)
- 엔드포인트: `POST /chatting/run`
- 파라미터: `{ serviceKey, projectId, cogoProjectId?, params }`
- 스모크: `npm run -s chat:smoke:edge:run`
- 응답: `{ ok, status, serviceKey, endpoint, trace_id, reason, latency_ms, result }`

### 15) Smoke 집계 API
- 요약 집계: `HOST=http://localhost:3002 LIMIT=10 npm run -s artifacts:smoke:summary`
- 필터/샘플: `?sinceMs=86400000&projectId=<uuid>&cogoProjectId=<uuid>&failureSamples=5`
- 응답에 Reason Top-K 정렬/정규화(`reasonTopKSorted`, `reasonTopKNormalized`) 포함
- Edge 실행 집계 `aggregate.perService`: `{ count, okCount, okRate, avgLatencyMs }`
- 페이지네이션: `next_cursor`/`has_more`로 이어서 조회 (opaque base64 cursor)
  - 무결성: 서버가 필터(projectId/cogoProjectId/sinceMs)를 서명(HMAC)해 `cursor`에 포함하고 검증
  - 양방향: `prev_cursor` 지원, 이전 구간은 `&dir=prev`로 조회
  - 캐시/무효화: `SMOKE_SUMMARY_CACHE_MS`(기본 30000ms), 즉시 최신 조회는 `&noCache=1`

### 16) 스케줄러 및 보존 주기
- Smoke 리포터 스케줄(pm2 cron): `npm run -s pm2:start:smoke-reporter` (기본 매시 정각)
- 보존 주기 정리: `SMOKE_KEEP_DAYS=14 npm run -s artifacts:smoke:prune`

### 17) 서비스 게이트 운영
- API: `POST /api/metrics/uui/service/gate`
- 스크립트: `npm run -s metrics:service:uui:gate`
- 번들: `npm run -s metrics:gate:bundle`
- pm2 크론: `npm run -s pm2:start:service-gate` (기본 15분 간격)

### 18) 게이트 요약 아카이브
- 원클릭 실행/보관: `npm run -s metrics:gate:archive`
- 결과 경로: `/artifacts/gate/<ts>/gate-summary.json`

알림 연계:
- 실패 시 Webhook: `WEBHOOK_TYPE=googlechat GOOGLE_CHAT_WEBHOOK_URL=... npm run smoke:edge:report`
- Edge 번들 실행 및 요약 저장: `npm run -s smoke:edge:report`
- 로드 포함 실행: `WITH_LOAD=1 npm run -s smoke:edge:report`
- 결과는 `/artifacts/smoke/<timestamp>/summary.json` 경로로 저장됩니다.
- 실패 알림 포맷(요약):
  - message: `failed services: variables_derive(8500ms), symbols_map(9200ms)`
  - extra.failed: `[ { key, latency } ]`
- 재시도 설정:
  - `WEBHOOK_MAX_RETRIES`(기본 3), `WEBHOOK_BACKOFF_BASE_MS`(기본 500), `WEBHOOK_BACKOFF_FACTOR`(기본 2), `WEBHOOK_JITTER_MS`(기본 250)
  - 실패 시 trace 링크 최대 3개 포함(`extra.traces`): Edge가 설정된 경우 `/figma-plugin/trace?traceId=...`, 없으면 `/api/mcp/timeline?traceId=...`
  - `extra.perService`에 서비스별 집계 통계 포함: `{ count, okCount, okRate, avgLatencyMs }`
  - `extra.perServiceFailed`에 임계 초과 서비스만 요약: `{ okRate, avgLatencyMs, reasons[] }`
  - `extra.context`: `{ projectId, cogoProjectId, sessions[] }` 포함

게이트 임계치 환경변수(기본값):
- `UUI_P95_MAX_MS=10000`, `UUI_ERROR_RATE_MAX=0.2`
- `CHAT_P95_MAX_MS=10000`, `CHAT_ERROR_RATE_MAX=0.2`
임계치 초과 시 종료코드 1 반환하여 CI 게이트로 활용할 수 있습니다.


