# COGO Agent Authentication & Security (Design)

This document specifies the production-ready design for distributed agent authentication over Supabase (Auth, Realtime, Edge) with SSE-heavy workloads.

## Identities & Tables

- **Users**: Supabase Auth users (email/password, OAuth, etc.)
- **Agents (logical devices)**:
  - `agent_devices(id uuid pk, user_id uuid fk, alias text, platform text, public_key text, status text, last_seen_at timestamptz, channel text, metadata jsonb, created_at timestamptz)`
- **Agent secrets/tokens**:
  - `agent_tokens(id uuid pk, agent_id uuid fk, secret_hash text, rotated_at timestamptz, expires_at timestamptz, status text)`
- **Events**: `bus_events` for audit (`trace_id` required)

Secrets are never stored in plaintext (hash-only). Rotate secrets regularly.

## Enrollment Flow (Owner Logged-in)

1) `POST /functions/v1/agent/enroll/start`
   - Input: none (user must be authenticated; dev-mode optional)
   - Output: `{ enroll_code, challenge, expires_in_sec }` (shown as QR or numeric code)
2) Device `POST /functions/v1/agent/enroll/complete`
   - Input: `{ enroll_code, public_key, signature }` (signature over `challenge`)
   - Server validates and issues:
     - `agent_id`, one-time `agent_secret` (HMAC), short-lived `agent_jwt` (1h)

## Runtime Auth for SSE-heavy Protocol

- First request: perform a session handshake to avoid repeated heavy JWT checks
  - `POST /functions/v1/agent/session/start` → `{ session_id, ttl_ms }`
- Subsequent SSE/API calls headers:
  - `X-Session-Id: <session_id>`
  - `X-Timestamp: <epoch_ms>` (window e.g., ±60s)
  - `X-Agent-Id: <agent_id>`
  - `X-Signature: HMAC_SHA256(body, agent_secret)`
  - Optional `X-Nonce: <nonce>` (short-lived replay protection)
- Server path (hot): lookup session in cache + HMAC + timestamp only; JWT is revalidated every N calls or on session renew.

Dev fast-path (for local/dev environments only):
- `EDGE_ALLOW_HEADER_SECRET=true` allows passing `X-Agent-Secret: <agent_secret>` to bypass DB lookup during development.

### Headers Reference

- `X-Agent-Id`: UUID of agent (required)
- `X-Timestamp`: epoch ms for replay window (required)
- `X-Signature`: hex(HMAC_SHA256(body, agent_secret)) (required)
- `X-Session-Id`: returned by `/agent/session/start` (recommended; enforced if `AGENT_SESSION_REQUIRED=true`)
- `X-Nonce`: one-time nonce; required if `AGENT_REQUIRE_NONCE=true`
- `X-Agent-Secret`: dev-only fast-path (allowed if `EDGE_ALLOW_HEADER_SECRET=true` or `EDGE_DEV_NO_AUTH=true`)

## JWT & Token Strategy

- `agent_jwt` (custom project JWT): 1 hour TTL, claims: `sub: agent_id`, `agent_id`, `owner_user_id`, `scopes`.
- `agent_secret` (HMAC): 90-day rotation, 7-day grace window.
- Refresh endpoint: `POST /functions/v1/agent/token/refresh` (requires HMAC + timestamp).

## Replay & Abuse Protection

- Timestamp window validation (e.g., 60s) + per-agent monotonic previous timestamp cache.
- Optional nonce (short TTL in Redis) for high-risk endpoints.
- Lightweight rate limits per `agent_id`.

## Supabase Integration

- Realtime: connect with project JWT containing `agent_id`/`owner_user_id` claims. Channel namespace `agent:{agent_id}:*`.
- RLS: policies based on `request.jwt()` claims to restrict rows by `agent_id`/`owner_user_id`.
- PostgREST: agents DO NOT use direct DB; Edge mediates reads/writes.

## Edge Endpoints (MVP)

