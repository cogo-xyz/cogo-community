# M3 Distributed Agent Development Batch Report

Date: 2025-08-25

## Executive Summary

- Completed M3 scope: Figma MCP → UUI JSON → COGO UI JSON pipeline, deprecating all CreateGo compatibility paths.
- Replaced legacy `chatting` usage with `chat` (canonical) and `chat-gateway` (ingress proxy).
- Added `/figma-compat/uui/generate` endpoint and validated via smoke tests.
- Upgraded Figma plugin to use `cogo_ui_json`, added Chat/Context SSE streaming and UI controls.
- Standardized OpenAPI and regenerated types; fixed YAML response issues.
- Verified real-time SSE flow end-to-end through Supabase Edge and distributed agents.
- Built and launched the Docker cogo0 stack; metrics server exposed on 3200 with green health.

## Key Changes

### Edge Functions
- Removed legacy `chatting` usage throughout; confirmed canonical SSE at `/functions/v1/chat` and ingress `/functions/v1/chat-gateway`.
- Introduced `/functions/v1/figma-compat/uui/generate` (prompt → UUI/COGO demo output).
- `figma-plugin` compatibility pruned for CreateGo (`/compat/creatego` removed). UUI compat endpoints retained.

### OpenAPI & Types
- `docs/openapi/edge-functions.yaml` fixed invalid responses and duplicate keys, removed `chatting` paths, added generate route.
- `src/types/generated/edge-functions.ts` regenerated.

### Figma Plugin
- `tools/figma-plugin/cogo-plugin`:
  - Sends `cogo_ui_json` (no `creatego_json`).
  - Added `chat_sse` (POST `/chat-gateway`) and `context_sse` (POST `/figma-context/stream`).
  - UI updated with inputs and buttons for SSE testing.

### Scripts & Workers
- CI smokes updated to use `cogo_ui_json` and `chat-gateway`/`chat`:
  - `src/scripts/ci/chatVerifyEdgeSse.ts`, `embedVerifyEdgeSse.ts`, `uuiEdgeGenerateSmoke.ts` (new), etc.
- `tmp/chat-enqueue-poll.js` migrated from `/chatting/*` to `/chat-gateway` SSE.
- `MCPGatewayBusWorker` removed CreateGo fallback; `ToolSchemas` switched `{creatego_json}` → `{cogo_ui_json}`.

### Docker & Metrics
- Optimized `.dockerignore` to exclude heavyweight directories (e.g., `cogo-worker/workspace`, `perfoneai_api`).
- `Dockerfile.metrics` hardened to avoid native build pitfalls; uses esbuild metrics-only bundles.
- Built and started cogo0 stack: orchestrator/indexing/research/executor/metrics.
- Metrics server listening at `http://localhost:3200` with summary API.

## Verification & Tests

### UUI Generate Smoke
```
SUPABASE_EDGE=$SUPABASE_EDGE SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY PROJECT_ID=$PROJECT_ID \
npx ts-node src/scripts/ci/uuiEdgeGenerateSmoke.ts
```
Expected: 200 OK with `{ ok: true, trace_id }`.

### Chat SSE (Edge)
```
npm run -s chat:verify:edge
```
Expected: `seenMeta: true, seenAnyDelta: true, seenDone: true` for both `/chat` and `/chat-gateway`.

### Embed SSE (Edge)
```
npm run -s embed:verify:edge
```
Expected: 200 OK and SSE frames.

### Figma Plugin SSE
- Build: `npm ci && npm run -s build` in `tools/figma-plugin/cogo-plugin`.
- Import `manifest.json` into Figma dev plugins.
- Use Chat SSE and Context SSE UI to stream.

### Observability Bundle
```
METRICS_HOST=http://localhost:3200 npm run -s smoke:edge:observability
```
Covers chat SSE meta, idempotency, trace SSE, orchestrator routes, and RAG SSE.

### Docker Stack
```
docker compose -f infra/compose/docker-compose.cogo0.yml build --no-cache
docker compose -f infra/compose/docker-compose.cogo0.yml up -d
curl -s http://localhost:3200/api/metrics/summary | jq .
```

## Backward Compatibility
- `public` schema views continue to bridge to `cogo` tables.
- All app references migrated to `.schema('cogo')` where applicable; CreateGo compatibility endpoints removed.

## Security & Config
- Development: `EDGE_AUTH_OPTIONAL=true`, CORS allow `figma.com`, idempotency headers respected.
- Production: JWT/HMAC recommended (plugin tokens via short-lived JWT); no secrets committed.

## Known Notes
- Metrics bundle scripts default `HOST=http://localhost:3002`; in containerized mode use `HOST=http://localhost:3200`.

## Appendix: Files Touched (Highlights)
- Package/Build: `.dockerignore`, `Dockerfile.metrics`, `package.json` (duplicate script removed, build inputs trimmed)
- Edge Functions: `supabase/functions/figma-compat/*`, `supabase/functions/figma-plugin/index.ts`
- Types/OpenAPI: `docs/openapi/edge-functions.yaml`, `src/types/generated/edge-functions.ts`
- Plugin: `tools/figma-plugin/cogo-plugin/src/code.ts`, `ui.html`
- Scripts: `src/scripts/ci/uuiEdgeGenerateSmoke.ts` (new), several CI smokes updated
- Workers/Schemas: `src/workers/MCPGatewayBusWorker.ts`, `src/services/protocol/ToolSchemas.ts`


