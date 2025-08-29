## Figma Plugin x Edge Protocol (Optional)

### Roles
- Plugin (optional): Presence register/unregister only (no heavy ops)
- Chatting Interface (COGO Platform): Start/Stream/Apply controls
- Edge: figma-context (start/stream/status/apply)

### Presence
- Register: POST /figma-plugin/presence/register (handled in plugin code via Edge)
- Heartbeat: background in plugin code
- Unregister: on user action

### Context Flow
1. Start
   - POST /figma-context/start { figma_url }
   - Returns { job_id }
2. Stream (SSE)
   - POST /figma-context/stream { job_id, cursor, [figma_url], [idle_timeout_ms], [max_sse_sec] }
   - Events: ready, page.ready, page.chunk, page.includes, progress, done, error
3. Status
   - GET /figma-context/status?job_id=...
4. Apply
   - POST /figma-context/apply { job_id, page: { id }, trace_id }

### Assistant-UI Controls
- Job ID, Trace 입력
- Live Subscribe 토글 → streamFigmaContext()
- Status 버튼 → getFigmaContextStatus()

### Compatibility
- Figma runtime: es2017 target, no optional chaining/spread in plugin code
- Manifest ui.html at plugin root

### Notes
- Synthetic mode for tests: stream with { dev_enable_synthetic: true, dev_total_nodes: N }
- Set FIGMA_API_KEY in Edge env for real data fetch

