## Chatting Example (Test Project)

This example demonstrates real, working requests and responses captured from the current environment.

### Test IDs
- projectId: `738a1fc6-3d88-42e0-8afa-eacb0d4ead61`
- cogoProjectId: `3f50a6d4-7990-435e-a6a6-97c95358adea`

Set these environment variables before running the examples:
```bash
export SUPABASE_EDGE="https://cjvgmyotqxfpxpvmwxfv.functions.supabase.co"
export SUPABASE_ANON_KEY="<ANON_KEY>"   # Do not commit real keys
export PROJECT_ID="738a1fc6-3d88-42e0-8afa-eacb0d4ead61"
export COGO_PROJECT_ID="3f50a6d4-7990-435e-a6a6-97c95358adea"
```

### 1) Enqueue a chat message
```bash
curl -s \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "content-type: application/json" \
  "$SUPABASE_EDGE/chatting/enqueue" \
  -d '{
    "projectId": "'$PROJECT_ID'",
    "cogoProjectId": "'$COGO_PROJECT_ID'",
    "sessionId": "sess_cli",
    "role": "user",
    "content": [{"type":"text","text":"List services for figma to cogo json and uui bdd."}]
  }'
```

Example response:
```json
{ "ok": true, "id": "6bbb65cc-ee6d-44d3-8e0b-0299d558233f" }
```

### 2) Poll for result
```bash
curl -s \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  "$SUPABASE_EDGE/chatting/talking/result?id=6bbb65cc-ee6d-44d3-8e0b-0299d558233f"
```

Example response (succeeded with service suggestions):
```json
{
  "ok": true,
  "status": "ok",
  "event": {
    "id": "cff769e5-fe50-45d7-9751-2abd26d2b36b",
    "created_at": "2025-08-20T08:24:48.506422+00:00",
    "event_type": "chat_call_succeeded",
    "payload": {
      "result": {
        "note": "chat.service_info",
        "role": "user",
        "content": [{ "type": "text", "text": "Detected service intent. Available related services are listed in services array." }],
        "services": [
          { "name": "UUI Variables Derive", "key": "variables_derive", "description": "Derive variables from design JSON" },
          { "name": "UUI Symbols Map", "key": "symbols_map", "description": "Map symbols/components to UUI" },
          { "name": "UUI BDD Generate", "key": "bdd_generate", "description": "Generate BDD scenarios from UI" },
          { "name": "UUI BDD Refine", "key": "bdd_refine", "description": "Refine BDD with user queries" },
          { "name": "UUI Actionflow Refine", "key": "actionflow_refine", "description": "Refine Actionflow steps" },
          { "name": "Figma → COGO JSON", "key": "figma_to_cogo", "description": "Explain how to convert Figma AST to UUI/COGO JSON via compat endpoints" }
        ]
      },
      "latency_ms": 0,
      "session_id": "sess_cli",
      "broadcast_hint": "both",
      "cogo_project_id": "3f50a6d4-7990-435e-a6a6-97c95358adea"
    }
  }
}
```

### 3) Subscribe via SSE (project scope)
```bash
curl -N "http://localhost:3002/api/chat/feed?projectId=$PROJECT_ID&cogoProjectId=$COGO_PROJECT_ID"
```

Example stream events:
```text
event: progress
data: {"type":"progress","event_type":"chat_call_scheduled","message_id":"01e944e6-0f81-40c9-9d03-b63373ce9ff7", ...}

event: progress
data: {"type":"progress","event_type":"chat_call_started","message_id":"01e944e6-0f81-40c9-9d03-b63373ce9ff7", ...}

event: done
data: {"type":"done","event_type":"chat_call_succeeded","message_id":"01e944e6-0f81-40c9-9d03-b63373ce9ff7", ...}
```

### 4) Respond (HITL)
```bash
curl -s \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "content-type: application/json" \
  "$SUPABASE_EDGE/chatting/respond" \
  -d '{
    "project_id": "'$PROJECT_ID'",
    "message_id": "97ec0d99-9534-41eb-bb57-160302950f66",
    "session_id": "sess_cli",
    "prompt_type": "confirm",
    "payload": {"approved": true, "reason": "ok by example"},
    "cogoProjectId": "'$COGO_PROJECT_ID'"
  }'
```

### 5) Metrics (project scope)
```bash
curl -s "http://localhost:3002/api/metrics/chat/project?projectId=$PROJECT_ID&cogoProjectId=$COGO_PROJECT_ID&sinceMs=86400000&limit=20"
```

Example (trimmed):
```json
{
  "ok": true,
  "projectId": "738a1fc6-3d88-42e0-8afa-eacb0d4ead61",
  "cogoProjectId": "3f50a6d4-7990-435e-a6a6-97c95358adea",
  "total": 9,
  "counts": {"chat_call_succeeded": 3, "chat_call_started": 3, "chat_call_scheduled": 3},
  "p50": 0,
  "p95": 0,
  "successRate": 1
}
```

### 6) Service catalog
```bash
npm run -s chat:smoke:services
# or
SUPABASE_EDGE="$SUPABASE_EDGE" SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" npx ts-node src/scripts/ci/chatServiceCatalogSmoke.ts
```

### 7) One-shot bundle
```bash
# UUI direct + chatting enqueue/poll + respond + SSE + catalog
npm run -s smoke:uui+chat:bundle
# Chat project metrics
HOST=http://localhost:3002 PROJECT_ID=$PROJECT_ID COGO_PROJECT_ID=$COGO_PROJECT_ID npm run -s chat:smoke:metrics:project

# Edge bundle (compat + chat + services + metrics)
SUPABASE_EDGE="$SUPABASE_EDGE" SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" PROJECT_ID=$PROJECT_ID COGO_PROJECT_ID=$COGO_PROJECT_ID npm run -s smoke:edge:bundle
HOST=http://localhost:3002 PROJECT_ID=$PROJECT_ID COGO_PROJECT_ID=$COGO_PROJECT_ID npm run -s metrics:bundle
```

### Notes
- Do not commit real keys. Use environment variables for secrets.
- `cogoProjectId` is for internal scoping and is independent of `projectId`.
- Ensure Edge function `chatting` is deployed and JWT requirement disabled for no-auth testing.


