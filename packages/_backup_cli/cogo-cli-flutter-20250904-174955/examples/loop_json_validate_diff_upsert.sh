#!/usr/bin/env bash
set -euo pipefail

# Prereqs:
#  - SUPABASE_PROJECT_ID, SUPABASE_ANON_KEY (and SERVICE_ROLE_KEY for upsert)
#  - jsonschema installed and allowlisted (or swap with your validator)

SESSION=".cogo/session"
mkdir -p "$SESSION"

echo "== Init runner config (if missing) =="
dart run packages/cogo-cli-flutter/bin/cogo_cli_flutter.dart init-config | cat

echo "== Ask agent to generate JSON, validate schema, show diff, then upsert =="
MSG="Generate data/model.json, validate with schema/model.schema.json, show diff, then upsert to DB"
dart run packages/cogo-cli-flutter/bin/cogo_cli_flutter.dart \
  chat-loop --message "$MSG" \
  --auto --max-steps 2 --timeout-seconds 30 \
  --log-dir "$SESSION" \
  --out-actions "$SESSION/actions.json" \
  --out-summary "$SESSION/loop-summary.json" | cat

echo "== Summaries =="
echo "- Actions: $SESSION/actions.json"
echo "- Summary: $SESSION/loop-summary.json"

