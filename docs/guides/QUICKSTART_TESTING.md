# COGO Agent Testing Quickstart

## 1) Environment
- SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY
- Development toggles (set to false for easy tests):
  - EDGE_VERIFY_JWT=false
  - EDGE_REQUIRE_HMAC=false
  - REQUIRE_IDEMPOTENCY=false

## 2) Seed test symbols
```bash
PROJECT_UUID=$(uuidgen)
SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... PROJECT_UUID=$PROJECT_UUID \
  npx ts-node src/scripts/ci/seedTestSymbols.ts
```

## 3) One-shot smokes
```bash
# IDE parity + ActionFlow
npm run smoke:ide:parity
# ActionFlow bundle (compile/api/result/sse)
npm run smoke:aflow:bundle
# Chat gateway SSE
time npm run chat:smoke:edge
# Figma SSE
npm run figma:verify:sse
```

## 4) Unified smoke + metrics
```bash
HOST=http://localhost:3100 PROJECT_ID=<pid> COGO_PROJECT_ID=<cid> npm run metrics:bundle
```

## 5) Troubleshooting
- 401 Unauthorized: ensure dev toggles are disabled or pass valid JWT/apikey
- ECONNREFUSED metrics: start metrics server on :3100 or change HOST
- Cloudflare 400: reduce request size or use RPC endpoints

Artifacts are saved under `artifacts/**` for review.

## Legacy ActionFlow Compatibility (Quick)

- Import sample (inline):
  - `npm run -s compat:import:smoke`
  - `npm run -s compat:run:smoke`
  - `npm run -s compat:gate`
- Real HTTP smoke (httpbin):
  - `npm run -s compat:http:smoke`
- Run from a single legacy JSON file:
  - `LEGACY_FILE=/path/to/legacy.json npm run -s compat:run:file`
  - Add `REAL_HTTP=1` to enable real HTTP
- Run all legacy JSON files in a directory:
  - `LEGACY_DIR=/path/to/legacy_dir npm run -s compat:run:dir`
- Weekly bundle auto-run (if `LEGACY_DIR` is set):
  - `npm run -s ops:weekly:bundle`
 - PR Lite bundle (includes runner bundle + optional dir run):
   - `npm run -s ci:pr:compat`
