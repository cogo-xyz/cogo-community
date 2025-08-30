## Edge Functions Test Guide (Figma Context & Design Generate)

### Prerequisites
- SUPABASE_EDGE: `https://<project>.functions.supabase.co`
- SUPABASE_ANON_KEY: Anon key
- (Optional) FIGMA_API_KEY for real Figma fetch; synthetic mode works without it

### 1) Design Generate (SSE)
Headers:
- `apikey: <ANON>`
- `Authorization: Bearer <ANON>`

Command:
```bash
BASE="https://<project>.functions.supabase.co/functions/v1"
ANON="<SUPABASE_ANON_KEY>"
curl -sS -N -X POST "$BASE/design-generate?prompt=$(python3 - <<'PY'
import urllib.parse
print(urllib.parse.quote('Create a simple login page with email and password'))
PY
)" \
  -H 'accept: text/event-stream' \
  -H "apikey: $ANON" -H "Authorization: Bearer $ANON"
```
Expected SSE events: `meta` → `rag.item` (0..N) → `rag.done` → `llm.done` → `ui.generate` → `done`

Artifacts 확인
```bash
# SSE 완료 이후 동일 trace 확인(예시)
TRACE="<trace_id>"
curl -sS "$BASE/api/metrics/trace/$TRACE" | jq '.artifacts'
```
체크리스트
- 응답 JSON에 `trace_id` 존재
- `artifacts.links`에 UI JSON/리포트 링크 존재(대용량)
- 스니펫 필드(`*_preview`) 크기 제한 내 표시

### 2) Figma Context (Start → Stream → Status)
```bash
BASE="https://<project>.functions.supabase.co/functions/v1"
ANON="<SUPABASE_ANON_KEY>"
FIGMA_URL="https://www.figma.com/design/<KEY>/<NAME>?node-id=1-1225&m=dev"

# Start
START=$(curl -sS -X POST "$BASE/figma-context/start" \
  -H 'content-type: application/json' -H "apikey: $ANON" -H "Authorization: Bearer $ANON" \
  --data "{\"figma_url\":\"$FIGMA_URL\"}")
JOB=$(echo "$START" | jq -r '.job_id')

# Stream (synthetic)
curl -sS -N -X POST "$BASE/figma-context/stream" \
  -H 'content-type: application/json' -H 'accept: text/event-stream' \
  -H "apikey: $ANON" -H "Authorization: Bearer $ANON" \
  --data "{\"job_id\":\"$JOB\",\"dev_enable_synthetic\":true,\"dev_total_nodes\":50}"

# Status
curl -sS "$BASE/figma-context/status?job_id=$JOB" -H "apikey: $ANON" -H "Authorization: Bearer $ANON"
```
Expected SSE events: `ready` → `page.ready` → `page.chunk` (+`page.includes`) → `debug/progress` → `done`

Artifacts 확인
- `status` 또는 완료 응답에 `artifacts.figma_subtree_preview`(스니펫) 또는 링크 존재

### 3) Troubleshooting
- 401/403: Check `apikey` / `Authorization: Bearer <ANON>` headers.
- 404: Verify BASE ends with `/functions/v1`.
- Body is unusable: Client sent SSE with missing/invalid body. `design-generate` accepts `?prompt=`.
- Figma real fetch requires `FIGMA_API_KEY` in Edge env; otherwise use synthetic mode.

### 4) Scripts
- `scripts/test/edge-figma-context-e2e.sh`: Start → stream(loop) → status
- `scripts/test/edge-design-generate-sse.sh`: SSE test for `design-generate`
- `scripts/test/edge-trace-artifacts.sh`: design-generate로 trace 생성 후 `/api-router/metrics/trace/{trace}`에서 artifacts 확인
- `scripts/test/edge-figma-compat-artifacts.sh`: `uui/generate` 호출 후 `artifacts` 프리뷰/링크 확인


