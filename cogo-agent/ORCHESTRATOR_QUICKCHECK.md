## Orchestrator Quickcheck

Use these steps to verify enqueue → tick → trace flow.

### 1) Enqueue via orchestrator-chat
```bash
jq -nc '{tenant:"default",intent:"chat",idempotencyKey:"test-1",payload:{text:"hi"}}' \
| curl -sS -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" -H "Content-Type: application/json" \
  --data-binary @- "$SUPABASE_URL/functions/v1/orchestrator-chat" | jq .
```

### 2) Process one via orchestrator-tick
```bash
jq -n '{trace_id:null}' \
| curl -sS -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" -H "Content-Type: application/json" \
  --data-binary @- "$SUPABASE_URL/functions/v1/orchestrator-tick" | jq .
```

### 3) Check trace-status
```bash
TRACE="<trace_id>"
curl -sS -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  "$SUPABASE_URL/functions/v1/trace-status?trace_id=$TRACE" | jq .
```

Notes
- Requires `SUPABASE_SERVICE_ROLE_KEY` in your environment.
- `trace-status` will show recent `bus_events` for the trace.

### Run Node worker (PM2)
```bash
cd workers
pm2 start ecosystem.config.cjs --only cogo-orchestrator-worker --env production
pm2 logs cogo-orchestrator-worker --lines 50
```

### KG worker (PM2) and smoke
```bash
# Start KG worker
cd workers
pm2 start ecosystem.config.cjs --only cogo-kg-worker --env production
pm2 logs cogo-kg-worker --lines 50

# Smoke KG upsert
export KG_NODE_RUNNING=1
bash scripts/quality/run_everything.sh | sed -n '/Smoke (KG upsert)/,/(^$|^== )/p'
```

### Env required
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `COGO_PROJECT_ID` (for metrics tagging)

