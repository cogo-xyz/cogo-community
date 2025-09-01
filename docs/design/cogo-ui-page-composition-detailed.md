## Cogo UI JSON — Page Independence, Composition, and Streaming (Detailed Design)

### 1) Purpose / Scope
- Define a precise, production-ready design for Cogo UI JSON as a set of standalone pages and a deterministic composition of pages (project + library pages).
- Standardize the streaming protocol (SSE) for progressive delivery and validation gates.
- Specify persistence (Supabase), idempotency, rate limits, error model, metrics, and rollout.

### 2) Glossary
- Page: Standalone renderable unit (must render by itself).
- Include: A reference to another page instance embedded into a host page (e.g., HEADER/FOOTER/DRAWER/BLOCK).
- Composition: The deterministic assembly of a host page and its includes.
- UUI JSON: Intermediate tree-focused format.
- Cogo UI JSON: App-focused format with pages/components and composition metadata.

### 3) JSON Model (Cogo UI JSON)
- Baseline schema: `docs/schemas/cogo_ui/ui.schema.json` (version/pages/components)
- Extensions (backward compatible):
  - pages[].layout (optional)
    - `{ width: number, height: number, bg?: string }` — ensures standalone render
  - pages[].includes (optional)
    - Array of IncludeItem
    - IncludeItem:
      - pageRefId: string (unique ID of included page; e.g., `lib:header`)
      - role: 'HEADER' | 'FOOTER' | 'DRAWER' | 'BLOCK'
      - dx: number (>=0)
      - dy: number (>=0)
      - index: number (z-order for include block relative to host components)
      - isEditable: boolean
- Components within a page:
  - Absolute positioning: dx, dy, width, height
  - Z-order: index_in_page (integer)

### 4) Composition Rules
- Ordering: HEADER (lowest z) → host components → FOOTER (top) unless overridden by include.index
- Positioning: Components of an included page are translated by include.dx/dy.
- Conflicts: If z-index collision occurs, order by include.index; if equal, order by declaration sequence.
- Cycles: Prohibited. Detector rejects cycles before composition.
- Limits: hard caps for performance
  - per-page components ≤ 5,000
  - per-include components ≤ 2,000
  - total composed components ≤ 10,000

### 5) Validation Gates
- Standalone Page Gate
  - Required fields: id, name, layout.width/height, sane dx/dy/size for components
  - Schema: `cogo_ui/ui.schema.json` + custom rules (dx,dy>=0; width,height>0)
- Composition Gate
  - Detect cycles (DFS with visited set)
  - Resolve includes; check positioning and z-order limits
  - Enforce role uniqueness: at most one HEADER/FOOTER/DRAWER per host unless explicitly allowed
- Round-trip Gate
  - Figma → UUI → Cogo (page-level) → Compose
  - Tolerance: |Δx|, |Δy| ≤ 2px; component count must match after normalization

### 6) Streaming Protocol (SSE)
- Purpose: progressively deliver page data and composition without long blocking calls.
- Event types
  - `ready`: `{ trace_id }`
  - `page.ready`: `{ page_id, trace_id }`
  - `page.chunk`: `{ page_id, chunk_idx, total_chunks?, components: ComponentPartial[] }`
  - `page.includes`: `{ page_id, includes: IncludeItem[] }`
  - `progress`: `{ stage: 'fetch'|'analyze'|'assemble', pct: number }`
  - `compose.ready`: `{ host_page_id }`
  - `compose.chunk`: `{ host_page_id, include_ref, chunk_idx, components: ComponentPartial[] }`
  - `done`: `{ page_id?: string, host_page_id?: string, duration_ms, size_bytes }`
  - `error`: `{ code, message }`
- Chunking limits
  - ≤ 1 MB or ≤ 500 nodes per chunk (whichever first)
- Idempotency
  - Headers: `Idempotency-Key`
  - Key: `job_id + page_id + chunk_idx`

### 7) Edge APIs (Proposed)
- POST `/functions/v1/figma-context/start`
  - Body: `{ figma_url, context_type, include_assets?, job_id? }`
  - Response: `{ job_id, first_cursor }`
