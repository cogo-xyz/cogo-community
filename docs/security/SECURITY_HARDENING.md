## Security Hardening Guide (COGO Edge Functions)

Purpose: Checklist and flags to harden production deployments of Supabase Edge functions used by COGO.

### Core Flags (set via Supabase Secrets)
- EDGE_VERIFY_JWT=true
- EDGE_REQUIRE_HMAC=true
- EDGE_RATE_LIMIT_PER_MIN=60 (tune per-tenant)
- EDGE_CORS_ALLOW_ORIGINS=https://assistant-ui.example.com,https://ide.example.com
- INCLUDE_CLI_ACTIONS=true (keep enabled; outputs are non-destructive by default with dry_run)
- EDGE_REQUIRE_INTENT_KEYS=true (reject when `intent.keywords` invalid)
- EDGE_REQUIRE_INTENT_REQUIRES=true (enforce `requires` contract)
- INTENT_REGISTRY_TTL_SEC=60 (or higher when stable)
- INTENT_METRICS_ENABLE=true

### Headers and Auth
- Development:
  - Authorization: Bearer <ANON>
  - apikey: <PUBLISHABLE>
- Production:
  - JWT verification: on
  - Optional HMAC: `x-signature`, `x-timestamp` with shared secret validation
  - Narrow CORS allowlist per UI/IDE origin

### Rate Limiting
- Apply per-tenant/per-IP limits. Recommended conservative baseline:
  - 60 req/min for mutation endpoints
  - 240 req/min for read/SSE endpoints

### Storage and Artifacts
- Use signed URLs with short TTL (`ARTIFACTS_SIGN_TTL_SEC`), default 600s
- Bucket-scoped MIME allowlist; size limits
- Avoid including secrets in artifacts

### Idempotency and Retries
- Enable idempotency store table `cogo.idempotency_store` (or legacy keys table)
- Include `idempotency_key` on non-stream POST; safely short-circuit duplicates

### Intent Registry
- Manage `cogo.intent_keyword`, `cogo.intent_action_template` centrally
- Enforce via flags above; keep templates disabled until reviewed

### Secrets Handling
- Never commit keys to source/docs; inject via Supabase Secrets
- Rotate exposed keys immediately; update CI/Secrets

### Verification Checklist (Prod)
- [ ] JWT/HMAC enabled
- [ ] CORS allowlist set
- [ ] Rate limit applied
- [ ] Idempotency table present and enforced
- [ ] Intent flags enabled; templates reviewed/enabled
- [ ] Artifacts TTL and lifecycle rules applied


