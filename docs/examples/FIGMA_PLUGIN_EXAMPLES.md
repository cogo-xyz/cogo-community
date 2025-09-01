## Figma Plugin — Example Calls

### Prerequisites
- Env variables:
  - `SUPABASE_EDGE` or `SUPABASE_PROJECT_ID`
  - `SUPABASE_ANON_KEY`

### Verify with Node Script
Run the repository helper script:

```bash
node tools/figma-verify.mjs
```

Expected output:

```
[env] { base: 'https://<ref>.functions.supabase.co/functions/v1', anonSet: true, projectId: '<uuid>' }
[symbols.map] 200 true <trace_id>
[uui.generate] 200 true <trace_id>
```

### symbols.map (curl)
```bash
PJ=$(uuidgen)
BASE=${SUPABASE_EDGE:-https://${SUPABASE_PROJECT_ID}.functions.supabase.co}/functions/v1
curl -sS -X POST "$BASE/figma-compat/uui/symbols/map" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  --data '{"projectId":"'$PJ'","page_id":1,"page_name":"Page","cogo_ui_json":[{"type":"container"}],"intent":{"language":"en","keywords":["symbols.identify"]}}'
```

### generate (curl)
```bash
PJ=${PJ:-$(uuidgen)}
BASE=${SUPABASE_EDGE:-https://${SUPABASE_PROJECT_ID}.functions.supabase.co}/functions/v1
curl -sS -X POST "$BASE/figma-compat/uui/generate" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  --data '{"projectId":"'$PJ'","prompt":"Login page","intent":{"language":"en","keywords":["ui.generate"]}}'
```

### Large JSON — Ingest Flow
```bash
# 1) Presign (if using storage upload) — endpoint may vary
# 2) Upload via signed URL
# 3) Enqueue ingest
BASE=${SUPABASE_EDGE:-https://${SUPABASE_PROJECT_ID}.functions.supabase.co}/functions/v1
TRACE=$(curl -sS -X POST "$BASE/figma-compat/uui/ingest" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  --data '{"projectId":"'$PJ'","signedUrl":"https://storage.example/signed.json"}' | jq -r '.trace_id')

curl -sS "$BASE/figma-compat/uui/ingest/result?trace_id=$TRACE"
```

### Figma Plugin Examples — Prompts & JSON

#### 1) Deterministic Generate
- Prompt: "login page with two text inputs and a primary button"
- Action: Generate (deterministic)
- Verifies: `POST /figma-compat/uui/generate`

cURL:
```bash
curl -s -X POST "$EDGE/figma-compat/uui/generate" \
  -H "content-type: application/json" -H "Authorization: Bearer $ANON" -H "apikey: $ANON" \
  -d '{"projectId":"'$PROJECT_ID'","prompt":"login page with two text inputs and a primary button"}' | jq .
```

#### 2) LLM Generate
- Prompt: "dashboard hero with title, cta button, and logo image"
- Action: Generate via LLM
- Verifies: `POST /figma-compat/uui/generate/llm`

cURL:
```bash
curl -s -X POST "$EDGE/figma-compat/uui/generate/llm" \
  -H "content-type: application/json" -H "Authorization: Bearer $ANON" -H "apikey: $ANON" \
  -d '{"projectId":"'$PROJECT_ID'","prompt":"dashboard hero with title, cta button, and logo image"}' | jq .
```

#### 3) Seeded with COGO UI JSON
- Seed COGO UI JSON:
```json
[
  { "type": "container", "id": "root", "children": [
    { "type": "text", "id": "title_1", "props": { "text": "Welcome" } }
  ]}
]
```
- Action: Generate (either deterministic or LLM) with `cogo_ui_json` field

cURL:
```bash
curl -s -X POST "$EDGE/figma-compat/uui/generate" \
  -H "content-type: application/json" -H "Authorization: Bearer $ANON" -H "apikey: $ANON" \
  -d '{"projectId":"'$PROJECT_ID'","prompt":"add a primary button","cogo_ui_json":[{"type":"container","id":"root","children":[{"type":"text","id":"title_1","props":{"text":"Welcome"}}]}]}' | jq .
```

#### 4) Convert Selection → UUI & Cogo
- Steps: Select nodes in Figma, run the plugin, click Convert
- API: `POST /figma-compat/uui/symbols/map`

#### 5) Ingest Flow (Large JSON)
- Prepare a file or use selection; plugin handles presign → upload → ingest → poll result
- Result provides signed URL (if configured) and trace id

#### 6) Agent ID Header (multi-instance)
- Optional header: `x-agent-id: cogo0`
- Plugin input includes Agent ID; propagated to server and bus events
