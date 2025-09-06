## Edge Endpoints (Summary)
- Unified error schema
  - All core endpoints return errors in the form:
    ```json
    { "ok": false, "error": "<slug>", "code": "<slug>", "message": "<human readable>", "trace_id": "<uuid>?" }
    ```
  - Success responses include `ok: true` and may include `trace_id` when applicable


- POST `/functions/v1/json-set` — upsert doc
  - Headers: Idempotency-Key, If-Match, If-None-Match, X-Trace-Id
  - Body: { project_id, path, value, expected_version? }
  - Response: 200 { ok, version } + ETag: W/"<project_id>:<path>:<version>"
  - Example (create-only):
    ```bash
    curl -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" -H "If-None-Match: *" \
      -d '{"project_id":"'$COGO_PROJECT_ID'","path":"examples/af.json","value":{"a":1}}' \
      "$SUPABASE_URL/functions/v1/json-set"
    ```

- POST `/functions/v1/json-merge` — shallow/deep merge
  - Body: { project_id, path, patch, merge: 'deep'|'shallow', expected_version? }
  - Response: 200 { ok, version, diff } + ETag
  - Example with If-Match (from previous ETag):
    ```bash
    curl -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" -H "If-Match: $ETAG" \
      -d '{"project_id":"'$COGO_PROJECT_ID'","path":"examples/af.json","patch":{"b":2},"merge":"deep"}' \
      "$SUPABASE_URL/functions/v1/json-merge"
    ```

- POST `/functions/v1/json-remove` — remove by JSON Pointer
  - Body: { project_id, path, pointers: string[], expected_version? }
  - Response: 200 { ok, removed, version } + ETag
  - Example with multiple pointers and If-Match:
    ```bash
    curl -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" -H "If-Match: $ETAG" \
      -d '{"project_id":"'$COGO_PROJECT_ID'","path":"examples/af.json","pointers":["/a","/b"]}' \
      "$SUPABASE_URL/functions/v1/json-remove"
    ```
  - Notes: Removal updates `version`/`updated_at`, thus included in `json-list` with `updated_after` if threshold is earlier.

- GET/POST `/functions/v1/json-get` — GET/POST, plus HEAD for ETag
  - Body (POST): { project_id, path }
  - Query (GET/HEAD): `?project_id=...&path=...`
  - Response: 200 { ok, json, version, updated_at } + ETag, or 304 when `If-None-Match` matches
  - Example (HEAD to obtain ETag):
    ```bash
    curl -I -H "Authorization: Bearer $KEY" \
      "$SUPABASE_URL/functions/v1/json-get?project_id=$COGO_PROJECT_ID&path=examples/af.json"
    ```
  - Example (GET 304 with If-None-Match):
    ```bash
    curl -sS -o /dev/null -w "%{http_code}\n" -H "Authorization: Bearer $KEY" -H "If-None-Match: $ETAG" \
      "$SUPABASE_URL/functions/v1/json-get?project_id=$COGO_PROJECT_ID&path=examples/af.json"
    ```
  - Example (POST 304 with If-None-Match):
    ```bash
    jq -n --arg project "$COGO_PROJECT_ID" --arg path "examples/af.json" '{project_id:$project,path:$path}' \
    | curl -sS -o /dev/null -w "%{http_code}\n" -H "Authorization: Bearer $KEY" -H "If-None-Match: $ETAG" -H "Content-Type: application/json" \
      --data-binary @- "$SUPABASE_URL/functions/v1/json-get"
    ```

- POST `/functions/v1/json-list` — list with pagination
  - Body: { project_id, prefix?, limit?, offset?, updated_after? }
  - Response: { ok, items, limit, offset, next_offset, count }
  - Example (incremental by updated_after):
    ```bash
    TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    jq -n --arg project "$COGO_PROJECT_ID" --arg ts "$TS" --arg prefix "docs/cogo-agent/examples/simple-screen/" \
      '{project_id:$project,prefix:$prefix,updated_after:$ts,limit:5}' \
    | curl -sS -H "Authorization: Bearer '$SUPABASE_SERVICE_ROLE_KEY'" -H "Content-Type: application/json" \
      --data-binary @- "$SUPABASE_URL/functions/v1/json-list" | jq '{ok,count,next_offset,items: (.items|map(.path))}'
    ```

- POST `/functions/v1/json-generate` — generate artifacts; persist optional
  - Body: { projectId, ui, persist?, base_path? }
  - Response: { ok, artifacts, saved? }
  - Batch mode:
    - Body: { projectId, ui, persist?, batch: [{ base_path, ui? }, ...], prompt_id?, prompt_version? }
    - Example:
      ```bash
      jq -n \
        --arg projectId "$COGO_PROJECT_ID" \
        --arg baseA "docs/cogo-agent/examples/simple-screen" \
        --arg baseB "docs/cogo-agent/examples/login-screen" \
        --argjson ui '{"screen":"simple","elements":[{"id":"input1","type":"textField","binding":"uiState.inputText"},{"id":"btnSend","type":"button","onTap":{"eventType":"onTap","symbol":"chat.send","params":{"text":"#_uiState.inputText"}}}]}' \
        '{projectId:$projectId,persist:true,batch:[{base_path:$baseA},{base_path:$baseB}],ui:$ui}' \
      | curl -sS -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" -H "Content-Type: application/json" \
          --data-binary @- "$SUPABASE_URL/functions/v1/json-generate" | jq .
      ```
  - Note: The expanded flow (`actionFlow.v1.expanded.json`) includes a REST callback step with query, headers, and body parameters by default, e.g.:
    ```json
    {
      "actionType": "callback",
      "actionId": "restApi",
      "params": {
        "path": "/echo",
        "method": "POST",
        "baseUrl": "#baseApiUrl",
        "authJwt": "#anonKey",
        "query": { "t": "ping", "lang": "#lang" },
        "headers": { "X-Auth": "#anonKey" },
        "body": { "value": "ping" }
      }
    }
    ```

