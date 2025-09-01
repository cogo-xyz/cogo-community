## FIGMA – Edge/Plugin Only Implementation Plan (No Distributed Agents)

### 1) Scope & Goals
- Remove dependency on distributed agents for Figma flows.
- Achieve end-to-end via Supabase Edge Functions and/or Figma Plugin only.
- Maintain node-id scoped extraction, chunked SSE streaming, idempotency, and metrics.

### 2) Operating Modes
- Edge-only: Client (Assistant-UI) calls Edge Functions directly with Figma URL (public) or via presigned upload.
- Plugin-only: Figma Plugin calls Edge endpoints; central token usage; no token in the plugin code.

### 3) Data Flow (High Level)
- Start: POST `/figma-context/start` → { job_id, first_cursor }
- Stream (SSE): POST `/figma-context/stream` with { job_id, cursor, figma_url? }
  - Emits: ready, keepalive, page.ready, page.includes, page.chunk, progress, debug, done, error
  - node-id present → limit scan to subtree
- Apply: POST `/figma-context/apply` with { job_id, page }
  - Writes `pages`/`components` directly from Edge (short, batched upserts)
- Optional Upload: `/figma-compat/uui/presign` → upload JSON → `/figma-compat/uui/ingest`
- Mapping/BDD/ActionFlow: `/figma-compat/uui/*` endpoints (already available)
- RAG/Embedding (Edge): Provide small-batch ingestion endpoints (see 6)

### 4) Endpoints (Existing → Keep)
- `figma-context` (Edge)
  - GET `/healthz`
  - POST `/start`, `/stream` (SSE), `/apply`
  - GET `/status`
  - POST `/cancel`
- `figma-compat` (Edge)
  - `/uui/symbols/map`, `/uui/variables/derive`, `/uui/bdd/generate|refine`, `/uui/actionflow/refine`, `/uui/generate|generate/llm`
  - `/uui/presign`, `/uui/ingest`, GET `/uui/ingest/result`

### 5) Node-id Behavior (Edge)
- From Figma URL, read `node-id`; hyphen form `9-5240` → API form `9:5240`.
- If present: scan frames/sections within the subtree; else whole document scan.
- Chunk planning: frames→nodes list; fallback to renderable nodes; fallback to flattened IDs.

### 6) Apply & RAG (Edge-Only Design)
- Apply (Edge)
  - POST `/figma-context/apply` writes to `pages`/`components` directly.
  - Idempotent: deterministic component IDs; replace-mode by page; limit per request (≤ 300 comps).
  - Split large pages into multiple `apply` calls (client/plugin loops).
- RAG/Embedding (Edge)
  - New (small-batch) endpoints under `rag`:
    - POST `/rag/ingest/start` → { job_id }
    - POST `/rag/ingest/stream` (SSE optional): { job_id, items: [{ id, text, metadata }] }
    - POST `/rag/ingest/upsert` → writes to `documents` and optionally updates `embedding`
  - Embeddings via external API (OpenAI-compatible) at Edge in ≤ 100 items per call; `VECTOR_DIMENSIONS` respected.

### 7) Security & Governance
- Keys: Use `key-vault` Edge for Figma PAT fetch; plugin never embeds secret.
- Auth: `EDGE_AUTH_OPTIONAL=false` in prod; JWT/HMAC toggles; `Idempotency-Key` supported.
- Allowlist: REST host allowlist for any outbound (LLM/RAG providers).
- Rate limits: request window limits per IP/project; near-limit and limit events to `bus_events`.

### 8) Observability & Metrics
- Reuse `metrics-overview` and `api-router` summary views.
- Emit events: `figma_job_started`, `figma_job_chunk_done`, `figma_job_done`, `figma_apply_*`, `rag_ingest_*` (from Edge).
- `/metrics/trace/{traceId}` returns timeline from `bus_events`.

### 9) Limits & SLO
- Edge per-call budget: ≤ 6–8s median, ≤ 15s hard timeout.
- Chunk size: ≤ 500 node-ids per `stream`; component extraction ≤ 100 per chunk.
- Apply upsert per call: ≤ 300 components; larger pages require multiple calls.

### 10) Figma Plugin – Minimal Contract
- Calls:
  - `POST /figma-context/start` with selected file/page URL (no PAT)
  - `POST /figma-context/stream` per cursor → render preview / confirm
  - `POST /figma-context/apply` after user confirm
  - Optionally `figma-compat/uui/*` to generate mappings/BDD/ActionFlow
- Headers: project, session, idempotency; optional JWT; never send PAT.

