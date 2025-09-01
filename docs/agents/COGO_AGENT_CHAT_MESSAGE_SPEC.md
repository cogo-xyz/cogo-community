## COGO Agent – Chat Response Spec (User-Facing)

This document defines the response message format returned to users via chat. It excludes internal utility calls (rag/llm/graph/schema-introspect, etc.) and includes only task_types exposed to user scenarios.

## Protocol Overview (IDE-first)
- Purpose: A contract so IDEs (Desktop/Mobile) can safely implement features using a minimal common field set
- Transport: JSON over HTTP; when needed, stream progress via SSE frames (`.../stream`) and synthesize a final JSON response
- Required (IDE relies on): `task_type`, `title`, `response`, `trace_id`, `intent.keywords`, `artifacts` (preview or links)
- Optional (IDE uses when present): `cli_actions`, `execution`
- Server-private (not exposed by default): `agent`, `provenance` (observability/debugging)
- Security: In dev use `Authorization: Bearer <ANON>` and `apikey: <PUBLISHABLE>`; in prod enable JWT/HMAC/rate limiting
- Artifacts: Store large outputs in Storage; include signed URL links or identifiers in responses
- Idempotency: Use `idempotency_key` for safe retries

### Related Documents
- Edge functions overview: `docs/EDGE_FUNCTIONS_OVERVIEW.md`
- Intent resolve registry/TTL/metrics: `docs/INTENT_RESOLVE_METRICS.md`
- Security hardening guide: `docs/SECURITY_HARDENING.md`
- Artifacts retention policy: `docs/ARTIFACTS_RETENTION.md`
- Supabase CLI update/local pipeline: `docs/SUPABASE_CLI_UPDATE_GUIDE.md`
- Intent keyword/templating registry plan: `docs/plans/INTENT_KEYWORD_REGISTRY.md`

## Message Flow
1) User → Chat input (natural language)
2) Server (agent) → extract/validate intent keywords (`intent.keywords`) and plan (internal)
3) (optional) Stream progress via SSE → IDE shows progress UI
4) Server → final response (JSON): minimum contract fields + `artifacts` (and `cli_actions` when applicable)
5) IDE → execute `cli_actions` based on user approval/policy (dry-run → apply)
6) (optional) IDE/Server → summarize results/artifacts and index by `trace_id`

SSE event example: `meta` → domain-specific progress frames (e.g., `rag.item`, `page.chunk`) → `done`

---

## Message Schema

### Required Fields (Common)
- task_type: One of the response types defined below
- title: Simple title understandable from user perspective
- response: Final output (or summary) text body
- trace_id: Trace ID (connected to SSE/logs/artifacts)
- intent: Block expressing user intent structurally (required for IDE/CLI automation)

Table summary:

| Field     | Type   | Description                | Example                                                   |
|-----------|--------|----------------------------|-----------------------------------------------------------|
| task_type | String | Response type              | "design_generate"                                        |
| title     | String | Response title             | "Design Generation - Login Page"                         |
| response  | String | Final result (or summary) body | "UI generated. See JSON below …"                         |
| trace_id  | String | Trace ID                   | "9a5558e6-726b-41bc-8e75-6577467900d1"                  |
| intent    | Object | User intent (structured)   | {"text":"Create a login page", "target":{"project_uuid":"..."}} |

Common Optional Fields (when needed):
- meta: { model, page, project_id, job_id, … }
- artifacts: Result JSON/links/brief previews, etc. (links recommended for large files)
- idempotency_key: Key for safe retries/re-execution (optional)
- cli_actions: List of actions for IDE/CLI to execute (see section below)
- ide_hints: { toast?: string, open_file?: string, highlight?: {path, range}, next_action?: string }
  - Localization: Server can provide multi-language toasts by referencing request's `intent.language` (or `language`) (e.g., ko/en/ru/th/ja)
- execution: { mode: 'local_cli' | 'remote_worker', approval_required?: boolean, dry_run?: boolean, default_conflict_strategy?: 'skip'|'overwrite'|'merge' }
  - Standard location: Include as top-level field in response object, consistently across all task_types
  - Purpose: Policy hints to allow IDE/CLI to auto-apply approval/dry-run/conflict policies
