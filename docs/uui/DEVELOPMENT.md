## UUI Pipeline – Developer Guide

This document explains how to run, verify, and troubleshoot the Universal UI Schema (UUI) pipeline locally without Docker, using the minimal server and CI helper scripts.

### Overview

- Pipeline: Figma JSON → UI JSON → UUIS AST passes → Rehash → Preview/Stream/Cache → Metrics
- Determinism: stable hashing, pass early-exit, hot-reload disabled in CI, order-insensitive comparisons
- Gate Script: `ci:uui:gate` enforces cache prune → registry rebuild via pipeline → preview hash verification → short SSE stream smoke → optional golden update

### Quick Start

1) Start minimal server automatically via gate (no manual boot required). Gate will auto-start if down.

```bash
cd /Users/hyunsuklee/Desktop/Dev/cogo-project/cogo-agent-core
HOST=http://localhost:3007 ENFORCE=true START_IF_DOWN=1 LAYOUT_ONLY=true npm run -s ci:uui:gate
```

2) Update golden snapshots then immediately verify clean:

```bash
# Update snapshots (prints "Mismatch" before writing new goldens)
HOST=http://localhost:3007 UPDATE_GOLDEN=1 npm run -s ci:ui:full

# Verify without updating (fails on real mismatches)
HOST=http://localhost:3007 npm run -s ci:ui:full
```

3) One-shot large-batch (gate + full UI CI + health/metrics) – recommended for local checks:

```bash
HOST=http://localhost:3007 ENFORCE=true START_IF_DOWN=1 LAYOUT_ONLY=true UPDATE_GOLDEN=1 npm run -s ci:uui:gate
HOST=http://localhost:3007 UUI_PREVIEW_SMOKE=1 UUI_STREAM_SMOKE=1 UUI_STREAM_LONG_SMOKE=0 npm run -s ci:ui:full
curl -s $HOST/api/metrics/summary | jq '.ui'
```

### Scripts

- Minimal server: `npm run -s start:minimal`
- Gate (strict preview hash verify + short SSE):
  - `npm run -s ci:uui:gate`
  - `npm run -s ci:uui:gate:update` (same as above + golden update)
- Full UI CI: `npm run -s ci:ui:full`
- Health checks:
  - `npm run -s ci:ui:health`
  - `npm run -s ci:ui:health:stream`
- Fragment cache:
  - `npm run -s uui:cache:list`
  - `npm run -s uui:cache:prune`

### Determinism & Flags

- `UUI_ENFORCE_FRAGMENT_HASH=true` – server enforces preview hash
- `UUI_HASH_LAYOUT_ONLY=true` – hash includes structural/layout fields only
- `UUI_PIPELINE_EARLY_EXIT_NO_CHANGE=true` – skip passes when no change detected
- `UUI_RULES_HOT_RELOAD_MS=0` – disable hot reloading to avoid drift in CI
- `UUI_NORMALIZE_ID_AUTOGEN=true` – auto-generate stable IDs on missing inputs

Gate will set the minimal required flags automatically; you can export them for manual runs.

### Golden Policy

- UPDATE mode (`UPDATE_GOLDEN=1`) shows "Mismatch" logs to inform what is being updated. This is expected and not an error.
- VERIFY mode (no `UPDATE_GOLDEN`) must exit non-zero on any mismatch.
- Comparators are stabilized to ignore volatile fields (`id`, `__hash`), drop empty props/events, and compare arrays deterministically.

### Key APIs (Minimal Server)

- Preview (hash enforce): `GET /api/uui/fragment/preview?url=...&key=...&verify=1`
- SSE Stream: `GET /api/uui/stream?url=...&key=...&maxChunks=...`
- Cache mgmt: `POST /api/uui/cache/prune`, `GET /api/uui/cache/list`
- Metrics: `GET /api/metrics/summary`

### Registry Consistency

- Always rebuild the UUI registry via pipeline to inject consistent `__hash` values:

```bash
npx ts-node src/scripts/ui/rebuildRegistryFromPipeline.ts
```

### Troubleshooting

- 404 on preview/stream: verify `url` points to a reachable registry; use local path `artifacts/uui/registry.json`
- Hash mismatch under enforce: rebuild registry via pipeline; ensure `UUI_HASH_LAYOUT_ONLY` alignment across tools
- CI mismatch prints only: indicates UPDATE mode; re-run in VERIFY mode to enforce failure

### Scope Notes

- Docker/MCP are intentionally excluded from this local developer loop until final test gating
- UUI pipeline, preview/stream, cache, and metrics are production-grade and idempotent


