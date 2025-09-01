## COGO CLI Implementation Plan

This document outlines the implementation plan for `cogo-cli`, a command-line tool that applies COGO chat protocol outputs to project artifacts (UI JSON, Symbols, Variables, ActionFlow, Data Action). The CLI is aligned with the COGO Chat SDK (`packages/cogo-chat-sdk-ts`) and the COGO Agent Chat Message Spec.

### Goals
- Turn chat protocol responses into deterministic, idempotent file updates.
- Support plan → apply workflow with safe backups and conflict strategies.
- Integrate with COGO Chat SDK for capabilities, typed SSE streaming, editor context echoing, attachments/artifacts.
- Maintain auditability via `trace_id` and emitted artifacts.

### Non-Goals
- No Flutter runtime integration; output JSONs usable by the Flutter platform are the target.
- No long-running workflows inside the CLI; rely on Edge functions for compute.

### Architecture Overview
- CLI Executable: Node.js/TypeScript, packaged via `npm`.
- Layers:
  1) Command Layer (yargs/commander): parse commands/options, route to services.
  2) Services Layer: planner, applier, sdk wrapper, artifacts/attachments.
  3) Core Utilities: config, logger, fs, JSON patch/merge, idempotency, validators.
- Data Flow: Edge Response → Planner (operations) → Applier (file writes) → Artifacts/Telemetry.

### Modules and Responsibilities
1) Core
- config: read/write `.cogo/config.json` (supabase, project, defaults).
- logger: leveled logging (`info`, `warn`, `error`, `debug`), JSON mode for CI.
- fs-utils: safe write with backup, diff helper, path resolution, globbing.
- json-ops: JSON Pointer, merge/patch, keyed-array merge.
- idempotency: compute fingerprints (sha256 of operations+targets), store last-applied map.
- validators: zod schemas for Plan JSON, Operations, Chat envelope.

2) SDK Integration
- Wrap `cogo-chat-sdk-ts`:
  - capabilities/info: verify `editor_context_support`, `dev_flags_summary`, `task_type_details`.
  - typed SSE: `streamTyped` + `aggregateCli` to build plans from `cli.plan` frames.
  - endpoints: `designGenerate`, `figmaContext`, `compat.variablesDerive`, `compat.symbolsMap`, `bdd.*`, `actionflow.*`, `dataAction.generate`, `attachments.*`.
  - artifacts helpers: `head`, `downloadJson`, and Supabase storage variants.
- Editor Context: accept `--editor-context` JSON and pass through to supported endpoints.

3) Planner
- Inputs: chat response JSON or aggregated SSE results; optional `task_type_details`.
- Output: Plan JSON: `{ trace_id, operations[], fingerprint, execution }`.
- Steps:
  - Validate envelope and `intent`.
  - Select applicable `cli_actions` for the workspace.
  - Infer file paths based on config (`project.ui_dir`, conventions) and hints.
  - Build operations (set/merge/patch/remove) with JSON Pointer.
  - Compute deterministic fingerprint for idempotency.

4) Applier
- Safety: backup targeted files to `backups/` with timestamp+trace, honor `--dry-run`.
- Conflict strategies: `ours|theirs|merge` for array/object merges.
- Execution policy: apply only if `execution.mode` and `approval` permit; else print plan.
- Result: write updated files, output summary JSON, and emit local artifact (optional file).

5) Attachments/Artifacts
- Upload large JSONs via `attachments presign → PUT → ingest → result`.
- Inspect and download artifacts via signedUrl or storage API.

6) Error Model
- Conform to unified error schema from chat spec.
- Exit codes: 0 success; 2 config/env missing; 3 validation error; 4 apply failed; 5 network/SDK error.

