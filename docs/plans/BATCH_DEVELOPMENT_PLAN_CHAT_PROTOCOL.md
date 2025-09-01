## Batch Development Plan — Chat Protocol & Edge Functions (IDE-first)

### Objective
Deliver a Cursor-grade chatting experience by standardizing request/response protocol, SSE event catalog, error model, capability handshake, and applying them consistently across Edge functions.

### Guiding Principles
- IDE-first: minimal, consistent contract; no guessing user intent
- Backward compatible: keep existing fields; add `envelope_version`
- Observability-ready: always propagate `trace_id`
- Automation-safe: `cli_actions` + `execution` + idempotency

---

## Batch 1 — Spec Upgrade (Docs)
Status: Completed
Scope:
- Update `docs/agents/COGO_AGENT_CHAT_MESSAGE_SPEC.md` with:
  - Request Schema (required/optional, `editor_context`, `attachments`)
  - SSE Event Catalog (`meta`, `progress`, `cli.plan`, `cli.apply`, `cli.done`, `keepalive`, `aborted`, `error`, `done`)
  - Error Model (JSON/SSE common)
  - Version Negotiation (`envelope_version`, `server_version`, `capabilities_version`)
  - Capabilities Handshake (endpoint + schema)
  - Cancellation Semantics
  - Attachments format
Acceptance:
- Spec sections added with examples; reviewed and linked from `docs/README.md` and `docs/index.md`

## Batch 2 — Shared Modules
Status: Completed
Scope (supabase/functions/_shared/):
- `sse.ts` (event builders, keepalive policy)
- `errors.ts` (unified error factory + http mapper)
- `attachments.ts` (validation + signed URL helpers)
- `versioning.ts` (envelope/server/capabilities helpers)
- `request.ts` (zod validators incl. `editor_context`)
Acceptance:
- Unit-tests for helpers; type-safe imports from each Edge function

## Batch 3 — Capabilities (intent-resolve)
Status: Completed
Scope:
- Expand `GET /intent-resolve/info` (or `/chat/capabilities`) to return:
  - supported `task_type` catalog
  - `intent.keywords` + `requires`
  - limits (rate/size) and SSE policy
  - versions (`server_version`, `capabilities_version`)
Acceptance:
- Contract validated by test; TTL cache + metrics recorded

## Batch 4 — SSE + Error Standardization (design-generate, figma-context)
Status: Completed
Scope:
- Integrate `sse.ts`, `errors.ts`, `versioning.ts`, `request.ts`
- Emit standardized events; support `aborted` on client cancel
- Always include `envelope_version` in final JSON
Acceptance:
- Golden snapshots for SSE sequences; abort test passes

## Batch 5 — CLI Streaming Standardization (figma-compat)
Status: Completed
Scope:
- Standardize `cli.plan`/`cli.apply`/`cli.done` event payloads
- Always include `execution`, `envelope_version` in final JSON
- Ensure `cli_actions` merge from templates works for empty/null cases
Acceptance:
- Golden snapshots include per-action `status/diff/logs` fields

## Batch 6 — Attachments & Cancellation
Status: Completed
Scope:
- Input attachments validation + signed URL usage
- Output artifacts links; large JSON via storage links
- Cancellation semantics (cleanups + idempotent retry)
Acceptance:
- Upload/download scenarios covered in tests; retry safety verified

## Batch 7 — Tests & CI Gates
Status: Completed
Scope:
- Extend `scripts/test/edge-*.sh` to cover:
  - Request schema
  - SSE catalog shape/order
  - Error model
  - Capabilities handshake
  - Cancellation/attachments
- JUnit aggregation for `cli.apply` stages; CI gate on protocol checks
Acceptance:
- `edge-all.sh` reports green; JUnit artifacts generated

## Batch 8 — Ops Hardening & Examples
Status: Completed
Scope:
- Production flags (JWT/HMAC/CORS/RateLimit) templates
- Minimal client examples showing new request schema + SSE handling
- Docs: append examples and troubleshooting
Acceptance:
- Smoke tests pass with prod flags; examples runbook added

---

### Timeline (indicative)
- Batch 1–2: 1–2 days
- Batch 3–5: 2–3 days
- Batch 6–8: 2 days

### Risks & Mitigations
- Client incompatibility → keep backward fields; gate via `envelope_version`
- SSE fragmentation → centralize via `_shared/sse.ts`
- Template gaps → safe fallbacks for `cli_actions`

### Definition of Done
- All task_types emit `trace_id` and `envelope_version`
- SSE events conform across functions; `aborted` supported
- Capabilities endpoint returns consistent catalog
- Unified error model across JSON/SSE
- CI gate validates protocol and passes


