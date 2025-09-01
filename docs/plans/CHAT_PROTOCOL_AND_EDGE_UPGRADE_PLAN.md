## Chat Protocol and Edge Upgrade Plan (IDE-first)

### Goal
Standardize chat request/response, SSE events, and capability handshake so IDE/CLI (Cursor-like) can automate safely using a consistent, minimal contract. Implement common modules across Edge functions.

### Scope
- Protocol spec additions to `COGO_AGENT_CHAT_MESSAGE_SPEC.md`
- Edge functions updates: `intent-resolve`, `design-generate`, `figma-context`, `figma-compat`
- New common helpers under `supabase/functions/_shared/`
- Tests, docs, and deployment updates

### Deliverables
- Request schema (JSON) with mandatory/optional fields
- SSE event catalog (names, payload schema)
- Unified error model (JSON/SSE)
- Version negotiation (`envelope_version`, `server_version`, `capabilities_version`)
- Attachments format (input/output)
- Capabilities endpoint/expansion
- Cancellation semantics and `aborted` frame
- Edge updates to emit standardized frames and fields

---

## 1) Protocol Additions (Spec)

### 1.1 Request Schema (client → server)
Required:
- `text: string`
- `intent.language: string` (e.g., `en`, `ko`, `ja`, `ru`, `th`)
- `target.project_uuid: string`

Optional:
- `payload: object` (e.g., `ui_json_ref`, `bdd_text`, `actionflow`, `api`)
- `attachments: { name, url|id, mime, size, kind }[]`
- `session_id: string`, `parent_message_id: string`
- `idempotency_key: string`
- `client: { ide: string, version: string }`
- `editor_context: { open_files?: string[], active_file?: string, selection?: {path: string, range: [number, number]} }`

### 1.2 SSE Event Catalog
- `meta`: job/trace metadata
- `progress`: `{ stage, progress_pct?, note? }`
- `cli.plan`: proposed CLI actions
- `cli.apply`: per-action status `{ id, status, diff?, logs?, start_ms?, end_ms? }`
- `cli.done`: summary of applied results
- `keepalive`: heartbeat
- `aborted`: client cancelled
- `error`: unified error frame
- `done`: stream completion

### 1.3 Error Model (JSON/SSE common)
```json
{ "code": "string", "message": "string", "retryable": false, "details": {}, "trace_id": "uuid" }
```

### 1.4 Version Negotiation
- Request/Response include `envelope_version: "v1"`
- Server adds `server_version`, `capabilities_version`

### 1.5 Attachments (input/output)
Structure: `{ name, url|id, mime, size, kind }`
Guideline: prefer signed URLs for large content

### 1.6 Capabilities Handshake
- Endpoint: `GET /intent-resolve/info` (expand) or new `/chat/capabilities`
- Returns: supported `task_type` list, `intent.keywords` with `requires`, limits (rate/size), SSE policy, versions

### 1.7 Cancellation Semantics
- Client abort → server emits `aborted` and cleans up resources; idempotency prevents duplicates on retry

---

## 2) Edge Implementation Tasks

### 2.1 Shared Modules (`supabase/functions/_shared/`)
- `sse.ts`: standard frames (event names, payload builders, keepalive)
- `errors.ts`: factory for unified error model + HTTP mapping
- `attachments.ts`: validation + signed URL helpers
- `versioning.ts`: envelope/server/capabilities version helpers
- `request.ts`: request schema parsing (`zod`) including `editor_context`

### 2.2 intent-resolve
- Expand `GET /intent-resolve/info` to serve Capabilities: task_type catalog, keywords(+requires), limits, versions
- Add TTL cache and metrics (reuse existing registry cache)

### 2.3 design-generate
- Accept `attachments`, `editor_context`
- Emit standardized SSE frames; include `envelope_version` in final
- On abort: emit `aborted`
- Error handling via `errors.ts`

### 2.4 figma-context
- Standard `progress` stages; support cancel; include `attachments` (e.g., pre-scan hints) if provided

### 2.5 figma-compat
- Standardize `cli.plan`/`cli.apply`/`cli.done` frames with per-action details
- Always include `execution` and `envelope_version` in final response

---

## 3) Testing & CI

### 3.1 Scripts
- Update `scripts/test/edge-all.sh` to cover:
  - Request schema validation (required/optional)
  - SSE catalog events ordering/shape
  - Error model conformance
  - Capabilities handshake
  - Cancellation (`aborted`) behavior
  - Attachments in/out
- Extend golden snapshots for `cli.apply` frames

### 3.2 CI
- JUnit aggregation of SSE/CLI phases
- Gate on error model conformity and version presence

---

## 4) Rollout Plan

### 4.1 Phases
1. Shared modules scaffolding (`_shared/*`)
2. Spec update + `intent-resolve` capabilities
3. SSE catalog + error model integration (design-generate/figma-context)
4. `figma-compat` CLI streaming standard化
5. Attachments + cancellation
6. Final doc polish and examples update

### 4.2 Flags & Compatibility
- Keep `envelope_version: "v1"` default; add warnings for unknown client versions
- Preserve existing fields to avoid breaking current clients

---

## 5) Documentation Updates
- Update `docs/agents/COGO_AGENT_CHAT_MESSAGE_SPEC.md` with sections:
  - Request Schema
  - SSE Event Catalog
  - Error Model
  - Capabilities Handshake
  - Attachments
  - Cancellation
  - Version Negotiation
- Add examples for `cli.apply` streaming and `aborted`

---

## 6) Acceptance Criteria
- All task_type responses contain `trace_id` and `envelope_version`
- SSE frames conform to catalog across functions
- Capabilities endpoint returns consistent catalog and versions
- Unified error model used for both JSON and SSE
- Tests green; CI gate passes with JUnit report

