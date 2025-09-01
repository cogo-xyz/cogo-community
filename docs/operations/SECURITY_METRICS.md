## Metrics Server Security and Smokes

### Auth Toggle
- Env:
  - `METRICS_REQUIRE_AUTH=1` enables auth for all metrics APIs.
  - `METRICS_AUTH_TOKEN=<token>` required via `Authorization: <token>` or `x-api-key`.
- Smoke:
  - `npm run -s metrics:auth:smoke`
  - Expects 401 without header and 200 with header.

### CORS
- Env:
  - `METRICS_CORS_ORIGIN` default `http://localhost:3000`.
- Smoke:
  - `npm run -s metrics:cors:smoke` (non-blocking in gates)
  - Verifies ACAO for allowed origin; disallowed origin should not be reflected.

### Rate Limit
- Env:
  - `METRICS_RATE_MAX` requests per minute (window 60s).
- Smoke:
  - `npm run -s metrics:rate:smoke`
  - Starts metrics via pm2, fires burst requests and expects some 429 responses.

#### Recommended Defaults
- **Baseline**: `METRICS_RATE_MAX=120` (2 rps avg) for shared dev; tighten in CI with `3~10` to validate.
- **Headers to observe** (standardHeaders: true):
  - `RateLimit-Limit`: configured max within window
  - `RateLimit-Remaining`: remaining quota
  - `RateLimit-Reset`: seconds to reset
  - When limited: `Retry-After` or `RateLimit-Reset` indicates wait time

#### Path Whitelisting / Tiering
- Apply limiter to `['/api/','/artifacts/']` by default.
- Exempt health endpoints: `/health`, `/api/metrics/healthz`.
- Allow higher quotas for internal mocks: `/api/echo/*` (optional) by adding a second limiter with larger `max`, applied before generic limiter.

#### Incident Playbook (Bursts/Outage)
1) Identify spike source (IP/token) via logs and proxies.
2) Temporarily raise `METRICS_RATE_MAX` (e.g., 3x) and redeploy/restart.
3) Add selective relax rule for trusted token or path if needed.
4) After stabilization, roll back to baseline and file a follow-up to adjust product-side batching/retry.
5) If chronic, implement per-IP/per-token buckets and circuit breaker at client.

### Runner Timing Toggle (for profiling)
- `AFLOW_TIMING_VERBOSE=1` enables detailed timings on ActionFlowRunner:
  - api_call: binding_ms, whitelist_ms, fetch_ms, parse_ms, onSuccess_ms, onError_ms
  - call_flow: subflow_ms; if: inner_ms; loop: loop_inner_ms; switch: switch_inner_ms
- `AFLOW_MAX_WHILE_ITERS` caps while-loops in profiling to avoid runaway.
- Default is off to avoid overhead; enable only during investigations.

### Gate Integration
- Gates pass `METRICS_AUTH_TOKEN` to sub-scripts to avoid 401.
- CORS smoke is optional and skipped if incompatible with current auth mode.