### 11) Migration Plan (No Agents)
- Phase A: Enable Edge-only toggle in UI; keep agents OFF for Figma paths.
- Phase B: Introduce `rag/ingest/*` small-batch Edge endpoints; deprecate agent ingest.
- Phase C: Update dashboards: show Edge-only metrics for Figma.
- Phase D: Remove/disable agent workers for Figma (apply/ingest) in compose.

### 12) Acceptance Checklist
- [ ] `/figma-context/stream` emits chunked SSE and honors node-id
- [ ] `/figma-context/apply` upserts pages/components idempotently
- [ ] `/figma-compat/uui/*` roundtrip from page → variables/BDD/ActionFlow
- [ ] RAG small-batch ingestion works at Edge; embeddings updated
- [ ] Security toggles on; keys via `key-vault`; rate limits enforced
- [ ] Metrics/trace visible; events recorded consistently

### 13) LLM + RAG Driven Design Generation (Edge)
- Goal: From chat intent or spec, synthesize page layout/components and emit COGO/UUI JSON, then (optionally) materialize to Figma.
- Inputs: user prompt, project context, retrieved knowledge (RAG), existing UI artifacts.
- Flow:
  1) Chat → `chat-gateway` (SSE) → orchestrated prompts to LLM (`llm/*` Edge) with retrieved context (`rag/*`).
  2) LLM returns structural plan (sections/blocks/components) and actions list.
  3) `figma-compat/uui/generate` or `.../generate/llm` composes COGO/UUI JSON (keyword/LLM hybrid) with guards.
  4) User confirms → `figma-context/apply` to persist as pages/components (idempotent) or export instructions for Figma.
- RAG Retrieval (Edge): `rag` endpoints stream items; retrieved snippets become LLM context (prompts include design tokens, brand rules).
- Safety:
  - Constrain models via `router-select` (allowed providers/models, cost/error budget).
  - Validate generated UI JSON schema; prune invalid fields before apply.

### 14) Chatting Interface Integration
- Transport: SSE via `chat-gateway` (already in place). Messages carry `trace_id` for timeline.
- Commands (examples):
  - "Generate a landing page for <brand> with hero, CTA, and features"
  - "Use knowledge about <product> to create pricing section"
  - "Refine button styles and add login flow BDD"
- Orchestration (Edge-only):
  - Chat calls `rag` to retrieve domain knowledge → calls `llm` for structured plan → calls `figma-compat/uui/generate(*/llm)` → previews via Assistant-UI → `figma-context/apply` on approval.
- Artifacts: Attach generated plan, UI JSON, diffs; stream progress events to chat (meta, rag.item, llm.delta, done).

### 15) Figma Access Token Policy & Placement
- Principle: Never embed PAT in client or chat logs. Centralized, revocable, auditable.
- Options (choose one):
  - A) Server-side Key Vault (recommended)
    - Storage: `secure_keys` via `key-vault` Edge. Alias: `FIGMA_API_KEY` (per env/project if needed).
    - Retrieval: `figma-context` obtains token at runtime; plugin never sees PAT.
    - Pros: central rotation/audit; no client exposure.
  - B) Plugin-side secure settings (allowed with constraints)
    - Figma Plugin stores token in plugin settings (never pasted in chat).
    - Plugin calls Edge presign/ingest only (no raw token transmission). Edge performs API access using server-side key when required.
    - Pros: team can shadow-roll tokens per designer; Cons: coordination overhead.
- Decision: Use Option A (Key Vault, server-side) for production. Option B only for isolated teams or demo.
- Rotation & Incident:
  - Rotate in Vault → invalidate previous versions; update audit trail in `secure_keys_audit`.
  - Monitor `figma_rate_*`/`figma_apply_*` anomalies, auto-disable on abuse.

### 16) Chat → LLM+RAG → Figma Creation: Minimal Sequence
1) User message → `chat-gateway` (SSE). Trace established.
2) Chat Orchestrator (Edge):
   - Query `rag` with project/topic → collect items
   - Call `llm` with prompt + items → get layout plan
   - Call `figma-compat/uui/generate/llm` → produce UI JSON
3) Return preview JSON in chat; optionally render thumbnail server-side (future).
4) On "Apply": POST `/figma-context/apply` with { job_id?, page } to persist as pages/components.
5) Emit events to `bus_events` for observability and to update chat timeline.