- `GET  /functions/v1/agent/healthz`
- `POST /functions/v1/agent/enroll/start`
- `POST /functions/v1/agent/enroll/complete`
- `POST /functions/v1/agent/session/start`
- `POST /functions/v1/agent/token/refresh`

Additional endpoints implemented for development and observability:

- `POST /functions/v1/agent/protected/echo` — HMAC-protected demo endpoint
- `GET  /functions/v1/agent/metrics` — dev metrics: `{ sessions, secrets, nonces, now }`
- `POST /functions/v1/agent/session/extend` — refresh session TTL: `{ session_id, ttl_ms }`
- `POST /functions/v1/agent/secret/rotate` — dev-only rotate token: `{ agent_id, new_secret }`

## Development Quickstart

1) Set secrets (Edge Functions): `SUPABASE_URL`, `SERVICE_ROLE_KEY`, optionally `EDGE_DEV_NO_AUTH=true`, `EDGE_ALLOW_HEADER_SECRET=true`
2) Start session: `POST /agent/session/start { agent_id }` → keep `session_id`
3) Call protected endpoints with headers: `x-agent-id`, `x-timestamp`, `x-signature`, `x-session-id` (and `x-nonce` if enabled)
4) Rotate secrets (dev): `POST /agent/secret/rotate { agent_id }`

### Dev Quick Runs

```bash
# Integrated smoke (Edge-based RAG + LLM + Stream)
USE_EDGE_LLM=true RAG_USE_EDGE=true \
SUPABASE_EDGE=$SUPABASE_EDGE SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
AGENT_ID=$AGENT_ID AGENT_SECRET=$AGENT_SECRET \
npm run -s edge:smoke:integrated

# LLM Gate (p50/p95/error)
npm run -s llm:gate

# Agent Gate (requires AGENT_ID/AGENT_SECRET)
npm run -s agent:gate
```

Troubleshooting streaming:
- If 404: ensure `llm` function deployed and `/llm/chat/stream` exists.
- In Node.js, prefer parsing `node-fetch` Readable stream (not `getReader()`).

## Production Checklist

- Auth
  - `EDGE_VERIFY_JWT=true`, `EDGE_REQUIRE_HMAC=true`, `EDGE_ALLOW_HEADER_SECRET=false`
  - `AGENT_SESSION_REQUIRED=true`, `AGENT_REQUIRE_NONCE=true` (sensitive endpoints)
- Timing & replay
  - `AGENT_HMAC_WINDOW_MS` sized for latency SLO
  - Nonce store backed by Redis (Edge in-memory only for dev)
- Caching
  - Sessions/nonces/secrets in Redis with conservative TTL
  - `AGENT_SECRET_CACHE_MS` small or 0 if shared cache used
- Observability
  - `bus_events`: `agent_enroll_*`, `agent_session_started`, `llm_chat`, `rag_search_executed`
  - Dashboards: `/api/metrics/agent`, `/api/metrics/llm`, `/api/metrics/rag*`
- CI Gates
  - `agent:gate` (HMAC/jitter/replay), `llm:gate` (p50/p95/error), `edge:smoke:integrated`

## cURL Examples

Protected echo (HMAC + session + nonce):
```bash
EDGE=${SUPABASE_EDGE%/}
AID=$AGENT_ID
SEC=$AGENT_SECRET

# session
SID=$(curl -s -X POST "$EDGE/agent/session/start" -H 'content-type: application/json' \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" -H "apikey: $SUPABASE_ANON_KEY" \
  -d '{"agent_id":"'$AID'"}' | jq -r .session_id)

BODY='{"hello":"world"}'
TS=$(node -e 'process.stdout.write(String(Date.now()))')
SIG=$(printf "%s" "$BODY" | openssl dgst -sha256 -hmac "$SEC" -binary | xxd -p -c 256)
NON="nonce_$(date +%s%3N)_$RANDOM"

curl -s -X POST "$EDGE/agent/protected/echo" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" -H "apikey: $SUPABASE_ANON_KEY" \
  -H "x-agent-id: $AID" -H "x-timestamp: $TS" -H "x-signature: $SIG" \
  -H "x-session-id: $SID" -H "x-nonce: $NON" \
  -d "$BODY" | jq -c
```

