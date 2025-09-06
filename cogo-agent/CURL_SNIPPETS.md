## Curl Snippets – Edge Functions

### Env
```bash
export SUPABASE_URL="https://<ref>.supabase.co"
export KEY="<SERVICE_OR_ANON>"
export P="<COGO_PROJECT_ID>"
# Optional: emit ETag in JSON bodies for debugging
# export DEBUG_ETAG_IN_BODY=true
```

### Health
```bash
curl -sS "$SUPABASE_URL/functions/v1/json-generate/healthz" | jq .
```

### RAG search
```bash
curl -sS -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  --data-binary '{"q":"hello","limit":3}' "$SUPABASE_URL/functions/v1/rag" | jq .
```

RAG env (dev):
- RAG_ENABLED=true|false
- RAG_MODE=hybrid|recent
- EMBED_DIM=1024

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

GET/HEAD with ETag:
```bash
# HEAD to obtain ETag
curl -sS -I -H "Authorization: Bearer $KEY" \
  "$SUPABASE_URL/functions/v1/json-get?project_id=$P&path=examples/af.json" | awk '/^ETag:/ {print $2}'

# GET with If-None-Match → 304 when unchanged
curl -sS -o /dev/null -w "%{http_code}\n" -H "Authorization: Bearer $KEY" -H "If-None-Match: $ETAG" \
  "$SUPABASE_URL/functions/v1/json-get?project_id=$P&path=examples/af.json"
```

### Conditional GET with ETag (If-None-Match → 304)
```bash
ETAG=$(curl -sS -I -H "Authorization: Bearer $KEY" \
  "$SUPABASE_URL/functions/v1/json-get?project_id=$P&path=examples/af.json" \
  | awk '/^ETag:/ {print $2}' | tr -d '\r\n')

jq -nc --arg project "$P" --arg path "examples/af.json" '{project_id:$project,path:$path}' \
| curl -sS -o /dev/null -w "%{http_code}\n" -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" -H "If-None-Match: $ETAG" \
  --data-binary @- "$SUPABASE_URL/functions/v1/json-get"
```

### artifacts-list ETag (HEAD + POST 304)
```bash
ETAG=$(curl -sS -I -H "Authorization: Bearer $KEY" \
  "$SUPABASE_URL/functions/v1/artifacts-list?project_id=$P&prefix=docs/cogo-agent/examples/simple-screen/" \
  | awk '/^ETag:/ {print $2}' | tr -d '\r\n')

jq -nc --arg project "$P" --arg prefix "docs/cogo-agent/examples/simple-screen/" '{project_id:$project,prefix:$prefix,limit:2,offset:0}' \
| curl -sS -o /dev/null -w "%{http_code}\n" -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" -H "If-None-Match: $ETAG" --data-binary @- \
  "$SUPABASE_URL/functions/v1/artifacts-list"
```

### json-list ETag (HEAD + POST 304)
```bash
ETAG=$(curl -sS -I -H "Authorization: Bearer $KEY" \
  "$SUPABASE_URL/functions/v1/json-list?project_id=$P&prefix=examples/" \
  | awk '/^ETag:/ {print $2}' | tr -d '\r\n')

jq -nc --arg project "$P" --arg prefix "examples/" '{project_id:$project,prefix:$prefix,limit:5,offset:0}' \
| curl -sS -o /dev/null -w "%{http_code}\n" -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" -H "If-None-Match: $ETAG" --data-binary @- \
  "$SUPABASE_URL/functions/v1/json-list"
```

### trace-status ETag (HEAD + GET 304)
```bash
TRACE_ID="<trace_id>"
ETAG=$(curl -sS -I -H "Authorization: Bearer $KEY" \
  "$SUPABASE_URL/functions/v1/trace-status?trace_id=$TRACE_ID" \
  | awk '/^ETag:/ {print $2}' | tr -d '\r\n')

curl -sS -o /dev/null -w "%{http_code}\n" -H "Authorization: Bearer $KEY" -H "If-None-Match: $ETAG" \
  "$SUPABASE_URL/functions/v1/trace-status?trace_id=$TRACE_ID"
```

### json-merge (deep)
```bash
jq -nc --arg project "$P" --arg path "examples/af.json" --argjson patch '{"b":2}' '{project_id:$project,path:$path,patch:$patch,merge:"deep"}' \
| curl -sS -H "Authorization: Bearer $KEY" -H "apikey: $KEY" -H "Content-Type: application/json" \
  --data-binary @- "$SUPABASE_URL/functions/v1/json-merge" | jq .
```

### json-merge (shallow)
```bash
jq -nc --arg project "$P" --arg path "examples/af.json" --argjson patch '{"b":2}' '{project_id:$project,path:$path,patch:$patch,merge:"shallow"}' \
| curl -sS -H "Authorization: Bearer $KEY" -H "apikey: $KEY" -H "Content-Type: application/json" \
  --data-binary @- "$SUPABASE_URL/functions/v1/json-merge" | jq .
```

