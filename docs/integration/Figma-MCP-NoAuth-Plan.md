## Figma MCP Integration (Pre‑Migration, No‑Auth Phase)

### Goal
- Build a working path between Figma Plugin and COGO distributed agents without platform login (no user/project auth yet).
- Support queueing (HTTP) and result delivery (Realtime WS preferred, HTTP polling fallback).
- Reuse community MCP pattern but swap the transport with Supabase Edge/Realtime.

Reference: Talk‑to‑Figma MCP (WebSocket bridge model) — we adapt it to Supabase Realtime/Edge instead of a custom WS server.
- https://github.com/grab/cursor-talk-to-figma-mcp

### Scope
- Included
  - Enqueue Figma MCP tools via Edge Function
  - Deliver progress/done to plugin via Realtime broadcast OR HTTP polling
  - Minimal toolset: get_document_info, get_selection, set_text_content, (optional) scan_text_nodes, create_frame
  - Metrics for calls/latency
- Excluded (for now)
  - COGO login / project selection / RLS
  - Figma OAuth / PAT
  - Long‑term persistence and per‑user history

### Architecture (Initial)
- Plugin → Server (enqueue): Edge Function HTTP
  - POST /functions/v1/figma-plugin/enqueue → insert row to public.agent_messages (service=mcp, role=gateway)
- Server → Plugin (notify):
  - A) Realtime broadcast (recommended): topic `plugin:<sessionId>`; events: progress, done, error
  - B) HTTP polling fallback: GET /functions/v1/figma-plugin/result?id=<messageId>
- Worker: MCPGatewayBusWorker consumes agent_messages, executes the tool, and emits progress/done via A or B.

### Message Contracts (Draft)
- Enqueue Request (POST /figma-plugin/enqueue)
  - { toolset: 'figma', tool: string, params: object, sessionId?: string, shard?: number }
- Enqueue Response
  - { ok: boolean, id: string, service: 'mcp', role: 'gateway', shard: number }
- WS Broadcast (topic: plugin:<sessionId>)
  - progress: { id, step, info? }
  - done: { id, result }
  - error: { id, error: { code, message } }
- Polling Result (GET /figma-plugin/result?id=...)
  - { ok: true, status: 'pending' | 'ok' | 'error', event?: { event_type, payload } }

### Implementation Plan (Order)
1) Edge Function (enqueue/result) — baseline
   - Status: initial version added at `supabase/functions/figma-plugin/index.ts`
   - Enhancement: include standardized `{ result, error, latency_ms }` in result payload when available
2) Realtime Broadcaster (server/worker)
   - Add `RealtimeBroadcaster` utility using service‑role client to `broadcast.send` into `plugin:<sessionId>`
   - Integrate into `MCPGatewayBusWorker`: on start→progress, on success→done, on failure→error (only if sessionId present)
3) Plugin Transport Abstraction (no‑auth)
   - TransportEdge (default): `enqueue(tool, params, sessionId)` + `waitResult(id)`
   - TransportRealtime (optional): UI iframe opens WS and subscribes `plugin:<sessionId>`; receive progress/done
   - Generate `sessionId` on plugin start; pass it on enqueue
4) Minimal Tool Adapter (bridge to MCP server/tooling)
   - Tools: get_document_info, get_selection, set_text_content, scan_text_nodes(optional), create_frame(optional)
   - Standardize error: `{ ok, error: { code, message }, latency_ms }`
5) Metrics
   - Counters: `mcp.calls_total{toolset,tool,status}`
   - Histogram: `mcp.latency_ms{toolset,tool,status}`
   - Expose in `/api/metrics/summary` under `summary.mcp`
6) Documentation & Examples
   - Plugin snippets (Edge & WS)
   - E2E test steps

### Endpoints & Topics
- HTTP
  - POST `/functions/v1/figma-plugin/enqueue`
  - GET `/functions/v1/figma-plugin/result?id=...`
- Realtime
  - Broadcast topic: `plugin:<sessionId>`
  - Events: `progress`, `done`, `error`

### Environment (Dev, No‑Auth)
- Plugin (UI iframe only)
  - SUPABASE_URL (platform project)
  - SUPABASE_ANON_KEY (publishable)
  - SESSION_ID (random at runtime)
- Server/Worker
  - SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
- Edge (Functions)
  - SUPABASE_URL, SERVICE_ROLE_KEY
  - REQUIRE_FIGMA_PLUGIN_TOKEN=false (dev)

### Testing (E2E)
1) Start worker (MCPGatewayBusWorker) and minimal server
2) Plugin generates `sessionId`
3) Enqueue: `POST /figma-plugin/enqueue` with { toolset:'figma', tool:'get_document_info', params:{}, sessionId }
4) Success criteria
   - Realtime path: plugin receives `done` on `plugin:<sessionId>`
   - Fallback path: `GET /figma-plugin/result?id=...` returns `{ status:'ok' }`
5) Negative tests: invalid tool → `error` delivered

### Definition of Done
- At least two tools (get_document_info, set_text_content) verified end‑to‑end via Edge+Realtime OR Edge+Polling
- Standard error surfaced in plugin
- MCP metrics visible in `/api/metrics/summary`

### Risks & Mitigations
- Realtime blocked or unstable → Plugin auto‑falls back to polling
- Long‑running tasks → emit periodic `progress` via WS; increase polling interval
- Figma plugin environment limitations → perform WS in UI iframe; main ↔ UI via postMessage

### Next (Post‑Migration / Auth Phase)
- Add COGO login in plugin UI (PKCE), project list & selection
- Enforce `project_id` scope in `agent_messages` / `bus_events` with RLS & realtime filters
- Optional: Figma OAuth for server‑side reads; keep design mutation in plugin for safety