LLM Chat (Edge):
```bash
curl -s -X POST "$EDGE/llm/chat" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" -H "apikey: $SUPABASE_ANON_KEY" \
  -d '{"provider":"anthropic","model":"claude-sonnet-3.5","messages":[{"role":"user","content":"hi"}]}' | jq -c
```

Notes:
- Dev mode: `EDGE_DEV_NO_AUTH=true` permits simplified behavior (no JWT signing service).
- Production mode: enable `EDGE_VERIFY_JWT=true`, `EDGE_REQUIRE_HMAC=true`.

## Environment Variables

Edge:
- `EDGE_DEV_NO_AUTH` (dev only), `EDGE_VERIFY_JWT`, `EDGE_REQUIRE_HMAC`
- `EDGE_ALLOW_HEADER_SECRET` (dev only; default true in dev)
- `JWT_SECRET` (sign custom JWTs if using Edge for signing)
- `AGENT_SESSION_TTL_MS` (default 600000)
- `AGENT_JWT_CACHE_TTL_MS` (default 300000)
- `AGENT_HMAC_WINDOW_MS` (default 60000)
- `AGENT_RATELIMIT_PER_SEC` (default 10)
- `AGENT_REQUIRE_JWT_EVERY_N` (default 20)
- `AGENT_SECRET_CACHE_MS` (default 300000) — in-memory secret cache TTL (per isolate)
- `AGENT_NONCE_TTL_MS` (default 300000) — nonce TTL for replay protection (per isolate)
- `AGENT_REQUIRE_NONCE` (default false) — require presence and one-time nonce for protected endpoints
- `AGENT_SESSION_REQUIRED` (default false) — require valid session for protected endpoints