### json-remove (multi pointers)
```bash
jq -nc --arg project "$P" --arg path "examples/af.json" '{project_id:$project,path:$path,pointers:["/a","/b"]}' \
| curl -sS -H "Authorization: Bearer $KEY" -H "apikey: $KEY" -H "Content-Type: application/json" \
  --data-binary @- "$SUPABASE_URL/functions/v1/json-remove" | jq .
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

### json-validate (by path)
```bash
jq -nc --arg schema "action.flow@1" --arg project "$P" --arg path "docs/cogo-agent/examples/simple-screen/actionFlow.v1.expanded.json" '{schema_id:$schema,project_id:$project,path:$path}' \
| curl -sS -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" --data-binary @- "$SUPABASE_URL/functions/v1/json-validate" | jq .
```

### artifacts-list (pagination)
```bash
OFFSET=0; LIMIT=3
resp=$(jq -n --arg project "$P" --arg prefix "docs/cogo-agent/examples/simple-screen/" \
  --argjson limit "$LIMIT" --argjson offset "$OFFSET" '{project_id:$project,prefix:$prefix,limit:$limit,offset:$offset}' \
| curl -sS -H "Authorization: Bearer '$SUPABASE_SERVICE_ROLE_KEY'" -H "Content-Type: application/json" --data-binary @- "$SUPABASE_URL/functions/v1/artifacts-list")
echo "$resp" | jq '{ok, count, limit, offset, next_offset, items: (.items|map(.path))}'
``` 

### Conditional update (If-Match)
```bash
VER=$(jq -nc --arg project "$P" --arg path "examples/af.json" '{project_id:$project,path:$path}' \
| curl -sS -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" --data-binary @- "$SUPABASE_URL/functions/v1/json-get" \
| jq -r '.version')

jq -nc --arg project "$P" --arg path "examples/af.json" --argjson val '{"a":1,"b":2}' '{project_id:$project,path:$path,value:$val}' \
| curl -sS -H "Authorization: Bearer $KEY" -H "apikey: $KEY" -H "Content-Type: application/json" -H "If-Match: W/\"v'$VER'\"" \
  --data-binary @- "$SUPABASE_URL/functions/v1/json-set" | jq .
```

### chat-gateway (handoff)
```bash
jq -nc --arg project "$P" --arg text "hello" '{payload:{projectId:$project,text:$text}}' \
| curl -sS -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  --data-binary @- "$SUPABASE_URL/functions/v1/chat-gateway" | jq .
```

### kg-upsert-schedule (dev trigger)
```bash
# GET — quick check
curl -sS -H "Authorization: Bearer $KEY" "$SUPABASE_URL/functions/v1/kg-upsert-schedule" | jq .

# POST — publish upsert requests for recently updated docs (by prefix/window)
jq -n --arg project "$P" --arg prefix "docs/cogo-agent/examples/" '{project_id:$project,prefix:$prefix,window_minutes:5,limit:10}' \
| curl -sS -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" --data-binary @- \
  "$SUPABASE_URL/functions/v1/kg-upsert-schedule" | jq .

# POST — by explicit paths
jq -n --arg project "$P" '{project_id:$project,paths:["docs/cogo-agent/examples/simple-screen/actionFlow.v1.json"]}' \
| curl -sS -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" --data-binary @- \
  "$SUPABASE_URL/functions/v1/kg-upsert-schedule" | jq .
```

### figma-compat (UUI) – presign upload
```bash
jq -nc --arg project "$P" --arg name "ui.json" '{projectId:$project,fileName:$name}' \
| curl -sS -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  --data-binary @- "$SUPABASE_URL/functions/v1/figma-compat/uui/presign" | jq .
```

### figma-compat (UUI) – ingest (after upload)
```bash
jq -nc --arg project "$P" --arg key "uploads/$P/ui.json" '{projectId:$project,storage_key:$key}' \
| curl -sS -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  --data-binary @- "$SUPABASE_URL/functions/v1/figma-compat/uui/ingest" | jq .
```

### figma-compat (UUI) – ingest result
```bash
TRACE="<trace_id>"
curl -sS -H "Authorization: Bearer $KEY" \
  "$SUPABASE_URL/functions/v1/figma-compat/uui/ingest/result?traceId=$TRACE" | jq .
```

### orchestrator quickcheck
```bash
# enqueue
jq -nc '{tenant:"default",intent:"chat",idempotencyKey:"test-1",payload:{text:"hi"}}' \
| curl -sS -H "Authorization: Bearer '$SUPABASE_SERVICE_ROLE_KEY'" -H "Content-Type: application/json" \
  --data-binary @- "$SUPABASE_URL/functions/v1/orchestrator-chat" | jq .

# tick (process one)
jq -n '{trace_id:null}' \
| curl -sS -H "Authorization: Bearer '$SUPABASE_SERVICE_ROLE_KEY'" -H "Content-Type: application/json" \
  --data-binary @- "$SUPABASE_URL/functions/v1/orchestrator-tick" | jq .

# trace-status
curl -sS -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  "$SUPABASE_URL/functions/v1/trace-status?trace_id=<trace_id>" | jq .
```
