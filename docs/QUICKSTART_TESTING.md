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
