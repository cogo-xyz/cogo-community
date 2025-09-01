### ActionFlow Compatibility Runbook

Endpoints (under `actionflow-compat` function)
- POST `/compat/actionflow/compile`
- POST `/compat/actionflow/validate`
- POST `/compat/actionflow/run` (SSE; bridges `bus_events` and triggers runner)

Security toggles (Env)
- `EDGE_VERIFY_JWT` (default: false)
- `EDGE_REQUIRE_HMAC` (default: false), `EDGE_HMAC_SECRET`, `EDGE_HMAC_SKEW_MS` (default: 300000)
- `EDGE_RATE_LIMIT_ENABLE` (default: false), `EDGE_RATE_LIMIT_WINDOW_MS` (default: 10000), `EDGE_RATE_LIMIT_MAX` (default: 50)

Runner behaviors
- Actions: `api_call` (resultPath/assign mapping, 3x retry/backoff), `setProperty`, `emit`, `navigate`
- Emits bus events: `aflow.step`, `aflow.emit`, `aflow.navigate`, `aflow.done` (payload includes `trace_id`)

Smokes/CI (from project root)
- Compatibility SSE bundle: `npm run -s smoke:aflow:bundle`
- IDE parity + bundle: `npm run -s smoke:ide:parity`
- Metrics (direct): `npm run -s smoke:aflow:metrics:direct`

Metrics (SQL)
- RPC: `public.aflow_metrics_snapshot()`
- View: `public.aflow_runs_recent`

Operational notes
- Dev: keep security toggles off; Prod: enable JWT/HMAC/RateLimit
- Idempotency: pass `idempotency-key` header when needed
- Trace propagation: client consumes SSE `aflow.start` and reads `trace_id` from data


