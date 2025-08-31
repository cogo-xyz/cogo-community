## COGO CLI Design (Draft)

Goal: Provide a CLI that applies COGO chat protocol results to project artifacts (UI JSON, Symbols, Variables, ActionFlow, Data Action) in a safe, traceable, idempotent way, aligned with `cogo-chat-sdk-ts`.

### Principles
- Use the chat protocol: respect `intent`, `cli_actions`, `artifacts`, `execution`, `trace_id`.
- Separation of plan/apply: first compute a plan from chat response, then apply with safeguards.
- Idempotency: use `idempotency_key` and operation fingerprints; re-apply should be safe.
- Offline-first: work with local workspace files; optionally sync via Supabase Storage.
- Auditability: record plan/apply results as artifacts with `trace_id`.

### Scope and Targets
- Edit project JSONs: `UI`, `symbol`, `variable`, `actionflow`, `data_action`.
- Integrate with cogo platform (Flutter) via generated JSON/artifacts; no Flutter runtime dependency in CLI.
- Support both direct chat responses and SDK-assisted flows.

### Command Surface

1) Init and Config
```
cogo cli init              # create .cogo/config.json
cogo cli config set key value
cogo cli whoami           # validate anon/service keys
```

2) Plan / Apply core
```
cogo cli plan --input chat.json [--editor-context ctx.json] \
  [--out plan.json] [--idempotency-key KEY]

cogo cli apply --plan plan.json \
  [--dry-run] [--backup-dir backups/] [--conflict-strategy ours|theirs|merge]
```

3) High-level shortcuts (invoke SDK endpoints)
```
cogo design generate --text "Create login UI" \
  [--dev-cli-simulate] [--editor-context ctx.json] [--out result.json]

cogo figma context --file fileKey --page "Home" \
  [--stream] [--out result.json]

cogo compat variables derive --project demo --page-id 1 --page-name Home \
  --ui-json ui.json [--out result.json]
```

4) Artifacts and Attachments
```
cogo artifacts head <signedUrl>
cogo artifacts download <signedUrl> -o output.json

cogo attachments presign --project demo --file sample.json -o presign.json
cogo attachments ingest --project demo --key <storage_key> -o ingest.json
cogo attachments result --trace <trace_id> -o result.json
```

### Inputs/Outputs
- Input: chat response JSON from Edge (must include `intent`, `cli_actions`, `artifacts`, `execution`, `trace_id`).
- Plan output: minimal actionable steps array with file paths and operations.
- Apply output: updated files, backup manifest, and summary (added/changed/removed).

### Plan Engine
1. Validate envelope_version and schema.
2. Select applicable `cli_actions` entries for current workspace.
3. Resolve file paths (UI, symbols, variables, actionflow, data_action) using conventions or hints.
4. Build operations list: add/update/merge/remove, with JSON Pointer support.
5. Compute fingerprints for idempotency and dedup.

### Apply Engine
- Safety:
  - Backup targeted files to `backups/` before writing.
  - Respect `execution.mode` (auto/manual), `approval`, `dry-run`, `conflict` policy.
- Operations:
  - JSON merge/patch, array keyed-merge, remove by key.
  - Schema-aware normalization where possible.
- Post:
  - Write summary and emit artifact with `trace_id`.

### Editor Context
- Accept `--editor-context ctx.json` or read from stdin.
- Echo into SDK requests where supported (design-generate, figma-context, figma-compat).

### Config
```
.cogo/config.json
{
  "supabase": { "project_id": "...", "anon_key": "...", "edge_base": "..." },
  "project": { "root": ".", "ui_dir": "app/ui", "schema": "cogo" },
  "defaults": { "language": "en", "backup_dir": "backups" }
}
```

### SDK Integration
- Use `cogo-chat-sdk-ts`:
  - Capabilities handshake to verify `editor_context_support`, `dev_flags_summary`.
  - `streamDesignGenerate`/`streamTyped` for SSE and `aggregateCli` for plan aggregation.
  - `compatVariablesDerive` to enrich mappings/types.
  - `artifacts` helpers for head/download.
  - `attachments` flow for large JSONs.

