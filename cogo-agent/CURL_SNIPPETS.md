## Curl Snippets – Edge Functions

### Env
```bash
export SUPABASE_URL="https://<ref>.supabase.co"
export KEY="<SERVICE_OR_ANON>"
export P="<COGO_PROJECT_ID>"
```

### Health
```bash
curl -sS "$SUPABASE_URL/functions/v1/json-generate/healthz" | jq .
```

### json-set
```bash
jq -nc --arg project "$P" --arg path "examples/af.json" --argjson val '{"a":1}' '{project_id:$project,path:$path,value:$val}' \
| curl -sS -H "Authorization: Bearer $KEY" -H "apikey: $KEY" -H "Content-Type: application/json" \
  --data-binary @- "$SUPABASE_URL/functions/v1/json-set" | jq .
```

### json-get
```bash
jq -nc --arg project "$P" --arg path "examples/af.json" '{project_id:$project,path:$path}' \
| curl -sS -H "Authorization: Bearer $KEY" -H "apikey: $KEY" -H "Content-Type: application/json" \
  --data-binary @- "$SUPABASE_URL/functions/v1/json-get" | jq .
```

### json-merge (deep)
```bash
jq -nc --arg project "$P" --arg path "examples/af.json" --argjson patch '{"b":2}' '{project_id:$project,path:$path,patch:$patch,merge:"deep"}' \
| curl -sS -H "Authorization: Bearer $KEY" -H "apikey: $KEY" -H "Content-Type: application/json" \
  --data-binary @- "$SUPABASE_URL/functions/v1/json-merge" | jq .
```

### json-generate (persist)
```bash
UI='/tmp/ui.json'; cat > "$UI" <<'JSON'
{"screen":"simple","elements":[
 {"id":"input1","type":"textField","binding":"uiState.inputText"},
 {"id":"btnSend","type":"button","onTap":{"eventType":"onTap","symbol":"chat.send","params":{"text":"#_uiState.inputText"}}}
]}
JSON
jq -nc --arg project "$P" --arg base "docs/cogo-agent/examples/simple-screen" --slurpfile ui "$UI" '{projectId:$project,base_path:$base,ui:$ui[0],persist:true}' \
| curl -sS -H "Authorization: Bearer $KEY" -H "apikey: $KEY" -H "Content-Type: application/json" \
  --data-binary @- "$SUPABASE_URL/functions/v1/json-generate" | jq .
```

### json-validate (action.flow@1)
```bash
body=$(jq -nc --arg project "$P" --arg path "docs/cogo-agent/examples/simple-screen/actionFlow.v1.expanded.json" '{project_id:$project,path:$path}')
get=$(echo "$body" | curl -sS -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" --data-binary @- "$SUPABASE_URL/functions/v1/json-get")
json=$(echo "$get" | jq -c '.json')
req=$(jq -nc --arg schema "action.flow@1" --argjson data "$json" '{schema_id:$schema,data:$data}')
echo "$req" | curl -sS -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" --data-binary @- "$SUPABASE_URL/functions/v1/json-validate" | jq .
```

### chat-gateway (handoff)
```bash
jq -nc --arg project "$P" --arg text "hello" '{payload:{projectId:$project,text:$text}}' \
| curl -sS -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  --data-binary @- "$SUPABASE_URL/functions/v1/chat-gateway" | jq .
```