- envelope_version: string (e.g., 'v1')
  - Standard location: Top-level response object; version flag for server-client protocol compatibility management

### Client Request Schema (IDE → Server)
- Required fields:
  - text: string (user text)
  - intent.language: string (e.g., en|ko|ja|ru|th)
  - target.project_uuid: string
- Optional fields:
  - payload: object (ui_json_ref|bdd_text|actionflow|api etc.)
  - attachments: [{ name, url|id, mime, size, kind }]
  - session_id: string, parent_message_id: string
  - idempotency_key: string
  - client: { ide: string, version: string }
  - editor_context: { open_files?: string[], active_file?: string, selection?: { path: string, range: [number, number] } }

Example (design-generate):
```json
{
  "text": "Create login UI",
  "intent": { "language": "en", "keywords": ["ui.generate"], "target": { "project_uuid": "demo" } },
  "editor_context": {
    "open_files": ["app/pages/loginPage.json"],
    "active_file": "app/pages/loginPage.json",
    "selection": { "path": "app/pages/loginPage.json", "range": [10, 30] }
  }
}
```

### SSE Event Catalog (Standardized)
- meta: initial job/context info
- progress: { stage: string, progress_pct?: number, note?: string }
- queued: { estimate_ms?: number, reason?: string } – server indicates backlog/slow path; client may switch to Realtime
- handoff: { job_id: string, reason?: string } – server moves to background; use Realtime trace channel
- cli.plan: preview planned CLI actions
- cli.apply: per-action status { id, status: 'pending'|'running'|'done'|'error', diff?: any, logs?: string[], start_ms?: number, end_ms?: number }
- cli.done: aggregate result of CLI execution
- keepalive: heartbeat frame (no payload or {ts})
- aborted: client cancelled request (sent when AbortController triggers)
Example (aborted):
```
event: ready
data: {"trace_id":"..."}

event: keepalive
data: {"trace_id":"..."}

event: aborted
data: {"trace_id":"...","reason":"dev_abort"}
```
- error: unified error frame (see below)
- done: terminal frame (stream end)

Quick-reference table:

| Event        | Payload key points                                      |
|--------------|---------------------------------------------------------|
| ready        | trace_id                                                |
| meta         | trace_id, envelope_version, intent, editor_context?     |
| progress     | stage, pct, message?                                    |
| queued       | estimate_ms?, reason?, trace_id                         |
| handoff      | job_id, reason?, trace_id                                |
| rag.item     | index, item:{id,score,snippet}                          |
| rag.done     | count, disabled?                                        |
| llm.done     | text                                                    |
| ui.generate  | result                                                  |
| page.ready   | page_id                                                 |
| page.chunk   | page_id, chunk_idx, total_chunks, components[]          |
| page.includes| page_id, includes[]                                     |
| cli.plan     | actions[]                                               |
| cli.apply    | action_id, status, message?, diff?                      |
| cli.done     | summary                                                 |
| keepalive    | trace_id                                                |
| aborted      | trace_id, reason                                        |
| error        | code, message, retryable?, details?                     |
| done         | final response fields, artifacts?, intent?, trace_id    |

### Hybrid SSE → Realtime Handoff (Recommended)

- Start with SSE to receive `meta` (with `trace_id`) and early frames.
- On `queued` or `handoff`, the client SHOULD subscribe to Supabase Realtime channel `trace:{trace_id}` for progress and finalization.
- Server durability is ensured by idempotent execution and `cogo.bus_events`; a relay broadcasts INSERTs to `trace:{trace_id}`.
- Clients MAY retry SSE with the same Idempotency-Key or resume via Realtime if SSE disconnects.
- Polling fallback: `GET /trace-status?trace_id=<id>` returns `{ ok, trace_id, status: pending|queued|handoff|done|error, events[] }` for environments where Realtime is disabled/unavailable.

Client pattern (TS SDK): use `streamOrRealtime(...)` with an optional Supabase subscriber factory. See `tools/examples/sdk-stream-or-realtime.mjs`.

### Client Close Semantics (Deterministic)