### Use Cases with cogo-chat-sdk (CLI mappings)

1) Capabilities handshake (intent-resolve/info)
```
SDK: client.getCapabilities() or api.intentCapabilities()
CLI: cogo cli whoami / cogo cli info
Notes: read sse_events, dev_flags_summary, task_type_details, editor_context_support.
```

2) Intent resolve (keyword + suggestions)
```
SDK: api.intentResolve({ text, language?, editor_context? })
CLI: cogo cli plan --input chat.json (pre-validate intent)
Notes: use suggestions for unknown keywords; respect envelope_version.
```

3) Design generate (SSE with typed events + CLI aggregation)
```
SDK: api.streamDesignGenerate(body, onEvent, { signal })
SDK(typed): streamTyped(url, headers, body, { handlers }); aggregateCli()
CLI: cogo design generate --text "..." [--dev-cli-simulate] --editor-context ctx.json
Plan: aggregate `cli.plan` frames → produce plan.json. Apply uses `cli.apply`/`cli.done` summaries.
Dev: support dev_abort_after_ms for aborted testing; idempotency_key optional.
```

4) Figma context scan (SSE)
```
SDK: api.streamFigmaContext(body, onEvent, { signal })
CLI: cogo figma context --file F --page P [--stream]
Notes: echo editor_context; surface ready/meta/progress/keepalive/done.
```

5) Compat Variables Derive (mapping/types + ide_hints)
```
SDK: api.compatVariablesDerive({ projectId, page_id, page_name, cogo_ui_json })
CLI: cogo compat variables derive --project demo --page-id 1 --page-name Home --ui-json ui.json
Notes: use ide_hints (selectToast) for UX messages; respect diagnostics.
```

6) Compat Symbols Map / Identify
```
SDK: api.compatSymbolsMap({ ... })
CLI: cogo compat symbols map --project demo --page-id 1 --ui-json ui.json
Notes: emit artifacts.symbols/events when available.
```

7) BDD Generate / Refine
```
SDK: api.bddGenerate({ ... }), api.bddRefine({ ... })
CLI: cogo bdd generate --input spec.json; cogo bdd refine --input feedback.json
Notes: outputs become artifacts; can be planned into actionflow edits.
```

8) ActionFlow Generate / Refine
```
SDK: api.actionflowGenerate({ ... }), api.actionflowRefine({ ... })
CLI: cogo actionflow generate --input bdd.json; cogo actionflow refine --input delta.json
Notes: plan/apply JSON patches to project actionflow files.
```

9) Data Action Generate (execution policy)
```
SDK: api.dataActionGenerate({ ... })
CLI: cogo data-action generate --input request.json
Notes: read response.execution (mode/approval) to gate apply; artifacts included.
```

10) Attachments (large JSON upload)
```
SDK: api.attachmentsPresign → PUT upload → api.attachmentsIngest → api.attachmentsResult
CLI: cogo attachments presign|ingest|result; cogo artifacts head|download
Notes: validate result.content_type/size; use artifacts helpers for fetch.
```

11) Artifacts helpers (direct signedUrl)
```
SDK: head(signedUrl), downloadJson(signedUrl)
SDK (Supabase): storageHead(bucket, key), storageDownloadJson(bucket, key)
CLI: cogo artifacts head <signedUrl>; cogo artifacts download <signedUrl> -o out.json
```

12) Idempotency and retries
```
SDK: pass idempotency_key to streamDesignGenerate/designGenerate
CLI: --idempotency-key on plan/apply; store fingerprint to avoid duplicate writes
Notes: failed apply can be retried safely; design doc recommends persistent store.
```

13) Editor context
```
SDK: buildEditorContext({ openFiles, activeFile, selection })
CLI: --editor-context ctx.json (or stdin); propagate on supported endpoints
```

