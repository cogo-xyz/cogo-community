# IDE Chat Integration Guide

This guide shows how IDEs (Desktop/Mobile) can integrate with the COGO chat protocol using a minimal, consistent contract.

## Request Schema

Required:
- `text`
- `intent.language`
- `intent.target.project_uuid`

Optional:
- `payload`, `attachments[]`, `session_id`, `parent_message_id`, `idempotency_key`
- `client` (ide/version)
- `editor_context` (open_files/active_file/selection)

Example:
```json
{
  "text": "Create login UI",
  "intent": { "language": "en", "keywords": ["ui.generate"], "target": { "project_uuid": "demo" } },
  "editor_context": {
    "open_files": ["app/pages/loginPage.json"],
    "active_file": "app/pages/loginPage.json",
    "selection": { "path": "app/pages/loginPage.json", "range": [10, 30] }
  }
}
```

## SSE Handling

Event catalog used by COGO:
- `ready`, `meta`, `progress`, `cli.plan`, `cli.apply`, `cli.done`, `keepalive`, `aborted`, `error`, `done`
Note: `ready`는 스트림이 정상 오픈됨을 알리는 초기사건으로, 가능한 경우 화면 상단에 즉시 연결상태를 표시하세요.

### TypeScript example (minimal SSE parser)
```ts
async function streamDesignGenerate(base: string, anon: string, prompt: string) {
  const url = `${base}/design-generate?prompt=${encodeURIComponent(prompt)}`;
  const resp = await fetch(url, {
    method: 'POST',
    headers: { 'accept': 'text/event-stream', 'apikey': anon, 'Authorization': `Bearer ${anon}` },
  });
  if (!resp.ok || !resp.body) throw new Error(`SSE error: ${resp.status}`);

  const reader = resp.body.getReader();
  const decoder = new TextDecoder();
  let buffer = '';
  const handle = (event: string, data: string) => {
    if (event === 'ready') {/* show connected */}
    if (event === 'meta') {/* parse intent/editor_context */}
    if (event === 'cli.plan') {/* render planned actions */}
    if (event === 'cli.apply') {/* update per-action status */}
    if (event === 'aborted') {/* show aborted UI and stop */}
    if (event === 'error') {/* show error */}
    if (event === 'done') {/* finalize and close */}
  };
  while (true) {
    const { value, done } = await reader.read();
    if (done) break;
    buffer += decoder.decode(value, { stream: true });
    let idx;
    // Process full events separated by double newlines
    while ((idx = buffer.indexOf('\n\n')) >= 0) {
      const raw = buffer.slice(0, idx).trimEnd();
      buffer = buffer.slice(idx + 2);
      let event = 'message'; let data = '';
      for (const line of raw.split('\n')) {
        if (line.startsWith('event: ')) event = line.slice(7).trim();
        if (line.startsWith('data: ')) data += line.slice(6);
      }
      handle(event, data);
    }
  }
}
```

### Using the COGO Chat SDK
```ts
import { createCogoClient, ChatEndpoints, streamOrRealtime, createSupabaseClient, createSupabaseTraceSubscriber } from '@cogo/cogo-chat-sdk-ts';

const client = createCogoClient({ edgeBase: process.env.EDGE_BASE!, anonKey: process.env.ANON! });
const api = new ChatEndpoints(client);

// Stream with final aggregation
const final = await api.streamDesignGenerateToFinal(
  { text: 'Create login UI', dev_cli_simulate: true },
  { onEvent: (e, d) => console.log(e, d) }
);
console.log('final:', final);
```
### Stream or Realtime (automatic switch)
```ts
const client = createCogoClient({ edgeBase: EDGE, anonKey: ANON });
const url = `${client.baseUrl()}/design-generate`;
const headers = { 'content-type': 'application/json', accept: 'text/event-stream', ...client.headers() };
const sb = await createSupabaseClient(process.env.SUPABASE_URL!, process.env.SUPABASE_ANON_KEY!);
const subscribeTrace = createSupabaseTraceSubscriber(sb);
await streamOrRealtime(url, headers, { text: 'demo', dev_queue_sim: true, dev_handoff_after_ms: 100 }, {
  subscribeTrace,
  handlers: {
    queued: (v) => console.log('queued', v.estimate_ms),
    handoff: (v) => console.log('handoff', v.job_id),
    done: (v) => console.log('done', v.trace_id)
  }
});
```
Dev flag for demoing CLI frames:
```bash
# design-generate (SSE) with simulated CLI frames
curl -sS -N -X POST "$BASE/design-generate" \
  -H 'content-type: application/json' \
  -H "apikey: $ANON" -H "Authorization: Bearer $ANON" \
  -H 'accept: text/event-stream' \
  -d '{"prompt":"Create login UI","dev_cli_simulate":true}'
```