- SSE stream MUST close promptly on `done`/`error`/`handoff`. The SDK enforces this by using an internal `AbortController` and aborting when those frames arrive.
- Realtime subscription MUST be cleaned up asynchronously. The SDK expects `subscribeTrace(traceId, onEvent, signal)` to return `Promise<() => Promise<void>>`; the unsubscribe is awaited in a `finally` block to guarantee release.
- External cancellation: if caller passes `AbortSignal`, the SDK chains it to the internal controller to close both SSE and Realtime consistently.

### Unified Error Model (JSON and SSE)
All errors returned as:
```json
{ "code": "string", "message": "string", "retryable": false, "details": {}, "trace_id": "uuid" }
```

### Version Negotiation
- Request should include desired envelope_version (default 'v1')
- Response MUST include envelope_version and MAY include server_version and capabilities_version

### Capabilities Handshake
- Endpoint: GET /intent-resolve/info (extended) or /chat/capabilities
- Returns: supported task_type catalog, intent.keywords (with requires), limits (rate/size), SSE policy, versions
- Notes: When Realtime is unavailable, clients SHOULD use `/trace-status` polling fallback with exponential backoff.

Example (response snippet):
```json
{
  "ok": true,
  "envelope_version": "v1",
  "capabilities_version": "v1",
  "server_version": "v1",
  "task_type": ["design_generate", "figma_context_scan", "variables_derive"],
  "intent_keywords": ["ui.generate", "figma.context_scan", "variables.derive"],
  "limits": { "sse_keepalive_ms": 15000, "max_attachment_mb": 10 },
  "sse_events": ["ready","meta","progress","queued","handoff","cli.plan","cli.apply","cli.done","keepalive","aborted","error","done"],
  "task_type_details": {
    "design_generate": { "keyword": "ui.generate", "recommended_channel": "sse", "handoff_supported": true, "sla_tier": "short" }
  },
  "editor_context": {
    "header": "x-editor-context",
    "body_field": "editor_context",
    "echo_in": ["design-generate","figma-context","figma-compat"]
  },
  "editor_context_support": true,
  "requires_source": "registry"
}
```

Query params:
- `include_fallback=1` → Force server to return default `requires` map even if registry is available. Helpful in dev/test when Service Role key is not configured.

Notes:
- Field `requires_source` indicates whether `task_type_details[*].requires` come from `registry` or `fallback`.
- `task_type_details[*].recommended_channel`: 'sse' | 'realtime' | 'both'
- `task_type_details[*].handoff_supported`: boolean; server may emit `handoff`
- `task_type_details[*].sla_tier`: 'short' | 'batch' | 'external'

### Attachments (Input/Output)
- Structure: { name, url|id, mime, size, kind }
- Guidance: use signed URLs for large files; avoid embedding large payloads inline

Testing note:
- For variables mapping empty-state UI hints, servers may support a development toggle (e.g., `dev_disable_fallback=true`) to avoid synthetic fallbacks and surface `ide_hints` toasts.

### Cancellation Semantics
- Client abort should be observed; server emits 'aborted' frame and cleans up resources
- Idempotency keys prevent duplicate execution on retries

### Development Flags (for local testing)
- dev_cli_simulate: boolean
  - When true (supported on selected endpoints like design-generate/figma-context streams), server emits synthetic CLI frames to help IDE UI development.
  - Frames sequence example:
  ```
  event: cli.plan
  data: {"trace_id":"...","actions":[{"id":"sim_1","tool":"cogo-cli","command":"variables upsert","args":["--project","demo","--from-stdin"]}]}

  event: cli.apply
  data: {"trace_id":"...","action_id":"sim_1","status":"running"}

  event: cli.apply
  data: {"trace_id":"...","action_id":"sim_1","status":"success","diff":"noop"}

  event: cli.done
  data: {"trace_id":"...","summary":{"total":1,"success":1,"failed":0}}
  ```

- dev_abort_after_ms: number
  - When set (body or env), server emits `aborted` after N ms to help test client-side cancellation UX.

Capabilities expose both a detailed `dev_flags` schema and a quick `dev_flags_summary` boolean map for availability.

---

### Implementation Notes (COGO Agent)
- Items below are immediately implementable by the COGO Agent. Process them in the order of fields.

1) task_type
   - Maintain fixed enum-level list (same as task_type section at document bottom). Reject unregistered values.
   - Processing routing: task_type → handler (Edge function/submodule) mapping.

