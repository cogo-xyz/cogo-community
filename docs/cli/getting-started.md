# COGO CLI (Flutter) - Getting Started

This guide helps you install and run the Flutter-based COGO CLI for common tasks like JSON CRUD via Supabase Edge, artifacts ingest/download, and schema validation.

## 1) Prerequisites
- Dart/Flutter SDK installed (CLI uses `dart run`)
- Supabase project (for remote JSON ops)
- Environment variables:
```bash
export SUPABASE_PROJECT_ID=xxxxx
export SUPABASE_ANON_KEY=xxxxx
export COGO_PROJECT_ID=00000000-0000-4000-8000-000000000000
```

## 2) Install dependencies
```bash
cd packages/cogo-cli-flutter
flutter pub get
```

## 3) First commands
```bash
# Show environment summary
dart run bin/cogo_cli_flutter.dart info --out-json .info.json

# Presign and ingest a file (Edge artifacts)
dart run bin/cogo_cli_flutter.dart attachments-presign --print-key-only > .storage_key.txt
KEY=$(cat .storage_key.txt)
dart run bin/cogo_cli_flutter.dart attachments-ingest --wait --storage-key "$KEY" --timeout-seconds 30 --out-json .ingest.json
```

## 4) Remote JSON CRUD (Supabase Edge)
```bash
# set
dart run bin/cogo_cli_flutter.dart \
  --out-json .result.json \
  json-set --remote --project-id "$COGO_PROJECT_ID" --doc-path "configs/app.json" \
  --value '{"name":"app","ver":1}' --retry 2 --retry-backoff-ms 800 --timeout-seconds 20

# merge
dart run bin/cogo_cli_flutter.dart \
  json-merge --remote --project-id "$COGO_PROJECT_ID" --doc-path "configs/app.json" \
  --merge deep --value '{"flags":{"beta":true}}'

# get
dart run bin/cogo_cli_flutter.dart \
  json-get --remote --project-id "$COGO_PROJECT_ID" --doc-path "configs/app.json" --out-json .get.json

# list
dart run bin/cogo_cli_flutter.dart \
  json-list --remote --project-id "$COGO_PROJECT_ID" --prefix "configs/" --limit 20 --offset 0 --out-json .list.json
```

## 5) Local JSON edits
```bash
# set
dart run bin/cogo_cli_flutter.dart json-set --file ui.json --pointer /meta/title --value '"Home"' --backup-dir .bak
# merge
dart run bin/cogo_cli_flutter.dart json-merge --file ui.json --pointer /meta --value '{"version":"1.1"}' --backup-dir .bak
# remove
dart run bin/cogo_cli_flutter.dart json-remove --file ui.json --pointer /meta/title --backup-dir .bak
```

## 6) Validate JSON against SSOT (creatego-packages)
```bash
# action.flow v1
dart run bin/cogo_cli_flutter.dart \
  json-validate action.flow@1 external/cogo-client/creatego-packages/examples/json/action.flow.v1.json --out-json .validate.flow.json

# data.api_definition v1
dart run bin/cogo_cli_flutter.dart \
  json-validate data.api_definition@1 external/cogo-client/creatego-packages/examples/json/data.api_definition.v1.json --out-json .validate.api.json
```

## 7) Tips
- Use `--out-json FILE` to capture results programmatically.
- For rate limits (429), increase `--retry` and `--retry-backoff-ms`.
- For concurrency conflicts, use `--expected-version` in `json-set/merge`.
- For web environments, prefer server delegation for heavy tasks.

