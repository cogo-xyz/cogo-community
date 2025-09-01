## Supabase Integration Guide (COGO Agent Core)

Project
- Project ID (ref): cjvgmyotqxfpxpvmwxfv
- Dashboard: https://supabase.com/dashboard/project/cjvgmyotqxfpxpvmwxfv

Required Environment
- SUPABASE_URL: https://cjvgmyotqxfpxpvmwxfv.supabase.co
- SUPABASE_SERVICE_ROLE_KEY: <service-role>
- SUPABASE_ANON_KEY: <anon/publishable>
- SUPABASE_ACCESS_TOKEN (CLI): <sbp_xxx>

Edge Functions (this repo)
- api-router (enabled): supabase/functions/api-router/index.ts
- auth-gateway (enabled): supabase/functions/auth-gateway/index.ts
- chat-gateway (enabled): supabase/functions/chat-gateway/index.ts
- router-select (new): supabase/functions/router-select/index.ts
- key-vault (new): supabase/functions/key-vault/index.ts

Runtime URLs
- Base: ${SUPABASE_URL}/functions/v1
- Router Select: ${SUPABASE_URL}/functions/v1/router-select
- Key Vault: ${SUPABASE_URL}/functions/v1/key-vault
- API Router: ${SUPABASE_URL}/functions/v1/api-router

App Environment
- ROUTER_SELECT_URL = ${SUPABASE_URL}/functions/v1/router-select
- KEY_VAULT_URL = ${SUPABASE_URL}/functions/v1/key-vault

Deployment (CLI)
1) Install/login/link
   - npm install -g supabase (or brew install supabase/tap/supabase)
   - export SUPABASE_ACCESS_TOKEN=<sbp_...>
   - cd supabase && supabase link --project-ref cjvgmyotqxfpxpvmwxfv
2) Deploy functions
   - supabase functions deploy router-select
   - supabase functions deploy key-vault
   - (optional) supabase functions deploy api-router auth-gateway chat-gateway
3) Test
   - curl -X POST ${SUPABASE_URL}/functions/v1/router-select -H 'content-type: application/json' -d '{"intent":"chat","expected_tokens":{"in":200,"out":300}}'
   - curl -X POST ${SUPABASE_URL}/functions/v1/key-vault/get -H 'content-type: application/json' -d '{"provider":"anthropic"}'

Verification in App
- Set ROUTER_SELECT_URL/KEY_VAULT_URL and run:
  - npm run smoke:routed
  - npm run smoke:workflow:intent
- Check metrics: /metrics (cogo_llm_tokens_total, cogo_llm_cost_usd_total)
- Check routing snapshot: /api/metrics/routing?service=chat (distributed server)