2) title
   - User-facing summary string. Optional i18n. Required.

3) response
   - Human-readable summary. Keep within ~2KB. Put large details under artifacts (links or previews).

4) trace_id
   - Generate at request ingress (UUIDv4). Propagate to SSE/logs/artifacts/metrics.
   - Ensure lookup is possible via `/api-router/metrics/trace/{traceId}`.

5) intent
   - keywords required: validated against `cogo.intent_keyword`. Unknowns are rejected or downgraded.
   - parsed.target must include at least `project_uuid`; otherwise 400.
   - confidence in 0..1 float. If omitted, compute internally and include.

Optional Fields
6) meta
   - Free-form metadata. No PII/secrets. Mask when necessary.

7) artifacts
   - Use `_shared/artifacts.ts` to upload/sign/record. Keep previews under ~4KB.
   - `links` should include signed URL and name/mime/size.

8) idempotency_key
   - Accept from header/body. Reuse to prevent duplicate execution on retries.

9) cli_actions
   - Allow only whitelisted commands. Validate `input_artifact_ref`.
   - Default policy: `dry_run=true`, then apply on approval.
   - Fallbacks: when templates are disabled/missing or merge yields empty, include safe defaults
     - bdd.generate/refine: echo suggestion
     - actionflow.generate: `actionflow upsert --project <...> --from-stdin` if `artifacts.actionflow` exists

10) ide_hints
   - Pure UX hints. Optional and decoupled from core logic.


## User Intent · Agent I/O Block

### intent block
Purpose: Standardize how IDEs receive the interpreted intent/scope so they can automate safely without guessing user intent.

Important: IDE only needs `intent` and final outputs (`response`/`artifacts`/`cli_actions`). `agent`, `provenance` are server-private by default.

Recommended structure:
```json
{
  "intent": {
    "text": "Create a simple login page with email and password",
    "language": "en",
    "keywords": ["ui.generate", "variables.derive"],
    "parsed": {
      "goal": "Generate COGO UI JSON and initial variables for login",
      "scope": ["single page", "basic form", "client-side validation"],
      "constraints": ["no backend secret", "mobile-first"],
      "acceptance": ["email + password fields", "login button", "loading state"],
      "target": { "project_uuid": "<PROJECT_UUID>", "page_id": 101 }
    },
    "confidence": 0.86,
    "intent_id": "u-2025-08-18T12:00:00Z-001",
    "registry": { "version": "1.0.0", "source": "cogo.intent_keyword" },
    "suggestions": { "ui.generate": ["ui.generate"], "variables.derive": ["variables.derive"] }
  }
}
```

Keyword rules:
- Format: `namespace.action` lowercase dot notation (e.g., `ui.generate`, `symbols.identify`, `variables.derive`, `actionflow.generate`, `data_action.bind`).
- Definition location: Only use values registered in `cogo.intent_keyword` registry (unregistered keywords are rejected/downgraded).
- Backward compatibility: Maintain free-form `parsed.goal` from old spec, but automation operates based on `keywords`.

Validation rules (summary):
- `intent.keywords[*]` ∈ registry.
- `intent.registry.version` must be compatible with server's active registry version (include warning/migration guide on mismatch).
- Additional payload requirements reference registry's `requires` schema when needed.

Additional property (suggestions):
- Purpose: Provide registry keyword suggestions for tokens not interpreted in user text
- Format: `intent.suggestions` is `{ [unknownToken: string]: string[] }` format
- Usage: IDE/CLI can display selection UI to optionally add suggested keywords to intent

### agent block (server-private: not exposed by default)
Purpose: Transparently include what requests the agent made and what responses it received so IDE can make execution/validation/rollback decisions.

Recommended structure:
```json
{
  "agent": {
    "plan": {
      "mode": "sequential",
      "steps": [
        {"id": "rag_1", "kind": "edge", "endpoint": "/rag", "depends_on": []},
        {"id": "llm_1", "kind": "edge", "endpoint": "/chat", "depends_on": ["rag_1"]}
      ]
    },
    "requests": [
      {"id": "rag_1", "endpoint": "/rag", "params": {"q": "login page patterns"}, "reason": "retrieve patterns", "timeout_ms": 5000},
      {"id": "llm_1", "endpoint": "/chat", "params": {"messages": [{"role":"system","content":"..."}]}, "reason": "plan + draft UI", "timeout_ms": 15000}
    ],
    "responses": [
      {"request_id": "rag_1", "ok": true, "latency_ms": 120, "output_ref": "artifacts.rag_preview"},
      {"request_id": "llm_1", "ok": true, "latency_ms": 920, "summary": "generated layout plan"}
    ]
  }
}
```

