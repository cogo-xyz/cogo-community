## cogo-cli-flutter

Command-line utilities for COGO Edge Functions, aligned with cogo-chat-sdk-flutter.

### Prerequisites
- SUPABASE_PROJECT_ID, SUPABASE_ANON_KEY (required)
- Optionally SUPABASE_EDGE (else computed from project id)
- COGO_PROJECT_ID (UUID)

### Commands
- info
- compat-symbols-map
- compat-variables-derive
- compat-bdd-generate
- compat-bdd-refine
- compat-actionflow-refine
- compat-generate
- trace-status [--trace-id ID | ID]
- attachments-presign [--print-key-only]
- attachments-presign-key
- attachments-ingest [--storage-key KEY] [--wait] [--timeout-seconds N]
- attachments-result [--trace-id ID | ID] [--timeout-seconds N]
- attachments-download [--trace-id ID | --signed-url URL] [--out-file FILE]
- json-set --file p.json --pointer /a/b --value '{"x":1}' [--backup-dir .bak]
- json-merge --file p.json --pointer /a --value '{"y":2}' [--backup-dir .bak]
- json-remove --file p.json --pointer /a/b [--backup-dir .bak]

Global options:
- --project-id UUID
- --page-id Number (compat 전용: components 업서트 등에 필요할 수 있음)
- --timeout-seconds N
- --out-key, --out-trace, --out-json

### Quickstart
```bash
export SUPABASE_PROJECT_ID=xxxxx
export SUPABASE_ANON_KEY=xxxxx
export COGO_PROJECT_ID=00000000-0000-4000-8000-000000000000

# 1) ingest existing uploads/uui.json, wait for result
dart run bin/cogo_cli_flutter.dart \
  --project-id "$COGO_PROJECT_ID" --timeout-seconds 30 \
  attachments-ingest --wait --storage-key "uploads/$COGO_PROJECT_ID/uui.json"

# 2) poll result by trace
TRACE=<trace_id_from_step1>
dart run bin/cogo_cli_flutter.dart \
  --project-id "$COGO_PROJECT_ID" \
  attachments-result --trace-id "$TRACE"

# 3) download artifact
dart run bin/cogo_cli_flutter.dart \
  --project-id "$COGO_PROJECT_ID" \
  attachments-download --trace-id "$TRACE" --out-file artifact.json
```

### Notes
- Edge auth: Authorization: Bearer <ANON>, apikey: <ANON> (handled internally)
- Realtime: ingest emits events to `bus_events` and broadcasts on `trace:{traceId}`
- Artifacts: result returns `{ bucket, key, signedUrl }` where `key` is bucket-relative (no leading bucket name)
- Components: when `LEGACY_COMPONENTS_ENABLE=true` and the server requires `COMP_COL_PAGE_ID`, provide a valid `--page-id`. If omitted, the server may return `page_id_required` or a foreign-key error. This does not affect compat artifact generation itself.

### Chat Loop (Cursor-like HITL workflow)
```bash
# Start a loop from a message (with HITL prompts)
dart run bin/cogo_cli_flutter.dart \
  chat-loop --message "Fix crash in auth flow; add tests" --hitl \
  --max-steps 5 --timeout-seconds 30 --log-dir .cogo/session \
  --include-glob "src/" --exclude-glob "dist/" \
  --out-actions .cogo/actions.json --out-summary .cogo/loop-summary.json

# Resume a previous loop by trace id
dart run bin/cogo_cli_flutter.dart \
  chat-loop --resume $(cat .cogo/session/trace_id.txt) --timeout-seconds 20
```

Key behaviors and options:
- Human-in-the-loop: `--hitl` prompts before executing local CLI actions or applying edits.
- Auto mode: `--auto` continues to follow up automatically up to `--max-steps`.
- Step retries: `--step-retries N`, `--step-retry-backoff-ms M` retry when a step times out or fails.
- Follow-up requests (chaining):
  - `--followup-body-file request.json` to supply a JSON body for the follow-up call
  - `--followup-message "continue with tests"` to set the `text` of the follow-up call
  - Merge rule when both provided: file JSON is the base, and `text` is overridden by `--followup-message`.
  - Selectors (`agent-id`, `task_type`, `intent`, `lang`) automatically propagate across chained calls.
