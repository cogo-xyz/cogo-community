### CreateGo Compat API Contracts and CQRS Mapping

#### Endpoints (Edge Functions)
- POST /figma-compat/uui/symbols/map
- POST /figma-compat/uui/variables/derive
- POST /figma-compat/uui/bdd/generate
- POST /figma-compat/uui/bdd/refine
- POST /figma-compat/uui/actionflow/refine
- POST /figma-compat/uui/generate
- POST /figma-compat/uui/generate/llm
- POST /figma-compat/uui/presign
- POST /figma-compat/uui/ingest
- GET  /figma-compat/uui/ingest/result?traceId=...
- POST /chat
- POST /chat-gateway

All accept Anon in dev; `x-agent-id` propagates to `bus_events`.

#### Payload Keys (normalized)
- projectId, cogoProjectId (strings)
- page_id (number), page_name (string)
- cogo_ui_json (any[]) — preferred UI root
- current_bdd (string), refinement_queries (string[])
- flow_id (string), current_flow (any)
- idempotencyKey (string) optional

#### Schema Responsibilities
- cogo (SRK-only): `project_updates`, `bus_events`, internal artifacts
- public (IDE-owned): UI tables, versioning, views for runtime

#### CQRS
- Commands: IDE → Edge → `cogo.project_updates`
- Projections: Platform/IDE worker → `public.*`
- Reads: IDE from `public.*`; Analytics: `cogo.*`

#### Idempotency & Trace
- Header/Body `Idempotency-Key` → dedupe
- Response returns `trace_id` where relevant (ingest)

#### Error Model
- `{ ok: false, error: string, reason?: string }`
