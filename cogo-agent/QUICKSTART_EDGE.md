## Quickstart – Edge Functions & Examples

### 1) Prerequisites
- Supabase project: note `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`.
- macOS zsh: install `jq`, `curl`.

### 2) Environment
```bash
export SUPABASE_URL="https://<ref>.supabase.co"
export SUPABASE_ANON_KEY="<anon>"
export SUPABASE_SERVICE_ROLE_KEY="<service>"
export COGO_PROJECT_ID="<uuid>"
```

### 3) Smoke tests
```bash
bash scripts/quality/smoke_edge.sh "$COGO_PROJECT_ID"
bash scripts/quality/smoke_chat.sh "$COGO_PROJECT_ID"
```

### 4) Generate & Persist Artifacts
```bash
UI='/tmp/ui.json'
cat > "$UI" <<'JSON'
{"screen":"simple","elements":[
 {"id":"input1","type":"textField","binding":"uiState.inputText"},
 {"id":"btnSend","type":"button","onTap":{"eventType":"onTap","symbol":"chat.send","params":{"text":"#_uiState.inputText"}}}
]}
JSON

jq -nc --arg project "$COGO_PROJECT_ID" --arg base "docs/cogo-agent/examples/simple-screen" --slurpfile ui "$UI" \
  '{projectId:$project,base_path:$base,ui:$ui[0],persist:true}' \
| curl -sS -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" -H "Content-Type: application/json" \
  --data-binary @- "$SUPABASE_URL/functions/v1/json-generate" | jq .
```

### 5) Validate
```bash
# Fetch persisted actionFlow and validate
body=$(jq -nc --arg project "$COGO_PROJECT_ID" --arg path "docs/cogo-agent/examples/simple-screen/actionFlow.v1.expanded.json" '{project_id:$project,path:$path}')
get=$(echo "$body" | curl -sS -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" -H "Content-Type: application/json" --data-binary @- "$SUPABASE_URL/functions/v1/json-get")
json=$(echo "$get" | jq -c '.json')
req=$(jq -nc --arg schema "action.flow@1" --argjson data "$json" '{schema_id:$schema,data:$data}')
echo "$req" | curl -sS -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" -H "Content-Type: application/json" --data-binary @- "$SUPABASE_URL/functions/v1/json-validate" | jq .
```

### 6) Flutter Web Chat
- See `examples/flutter_web_chat/README.md` for running the web chat.

### 7) CLI Wrapper (optional)
```bash
bash scripts/quality/json_cli.sh list docs/cogo-agent/examples/simple-screen/
```
