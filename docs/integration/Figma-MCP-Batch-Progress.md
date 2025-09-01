## Figma MCP – Batch Development Progress (No‑Auth Phase)

### 1) What’s Done
- Edge Function `figma-plugin` (enqueue/result)
  - Supabase URL 자동 유도(Functions 호스트→프로젝트 호스트)
  - 경로 정규화(`/figma-plugin/*` → `/*`)
  - Edge WS 스모크 성공(Authorization/apikey: anon 헤더 자동 첨부)
- 브리지 워커 `MCPGatewayBusWorker`
  - `agent_messages(service=mcp, role=gateway)` 구독, 재시도/폴백 처리
  - 실시간 브로드캐스트: `plugin:<sessionId>`로 progress/done/error 송신
  - 아티팩트 기록(request/response/summary)
  - `bus_events`에 프로젝트 스코프(`project_id`) 포함하여 이벤트 기록
- 라우트/스크립트
  - `/api/mcp/enqueue`가 `projectId`를 `agent_messages.project_id`로 저장
  - 스모크 `mcp:smoke:plugin:ws`가 `PROJECT_ID` 전달 지원(로컬/Edge 공통)
- 메트릭/엔드포인트
  - `GET /api/metrics/mcp/project?projectId=<uuid>`: 프로젝트 단위 MCP 이벤트 요약
  - 로컬/Edge WS 스모크 모두 성공 확인

### 2) How to Run (Quick)
- 워커(별도 터미널 권장)
```
SUPABASE_URL=<...> SUPABASE_SERVICE_ROLE_KEY=<...> \
ENABLE_SUPABASE=true AGENT_SERVICE=mcp AGENT_ROLE=gateway AGENT_SHARD=0 \
npx ts-node -T src/workers/MCPGatewayBusWorker.ts
```
- 로컬 WS 스모크
```
HOST=http://localhost:3000 TIMEOUT_MS=45000 \
SUPABASE_URL=<...> SUPABASE_ANON_KEY=<...> \
PROJECT_ID=<uuid> npm run -s mcp:smoke:plugin:ws
```
- Edge WS 스모크
```
EDGE_URL="https://<project>.functions.supabase.co/figma-plugin" TIMEOUT_MS=45000 \
SUPABASE_URL=<...> SUPABASE_ANON_KEY=<...> \
PROJECT_ID=<uuid> npm run -s mcp:smoke:plugin:ws
```
- 프로젝트 메트릭
```
curl -s "http://localhost:3000/api/metrics/mcp/project?projectId=<uuid>" | jq
```

### 3) Remaining (Next Batch)
- 플러그인 연동
  - 플러그인 전송 모듈에 `sessionId` 생성/전달, `plugin:<sessionId>` WS 구독 적용
  - `projectId` 전달(로그인 전 단계는 수동 지정)
  - HTTP 폴백(result) 경로 연결
- 툴셋 보강
  - `get_selection`, `set_text_content` e2e 검증(현재 ready/welcome 확인 완료 상태)
  - 필요 시 MCP 도구 매핑 확장
- 메트릭 확장
  - `GET /api/metrics/summary?projectId=...` 필터 추가(요약에도 프로젝트 스코프 반영)
  - 프로젝트별 성공률/지연 p50/p95 카드
- 보안/정책
  - 운영 단계에서 RLS 강화(프로젝트 멤버십 기반 SELECT/INSERT 범위)
  - Edge 토큰 정책 옵션(`REQUIRE_FIGMA_PLUGIN_TOKEN`, `x-plugin-token`)

### 4) Files Touched
- Edge: `supabase/functions/figma-plugin/index.ts`
- Worker: `src/workers/MCPGatewayBusWorker.ts`
- Routes: `src/routes/mcpProxyRoutes.ts`, `src/servers/minimal/index.ts`
- CI/Smoke: `src/scripts/ci/figmaPluginWsSmoke.ts`
- Docs: `docs/integration/Figma-MCP-NoAuth-Plan.md`, `docs/integration/Figma-MCP-Batch-Progress.md`

### 5) Notes
- 모든 이벤트에는 `trace_id`, `project_id`, `sessionId`(브로드캐스트 채널) 경로를 유지
- 스냅샷/아티팩트는 `artifacts/mcp/<toolset>/<timestamp>/` 하위에 저장

