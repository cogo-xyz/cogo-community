## Distributed Agents Edge Upgrade Plan — Chat, LLM, Embedding (SSE + Provider-Agnostic)

### 1) Scope & Objectives
- Migrate all agent-facing Chat (LLM) and Embedding calls to Supabase Edge Functions with standardized SSE.
- Use OpenAI-compatible APIs with provider-agnostic config. Embeddings must use DeepInfra via `EMBEDDING_API_*` only.
- Ensure idempotency, rate limiting, RLS alignment, observability (trace_id, bus_events), and metrics integration.
- Keep strict auth and HMAC request signing as production-only toggles (documented, not enabled by default).

Success criteria:
- Edge `chat` streams deltas over SSE; `messages`/`bus_events` persist OK.
- Edge `embed` processes batches with retries; upserts `vector_documents`/`code_vectors` OK.
- Distributed agents call Edge (not providers directly) with stable wrappers; end-to-end tests pass.

### 2) Current State Summary
- `supabase/functions/chat`: SSE implemented, rate-limit, idempotency optional, persistence & event logging.
- `supabase/functions/embed`: SSE standardized, DeepInfra support (`encoding_format: float`), batching, retries, upsert-only.
- Metrics server requires `provider_health`; `health-refresh` Edge function deployed, cron SQL prepared.
- Client side: `SupabaseEdgeEmbeddingService` exists and now also supports direct provider calls when needed.

### 3) Target Architecture (Edge-first)
- Edge Functions front all external LLM/Embedding providers.
  - Chat: `/functions/v1/chat` (SSE deltas, persist messages, bus events `chat_done`).
  - Embed: `/functions/v1/embed` (SSE progress, provider batching+retry, upserts vectors, bus events `embed_done`).
- Distributed Agents use thin client services to call Edge:
  - `SupabaseEdgeChatService` (new): streams chat via Edge, returns assistant content; persists via Edge.
  - `SupabaseEdgeEmbeddingService` (existing): triggers Edge embed jobs; optionally supports direct provider call for query-time embedding in server-side RPCs.
- Observability: all calls include `trace_id`; events persisted in `bus_events`; metrics server reads `provider_health` and traces.

### 4) API & Config Standards
- Chat (LLM):
  - Env: `CHAT_API_BASE`, `CHAT_MODEL_DEFAULT`, `CHAT_API_KEY` (fallback `OPENAI_API_KEY`).
  - SSE frames: `ready`, `keepalive`, `chat.delta`, `chat.done`, `error`.
  - Idempotency: header `Idempotency-Key` or body `idempotency_key` (optional via `REQUIRE_IDEMPOTENCY`).
  - Rate limit: `CHAT_RATE_LIMIT_PER_MIN`.
- Embedding:
  - Env: `EMBEDDING_API_BASE`, `EMBEDDING_MODEL_DEFAULT`, `EMBEDDING_API_KEY`.
  - DeepInfra: auto add `encoding_format: "float"` when base matches DeepInfra OpenAI-compatible URL.
  - Batching: `EMBED_MAX_BATCH` (default 64). Retries: `EMBED_PROVIDER_MAX_RETRIES` (default 2). Rate: `EMBED_RATE_LIMIT_PER_MIN`.
  - SSE frames: `ready`, `keepalive`, `embed.status`, `embed.done`, `error`.
- Security (prod-only): `verify_jwt=true`, `EDGE_AUTH_OPTIONAL=false`, HMAC signing (X-Signature/X-Timestamp), key rotation.

### 5) Database & Policies
- Migrations (confirmed):
  - `vector_documents(vector(1024))`, `code_vectors(vector(1024))`, unique indexes for idempotency.
  - `messages` table for chat history; RLS aligned to session policies.
  - `provider_health` for metrics server.
- RPC/Functions:
  - `get_vector_dim`, `match_code_vectors`, `match_agent_knowledge_vectors` dimension alignment.
  - Ensure row-level policies match app usage modes (service role vs anon).

### 6) Implementation Plan (Actionable Tasks)
1. Edge — Chat hardening & parity
   - Validate SSE contract and OpenAPI docs; ensure `chat.delta` payload and `chat.done` fields match clients.
   - Confirm idempotency insertion path into `messages` and bus events `chat_done` payload shape.
   - Add provider retry/backoff (optional) in chat if required by SLA.

2. Edge — Embed finalize
   - DONE: Batching, retries, upsert-only, DeepInfra `encoding_format` auto.
   - Verify `bus_events` status frames (`embed_status`) and final `embed_done` with `trace_id`.

3. Client Services (agents)
   - Add `src/services/edge/SupabaseEdgeChatService.ts` (new):
     - Methods: `streamChat({ sessionId, content, model?, idempotencyKey? })` → yields deltas; returns final text.
     - Env usage mirrors Chat Edge defaults; supports `CHAT_FORCE_MOCK` for dev.
   - Extend `SupabaseEdgeEmbeddingService` (existing):
     - DONE: `generateEmbedding`, `embedQuery` for compatibility.
     - Continue to prefer Edge job for document/corpus embedding; direct provider path only for short-lived query vectors.

4. Agent Integrations
   - Update `DistributedIndexingAgent` and workers to call Edge `embed` (already integrated via worker preview → ensure session IDs/job IDs wired).
   - Route agent chat (where applicable) through `SupabaseEdgeChatService` instead of direct provider SDKs.
   - Remove/disable legacy direct provider paths in production builds.