- Include/Exclude filters: `--include-glob`, `--exclude-glob` filter apply-edits targets by path substring match.
- Output artifacts:
  - `--out-actions` writes dispatcher summaries, including per-action `exit_code`, `log_files[]`, and apply-edits per-file `applied|skipped|error`.
  - `--out-summary` writes a compact loop summary:
    ```json
    {
      "trace_id": "...",
      "steps": [
        { "step": 1, "status": "ready|timeout_or_failed", "attempts": 1, "duration_ms": 1234, "actions_count": 2 }
      ],
      "ended_reason": "completed|max_steps_reached|timeout_or_failed|no_followup_trace",
      "log_dir": ".cogo/session",
      "trace_file": ".cogo/session/trace_id.txt"
    }
    ```
- Dispatcher safety & defaults:
  - Uses `.cogo/runner.config.json` allowlist/denylist. Non-allowed commands are skipped; denylisted commands are blocked.
  - Global defaults: `default_cli_retries`, `default_cli_retry_backoff_ms`, `default_cli_timeout_seconds`, `default_cli_on_fail`.
  - Web vs Native: when `runner_type=web`, `cli` and `apply_edits` are skipped (logged with reason).
- Apply-edits preview & safety:
  - `--preview` shows a unified diff (colorize with `--color`); `--preview-max-lines N` limits per-file preview.
  - `--hitl-all` allows a single approval for all edits.
  - Backups: `--backup-dir <dir>` or `--backup-default` to save previous file versions under `.cogo/backups`.
  - Skips: `--skip-large-bytes N` to skip large edits; `--skip-binary` to skip likely-binary paths.

### Compat examples
```bash
# Generate from prompt
dart run bin/cogo_cli_flutter.dart \
  --project-id "$COGO_PROJECT_ID" \
  compat-generate

# Variables derive (optional: --page-id 1)
dart run bin/cogo_cli_flutter.dart \
  --project-id "$COGO_PROJECT_ID" --page-id 1 \
  compat-variables-derive

# Symbols map (optional: --page-id 1)
dart run bin/cogo_cli_flutter.dart \
  --project-id "$COGO_PROJECT_ID" --page-id 1 \
  compat-symbols-map

# BDD generate/refine (optional: --page-id 1)
dart run bin/cogo_cli_flutter.dart \
  --project-id "$COGO_PROJECT_ID" --page-id 1 \
  compat-bdd-generate
dart run bin/cogo_cli_flutter.dart \
  --project-id "$COGO_PROJECT_ID" --page-id 1 \
  compat-bdd-refine

# ActionFlow refine (optional: --page-id 1)
dart run bin/cogo_cli_flutter.dart \
  --project-id "$COGO_PROJECT_ID" --page-id 1 \
  compat-actionflow-refine
```

### JSON ops examples
```bash
# set
dart run bin/cogo_cli_flutter.dart \
  json-set --file ui.json --pointer /meta/title --value '"Home"' --backup-dir .bak

# merge
dart run bin/cogo_cli_flutter.dart \
  json-merge --file ui.json --pointer /meta --value '{"version":"1.1"}' --backup-dir .bak

# remove
dart run bin/cogo_cli_flutter.dart \
  json-remove --file ui.json --pointer /meta/title --backup-dir .bak
```


### Runner Config

Create a `.cogo/runner.config.json` to control dispatcher behavior. `schemaVersion` is recommended.

Example:

```json
{
  "schemaVersion": "1",
  "allowlist": ["npm", "pnpm", "yarn", "flutter", "dart"],
  "denylist": ["rm", "sudo", "curl", "wget"],
  "env_allowlist": ["^(SUPABASE|COGO)_"],
  "env_denylist": ["SECRET", "KEY$"],
  "auto_cli_allowlist": ["json-set", "json-merge", "json-remove"],
  "default_cli_retries": 1,
  "default_cli_retry_backoff_ms": 500,
  "default_cli_timeout_seconds": 30,
  "default_cli_on_fail": "stop",
  "runner_type": "native"
}
```

