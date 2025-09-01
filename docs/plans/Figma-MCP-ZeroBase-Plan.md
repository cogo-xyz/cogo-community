## Figma Plugin · Edge Functions · Figma MCP (Zero-base) Development Plan

### Constraints
- Preserve existing DB schema/storage contracts: `public.fig2cg_ai_res`, `public.components`, storage bucket/path format.
- New Figma Plugin and Edge Functions can be redesigned from scratch; no npm packages in plugin, only fetch/WS.
- Use COGO standards: Supabase Edge/Realtime/Bus, Envelope meta, UUI toolset (uui.*).

### Architecture
- Figma Plugin
  - Config UI: save `SUPABASE_EDGE`, `PROJECT_ID`(uuid), `COGO_PROJECT_ID`(uuid).
  - Get service catalog: `GET /chatting/services`.
  - Two paths:
    - Direct: POST `/figma-compat/uui/{symbols/map|variables/derive|bdd/*|actionflow/refine}` with figma-like JSON and meta.
    - Chatting: POST `/chatting/enqueue` → progress over Realtime → GET `/chatting/talking/result`.
  - Realtime: subscribe `plugin:<sessionId>`.
- Edge Functions
  - `figma-compat`: UUI compat endpoints for figma-like → COGO JSON conversion; mirror results into legacy DB/storage.
  - `chatting`: enqueue/result/respond/services (catalog), already in place.
  - (Optional) `figma-mcp-gateway`: bridge to Figma MCP tools via WS.
- Workers/Bus
  - Use `agent_messages`/`bus_events`, broadcast Envelope with meta (`trace_id`,`project_id`,`cogo_project_id`,`session_id`).

### Data Contracts (Preserved)
- On success, write snapshot to `public.fig2cg_ai_res.json` and update `public.components` (columns/types unchanged).
- Storage uploads follow existing bucket/path rules; URLs embedded into JSON (fills[].url).

### APIs (Summary)
- Catalog: `GET /chatting/services` → `{ ok, services: [...] }`.
- Direct UUI compat: `POST /figma-compat/uui/{symbols/map|variables/derive|bdd/generate|bdd/refine|actionflow/refine}` → `{ ok, result, trace_id }`.
- Chatting: `POST /chatting/enqueue`, `GET /chatting/talking/result`, `POST /chatting/respond`.

### MCP (Server-side, optional)
- Tools: `get_document_info`, `export_nodes_png`, `list_components`, `convert_to_cogo`.
- Bridge endpoint: `POST /figma-mcp/run` (tool, params) for server-side assistance; not required for initial plugin.

### Testing
- Unit: Direct convert → Ajv validate against `docs/schemas/cogo_ui/*.json` (bundle metaschema or strip `$schema`).
- Integration (Chat): enqueue → Realtime progress → result; respond; SSE; load.
- Regression: keep legacy `/figmatocg` path functional by internally calling shared converter.

### Rollout Steps
1) Implement `figma-compat` Edge with UUI endpoints and healthz.
2) Update catalog to include `/figma-compat/uui/*` endpoints.
3) Plugin: add settings, catalog UI, direct/chat paths, Realtime subscription.
4) Converter writes to legacy DB/storage on success.
5) Add unit/integration smokes; wire dashboards/metrics.

### DoD
- Direct and chat paths both green on smokes; results stored in legacy tables; storage URLs embedded; metrics visible.


