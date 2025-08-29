# COGO Agent – Designer Chatting Guide (End-User)

This guide helps designers (end users) use the COGO-Agent Chatting to move from screen design to dynamic behavior with minimal friction.

## 1. What You’ll Do via Chat

- Identify events and `#symbols` on your screen
- Map `#symbols` to variables (appData/uiState)
- Write/Refine BDD per event (Given-When-Then)
- Generate ActionFlow JSON from confirmed BDD
- (Optionally) Ask the Agent to run quick validations or produce samples

## 2. Core Prompts (Copy/Paste)

1) Propose events and symbols
```
Scan this screen and propose interactive events and #symbols. Use concise, meaningful names.
```

2) Map symbols to variables
```
Map the proposed #symbols to variables for <PageName>. Use #_appData.<page>.* and #_uiState.<page>.*.
```

3) Draft BDD for an event
```
Write BDD for #onLoginClicked using #userName and #password. Include success and error branches.
```

4) Refine the BDD
```
Refine the BDD to add validation for empty fields and set #errorMessage accordingly.
```

5) Generate ActionFlow
```
Compile the confirmed BDD into ActionFlow JSON. Mark undecided steps with actionType: "none".
```

## 3. Example Outputs

- Mapping
```
"#userName" → "#_appData.loginPage.userName"
"#isLoading" → "#_uiState.loginPage.isLoading"
```

- BDD (excerpt)
```
Given #userName and #password are provided
When #onLoginClicked occurs
Then call #restAPI:Login and set #errorMessage or navigate Home
```

- ActionFlow (excerpt)
```json
{
  "id": "loginProcessFlow",
  "actionType": "flow",
  "steps": [
    { "actionType": "basic", "actionId": "setProperty", "params": { "target": "#isLoading", "value": false }},
    { "actionType": "callback", "actionId": "restApi", "params": { "baseUrl": "#_appData.api.base", "path": "/login", "method": "POST", "body": { "u": "#userName", "p": "#password" }, "saveTo": "#_appData.session.auth" }}
  ]
}
```

## 4. Artifacts in Chat Responses

- The agent returns small previews inline under `artifacts.*_preview`.
- Large outputs are stored and exposed via signed links under `artifacts.links[]`.
- Use `trace_id` to retrieve all related artifacts and events.

Quick commands:
```bash
# SSE design generate
curl -sS -N -X POST "$BASE/design-generate?prompt=$(python3 - <<'PY'
import urllib.parse; print(urllib.parse.quote('Create a simple login page'))
PY
)" -H 'accept: text/event-stream' -H "apikey: $ANON" -H "Authorization: Bearer $ANON"

# Trace artifacts lookup
curl -sS "$BASE/api-router/metrics/trace/<TRACE_ID>" | jq '.artifacts'
```

## 5. Tips

- Keep names short and clear; prefer `loginPage.userName` over ambiguous names.
- Confirm every symbol→variable mapping before generating BDD.
- For multi-page flows, specify the page context in your prompts.
- Ask the Agent to highlight undecided or risky steps.

## 6. Where Execution Happens

- The chat produces artifacts (mapping, BDD, ActionFlow). Heavy execution and long validations run on the Agent side, not in Chatting or Edge.

## 7. Protocol Labels (Be explicit)

- "Edge Function": Any endpoint under `/figma-compat/*` is an Edge Function (short-lived HTTP JSON). Always label it as Edge in docs/requests.
- "SSE": When responses are streamed (e.g., Chat via `chat-gateway`), Accept header is `text/event-stream`, and the client consumes Server-Sent Events.
- "Realtime": When notifications arrive via Supabase Realtime channels (e.g., `cogo:agent:<agent_id>` or `trace:<trace_id>`), call it Realtime.

Minimal SSE frame example:
```
event: message
data: {"trace_id":"...","type":"progress","payload":{"step":"compile","pct":42}}

```

## 7. Figma Inputs – Plugin vs Chat

### 7.1 Figma Plugin (Recommended)
- Figma Access Token is entered in plugin settings (centralized management). Do not paste tokens in chat.
- Select page/component in Figma → "Send to Agent". Plugin calls upload/ingest to Edge Function (Edge).
- Once you receive `trace_id` or `ingestId` as result, reference in chat:
```
Use ingestId <id> from my last Figma selection. Generate symbols/variables and draft BDD for #onLoginClicked.
```

### 7.2 Chat-only usage (without plugin)
- You can provide public Figma URLs. Private files require tokens, but do not transmit tokens through chat.
- Use your team's Edge presign path (even without plugin) to securely upload JSON.
- Presign (Edge Function): `POST /figma-compat/uui/presign` with `{ projectId, fileName }` → obtain `signedUrl/token` → upload → `POST /figma-compat/uui/ingest` with `{ projectId, storage_key }` → obtain `trace_id`.

## 8. Quick Prompts – Figma URL / Page Requests

1) Request symbol/variable generation from public URL (no plugin)
```
Generate symbols and variables for this Figma page: <FIGMA_PAGE_URL>.
Use Edge presign/ingest centrally; do not ask me for tokens.
```

2) Generate BDD/ActionFlow after sending via plugin
```
Use ingestId <TRACE_OR_ID> from my last Figma selection and generate BDD for #onLoginClicked, then compile to ActionFlow (undecided → actionType:"none").
```

3) Specify real-time/streaming response preference
```
Stream responses via SSE if available; otherwise post a single JSON response. If Realtime events are published, subscribe on trace:<TRACE_ID>.
```

## 6. References

- Scenarios: `docs/manuals/COGO_User_Scenarios.md`
- Developer manual: `docs/manuals/Developer_Manual.md`