Aborted example:
```
event: aborted
data: {"trace_id":"...","reason":"dev_abort"}
```

## Attachments

Use links/signed URLs for large content.

Input/Output structure:
```json
{"name":"file.json","url":"https://...","mime":"application/json","size":1234,"kind":"uui"}
```

### Upload Flow (Signed URL)
Typical sequence used by Figma-compat helpers:
1) Presign upload URL
2) PUT the content to `signedUrl`
3) Call `ingest` with `storage_key`
4) Poll `ingest/result?traceId=...`

Example (bash):
```bash
BASE="https://$SUPABASE_PROJECT_ID.functions.supabase.co/functions/v1"
ANON="$SUPABASE_ANON_KEY"

# 1) presign
PRES=$(curl -sS -X POST "$BASE/figma-compat/uui/presign" \
  -H 'content-type: application/json' \
  -H "apikey: $ANON" -H "Authorization: Bearer $ANON" \
  -d '{"projectId":"demo","fileName":"sample.json"}')
URL=$(echo "$PRES" | jq -r '.signedUrl')
KEY=$(echo "$PRES" | jq -r '.key')

# 2) upload
echo '{"hello":"world"}' | curl -sS -X PUT "$URL" \
  -H 'content-type: application/json' --data-binary @-

# 3) ingest
ING=$(curl -sS -X POST "$BASE/figma-compat/uui/ingest" \
  -H 'content-type: application/json' \
  -H "apikey: $ANON" -H "Authorization: Bearer $ANON" \
  -d "{\"projectId\":\"demo\",\"storage_key\":\"$KEY\"}")
TID=$(echo "$ING" | jq -r '.trace_id')

# 4) result (includes content_type/size when available)
curl -sS "$BASE/figma-compat/uui/ingest/result?traceId=$TID" \
  -H "apikey: $ANON" -H "Authorization: Bearer $ANON" | jq -c '{status, signedUrl, content_type, size}'
```

## Execution & CLI Actions

- `execution` conveys policy: mode/approval/dry-run/conflict
- `cli_actions` conveys whitelisted commands; IDE should render a plan → get approval → apply and stream `cli.apply` frames

### CLI Plan → Apply Flow (Example)

1) Response with plan (from agent):
```json
{
  "trace_id": "...",
  "cli_actions": [
    {
      "id": "vars_upsert_1",
      "tool": "cogo-cli",
      "command": "variables upsert",
      "args": ["--project", "demo", "--from-stdin"],
      "input_artifact_ref": "result.mapping",
      "target": { "project_uuid": "demo" },
      "dry_run": true,
      "apply_strategy": "merge",
      "conflict_strategy": "skip"
    }
  ]
}
```

2) IDE renders plan and asks for approval from the user.

3) On approval, IDE applies actions in order. Suggested flow:
- Resolve `input_artifact_ref` to actual JSON payload (from `result` or `artifacts`)
- Execute command in a controlled environment (local CLI or remote worker)
- Stream progress back to UI as `cli.apply` frames

Pseudo SSE frames during apply:
```
event: cli.apply
data: {"trace_id":"...","action_id":"vars_upsert_1","status":"running"}

event: cli.apply
data: {"trace_id":"...","action_id":"vars_upsert_1","status":"success","diff":"..."}

event: cli.done
data: {"trace_id":"...","summary":{"total":1,"success":1,"failed":0}}
```

Notes:
- Respect `dry_run` and `approval_required` before applying.
- Follow `apply_strategy`/`conflict_strategy` for deterministic merges.

## Testing Tips

- Use `dev_disable_fallback=true` on variables derive to surface `ide_hints` toasts for empty mapping
- Use `dev_abort_after_ms` on figma-context/stream to test `aborted` frames

## References
- `agents/COGO_AGENT_CHAT_MESSAGE_SPEC.md`
- `api/EDGE_TEST_GUIDE.md`
- `api/EDGE_FUNCTIONS_OVERVIEW.md`

### Capabilities (Quick check)
```bash
curl -sS "$BASE/intent-resolve/info" -H "Authorization: Bearer $ANON" | jq '{editor_context, sse_events, limits, requires_source}'

# Force fallback requires map (useful when SERVICE_ROLE_KEY not configured)
curl -sS "$BASE/intent-resolve/info?include_fallback=1" -H "Authorization: Bearer $ANON" | jq '{requires_source, task_type_details, editor_context_support}'

# DEV flags quick view
curl -sS "$BASE/intent-resolve/info" -H "Authorization: Bearer $ANON" | jq '{editor_context_support, dev_flags_summary, dev_flags}'
```