- POST `/functions/v1/json-validate` — validate artifacts
  - Body: { schema_id: 'action.flow@1'|'variables@1'|'symbols@1'|'bdd@1'|'events.map@1', data? , project_id?, path? }
  - Response: 200 { ok: true } or 422 with details
  - Notes:
    - Supports `events.map@1` to verify that `events[]` exists and each item has `event` and `actionFlowId`.
    - If `data` is omitted but `project_id` and `path` are provided, the function will fetch the artifact via `json-get` and validate it.
    - CORS: shared headers include `Accept, authorization, apikey, content-type, idempotency-key, if-match, if-none-match`. Methods: `GET, POST, OPTIONS, HEAD`.
    - Dev note: In some dev deployments with relaxed middleware, stale `If-Match` may return 200. Production should enforce 412/428/409.

- POST `/functions/v1/chat-gateway` — forwards to `/chat` (SSE aware)
  - Accepts `{ payload: {...} }` or raw payload; forwards Accept/idempotency

- POST `/functions/v1/chat` — handoff to orchestrator (default)
  - Emits chat.queued/started/handoff/done with prompt meta and optional RAG

- GET `/functions/v1/trace-status?trace_id=...`
  - Response: { ok, status, last_event_at, event_counts, queued_at, started_at, handoff_at, done_at, events }

- POST `/functions/v1/artifacts-list` — list artifacts by base path
  - Body: { project_id, prefix? | base_path?, limit?, offset? }
  - Response: { ok, items:[{ project_id, path, version, updated_at }], limit, offset, next_offset, count }
  - Example:
    ```bash
    jq -n --arg project "$COGO_PROJECT_ID" --arg prefix "docs/cogo-agent/examples/simple-screen/" '{project_id:$project,prefix:$prefix,limit:20}' \
    | curl -sS -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" -H "Content-Type: application/json" \
      --data-binary @- "$SUPABASE_URL/functions/v1/artifacts-list" | jq .
    ```

### Preconditions & environments
- Environment: `EDGE_STRICT_PRECONDITIONS=true` (PRD 권장)
  - `If-Match` 버전 불일치 → 412
  - `If-None-Match:*` 존재 시 → 412
- Development에서는 완화되어 200이 반환될 수 있습니다. 스모크 스크립트는 PRD/DEV에 따라 상태 코드를 유연하게 확인합니다.

- POST `/functions/v1/metrics-ingest` — ingest quality metrics
  - Body: { project_id, trace_id?, metrics: {}, tags?: {} }
  - Response: { ok, trace_id, id }
  - Example:
    ```bash
    jq -n --arg project "$COGO_PROJECT_ID" '{project_id:$project,metrics:{validate_pass_rate:0.98,gen_ms:4200},tags:{runner:"corpus"}}' \
    | curl -sS -H "Authorization: Bearer '$SUPABASE_SERVICE_ROLE_KEY'" -H "Content-Type: application/json" \
      --data-binary @- "$SUPABASE_URL/functions/v1/metrics-ingest" | jq .
    ```

- GET/POST `/functions/v1/figma-compat/*` — UUI compatibility tools (presign, ingest, generate)
  - `GET /figma-compat/healthz` — health check
  - `POST /figma-compat/uui/presign` — returns storage upload info `{ bucket, key, signedUrl?, token? }`
  - `POST /figma-compat/uui/ingest` — emits `uui_ingest_requested`; returns `{ ok, trace_id }`
  - `GET /figma-compat/uui/ingest/result?traceId=...` — returns `{ ok, status: 'ready'|'pending', bucket, key, signedUrl? }`
  - Unified error schema `{ ok:false, error, code, message }`; shared CORS applied

- GET/POST `/functions/v1/kg-upsert-schedule` — dev trigger to publish KG upserts
  - GET: returns `{ ok, info, accepts }`
  - POST: scan `public.cogo_documents` or accept explicit `paths`
    - Body: `{ project_id?, prefix?, window_minutes?=5, limit?=100, paths?: string[] }`
    - Emits `kg.upsert_request` events to `public.bus_events`
  - Response: `{ ok, enqueued, published }` (both provided for compatibility) with unified error schema and CORS
  - Example (POST by prefix and window):
    ```bash
    jq -n --arg project "$COGO_PROJECT_ID" --arg prefix "docs/cogo-agent/examples/" '{project_id:$project,prefix:$prefix,window_minutes:5,limit:10}' \
    | curl -sS -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" --data-binary @- \
      "$SUPABASE_URL/functions/v1/kg-upsert-schedule" | jq .
    ```
  - Example (POST by explicit paths):
    ```bash
    jq -n --arg project "$COGO_PROJECT_ID" '{project_id:$project,paths:["docs/cogo-agent/examples/simple-screen/actionFlow.v1.json"]}' \
    | curl -sS -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" --data-binary @- \
      "$SUPABASE_URL/functions/v1/kg-upsert-schedule" | jq .
    ```