### Commands and Options (Initial Scope)
- `cogo cli init`
- `cogo cli config set <key> <value>`
- `cogo cli whoami` (validate keys/project reachability)
- `cogo cli info` (print capabilities summary)
- `cogo cli plan --input chat.json [--editor-context ctx.json] [--out plan.json] [--idempotency-key KEY]`
- `cogo cli apply --plan plan.json [--dry-run] [--backup-dir backups/] [--conflict-strategy ours|theirs|merge]`
- `cogo design generate --text "..." [--dev-cli-simulate] [--editor-context ctx.json] [--out result.json]`
- `cogo figma context --file <fileKey> --page <name> [--stream] [--out result.json]`
- `cogo compat variables derive --project <id> --page-id <n> --page-name <name> --ui-json <file>`
- `cogo compat symbols map --project <id> --page-id <n> --ui-json <file>`
- `cogo bdd generate|refine --input <file>`
- `cogo actionflow generate|refine --input <file>`
- `cogo data-action generate --input <file>`
- `cogo attachments presign|ingest|result ...`
- `cogo artifacts head|download <signedUrl> [-o out]`

### Data Models
- Plan Operation Types:
  - set: overwrite a value at pointer
  - merge: deep-merge object at pointer
  - patch: RFC6902-like patch array (subset as needed)
  - remove: delete path or array item by key
- Plan JSON (zod schema):
  - `trace_id: string`
  - `operations: Array<{ file: string; op: 'set'|'merge'|'patch'|'remove'; jsonPointer: string; value?: any }>`
  - `fingerprint: string`
  - `execution: { mode: 'auto'|'manual'; approval: boolean; dry_run?: boolean; conflict?: 'ours'|'theirs'|'merge' }`

### Configuration
`.cogo/config.json`
```
{
  "supabase": { "project_id": "...", "anon_key": "...", "edge_base": "..." },
  "project": { "root": ".", "ui_dir": "app/ui", "schema": "cogo" },
  "defaults": { "language": "en", "backup_dir": "backups" }
}
```

### Idempotency Strategy
- `idempotency_key` from request or generated UUID.
- Fingerprint: hash of sorted operations, target files, and execution policy.
- Store: `.cogo/idempotency.json` mapping `fingerprint → { lastTrace, timestamp }`.
- Behavior: if fingerprint already applied with same content, skip unless `--force`.

### Security & Governance
- Never log or store secrets. Read keys from env or `.cogo/config.json`.
- Follow Safe Deployment rules; no destructive ops outside project root.
- Respect `server-private` fields in protocol; do not expose.

### Telemetry & Artifacts
- Always include and echo `trace_id`.
- Emit local JSON summary of plan/apply result keyed by `trace_id`.
- Optionally upload artifacts via attachments flow when size is large.

### Testing Plan
1) Unit Tests
  - planner: intent/cli_actions → operations
  - applier: JSON Pointer ops, merge/patch, conflict strategies
  - idempotency: fingerprint stability
2) Integration Tests
  - use dev flags (`dev_cli_simulate`, `dev_abort_after_ms`) against Edge
  - typed SSE: aggregateCli correctness
3) E2E Tests
  - sample repo fixture; run `plan → apply --dry-run`, ensure backups/diffs
  - attachments: presign→PUT→ingest→result→download
4) CI
  - GitHub Actions: run tests, produce JUnit XML, lint

### Milestones & Timeline
1) M0 – Scaffolding (1-2d)
  - package structure, commander/yargs, config, logger
2) M1 – Planner (2-3d)
  - schema, operations, fingerprints, basic validations
3) M2 – Applier (2-3d)
  - backups, conflict strategies, summaries
4) M3 – SDK Integration (2-3d)
  - capabilities, typed SSE, endpoints, editor_context
5) M4 – Attachments/Artifacts (1-2d)
  - presign/ingest/result, head/download
6) M5 – Testing & CI (2-3d)
  - unit/integration/e2e; CI with JUnit
7) M6 – Docs & Release (1-2d)
  - user guide, examples, versioning

### Risks & Mitigations
- Registry/capabilities unavailable → use fallback maps (as in intent-resolve).
- Large file writes → always backup; provide rollback guidance.
- Partial applies → atomic temp-write + replace; plan chunks for resumption.
- SSE flakiness → typed SSE with retries and `keepalive` handling.

### Future Enhancements
- Interactive TUI for reviewing plans and diffs.
- Workspace watchers to auto-plan on new chat responses.
- Policy engine for repository-specific guardrails.