5. Configuration & Secrets
   - Consolidate to `CHAT_API_*` and `EMBEDDING_API_*` envs; remove `HUGGINGFACE_API_TOKEN` from code and CI secrets.
   - Set reasonable defaults per environment; document overrides and limits.

6. Observability & Metrics
   - Ensure every call includes `trace_id`; log `bus_events` for start/status/done/error.
   - Deploy `health-refresh` and enable cron (`supabase/sql/schedule_health_refresh.sql`).
   - Define SLOs: p95 latency and error rate per `chat`/`embed` and enforce in metrics gate.

7. Security (Production Toggle)
   - Turn on `verify_jwt=true` for `chat`/`embed` (and keep `health-refresh` per policy).
   - Enable HMAC signing at ingress; validate signature, timestamp drift, and replay protection.
   - Rotate DeepInfra/OpenAI keys; store only in Supabase Secrets.

8. Documentation & OpenAPI
   - Update `docs/openapi/edge-functions.yaml` for chat/embed details and DeepInfra note.
   - Run `npm run -s types:edge` to refresh typed clients.
   - Expand runbook(s): rollout, smoke, troubleshooting, production toggles.

### 7) Test & Rollout Plan
- Local Smoke (CI):
  - `npm run -s chat:smoke:sse` (chat), `src/scripts/ci/embedThenSearchSmoke.ts` (embed).
  - Edge bundle smoke: `npm run -s smoke:edge:bundle` (includes metrics checks).
- Distributed Tests:
  - Start metrics server, bus workers; enqueue indexing jobs; verify vectors written and events emitted.
  - Trace verification via `/api/metrics/trace/{traceId}`.
- Rollout Gates:
  - Gate 1: SSE contracts stable, no 401/429 anomalies.
  - Gate 2: p95 latency and error-rate below thresholds (configurable).
  - Gate 3: Production toggles enabled (strict auth/HMAC) and pen-tested for basic replay/forgery.

### 8) Risks & Mitigations
- Provider throttling (429): handled via exponential backoff; consider jitter and global rate caps.
- Schema drift: prevent by disallowing insert fallbacks and relying on unique indexes/migrations.
- Secrets leakage: CI checks and docs enforcement; immediate rotation on exposure.
- RLS conflicts: run policy smoke with anon vs service role; ensure function verify_jwt toggles match environment.

### 9) Deliverables Checklist
- Edge Functions
  - [ ] Chat SSE parity verified; OpenAPI updated
  - [ ] Embed SSE batching+retry verified (DeepInfra)
- Client Services & Agents
  - [ ] `SupabaseEdgeChatService` implemented and adopted
  - [ ] `SupabaseEdgeEmbeddingService` used for all document embeddings
- DB & Metrics
  - [ ] Migrations applied; RPC dim align; provider_health cron enabled
  - [ ] Metrics gates configured for p95/error-rate and reporting
- Security & Ops
  - [ ] Production toggles documented and applied (JWT/HMAC)
  - [ ] Secrets rotated & centralized
- Docs
  - [ ] Runbooks updated; CI smoke extended; troubleshooting guide updated

### 10) Timeline (Indicative)
- D1: Chat service wrapper + OpenAPI finalize + local smokes
- D2: Agent integrations (chat + embed), distributed smokes
- D3: Metrics/SLO gates + health-refresh cron + docs
- D4: Prod toggles rehearsal (JWT/HMAC) + final review

### 11) Chat Endpoint Consolidation (Refactor Plan)
Goal: Remove duplication across three endpoints and standardize on a single SSE chat API.

Canonical endpoint
- Keep: `/functions/v1/chat` as the single SSE chat endpoint.
- Purpose: Streaming deltas, persistence (`messages`), events (`chat_done`), rate limit, idempotency.

Compatibility layers
- `chat-gateway` (keep): Orchestrator ingress only. Routes/validates requests, then forwards to `/chat` (server-to-server). No provider logic inside.
- `chatting` (deprecate): Mark legacy. Provide temporary proxy to `/chat` for N release cycles, then return `410 Gone`.

Refactor steps
1) Code
   - Ensure `/chat` has full SSE + persistence; verify parity with clients.
   - `chat-gateway`: strip LLM handling; forward to `/chat` with required headers (Bearer SRK, optional HMAC in prod).
   - `chatting`: implement proxy to `/chat` or soft-deprecation banner, add metrics tag `legacy_chatting`.
2) Config
   - `supabase/config.toml`: set verify_jwt per function (dev=false, prod=true for `/chat`, `/chat-gateway`).
   - Secrets: use `CHAT_API_*` only; remove legacy env usage from `chatting`.
3) OpenAPI & Types
   - `/chat` detailed spec; `/chat-gateway` (ingress) minimal spec; `/chatting` marked deprecated.
   - Regenerate TS types (`npm run -s types:edge`).
4) Rollout
   - Stage 1: Proxy mode for `chatting` (monitor usage, error budget).
   - Stage 2: Announce EOL; block new features.
   - Stage 3: Return `410 Gone` with migration hint; remove code after grace period.
5) Tests
   - SSE smoke on `/chat`; gateway-to-chat integration test; legacy proxy smoke.

Risk & Mitigation
- Client breakage: maintain proxy period + clear deprecation headers.
- Policy mismatch: align verify_jwt/HMAC between gateway and chat; enforce consistent auth.


