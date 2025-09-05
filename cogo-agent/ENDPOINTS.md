## Edge Endpoints (Summary)

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

- POST `/functions/v1/json-get` — or HEAD with If-None-Match
  - Body: { project_id, path }
  - Response: 200 { ok, json, version, updated_at } + ETag, or 304
  - Example (HEAD 304):
    ```bash
    curl -I -H "Authorization: Bearer $KEY" -H "If-None-Match: $ETAG" \
      -H "Content-Type: application/json" \
      -d '{"project_id":"'$COGO_PROJECT_ID'","path":"examples/af.json"}' \
      "$SUPABASE_URL/functions/v1/json-get"
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

- POST `/functions/v1/chat-gateway` — forwards to `/chat` (SSE aware)
  - Accepts `{ payload: {...} }` or raw payload; forwards Accept/idempotency

- POST `/functions/v1/chat` — handoff to orchestrator (default)
  - Emits chat.queued/started/handoff/done with prompt meta and optional RAG

- GET `/functions/v1/trace-status?trace_id=...`
  - Response: { ok, status, last_event_at, event_counts, queued_at, started_at, handoff_at, done_at, events }