### execution (application policy) field
```json
{
  "execution": {
    "mode": "local_cli",
    "approval_required": true,
    "dry_run": true,
    "default_conflict_strategy": "skip",
    "rollback": { "enabled": true, "strategy": "artifact_restore" }
  }
}
```

### provenance (source) field (server-private: not exposed by default)
```json
{
  "provenance": {
    "agent_id": "cogo-orchestrator-01",
    "role": "planner",
    "model": "claude-sonnet-4-20250514",
    "toolchain": ["rag", "chat"],
    "created_at": "2025-08-18T12:01:23Z"
  }
}
```

#### Artifacts Field (Purpose and Description)
- Purpose: Separate large/structured outputs from chat body for safe delivery and linkage with artifact storage/trace
- Rationale:
  - Chat message `response` focuses on human-readable summary
  - Original JSON/files often need format preservation, versioning, and download capabilities
  - Security/governance: appropriate to deliver large/sensitive data via links/IDs
- Recommended usage:
  - Small: Include preview snippets (JSON snippet) in artifacts
  - Large: Include only artifact ID/URL (e.g., `artifact_id`, `url`)
- Example structure:
```json
{
  "artifacts": {
    "cogo_ui_json_preview": { "version": "1.0", "page": {"name": "..."}, "tree": [/* truncated */] },
    "actionflow": { "id": "...", "actionType": "flow", "steps": [/* ... */] },
    "links": [{ "name": "full_ui_json", "url": "https://.../artifacts/ui/login.json" }]
  }
}
```
- frames: SSE frame summary list (when needed)

### CLI/IDE Integration Spec (Additional)
- Purpose: Standardize how COGO IDE (Desktop/Mobile) or background CLI receives chat responses to safely modify/apply actual COGO JSON (UI, symbols, variables, actionflow, data actions)

#### cli_actions field structure
```json
{
  "cli_actions": [
    {
      "id": "vars_upsert_1",
      "tool": "cogo-cli",
      "command": "variables upsert", 
      "args": ["--project", "<PROJECT_UUID>", "--page-id", 101, "--from-stdin"],
      "input_artifact_ref": "artifacts.mapping", 
      "target": { "project_uuid": "<PROJECT_UUID>", "page_id": 101, "component_id": null },
      "idempotency_key": "<trace_id>:vars_upsert_1",
      "dry_run": true,
      "apply_strategy": "merge", 
      "conflict_strategy": "skip", 
      "depends_on": ["symbols_identify_1"]
    }
  ]
}
```

Template merging (templates):
- Server can load templates based on `cogo.intent_action_template` registry and merge into response's `cli_actions`.
- Priority: Inline `cli_actions` in response → template load results merge (duplicate ids kept only once).
- Placeholders: Substitute context values like `{{project_uuid}}`, `{{page_id}}`, `{{trace_id}}`.
 - Fallback: When templates are not interpreted or results are empty, server can include minimum actions according to Fallbacks policy above.

Field descriptions:
- tool/command/args: Execution tool and subcommand, arguments. IDE limits to whitelist.
- input_artifact_ref: Reference path to JSON/URL in this message's `artifacts` (JSON Path-like). When used with `--from-stdin`, IDE pipes content to standard input.
- target: Target identifier for application. Minimum `project_uuid` required. Include `page_id`, `component_id` when needed.
- idempotency_key: Prevent duplicate execution of same action. Recommend `trace_id:id` when unspecified.
- dry_run: If true, perform simulation only and report change summary (diff).
- apply_strategy: Change application method. Recommended set: [merge|replace|upsert].
- conflict_strategy: Conflict handling. [skip|overwrite|create_new|fail].
- depends_on: Preceding action ID. Skip/rollback policy on preceding failure follows IDE policy.