Client (agent):
- `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `agent_id`, `agent_secret`

## Telemetry & Alerts

- Emit `bus_events` on enrollment, session start, token refresh, and security violations.
- Reuse `/api/metrics/*` for latency & hit-rate; add per-agent labels if needed.
- Alerts: webhook via `/api/alerts/rag` (extend or create `/api/alerts/agent`).

## CORS

Edge returns CORS headers including (at minimum):
- `Access-Control-Allow-Origin: *`
- `Access-Control-Allow-Methods: GET, POST, OPTIONS, HEAD`
- `Access-Control-Allow-Headers: authorization, x-client-info, apikey, content-type, idempotency-key, x-agent-id, x-signature, x-timestamp, x-agent-secret, x-session-id, x-nonce`

## Example Requests (curl)

Enroll (dev):
```bash
EDGE="$SUPABASE_EDGE"; EDGE=${EDGE%/}
curl -s -X POST "$EDGE/agent/enroll/start" \
  -H "content-type: application/json" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" -H "apikey: $SUPABASE_ANON_KEY"

curl -s -X POST "$EDGE/agent/enroll/complete" \
  -H "content-type: application/json" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" -H "apikey: $SUPABASE_ANON_KEY" \
  -d '{"enroll_code":"123456","public_key":"dev-pk","signature":"dev-sig:challenge"}'
```

Session + Protected Echo (dev; HMAC + optional session + nonce):
```bash
EDGE=${SUPABASE_EDGE%/}
AID=$AGENT_ID; SEC=$AGENT_SECRET
S=$(curl -s -X POST "$EDGE/agent/session/start" -H 'content-type: application/json' \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" -H "apikey: $SUPABASE_ANON_KEY" \
  -d '{"agent_id":"'$AID'"}')
SID=$(printf "%s" "$S" | jq -r .session_id)
BODY='{"hello":"world"}'
TS=$(node -e 'process.stdout.write(String(Date.now()))')
SIG=$(printf "%s" "$BODY" | openssl dgst -sha256 -hmac "$SEC" -binary | xxd -p -c 256)
NON=nonce_$RANDOM$RANDOM
curl -s -X POST "$EDGE/agent/protected/echo" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" -H "apikey: $SUPABASE_ANON_KEY" \
  -H "x-agent-id: $AID" -H "x-timestamp: $TS" -H "x-signature: $SIG" \
  -H "x-session-id: $SID" -H "x-agent-secret: $SEC" -H "x-nonce: $NON" \
  -d "$BODY"
```

Rotate (dev only):
```bash
EDGE=${SUPABASE_EDGE%/}
curl -s -X POST "$EDGE/agent/secret/rotate" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" -H "apikey: $SUPABASE_ANON_KEY" \
  -d '{"agent_id":"'$AGENT_ID'"}'
```

Metrics:
```bash
curl -s "$EDGE/agent/metrics" -H "Authorization: Bearer $SUPABASE_ANON_KEY" -H "apikey: $SUPABASE_ANON_KEY"
```

## Dev vs Production Guidance

- Development:
  - `EDGE_DEV_NO_AUTH=true`, `EDGE_ALLOW_HEADER_SECRET=true`, `AGENT_SESSION_REQUIRED=false`, `AGENT_REQUIRE_NONCE=false`
  - Use `/agent/secret/rotate` for quick token rotation; secrets may be passed with `X-Agent-Secret` header
- Production:
  - `EDGE_VERIFY_JWT=true`, `EDGE_REQUIRE_HMAC=true`, `EDGE_ALLOW_HEADER_SECRET=false`
  - Consider `AGENT_SESSION_REQUIRED=true`, `AGENT_REQUIRE_NONCE=true` for sensitive endpoints
  - Move caches (sessions, nonces, secrets) to Redis/shared store; tune TTLs

## Future Hardening

- Device proof with ECDSA challenge/response at enrollment & on rotation.
- Formal nonce store (Redis) and sliding-window rate-limit per agent.
- LLM rerank/signature verification on sensitive paths (optional).

## Dev Test User & Mode Tests

This section documents the development test user and the basic auth mode tests (unauthorized vs authorized).

### Test User
- Email: `dev-agent+1755941714@cogo.xyz`
- Role: `cogo_agent` (via Supabase Admin API `app_metadata.role`)

Grant role to the user (replace `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, and user id if needed):
```bash
BASE=$SUPABASE_URL
UID=36655d46-3102-4f99-ac04-f90edd20d973
curl -s -X PUT "$BASE/auth/v1/admin/users/$UID" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "content-type: application/json" \
  -d '{"app_metadata":{"role":"cogo_agent"}}'
```

Sign in to get `access_token` for testing:
```bash
TOKEN=$(curl -s -X POST "$BASE/auth/v1/token?grant_type=password" \
  -H "apikey: $SUPABASE_ANON_KEY" -H "content-type: application/json" \
  -d '{"email":"dev-agent+1755941714@cogo.xyz","password":"<password>"}' | jq -r .access_token)
```

### Mode Tests
- Unauthorized broadcast (no Bearer token) → 401 Unauthorized as expected
```bash
curl -s -X POST http://localhost:6001/api/agent/collab/broadcast \
  -H 'content-type: application/json' \
  -d '{"type":"message","payload":{"hello":"world"}}'
```

- Authorized broadcast (Bearer token) → success, `totalEvents` increments
```bash
curl -s -X POST http://localhost:6001/api/agent/collab/broadcast \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"type":"message","payload":{"hello":"world"}}'

curl -s http://localhost:6001/health | jq -c .comm  # totalEvents should increase
```

Notes:
- Keep secrets out of VCS. Use environment variables or secrets manager.
- For broader E2E, run `npm run -s edge:smoke:integrated` and `npm run -s llm:gate`.