14) Dev flags and cancellation
```
SDK: dev_cli_simulate, dev_abort_after_ms, dev_disable_fallback
CLI: --dev-cli-simulate, --dev-abort-after-ms, --dev-disable-fallback
Cancel: AbortController in SDK; CLI ctrl-c maps to abort signal.
```

### Plan JSON (example)
```json
{
  "trace_id": "...",
  "operations": [
    { "file": "app/ui/login.json", "op": "merge", "jsonPointer": "/nodes/0", "value": { "type": "container" } },
    { "file": "app/variables.json", "op": "set", "jsonPointer": "/colors/primary", "value": "#3366ff" }
  ],
  "fingerprint": "sha256:...",
  "execution": { "mode": "auto", "approval": false, "dry_run": false, "conflict": "merge" }
}
```

### CLI ↔ SDK mapping (summary)
```
cogo cli info                      → getCapabilities
cogo cli plan --input chat.json    → aggregateCli or parse cli_actions
cogo cli apply --plan plan.json    → filesystem ops + artifacts emit
cogo design generate               → streamDesignGenerate / streamTyped + aggregateCli
cogo figma context                 → streamFigmaContext
cogo compat variables derive       → compatVariablesDerive
cogo compat symbols map            → compatSymbolsMap
cogo bdd generate|refine           → bddGenerate / bddRefine
cogo actionflow generate|refine    → actionflowGenerate / actionflowRefine
cogo data-action generate          → dataActionGenerate
cogo attachments presign|ingest    → attachmentsPresign / attachmentsIngest / attachmentsResult
cogo artifacts head|download       → artifacts.head / artifacts.downloadJson
```

### Examples (Sample Inputs/Outputs)

1) Plan from chat response
```json
// chat.json (input from Edge)
{
  "envelope_version": "v1",
  "trace_id": "trc-123",
  "intent": { "keyword": "uui.design_generate", "suggestions": [] },
  "cli_actions": [
    { "file": "app/ui/login.json", "op": "merge", "jsonPointer": "/nodes/0", "value": { "type": "container", "id": "root" }},
    { "file": "app/variables.json", "op": "set", "jsonPointer": "/colors/primary", "value": "#3366ff" }
  ],
  "execution": { "mode": "auto", "approval": false, "conflict": "merge" }
}
```

```bash
cogo cli plan --input chat.json --out plan.json
```

```json
// plan.json (output)
{
  "trace_id": "trc-123",
  "operations": [
    { "file": "app/ui/login.json", "op": "merge", "jsonPointer": "/nodes/0", "value": { "type": "container", "id": "root" }},
    { "file": "app/variables.json", "op": "set", "jsonPointer": "/colors/primary", "value": "#3366ff" }
  ],
  "fingerprint": "sha256:...",
  "execution": { "mode": "auto", "approval": false, "conflict": "merge" }
}
```

2) Apply summary (dry-run vs apply)
```bash
cogo cli apply --plan plan.json --dry-run
cogo cli apply --plan plan.json --backup-dir backups/
```

```json
// apply-summary.json (example)
{
  "trace_id": "trc-123",
  "dry_run": false,
  "backups": ["backups/2025-01-30/app/ui/login.json", "backups/2025-01-30/app/variables.json"],
  "changes": { "added": 0, "modified": 2, "removed": 0 },
  "files": ["app/ui/login.json", "app/variables.json"]
}
```

3) Design generate (SSE typed frames)
```bash
cogo design generate --text "Create login UI" --editor-context ctx.json --dev-cli-simulate -o result.json
```

```text
event: ready
event: meta { trace_id: "trc-abc" }
event: cli.plan { operations: [...], summary: {...} }
event: cli.apply { result: { modified: 2 } }
event: cli.done { ok: true }
event: done { trace_id: "trc-abc" }
```

4) Figma context (SSE)
```bash
cogo figma context --file AbCdEf --page Home --stream -o figma.json
```

