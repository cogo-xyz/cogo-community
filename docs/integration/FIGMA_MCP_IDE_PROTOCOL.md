## Unified Protocol: Figma Plugin ↔ MCP ↔ Edge ↔ IDE

Date: 2025-08-25

### Goals
- Separate concerns: User chat vs IDE data integration
- Standardize message shapes and endpoints across plugin/MCP/IDE

### Roles
- Figma Plugin: user-triggered actions, live SSE preview, artifact upload
- MCP (WebSocket/HTTP): task brokering; forwards to Edge; receives results/events
- Edge Functions: stateless transforms (figma-compat), chat-gateway, presign/ingest
- IDE (Flutter): reads/writes public.* with RLS; renders `cogo_ui_json`

### Message Contracts
- Chat
  - Request: { text, sessionId?, projectId?, cogoProjectId? }
  - SSE events: meta, llm.delta, llm.done
  - Endpoint: /functions/v1/chat-gateway → /chat

- UUI / COGO
  - Convert: { projectId, page_id?, variables?, cogo_ui_json? }
    - /figma-compat/uui/variables/derive
    - /figma-compat/uui/symbols/map
    - /figma-compat/uui/bdd/(generate|refine)
  - Generate
    - /figma-compat/uui/generate (demo, deterministic)
    - /figma-compat/uui/generate/llm (LLM-backed)
  - Ingest (large files): presign → upload → ingest → poll result
    - /figma-compat/uui/presign, /uui/ingest, /uui/ingest/result
  - Preview to Figma-like (optional, client-side mapper recommended)

### Storage & Projection
- Agent writes cogo.* and emits outbox(cogo.project_updates)
- Projection worker upserts to public.* for IDE
- IDE renders from public.*; no direct agent writes to public.*

### Auth
- Plugin: dev(Anon), prod(JWT short-lived)
- IDE: user session (RLS)
- Agent/worker: service role

### Error & Idempotency
- Idempotency-Key header honored in convert/generate/ingest
- SSE reconnect tolerant; same trace_id on retries when key reused

### Implications for Edge
- Keep figma-compat stateless; strict body size limit; route large via ingest
- Ensure `cogo_ui_json` primary, `uui_json` companion; `figma_like` limited to preview
- Provide minimal LLM-backed generation; full chains remain optional via agents


