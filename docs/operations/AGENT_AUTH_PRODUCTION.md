# Agent Authentication – Production Hardening & Operations

## Objectives
- Enforce strong auth for distributed agents with low overhead under SSE-heavy workloads
- Minimize blast radius via least-privilege and rotateable credentials
- Provide observability and safe operations playbooks

## Mandatory Settings (Production)
- EDGE_VERIFY_JWT=true
- EDGE_REQUIRE_HMAC=true
- EDGE_ALLOW_HEADER_SECRET=false
- AGENT_SESSION_REQUIRED=true (recommended)
- AGENT_REQUIRE_NONCE=true (for sensitive/protected endpoints)
- AGENT_HMAC_WINDOW_MS=60000 (tune per latency budget; 30–120s typical)
- AGENT_SESSION_TTL_MS=600000 (10m; adjust based on workload)
- AGENT_SECRET_CACHE_MS=0 (or minimal) if shared cache (Redis) is used; set >0 only if acceptable

## Secrets & Keys
- JWT signing keys stored in managed KMS or Supabase secrets (no plaintext in repo)
- SERVICE_ROLE_KEY never exposed to agents; Edge only; limit Postgres role to necessary tables/functions
- Agent secrets stored hashed/encrypted at rest; rotate periodically (e.g., 90 days) and on suspicion of compromise

## Redis-backed Caches (Recommended)
- Sessions: store session_id → { agent_id, exp_ms }
- Nonces: one-time keys with TTL; enforce uniqueness within TTL
- Secrets: optionally cache agent secret material with short TTL; invalidate on rotation

## RLS & Claims
- JWT claims must include: agent_id, owner_user_id
- RLS checks: rows restricted by agent_id or owner_user_id; admin bypass limited to Edge with service role

## Rate Limiting & Abuse Controls
- Per-agent QPS caps; exponential backoff on violations
- Timestamp skew checks; reject requests outside window
- Optional IP allowlists for known agent PoPs

## Observability
- Emit bus_events: agent_enroll_started, agent_enroll_completed, agent_session_started, auth_violation
- Trace IDs required on critical flows; correlate in metrics
- Metrics: p50/p95 latency, error rate, HMAC failures, replay rejections, session cache hit rate

## Runbooks
### Secret Rotation
1) Generate new secret; write to cogo.agent_tokens (atomic upsert)
2) Invalidate secret cache entry for agent_id
3) Notify agent to pick up new secret (grace window optional)
4) Monitor auth failures; revert if needed

### JWT Key Roll
1) Publish new kid+key (dual-publish) and accept both for grace period
2) Rotate signing to new key; deprecate old key after window

### Incident: Replay/Abuse
1) Enable AGENT_REQUIRE_NONCE=true on hot endpoints
2) Reduce AGENT_HMAC_WINDOW_MS and raise rate-limit strictness
3) Block offending agent_id(s); rotate secrets

## Deployment
- Prefer immutable releases with rollout/symlink pattern; avoid destructive rsync
- All secrets managed via Supabase Functions Secrets or cloud secret manager

## CI Gates
- Add smoke for: JWT verify on, header-secret off, HMAC required
- Negative tests: missing headers, nonce replay, timestamp skew, invalid signature

## Examples
- See AGENT_AUTH_DESIGN.md for curl and headers; in prod remove X-Agent-Secret entirely
