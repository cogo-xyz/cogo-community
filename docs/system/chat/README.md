# Chat Scenario (User → Chat → Agent → Response)

## 1) User messages
- User opens chat and sends a message: "Generate a welcome message for Login screen"

## 2) Message flow
1. Client → `chat-gateway` (Edge): POST /functions/v1/chat-gateway
2. `chat-gateway` → Orchestrator/Chat worker: route request, enrich context (optional RAG)
3. Agent executes prompt → produces response text and optional structured data
4. `chat-gateway` streams SSE back to client

## 3) API example
```bash
curl -s -X POST "${SUPABASE_URL}/functions/v1/chat-gateway" \
  -H "content-type: application/json" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" -H "apikey: ${SUPABASE_ANON_KEY}" \
  -d '{
    "project_uuid": "'$PROJECT_UUID'",
    "messages": [
      { "role": "user", "content": "Generate a welcome message for Login screen" }
    ],
    "stream": false
  }' | jq .
```

## 4) Expected response
- 200 OK JSON: `{ ok: true, output: { text: "..." }, trace_id: "..." }`
- Or SSE when `stream=true`: events `delta`, `done`

## 5) Artifacts
- Saved under `artifacts/chat/YYYY-MM-DD/<trace_id>.json` with request/response, project_uuid

## 6) E2E
- Script: `src/scripts/ci/chatScenarioE2E.ts`
- Run: `SUPABASE_URL=... SUPABASE_ANON_KEY=... PROJECT_UUID=$(uuidgen) npx ts-node src/scripts/ci/chatScenarioE2E.ts`
