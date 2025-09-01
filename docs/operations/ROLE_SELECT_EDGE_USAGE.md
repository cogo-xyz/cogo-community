# Role-Select Edge Usage

Updated: 2025-08-23

## Health
```bash
curl -s "$SUPABASE_EDGE/role-select/healthz" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" -H "apikey: $SUPABASE_ANON_KEY"
```

## JSON (basic)
```bash
curl -s -X POST "$SUPABASE_EDGE/role-select" \
  -H "content-type: application/json" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" -H "apikey: $SUPABASE_ANON_KEY" \
  --data-binary '{"intent_text":"refactor and add tests for module"}'
```

### Response
```json
{ "ok": true, "trace_id": "...", "role_id": "cogo-code-generation-agent", "confidence": 0.8 }
```

## SSE (stream)
```bash
curl -sN -H "accept: text/event-stream" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" -H "apikey: $SUPABASE_ANON_KEY" \
  -X POST "$SUPABASE_EDGE/role-select?sse=1" \
  -d '{"intent_text":"create embeddings for docs"}'
```

### Events
- `meta` → start info
- `role.selected` → `{ role_id, confidence }`

## Client (Node)
```ts
import { EdgeRoleSelectClient } from '../../src/services/edge/EdgeRoleSelectClient';
const client = new EdgeRoleSelectClient();
const res = await client.select('refactor and add tests for module');
```
