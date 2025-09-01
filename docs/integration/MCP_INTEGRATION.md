## MCP Integration (Figma/Browser) with COGO Distributed Agents

This document describes how to preserve the original MCP server (cursor-talk-to-figma-mcp) while replacing the client-side connector from Cursor to COGO. The MCP interface and tool specifications remain unchanged. Reference: [cursor-talk-to-figma-mcp](https://github.com/grab/cursor-talk-to-figma-mcp)

### Architecture
- **MCP Server (preserved)**: `mcp-servers/figma-context/cogo-talk-to-figma-mcp`
  - Keep the original spec for the Figma MCP server/websocket/plugin
  - Externalize port/channel via `configs/mcp.json`
- **MCP Gateway Worker (new)**: `src/workers/MCPGatewayBusWorker.ts`
  - Bridge Supabase bus messages ↔ MCP server (WebSocket or child-process)
  - Apply COGO distributed standards: trace_id, idempotency, retry, circuit breaker, metrics, artifacts

### Message and Schema
- **Request (bus message)**
  - `service: "mcp"`, `role: "gateway"`, `shard: <number>`
  - `payload`
```json
{
  "toolset": "figma|browser",
  "tool": "get_document_info",
  "params": { },
  "tenant": "optional",
  "intent": "optional",
  "trace_id": "optional",
  "idempotency_key": "optional"
}
```
- **Response/Events**
  - `mcp_call_scheduled`, `mcp_call_succeeded`, `mcp_call_failed` (stored in `bus_events`)
  - Artifacts written to: `artifacts/mcp/<toolset>/<ts>/{request.json,response.json,summary.json,error.json}`

### MCP Call Adapter (inside Gateway)
- WebSocket mode: `ws://localhost:3007` (figma), `ws://localhost:3004` (browser)
- Child-process mode (optional): invoke Bun/Node runner
- Binding example
  - `tool: get_document_info → mcp.tools.get_document_info(params)`
  - Retry/circuit key: `mcp.call.<toolset>.<tool>.<shard>`

### Environment and Security
- Secrets/Env
  - `FIGMA_PERSONAL_ACCESS_TOKEN`, `FIGMA_PLUGIN_CHANNEL`
  - `MCP_FIGMA_WS_URL`, `MCP_BROWSER_WS_URL`
  - Operator guard for non-GET: set `REQUIRE_ADMIN_FOR_NON_GET=true` and require `x-admin-token` header
- Policy
  - Optional API proxy: `/api/mcp/:toolset/:tool` → routes to MCP Gateway
  - Deny-by-default route policy with allowlist

### Observability and Gate
- Metrics
  - `mcp_calls_total`, `mcp_fail_total`, `mcp_latency_ms`
- CI Gate
  - Add an “MCP ping” step (skip when secrets are unavailable)
  - When Supabase is ON-mode, require `orchestrator` events > 0 and MCP call success rate > 0
  - Use `npm run -s mcp:ping` for a lightweight health check (uses `configs/mcp.json`) 
  - For CI docker, `docker-compose.ci.yml` optionally builds `cogo-figma-mcp`/`cogo-browser-mcp` and exposes WS URLs via env
  - Retry tuning: `configs/retry_policy.json` supports per-tool keys like `mcp.call.figma.get_document_info`, `mcp.call.browser.navigation`, `mcp.call.browser.screenshot`

### Integration Steps (Order)
1) Fork/rename repository (keep code): `mcp-servers/figma-context/cogo-talk-to-figma-mcp`
   - Register ws/channel in `configs/mcp.json`
2) Implement `MCPGatewayBusWorker`
   - Receive bus message → call MCP → write artifacts/events → emit result
   - Apply retry/circuit/metrics/trace/idempotency
3) (Optional) Add proxy route `/api/mcp/:toolset/:tool` with admin token guard
4) Include MCP ping test in CI and alert on gate failure
5) Maintain this document `docs/MCP_INTEGRATION.md`

### Advantages
- Reuse original MCP spec/plugins (see [cursor-talk-to-figma-mcp](https://github.com/grab/cursor-talk-to-figma-mcp))
- Unified with COGO standards (trace/idempotency/retry/circuit/metrics/DLQ)
- Easy to extend to browser MCP via the same gateway worker

### Directory and Configuration Standards
- `mcp-servers/figma-context/cogo-talk-to-figma-mcp`
  - Run script: `npm run mcp:figma` (or Bun: `bun socket`, `bunx`)
  - Ports/channels configured by `configs/mcp.json`
- `mcp-servers/browser-use`
  - Run script: `npm run mcp:browser`
- `configs/mcp.json` example
```json
{
  "figma": { "ws": "ws://localhost:3007", "channel": "figma-01" },
  "browser": { "ws": "ws://localhost:3004", "channel": "browser-01" }
}
```

### API/Security/Policy
- Optional API proxy: `/api/mcp/:toolset/:tool` → MCP Gateway
  - For non-GET: require `REQUIRE_ADMIN_FOR_NON_GET=true` and `x-admin-token`
  - Manage allow/deny with `route_policies.json`
  - Health ping: `GET /api/mcp/ping/:toolset/:tool` (lightweight readiness)
  - Health summary: `GET /api/mcp/health` (pings figma/browser via WS)
- Secrets
  - Manage `FIGMA_PERSONAL_ACCESS_TOKEN`, `FIGMA_PLUGIN_CHANNEL`, `MCP_BROWSER_WS_URL` via `.env`/Secrets
  - Inject similarly to `ADMIN_TOKEN`, `GOOGLE_CHAT_WEBHOOK_URL` in CI

### Message/Artifact/Metrics Standards
- Message fields
  - Common: `id`, `service/role/shard`, `tenant`, `intent`, `trace_id`, `idempotency_key`, `attempts`
  - MCP: `toolset`, `tool`, `params`
- Artifacts
  - Write request/response JSON to `artifacts/mcp/<toolset>/<ts>/`
  - On failure, write `error.json` with `trace_id` and reason
- Metrics/Trace
  - Add counters/histograms: `mcp.calls_total`, `mcp.fail_total`, `mcp.latency_histogram`
  - Merge MCP section into `/api/metrics/summary` (total, fail, latency)

### CI/Gate
- Add simple MCP ping
  - Figma: `get_document_info` or `get_selection` (empty result acceptable)
  - Browser: `navigation` then `get_title` (or a prepared headless flow)
- Gate fail conditions
  - Connection/timeout error in MCP section
  - Trigger Chat notification via existing alerts pipeline

### Development/Run Order (Action Items)
1) Rename/fork reference repo to `mcp-servers/figma-context/cogo-talk-to-figma-mcp`; add scripts and read ws/channel from `configs/mcp.json`
2) Standardize a browser MCP server wrapper in `mcp-servers/browser-use`
3) Implement `MCPGatewayBusWorker` (copy distributed worker template → set role to `mcp.gateway`)
4) Add optional `/api/mcp` proxy with admin token guard and policy
5) Wire artifacts/metrics/bus events with standard fields (trace_id/idempotency/attempts)
6) Add MCP ping test to CI (skip when secrets are absent)
7) Keep this document up to date with setup, run, troubleshooting

### Implementation Tips
- Figma MCP reference has server/websocket/plugin axes; manage channel identifier in `configs/mcp.json` to switch per environment
- If Bun dependency is heavy, port to Node (only the process runner changes)
- For large operations, implement tools in MCP; keep the gateway focused on call order/retries/artifact aggregation