### New Options
- chat-stream: `--retry-backoff-ms`
- trace logs: `--show-progress`
- artifacts-upload-batch: `--concurrency`
- session-summary: `--out-actions`, `--out-summary`

### Apply/Restore
```
cogo_cli_flutter apply-edits --trace-id $TID --skip-large-bytes 200000 --skip-binary

# Restore latest backup of a file
cogo_cli_flutter apply-restore --file src/app/config.json --latest
# Or list backups
cogo_cli_flutter apply-restore --file src/app/config.json --list
```

### Hybrid Loop (Flutter + CLI loop delegation)
- Goal: Minimize user involvement in-app, but delegate complex/batch mappings to the CLI loop.
- Flow:
  1) Flutter collects user intent and calls `/chat-gateway`.
  2) Flutter polls `/trace-status`, inspects `next_actions`.
  3) If a specific mapping (e.g., JSON→validate→diff) is detected, Flutter delegates to `cogo_cli_flutter chat-loop --resume <trace_id> --auto` with `--out-actions/--out-summary`.
  4) Otherwise, Flutter executes actions locally via `dispatchNextActions(...)` (HITL and allowlist rules apply).

Run the example (no DB):
```
# Pure Flutter loop with local dispatcher (small edits auto-apply, diff via CLI)
dart run packages/cogo-cli-flutter/examples/flutter_batch_json_validate_diff.dart

# Hybrid: delegate specific mappings to CLI chat-loop
dart run packages/cogo-cli-flutter/examples/flutter_hybrid_loop.dart
```
Files:
- `examples/flutter_batch_json_validate_diff.dart`: apply JSON → validate (Dart) → diff via CLI.
- `examples/flutter_hybrid_loop.dart`: Flutter loop inspects next_actions and calls CLI chat-loop for batch mappings; else runs dispatcher directly.

## Chat Protocol Mapping (Zero-complexity integration)

This CLI and the provided Flutter examples are designed to match the chatting protocol so app code can remain simple mapping code, not custom business logic.

- Request fields mapping (defaults):
  - `projectId`: forwarded as-is
  - `agentId`, `task_type`, `intent`, `lang`: forwarded when provided
  - `--message` option is mapped to JSON `text`
  - `--body-file`: send raw JSON body as-is (takes precedence over `--message`)
- Endpoints:
  - Non-SSE: `POST /chat-gateway`
  - SSE: `POST /chat` (used by `chat-stream`)
  - Trace polling: `GET /trace-status?trace_id=...`
- Loop contract:
  - App sends a request → polls trace → reads `next_actions[]` → runs dispatcher (HITL/allowlist/runners)
  - No complex per-app logic required. The dispatcher handles allow/deny, retries, timeouts, env filtering, logs.

Minimal Flutter mapping (pseudo-Dart):
```dart
final http = EdgeHttp(EdgeHttp.buildBase(), SUPABASE_ANON_KEY);
// 1) send
final body = {'projectId': pid, 'text': userText, if (agentId!=null) 'agentId': agentId};
final r = await http.post('/chat-gateway', jsonEncode(body));
final traceId = _pickTraceId(_json(r.body));
// 2) poll until ready
while(!ready) { final s = await http.get('/trace-status?trace_id='+traceId); /* break when ready */ }
// 3) dispatch next_actions
await dispatchNextActions(nextActions, hitl:true, http:http, traceId:traceId, logDir:'.cogo/session');
```

Reference examples:
- `examples/flutter_chat_app_reference.dart` (Desktop/Native UX)
- `examples/flutter_web_chat_reference.dart` (Web: no local process/file; preview+download; server delegation hook; multilingual)
- `examples/flutter_hybrid_loop.dart` (Hybrid: delegate specific bundles to CLI loop)


