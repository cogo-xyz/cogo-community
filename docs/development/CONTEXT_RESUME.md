## Cursor Re-login – Resume Context (Immediate Ops)

This cheat sheet lets you resume development instantly without hunting context. It focuses on UUI pipeline (no Docker/MCP) and CI gates currently stabilized on main.

### Current State
- Branch: main (PR merged: UUI gate/CI docs + comparator stabilization)
- Scope: UUI pipeline only (Preview/Stream/Cache/Batch). Docker/MCP pending by policy.
- Health: Gates pass locally with strict hash verification and SSE stream smoke.

### One-shot Batch (Recommended)
Run gate (cache prune → registry rebuild via pipeline → preview hash verify → short SSE) with golden update enabled:
```bash
cd /Users/hyunsuklee/Desktop/Dev/cogo-project/cogo-agent-core
HOST=http://localhost:3007 ENFORCE=true START_IF_DOWN=1 LAYOUT_ONLY=true UPDATE_GOLDEN=1 npm run -s ci:uui:gate
```
Then full UI CI including token build and goldens:
```bash
HOST=http://localhost:3007 UUI_PREVIEW_SMOKE=1 UUI_STREAM_SMOKE=1 UUI_STREAM_LONG_SMOKE=0 npm run -s ci:ui:full
```
Metrics summary:
```bash
curl -s http://localhost:3007/api/metrics/summary | jq '.ui'
```

### Strict Verify (no golden updates)
```bash
HOST=http://localhost:3007 ENFORCE=true START_IF_DOWN=1 LAYOUT_ONLY=true npm run -s ci:uui:gate
HOST=http://localhost:3007 npm run -s ci:ui:full
```

### Minimal Server (auto-started by gate)
If needed manually:
```bash
PORT=3007 UUI_PREVIEW_ENABLED=true UUI_STREAMING_ENABLED=true UUI_FRAGMENT_ALLOW_FILE=true \
UUI_FRAGMENT_HOSTS_REQUIRED=false UUI_ENFORCE_FRAGMENT_HASH=true UUI_HASH_LAYOUT_ONLY=true \
PORT_AUTOFREE=true npm run -s start:minimal
```

### Key Endpoints
- Preview (verify hash): `GET /api/uui/fragment/preview?url=artifacts/uui/registry.json&key=fragment/card&verify=1`
- Stream (SSE): `GET /api/uui/stream?url=artifacts/uui/registry.json&key=fragment/card&maxChunks=2`
- Cache: `POST /api/uui/cache/prune`, `GET /api/uui/cache/list`
- Metrics: `GET /api/metrics/summary`

### Important Paths
- Registry JSON: `artifacts/uui/registry.json`
- Gate script: `src/scripts/ci/uuiGate.ts` (npm: `ci:uui:gate`, `ci:uui:gate:update`)
- UI CI: `npm run -s ci:ui:full`
- Comparators: `src/scripts/ui/compare{AllGoldens,Golden,AstGoldens}.ts` (stable, ignore id/__hash)
- Rebuild registry via pipeline: `src/scripts/ui/rebuildRegistryFromPipeline.ts`

### Notes
- "Mismatch" lines during UPDATE mode are informational (snapshots being refreshed). In VERIFY mode they are failures.
- Determinism flags used in CI: `UUI_RULES_HOT_RELOAD_MS=0`, `UUI_PIPELINE_EARLY_EXIT_NO_CHANGE=true`, `UUI_HASH_LAYOUT_ONLY=true`.
- Docker/MCP are deferred until final test/approval.