### 17) Acceptance (LLM/RAG + Chat + Token)
- [ ] Chat requests stream via SSE; RAG and LLM steps observable in timeline
- [ ] Generated UI JSON validated; unsafe keys pruned; size within limits
- [ ] Apply persists components idempotently; large pages split
- [ ] Figma token fetched from Key Vault (no client exposure)
- [ ] Cost/error SLOs enforced via `router-select`; retries/backoff bounded

### 18) Shared LLM + RAG Edge Services (Async + Realtime)
- Principle: Reuse common Edge services (`rag/*`, `llm/*`, `router-select`, `chat-gateway`) and publish progress/results via Realtime-compatible events.
- Transport: 
  - SSE for stepwise progress (chat-gateway, rag streaming, llm deltas)
  - Realtime bus (`bus_events`) for durable async notifications (`rag_ingest_*`, `gen_plan_*`, `ui_generate_*`)
- Endpoint Roles:
  - `chat-gateway`: single ingress for chat; proxies to `/chat` with SSE; normalizes `output.text` in non-stream mode.
  - `rag/*`: retrieval and small-batch ingest (ingest.start/stream/upsert); emits `rag.item`, `rag.done`.
  - `llm/*`: model-invocation abstracted behind provider routing (`router-select`), streams `llm.delta`/`llm.done`.
  - `router-select`: chooses provider/model/region per SLO/cost; policy from DB (`llm_models`, `provider_health`, `routing_policies`).

### 19) Choreography – Chat → RAG → LLM → UI JSON → Apply (Edge-only)
1) Chat ingress
   - Client → `chat-gateway` (SSE). Headers include Authorization, optional Idempotency-Key.
   - Gateway assigns `trace_id` and forwards to `/chat` with `stream=true`.
2) Context retrieval
   - Orchestrated step (within chat flow) calls `POST /rag` with query; client subscribes to SSE frames (`rag.item`, `rag.done`).
   - Important: chat flow and RAG both reference same `trace_id` for unified timeline (API includes it in payloads).
3) Model selection & generation
   - `router-select` invoked to choose model; `llm/*` called with prompt + retrieved items.
   - LLM streams tokens (`llm.delta`) → final content (`llm.done`).
4) UI synthesis
   - `figma-compat/uui/generate/llm` composes COGO/UUI JSON using LLM output + safeguards.
   - Validate JSON size/schema; if large, artifact offload and return pointer.
5) User confirmation & apply
   - Client previews; on confirm → `POST /figma-context/apply` to persist pages/components.
6) Observability
   - Each step emits bus events (`*_start`, `*_done`); `/api-router/metrics/trace/{traceId}` aggregates from `bus_events`.

### 20) Async Patterns & Realtime
- Long steps publish bus events: `gen_plan_scheduled|started|succeeded|failed`, `rag_ingest_*`, `ui_generate_*`, `figma_apply_*`.
- Clients can: 
  - stay on SSE (chat-gateway) for continuous UI updates, and/or
  - subscribe to Realtime channels filtered by `trace_id` (optional UI feature) for out-of-band notifications.
- Idempotency & retries: all write paths accept `Idempotency-Key`; on retry, upstream checks for duplicates before work.

### 21) Token & Policy Revisited (Shared Services)
- LLM/RAG provider keys: stored in `secure_keys`; fetched by `key-vault` Edge; never exposed to clients.
- Figma token: server-side via Key-Vault (Option A); plugin never transports PAT.
- Routing policy: `router-select` reads `llm_models`/`provider_health`/`routing_policies` to enforce SLO/cost/region constraints.

### 22) Contract – Minimal Request Shapes
- Chat (SSE):
  - POST `/chat-gateway` { messages[], stream:true } → frames: meta, progress, llm.delta, done
- RAG:
  - POST `/rag` { q, limit, trace_id } (SSE ok) → frames: rag.item, rag.done
- LLM:
  - POST `/llm/completions` { model?, messages, trace_id } (SSE ok) → frames: llm.delta, llm.done
- Generate UI:
  - POST `/figma-compat/uui/generate/llm` { prompt, cogo_ui_json?, trace_id } → { uui_json, cogo_ui_json } (artifact if large)
- Apply:
  - POST `/figma-context/apply` { job_id?, page, trace_id }

### 23) Acceptance (Shared Services + Async)
- [ ] Chat end-to-end streams and logs rag/llm/ui_generate/apply steps on same `trace_id`
- [ ] `router-select` picks enabled model; cost/error budgets enforced
- [ ] RAG retrieval and embeddings operate at Edge; ingest small-batch path available
- [ ] Artifacts offloaded when large; pointers returned; metrics visible via trace API
