## SSE Rollout & Refactor Runbook

### Scope
Adopt SSE-first for client path. Move LLM/Embedding to Supabase Edge Functions. Keep Realtime optional for broadcasts.

### Steps
1) Deploy Edge Functions
   - `supabase functions deploy chat`
   - `supabase functions deploy embed`
2) Configure Env/Secrets
   - Provider keys in Supabase Secrets (service-level), not in code
   - Rate-limit thresholds, max content length, model defaults
3) DB/RLS
   - Ensure tables: `messages`, `message_embeddings`, `document_embeddings`
   - Apply RLS: client read-only, Edge writes
4) Client Update
   - Switch chat UI to POST `/functions/v1/chat` and parse SSE frames
   - Embed uploader to POST `/functions/v1/embed`
5) Observability
   - Include `trace_id` in all events/logs
   - Add dashboards: TTFB, duration, token usage, error rate
6) Load/Chaos Tests
   - Concurrent SSE streams, token-heavy prompts, long generations
   - Backoff/retry validation for network hiccups

### SSE Client Parsing Snippet (TS)
```ts
const res = await fetch("/functions/v1/chat", { method: "POST", headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` }, body: JSON.stringify({ session_id, content }) });
const reader = res.body!.getReader();
const decoder = new TextDecoder();
let buf = "";
for (;;) {
  const { value, done } = await reader.read();
  if (done) break;
  buf += decoder.decode(value, { stream: true });
  let idx;
  while ((idx = buf.indexOf("\n\n")) >= 0) {
    const frame = buf.slice(0, idx); buf = buf.slice(idx + 2);
    const lines = frame.split("\n");
    let event = "message", data = "";
    for (const line of lines) {
      if (line.startsWith("event:")) event = line.slice(6).trim();
      if (line.startsWith("data:")) data += line.slice(5).trim();
    }
    if (event === "chat.delta") {/* handle delta */}
    if (event === "chat.done") {/* handle done */}
    if (event === "error") {/* handle error */}
  }
}
```

### Backout
- Keep previous HTTP/WS path behind a feature flag. Toggle if SSE instability detected.


