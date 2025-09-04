## cogo-cli-flutter

Command-line utilities for COGO Edge Functions, aligned with cogo-chat-sdk-flutter.

### Prerequisites
- SUPABASE_PROJECT_ID, SUPABASE_ANON_KEY (required)
- Optionally SUPABASE_EDGE (else computed from project id)
- COGO_PROJECT_ID (UUID)

### Commands
- info
- trace-status [--trace-id ID | ID]
- attachments-presign [--print-key-only]
- attachments-presign-key
- attachments-ingest [--storage-key KEY] [--wait] [--timeout-seconds N]
- attachments-result [--trace-id ID | ID] [--timeout-seconds N]
- attachments-download [--trace-id ID | --signed-url URL] [--out-file FILE]
- json-set [--remote --project-id UUID --doc-path PATH --idempotency-key K --expected-version N --retry M --retry-backoff-ms B --timeout-seconds S] \
           [--file p.json --pointer /a/b] --value '{"x":1}' [--backup-dir .bak]
- json-merge [--remote --project-id UUID --doc-path PATH --merge deep|shallow --expected-version N --retry M --retry-backoff-ms B --timeout-seconds S] \
             [--file p.json --pointer /a] --value '{"y":2}' [--backup-dir .bak]
- json-remove [--remote --project-id UUID --doc-path PATH --pointers '/a/b,/a/c' --retry M --retry-backoff-ms B --timeout-seconds S] \
              [--file p.json --pointer /a/b] [--backup-dir .bak]
- json-get --remote --project-id UUID --doc-path PATH [--timeout-seconds S]
- json-list --remote --project-id UUID [--prefix PRE] [--limit N] [--offset O] [--timeout-seconds S]
- json-validate [--creatego-packages-dir DIR] <schemaId>@<version> <json_file>

Global options:
- --out-json FILE writes the full command result JSON to file
- --project-id UUID
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

### JSON (Local) examples
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

### JSON (Remote via Supabase Edge) examples
```bash
export SUPABASE_PROJECT_ID=xxxxx
export SUPABASE_ANON_KEY=xxxxx
export COGO_PROJECT_ID=00000000-0000-4000-8000-000000000000

# set (remote)
dart run bin/cogo_cli_flutter.dart \
  --out-json .result.json \
  json-set --remote --project-id "$COGO_PROJECT_ID" --doc-path "configs/app.json" \
  --value '{"name":"app","ver":1}' --idempotency-key test-1 --retry 2 --retry-backoff-ms 800 --timeout-seconds 20

# merge (remote, deep)
dart run bin/cogo_cli_flutter.dart \
  json-merge --remote --project-id "$COGO_PROJECT_ID" --doc-path "configs/app.json" \
  --merge deep --value '{"flags":{"beta":true}}'

# remove (remote)
dart run bin/cogo_cli_flutter.dart \
  json-remove --remote --project-id "$COGO_PROJECT_ID" --doc-path "configs/app.json" \
  --pointers '/flags/beta'

# get (remote)
dart run bin/cogo_cli_flutter.dart \
  json-get --remote --project-id "$COGO_PROJECT_ID" --doc-path "configs/app.json" --out-json .get.json

# list (remote)
dart run bin/cogo_cli_flutter.dart \
  json-list --remote --project-id "$COGO_PROJECT_ID" --prefix "configs/" --limit 20 --offset 0 --out-json .list.json
```

### Validate JSON against SSOT schemas
`creatego-packages` includes a lightweight schema registry and validator.
```bash
# action.flow v1
dart run bin/cogo_cli_flutter.dart \
  json-validate action.flow@1 external/cogo-client/creatego-packages/examples/json/action.flow.v1.json --out-json .validate.flow.json

# data.api_definition v1
dart run bin/cogo_cli_flutter.dart \
  json-validate data.api_definition@1 external/cogo-client/creatego-packages/examples/json/data.api_definition.v1.json --out-json .validate.api.json
```

### info command (environment summary)
```bash
dart run bin/cogo_cli_flutter.dart info --out-json .info.json
# Prints { env: { project_id, edge_base, supabase_anon_key_set, defaults }, server: {...} }
```
