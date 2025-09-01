### ActionFlow Production Rollout

Pre-checks
- Ensure DB SQL applied: symbols/actionflows/actionflow_runs, bus_events, metrics RPC/view
- Verify `ci:aflow` passes in staging

Edge security (set in project env)
- `EDGE_VERIFY_JWT=true` (provide JWT validation upstream or gateway)
- `EDGE_REQUIRE_HMAC=true`, `EDGE_HMAC_SECRET=<secret>`, `EDGE_HMAC_SKEW_MS=300000`
- `EDGE_RATE_LIMIT_ENABLE=true`, `EDGE_RATE_LIMIT_WINDOW_MS=10000`, `EDGE_RATE_LIMIT_MAX=50`
- `REQUIRE_IDEMPOTENCY=true` (idempotency-key required)

Rollout steps
1) Deploy `actionflow-compat` with security toggles
2) Run `npm run -s ci:aflow` against production
3) Monitor metrics snapshot (`smoke:aflow:metrics:direct`) and logs

Weekly report (optional)
- Schedule: `npm run -s report:aflow:weekly` (set `ALERT_WEBHOOK`)

Rollback
- Toggle off HMAC/RateLimit if necessary; redeploy function
- Disable run enqueue via feature flag if incident escalates


