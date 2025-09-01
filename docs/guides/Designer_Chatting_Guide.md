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

### 7.1 Figma Plugin (권장)
- Figma Access Token은 플러그인 설정에서 입력(중앙 관리). 채팅에 토큰을 붙여넣지 않습니다.
- Figma에서 페이지/컴포넌트를 선택 → "Send to Agent". 플러그인이 Edge Function(Edge)으로 업로드/ingest를 호출합니다.
- 결과로 `trace_id` 또는 `ingestId`를 받으면, 채팅에서 참조:
```
Use ingestId <id> from my last Figma selection. Generate symbols/variables and draft BDD for #onLoginClicked.
```

### 7.2 Chat만 사용하는 경우(플러그인 없이)
- 공개 Figma URL을 제공할 수 있습니다. 비공개 파일은 토큰이 필요하지만, 채팅으로 토큰을 전달하지 않습니다.
- 팀이 운영하는 Edge의 presign 경로를 사용하여(플러그인이 없는 경우에도) JSON을 안전하게 업로드하세요.
- Presign (Edge Function): `POST /figma-compat/uui/presign` with `{ projectId, fileName }` → `signedUrl/token` 획득 → 업로드 → `POST /figma-compat/uui/ingest` with `{ projectId, storage_key }` → `trace_id` 획득.

## 8. Quick Prompts – Figma URL / Page 요청

1) 공개 URL로 심볼/변수 생성 요청(플러그인 없음)
```
Generate symbols and variables for this Figma page: <FIGMA_PAGE_URL>.
Use Edge presign/ingest centrally; do not ask me for tokens.
```

2) 플러그인으로 전송 후 BDD/ActionFlow 생성
```
Use ingestId <TRACE_OR_ID> from my last Figma selection and generate BDD for #onLoginClicked, then compile to ActionFlow (undecided → actionType:"none").
```

3) 실시간/스트리밍 응답 여부 명시 요청
```
Stream responses via SSE if available; otherwise post a single JSON response. If Realtime events are published, subscribe on trace:<TRACE_ID>.
```

## 6. References

- Scenarios: `docs/manuals/COGO_User_Scenarios.md`
- Developer manual: `docs/manuals/Developer_Manual.md`
