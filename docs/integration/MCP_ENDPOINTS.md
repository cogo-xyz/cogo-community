## MCP Endpoints and CLI Scripts

This document lists the MCP-related HTTP endpoints and CLI scripts added to the COGO Agent Core.

### HTTP Endpoints

- MCP Proxy (secured by optional admin token for non-GET requests)
  - `POST /api/mcp/:toolset/:tool`
    - Body: `{ params?: object }`
    - Calls MCP via gateway; returns `{ ok, result, error, latency_ms }`
  - `GET /api/mcp/ping/:toolset/:tool`
    - Lightweight health ping; returns `{ ok, latency_ms, error }`
  - `POST /api/mcp/enqueue`
    - Body: `{ toolset, tool, params?, shard? }`
    - Enqueues a bus message (`service=mcp`, `role=gateway`)
  - `GET /api/mcp/config`
    - Returns effective MCP config (file + env overrides)

- MCP Metrics and Events
  - `GET /api/metrics/mcp/summary`
    - Prometheus-based summary (calls, fails, p50/p95, detail by toolset/tool)
  - `GET /api/metrics/mcp/events?hours=24&limit=100`
    - Lists recent `mcp_call_%` events from `bus_events`
  - `GET /api/metrics/mcp/artifacts/summary`
    - Filesystem-based summary using `artifacts/mcp/**/summary.json`

#### Suggested Dashboard Queries

- Success rate by toolset/tool: derive from `summary.mcp.detail[toolset][tool] { ok, error }`
- Latency lines: `summary.mcp.p50` and `summary.mcp.p95`
- Circuit state: `summary.circuits.openByKey` and `openCount`

### CLI Scripts (npm run scripts)

- `mcp:gateway`
  - Start MCP Gateway Bus Worker (requires Supabase)
- `mcp:ping`
  - Calls MCP client directly and writes an artifact under `artifacts/mcp-ping/`
  - Env: `MCP_PING_REQUIRE_REAL=true` to enforce real WS requirement
- `mcp:enqueue`
  - Enqueues a bus message to trigger the MCP gateway worker
- `mcp:verify:e2e`
  - Enqueue + wait for `mcp_call_succeeded/failed` in `bus_events`; writes `artifacts/mcp-e2e/`
- `gate:unified`
  - Runs MCP ping, then local and docker scenarios; writes `artifacts/gate-run/`

### Configuration

- `configs/mcp.json`
  - Example: `{ "figma": { "ws": "ws://localhost:3007", "channel": "figma-01" }, "browser": { "ws": "ws://localhost:3004", "channel": "browser-01" } }`
  - Env overrides: `MCP_FIGMA_WS_URL`, `MCP_BROWSER_WS_URL` (defaults: 3007/3004)
- Retry policy: `configs/retry_policy.json`
  - Per-tool keys supported, e.g., `mcp.call.figma.get_document_info`
- Circuit breaker policy: `configs/circuit_breaker.json`
  - Per-key policies supported, e.g., `mcp.call.browser.get_title.0`