- POST `/functions/v1/figma-context/stream` (SSE)
  - Body: `{ job_id, cursor }`
  - Frames: `ready`, `page.*`, `compose.*`, `progress`, `done`, `error`
- GET `/functions/v1/figma-context/status?job_id=...`
  - Response: `{ job_id, done_chunks, total_chunks, last_cursor, status }`
- POST `/functions/v1/figma-context/cancel`
  - Body: `{ job_id }`
  - Response: `{ ok: true }`
- Security
  - Dev: `EDGE_AUTH_OPTIONAL=true`
  - Prod: `verify_jwt=true`, HMAC signing (X-Timestamp/X-Signature)
- Rate limiting
  - FIGMA_RATE_LIMIT_PER_MIN (per session/job_id)
  - Near/limited events inserted into `bus_events`

### 8) Persistence (Supabase)
- Tables
  - `pages(id, name, width, height, image_url, header_id, footer_id, drawer_id, bg_clr, on_load, ...)`
  - `components(id, page_id, name, type, dx, dy, width, height, index_in_page, options, ...)`
  - `project_pages(project_id, page_id)`
  - `library_pages(library_id, page_id)`
  - `project_library_page_relations(id, project_page_id, library_page_id, dx, dy, is_editable, type, index_in_page)`
  - `figma_jobs(id, figma_url, total_chunks, done_chunks, last_cursor, status, created_at, updated_at)`
  - `figma_job_chunks(job_id, chunk_idx, cursor, status, started_at, finished_at, error)`
- Unique keys
  - `pages(id)` or `(name,width,height)`
  - `components(page_id,id)` or `(page_id,index_in_page)`
  - `project_library_page_relations(project_page_id, library_page_id, index_in_page)`
  - `figma_job_chunks(job_id, chunk_idx)`

### 9) Algorithms
- Cycle detection (includes)
  - DFS starting from host page; visited set; reject if visiting an active stack node
- Composition assembly
  - Resolve includes depth-first
  - For each included page, translate components by include.dx/dy
  - Merge arrays and sort by final z-order
  - Enforce caps and return assembled tree
- Chunking & merge
  - Emit `page.chunk` for each batch; client/assembler merges by id/index

### 10) Error Model
- `bad_request`: missing fields or invalid cursor
- `unauthorized`: auth missing/invalid
- `rate_limited`: too many requests in window
- `provider_error`: upstream(Figma) error (map status code and message)
- `config_error`: misconfiguration (e.g., missing API keys)
- SSE `error` frames always include `trace_id`

### 11) Metrics / Observability
- `bus_events` insertions
  - `figma_rate_near_limit`, `figma_rate_limited`
  - `figma_job_started`, `figma_job_chunk_done`, `figma_job_done`
  - `figma_compose_done`, `figma_compose_failed`
- Metrics server
  - `/api/metrics/rate-limits` — count near/limited
  - `/api/metrics/trace/{trace_id}` — end-to-end tracing

### 12) Security
- Development: `EDGE_AUTH_OPTIONAL=true`, `verify_jwt=false`
- Production: `verify_jwt=true`, HMAC signing required; timestamp drift ≤ 300s
- Secrets in Supabase: `FIGMA_API_KEY`, never committed

### 13) Testing Strategy
- Unit
  - Composition: cycle detection, z-ordering, translations, caps
  - Schema: cogo/uui JSON validation
- Integration
  - SSE streaming: ready→page.chunk→done sequence
  - Rate-limit spikes: near/limited events aggregated
- E2E
  - Figma sample → UUI → Cogo (page) → Compose
  - Round-trip tolerance checks

### 14) Rollout Plan
- Phase 1: Implement start/stream/status/cancel in Edge; chunked analysis only
- Phase 2: Add assembler/validator; DB upsert of pages/components/includes
- Phase 3: Migrate MCP `/getContext` to Edge; WS remains in MCP
- Phase 4: CI gates (schema + round-trip) and release checklist updates

### 15) Open Questions
- Multiple DRAWER/BLOCK includes policy: allow multiple (default) with explicit role constraints
- Max payload sizes tuning per environment
- Client-side vs server-side final assembly responsibility (default: server assembles for DB; client assembles for preview)