Recommended procedure (IDE/CLI):
1) Present cli.plan frame/preview(diff) → user confirmation or auto-approval based on policy
2) On approval, execute according to sequential/parallel dependencies → status via SSE `cli.apply`, completion `cli.done`
3) On failure, expose `cli.error` frame with rollback/retry guidance

Security/Governance:
- Command whitelisting·argument validation·working directory isolation
- Do not include sensitive data directly in `artifacts`, use links/signed URLs
- Record execution results/change summaries in `cogo.artifacts` (optional)

---

## task_type Definitions and Examples

Below examples are user response examples based on actual implementations (Edge Functions: design-generate, figma-context, figma-compat series) and documentation.

### Task Type Catalog (Definitions)
- Purpose: Catalog to ensure IDE/server use task_type with consistent meaning
- Common rules: All responses require `trace_id`, large files delivered via `artifacts.links`

- design_generate
  - **Description**: Generate COGO UI JSON draft based on natural language requirements
  - **Related intent.keywords**: `ui.generate`
  - **Input (example)**: `prompt` (required), `model` (optional)
  - **Output**: `response` summary, `artifacts.cogo_ui_json_preview` (preview), links when needed
  - **General CLI actions**: None (draft), variables/actionflow derived in later steps

- figma_context_scan
  - **Description**: Scan Figma page/nodes (SSE chunks)
  - **Related intent.keywords**: `figma.context_scan`
  - **Input (example)**: `figma_url` (required), `node-id` (optional)
  - **Output**: `meta.job_id`, progress frames, (optional) `artifacts.figma_subtree_preview|links`
  - **General CLI actions**: None (scan)

- figma_apply
  - **Description**: Apply scan results to project page/component
  - **Related intent.keywords**: `figma.apply`
  - **Input (example)**: `job_id` (required), `page_id` (required)
  - **Output**: Application result summary

- symbols_identify
  - **Description**: Identify `#symbols` and event candidates from UI JSON
  - **Related intent.keywords**: `symbols.identify`
  - **Input (example)**: `ui_json` or reference link
  - **Output**: `artifacts.symbols`, `artifacts.events`

- variables_derive
  - **Description**: Generate `#symbols` → variable (appData/uiState) mapping
  - **Related intent.keywords**: `variables.derive`
  - **Input (example)**: `page`, `symbols[]`, naming/type policy
  - **Output**: `artifacts.mapping`, `artifacts.types`
  - **General CLI actions**: `variables upsert` (dry-run → approval → apply)

- bdd_generate
  - **Description**: Generate Given-When-Then draft for event
  - **Related intent.keywords**: `bdd.generate`
  - **Input (example)**: `event_id`, `symbols/variables`
  - **Output**: `response` body (GWT text)

- bdd_refine
  - **Description**: Enhance/refine existing BDD (branches/validation, etc.)
  - **Related intent.keywords**: `bdd.refine`
  - **Input (example)**: Existing BDD, policy
  - **Output**: `response` body (update summary)

- actionflow_generate
  - **Description**: Generate ActionFlow JSON from finalized BDD
  - **Related intent.keywords**: `actionflow.generate`
  - **Input (example)**: BDD text/structure
  - **Output**: `artifacts.actionflow`

- actionflow_refine
  - **Description**: Enhance ActionFlow (guards/branches/API binding, etc.)
  - **Related intent.keywords**: `actionflow.refine`
  - **Input (example)**: Existing ActionFlow, policy
  - **Output**: `response` body (update summary) or diff link

- data_action_generate
  - **Description**: Define and bind data/REST actions (whitelist, saveTo included)
  - **Related intent.keywords**: `data_action.bind`
  - **Input (example)**: API spec/path/method, binding policy
  - **Output**: `artifacts.action` (single action definition)

### 1) design_generate (IDE minimum example)
- Description: User request "create this screen" → LLM+RAG planning → COGO UI JSON generation (progress via SSE)
- Input (example): prompt, (optional) model
- Output: Plan summary, final UI JSON preview (summary/link)

