## COGO Monorepo Integration and Figma Plan (Agent + Platform)

### 1) Objectives
- Single repository for cogo-agent and cogo-platform with clear modular boundaries.
- Zero-base Figma Plugin and Edge Functions with COGO standards (Realtime/Envelope/UUI toolset/Chatting).
- Preserve existing DB schema and storage contracts (legacy tables/paths).
- Enable self-upgrade (agent upgrades platform) with safe rollout/rollback.

### 2) Constraints & Contracts
- DB tables (examples): `public.fig2cg_ai_res`, `public.components` remain unchanged.
- Storage bucket/path convention remains; image URLs embedded into fills.
- No npm packages in Figma Plugin; fetch/WS only.

### 3) Repository Structure (proposed)
```
cogo-agent-core/
  apps/
    agent/               # agent server (routes/workers orchestration)
    platform/            # platform API & Admin UI
  supabase/
    functions/           # Edge (chatting, figma-compat, ...)
    sql/                 # schema/policies
    migrations/
  services/
    workers/             # ChatGateway/MCPGateway/BusEvents
    orchestrator/        # LangGraph flows
    realtime/            # Envelope broadcaster/util
    storage/             # storage adapters (legacy path compliant)
    platform-upgrader/   # self-upgrade controller
  mcp-servers/
    figma-context/
  packages/
    protocol/            # Envelope/tool schemas/catalog
    client-sdk/
    ui-schema/           # UUI/COGO schema + Ajv bundle
    db/
    observability/
  docs/
    plans/
    integration/
    examples/
    schemas/
  scripts/
    ci/  db/  ops/
  tests/
  configs/
  ...
```

### 4) Figma: Plugin · Edge · MCP (zero-base)
- Plugin
  - Settings: `SUPABASE_EDGE`, `PROJECT_ID(uuid)`, `COGO_PROJECT_ID(uuid)`
  - `GET /chatting/services` → service list
  - Direct path: `POST /figma-compat/uui/{symbols/map|variables/derive|bdd/*|actionflow/refine}`
  - Chat path: `POST /chatting/enqueue` → Realtime → `GET /chatting/talking/result`
  - Realtime subscribe: `plugin:<sessionId>`
- Edge
  - `chatting` (enqueue/result/respond/services)
  - `figma-compat` (UUI conversion bridge, writes to legacy DB/storage)
  - (optional) `figma-mcp-gateway` (WS→MCP tools)
- MCP
  - Tools: `get_document_info`, `export_nodes_png`, `list_components`, `convert_to_cogo`
  - Used server-side as needed; plugin remains thin

### 5) Data Flow & Legacy Writes
- On successful conversion, snapshot to `fig2cg_ai_res.json`, update `components` accordingly.
- Storage uploads follow existing bucket/path; URLs embedded into fills[].url.

### 6) APIs (summary)
- Catalog: `GET /chatting/services`
- UUI direct: `POST /figma-compat/uui/{symbols/map|variables/derive|bdd/generate|bdd/refine|actionflow/refine}`
- Chatting: `POST /chatting/enqueue`, `GET /chatting/talking/result`, `POST /chatting/respond`
- Envelope meta: `trace_id`, `project_id`, `cogo_project_id`, `session_id`

### 7) Self-Upgrade Mechanism
- VersionRegistry table: component/version/artifact/trace
- Upgrade Manifest(JSON/YAML): edge bundles, sql steps, function secrets
- Controller performs dry-run, deploy, smoke, finalize, rollback on fail

### 8) Testing & Observability
- Unit convert: Edge call → Ajv validation (`packages/ui-schema` bundle or `$schema` stripping)
- Integration (Chat): respond/SSE/load smokes; metrics at `/api/metrics/chat/project`
- Dashboards: summary & project dashboard include chat aggregates

### 9) Rollout Steps
1) Add `figma-compat` endpoints (done: skeleton) + implement shared converter + legacy writer
2) Update `/chatting/services` catalog to include `figma-compat` endpoints
3) Build Plugin settings/catalog UI + direct/chat paths + Realtime
4) Introduce VersionRegistry and minimal upgrader skeleton
5) Wire smokes in `scripts/ci/*` and make gates

### 10) DoD
- Direct & Chat paths pass smokes; results present in legacy tables/storage
- Metrics visible; docs up-to-date; rollback path validated