```text
event: ready
event: progress { scanned: 42 }
event: done { trace_id: "trc-xyz" }
```

5) Variables derive (ide_hints)
```bash
cogo compat variables derive --project demo --page-id 1 --page-name Home --ui-json app/ui/home.json -o derive.json
```

```json
// derive.json (snippet)
{
  "trace_id": "trc-555",
  "artifacts": { "mapping": { "button.primary": "#3366ff" }, "types": { "color": ["#3366ff"] } },
  "ide_hints": {
    "toast": { "en": { "title": "Variables derived", "message": "Primary color mapped." }, "ko": { "title": "변수 생성", "message": "기본 색상이 매핑되었습니다." } },
    "open_file": "app/variables.json",
    "highlight": { "file": "app/variables.json", "range": [10, 20] }
  },
  "diagnostics": { "mapping_size": 1, "types_size": 1 }
}
```

6) Attachments flow
```bash
cogo attachments presign --project demo --file sample.json -o presign.json
curl -X PUT -H 'content-type: application/json' --data @sample.json $(jq -r .signedUrl presign.json)
cogo attachments ingest --project demo --key $(jq -r .key presign.json) -o ingest.json
cogo attachments result --trace $(jq -r .trace_id ingest.json) -o result.json
```

7) Artifacts head/download
```bash
cogo artifacts head $(jq -r .signedUrl result.json)
cogo artifacts download $(jq -r .signedUrl result.json) -o output.json
```

8) Capabilities / Info
```bash
cogo cli info
```

```json
// info (snippet)
{
  "ok": true,
  "sse_events": ["ready","meta","progress","cli.plan","cli.apply","cli.done","keepalive","aborted","error","done"],
  "dev_flags_summary": { "dev_cli_simulate": true, "dev_abort_after_ms": false, "dev_disable_fallback": false },
  "task_type_details": { "uui.design_generate": { "requires": ["editor_context"] } },
  "editor_context_support": true
}
```

9) Error and exit codes
```text
Exit 2: Missing SUPABASE_* configuration
Exit 3: Invalid chat envelope or plan JSON
Exit 4: Apply failed (conflicts unresolved)
Exit 5: Network/SDK error
```

### Error Model
- Adopt unified error schema from chat spec.
- Exit codes: 0 success, 2 config/env missing, 3 validation error, 4 apply failed.

### Telemetry & Trace
- Always propagate/emit `trace_id`.
- Optional: record minimal local telemetry (JSON log) keyed by trace.

### Testing Strategy
- Unit: plan builder (JSON merge/patch), path resolution, idempotency.
- Integration: run against `edge-all` dev endpoints with `dev_cli_simulate`.
- E2E: plan->apply dry-run on sample repo; verify backups and diffs.

### Roadmap (Phased)
1. MVP: config, plan/apply, backups, dry-run, JSON merge/patch.
2. SSE: typed SSE + aggregateCli; interactive progress.
3. Advanced ops: symbol/variable inference helpers; array keyed-merge strategies.
4. Attachments and artifacts sync; download large results and apply.
5. Registry-aware: load `task_type_details.requires` for validations.
6. Flutter CLI integration: provide `packages/cogo-cli-flutter` for IDE usage (see below).

### Flutter CLI (cogo-cli-flutter)
- Goal: Provide a Flutter/Dart CLI wrapper so COGO Platform IDE can invoke local commands identically to TS CLI.
- SDK: `packages/cogo-chat-sdk-flutter` (SSE typed + Hybrid OR + Realtime broadcast).
- Commands (initial): `cli info`, `design generate`, `figma context`, `compat variables derive`, `compat symbols map`, `attachments presign|ingest|result`, `artifacts head|download`, `trace-status`.
- Handoff: handle `queued`/`handoff`; auto-subscribe `trace:{traceId}` and print JSON lines.
- Output: JSON envelopes with `ok`, `trace_id`, and result artifacts to allow IDE parsing.