Example response:
```json
{
  "task_type": "design_generate",
  "title": "Design Generation - Login Page",
  "response": "Generated UI plan (header/main/footer) and initial COGO UI JSON.",
  "trace_id": "9a5558e6-726b-41bc-8e75-6577467900d1",
  "intent": {
    "text": "Create a simple login page with email and password",
    "keywords": ["ui.generate"],
    "parsed": {"goal": "UI JSON for login", "target": {"project_uuid": "<PROJECT_UUID>"}},
    "confidence": 0.85
  },
  "execution": {"mode": "local_cli", "approval_required": true, "dry_run": true},
  "artifacts": {
    "cogo_ui_json_preview": {
      "version": "1.0",
      "page": {"name": "loginPage"},
      "tree": [{"id": "root", "type": "container"}]
    }
  },
  "meta": {"model": "auto", "sse": true}
}
```

### 2) figma_context_scan (IDE minimum example)
- Description: Scan Figma page/node structure and send components/chunks via SSE
- Input (example): figma_url (and optional node-id)
- Output: Collection summary (total chunks/representative components, etc.)

Example response:
```json
{
  "task_type": "figma_context_scan",
  "title": "Figma Context Scan - Page",
  "response": "Scanned page successfully. 1 chunk emitted, includes header/footer placeholders.",
  "trace_id": "47423a2f-7707-4556-8abe-fb324af39975",
  "intent": {
    "text": "Scan the current Figma page and prepare for mapping",
    "keywords": ["figma.context_scan"],
    "parsed": {"target": {"project_uuid": "<PROJECT_UUID>"}}
  },
  "meta": {"job_id": "2a6d74b5-6490-4ded-aa08-6451c2505f63", "chunks": 1}
}
```

### 3) figma_apply
- Description: Apply scan results to project page/component
- Input (example): job_id, page_id
- Output: Application result and trace_id

Example response:
```json
{
  "task_type": "figma_apply",
  "title": "Apply to Page",
  "response": "Apply queued successfully.",
  "trace_id": "d0b1f9ab-2c8a-4851-8a90-3d34c3d3e6f0",
  "meta": {"job_id": "2a6d74b5-6490-4ded-aa08-6451c2505f63", "page_id": 101}
}
```

### 4) symbols_identify
- Description: Identify dynamic points/event candidates `#symbols` from UI JSON
- Input (example): ui_json (or reference link)
- Output: `#symbols` list and simple rationale

Example response:
```json
{
  "task_type": "symbols_identify",
  "title": "Symbols Identified - loginPage",
  "response": "Found 4 symbols and 2 events.",
  "trace_id": "1f2a7b61-3a5b-4e7b-8cf2-3a1a8c02bb7a",
  "artifacts": {
    "symbols": ["#userName", "#password", "#errorMessage", "#rememberMe"],
    "events": ["#onLoginClicked", "#onRememberToggle"]
  },
  "ide_hints": {
    "toast": "No symbols/events detected. Add #placeholders or input names.",
    "toast_ko": "심볼/이벤트가 감지되지 않았습니다. 텍스트에 #플레이스홀더를 추가하거나 입력 name을 제공하세요.",
    "open_file": "app/pages/loginPage.json",
    "highlight": { "path": "app/pages/loginPage.json", "range": [12, 24] },
    "next_action": "add_placeholders"
  }
}
```

### 5) variables_derive
- Description: Derive/map `#symbols` to variables (appData/uiState)
- Input (example): page, symbols[], policy (naming/type)
- Output: Mapping table and type information

Example response:
```json
{
  "task_type": "variables_derive",
  "title": "Variables Mapping - loginPage",
  "response": "Mapped symbols to appData/uiState.",
  "trace_id": "a4d5e4b2-3b94-4b12-9f3e-9b0f2c10a2ce",
  "artifacts": {
    "mapping": {
      "#userName": "#_appData.loginPage.userName",
      "#isLoading": "#_uiState.loginPage.isLoading"
    },
    "types": {"#_appData.loginPage.userName": "string", "#_uiState.loginPage.isLoading": "boolean"}
  ,
  "suggestions": { "mapping_examples": { "#userName": "#_appData.loginPage.userName", "#isRemember": "#_uiState.loginPage.isRemember" } }
  },
  "ide_hints": {
    "toast": "No variables mapping created. Add #placeholders in text or input names.",
    "toast_ko": "변수 매핑이 생성되지 않았습니다. 텍스트에 #플레이스홀더 또는 입력 name을 추가하세요.",
    "open_file": "app/pages/loginPage.json",
    "highlight": { "path": "app/pages/loginPage.json", "range": [5, 30] },
    "next_action": "add_placeholders"
  },
  "cli_actions": [
    {
      "id": "vars_upsert_1",
      "tool": "cogo-cli",
      "command": "variables upsert",
      "args": ["--project", "<PROJECT_UUID>", "--page-id", 101, "--from-stdin"],
      "input_artifact_ref": "artifacts.mapping",
      "target": { "project_uuid": "<PROJECT_UUID>", "page_id": 101 },
      "idempotency_key": "a4d5e4b2-3b94-4b12-9f3e-9b0f2c10a2ce:vars_upsert_1",
      "dry_run": true,
      "apply_strategy": "merge",
      "conflict_strategy": "skip"
    }
  ]
}
```

