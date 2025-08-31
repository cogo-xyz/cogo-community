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
- Realtime: ingest emits events to bus_events and broadcasts on trace:{traceId}
- Artifacts: result returns { bucket, key, signedUrl } where key is bucket-relative (no leading bucket name)
- Components: 환경에서 LEGACY_COMPONENTS_ENABLE=true이고 COMP_COL_PAGE_ID가 요구되면 유효한 --page-id를 제공해야 합니다. 없으면 서버에서 "page_id_required" 또는 FK 오류가 반환될 수 있으나, compat 결과/아티팩트 생성에는 영향 없습니다.

### Compat examples
```bash
# Generate from prompt
dart run bin/cogo_cli_flutter.dart \
  --project-id "$COGO_PROJECT_ID" \
  compat-generate

# Variables derive (옵션: --page-id 1)
dart run bin/cogo_cli_flutter.dart \
  --project-id "$COGO_PROJECT_ID" --page-id 1 \
  compat-variables-derive

# Symbols map (옵션: --page-id 1)
dart run bin/cogo_cli_flutter.dart \
  --project-id "$COGO_PROJECT_ID" --page-id 1 \
  compat-symbols-map

# BDD generate/refine (옵션: --page-id 1)
dart run bin/cogo_cli_flutter.dart \
  --project-id "$COGO_PROJECT_ID" --page-id 1 \
  compat-bdd-generate
dart run bin/cogo_cli_flutter.dart \
  --project-id "$COGO_PROJECT_ID" --page-id 1 \
  compat-bdd-refine

# ActionFlow refine (옵션: --page-id 1)
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