### 6) bdd_generate
- Description: Generate BDD draft for specific event
- Input (example): event_id, symbols/variables
- Output: Given-When-Then text

Example response:
```json
{
  "task_type": "bdd_generate",
  "title": "BDD Draft - #onLoginClicked",
  "response": "Given #userName and #password … Then call #restAPI:Login and set #errorMessage",
  "trace_id": "3a2b1c90-2c1e-4aa9-9b5b-0726a9d74f46"
}
```

### 7) bdd_refine
- Description: Enhance/refine existing BDD (branches/validation, etc.)

Example response:
```json
{
  "task_type": "bdd_refine",
  "title": "BDD Refined - #onLoginClicked",
  "response": "Added empty-field validation and error branch for #errorMessage.",
  "trace_id": "7c73fa9e-2a8b-4c27-814f-ef842d4d1a63"
}
```

### 8) actionflow_generate
- Description: Generate ActionFlow JSON from finalized BDD (undecided steps use actionType:"none")

Example response:
```json
{
  "task_type": "actionflow_generate",
  "title": "ActionFlow Generated - loginProcessFlow",
  "response": "Compiled BDD to ActionFlow with 3 steps (setProperty → restApi → setProperty).",
  "trace_id": "c8b8d7f3-2f1e-4579-8b52-2b8a7db5a1b0",
  "artifacts": {
    "actionflow": {
      "id": "loginProcessFlow",
      "actionType": "flow",
      "steps": [
        {"actionType": "basic", "actionId": "setProperty", "params": {"target": "#isLoading", "value": true}},
        {"actionType": "callback", "actionId": "restApi", "params": {"path": "/login", "method": "POST"}},
        {"actionType": "basic", "actionId": "setProperty", "params": {"target": "#isLoading", "value": false}}
      ]
    }
  }
}
```

### 9) actionflow_refine
- Description: Enhance ActionFlow (guards/branches/API binding, etc.)

Example response:
```json
{
  "task_type": "actionflow_refine",
  "title": "ActionFlow Refined - loginProcessFlow",
  "response": "Added guard and error branch; bound Login API with saveTo mapping.",
  "trace_id": "f1c9c220-2eb6-4e56-9ad1-216c8342d4e8"
}
```

### 10) data_action_generate
- Description: Define and bind data/REST actions (whitelist, saveTo included)

Example response:
```json
{
  "task_type": "data_action_generate",
  "title": "Data Action - Login API Binding",
  "response": "Added restApi action with host whitelist and saveTo mapping.",
  "trace_id": "a8d531d1-8d3c-43e6-8f96-a6a21f2b7c2c",
  "artifacts": {
    "action": {
      "actionType": "callback",
      "actionId": "restApi",
      "params": {
        "baseUrl": "#_appData.api.base",
        "path": "/login",
        "method": "POST",
        "body": {"u": "#userName", "p": "#password"},
        "saveTo": "#_appData.session.auth"
      }
    }
  }
  ,
  "execution": {"mode": "local_cli", "approval_required": true, "dry_run": true, "default_conflict_strategy": "skip"}
}
```

---

### Reference (Recommended Client Handling with SSE)
- When requesting with `Accept: text/event-stream`, display progress stages frame-by-frame on screen, then synthesize the "response message" from this spec and deliver to user.
- Large JSON files delivered via links/artifact IDs, with summary in `response`.


