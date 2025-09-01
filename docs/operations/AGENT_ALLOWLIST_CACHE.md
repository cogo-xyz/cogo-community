## Agent Allowlist: DB Lookup vs Cache (Toggleable by Secrets)

### Goal
- Allow Edge Functions and distributed agents to validate `agent_id` against a central allowlist with environment-controlled caching behavior.
- Support fast iteration in development (always-hit DB or very short TTL) and efficient production (TTL/SWR + realtime invalidation) without code changes.

### Components
- **Table** (schema suggestion): `cogo.allowed_agents`
  - `agent_id text primary key`
  - `enabled boolean not null`
  - `scopes text[] default '{}'`
  - `version integer default 0`
  - `updated_at timestamptz not null default now()`
  - `meta jsonb default '{}'::jsonb`
- **RPC**: `public.get_allowed_agents_manifest()` returns
  - `{ version: number, updated_at: string, agents: Array<{ agent_id: string, enabled: boolean, scopes?: string[] }> }`
- **Edge cache util** (shared across functions): in-memory cache with env-driven policy

### Environment Variables (Secrets)
- **AGENT_ALLOWLIST_CACHE_MODE**: `off | ttl | swr`
  - `off`: Always fetch from DB (dev/diagnostics)
  - `ttl`: Use cache until TTL expires (prod default)
  - `swr`: Serve stale, refresh in background (optional advanced)
- **AGENT_ALLOWLIST_CACHE_TTL_MS**: TTL in ms (e.g., `60000`)
- **AGENT_ALLOWLIST_VERSION**: Integer. Bump to force global invalidation across Edge instances.
- **AGENT_ALLOWLIST_FORCE_KEY**: Optional admin header key for manual refresh endpoint.
- **AGENT_ALLOWLIST_REALTIME_INVALIDATE**: `0|1`. If `1`, subscribe to Postgres Changes on `allowed_agents` and invalidate cache on change.
 - **AGENT_ALLOWLIST_ENABLE**: `0|1`. If `1`, enforce allowlist at distributed agent server HTTP layer.

### Recommended Defaults
- Development: `AGENT_ALLOWLIST_CACHE_MODE=off` OR `AGENT_ALLOWLIST_CACHE_TTL_MS=500`
- Staging: `AGENT_ALLOWLIST_CACHE_MODE=ttl`, `AGENT_ALLOWLIST_CACHE_TTL_MS=5000`
- Production: `AGENT_ALLOWLIST_CACHE_MODE=ttl`, `AGENT_ALLOWLIST_CACHE_TTL_MS=60000`, `AGENT_ALLOWLIST_REALTIME_INVALIDATE=1`

### Runtime Behavior
1) On cold start, Edge fetches `get_allowed_agents_manifest()` and populates cache.
2) For each request, Edge validates `agent_id` using the cached manifest (or DB if `off`).
3) Cache is refreshed when:
   - TTL expires (ttl mode)
   - Realtime change event is received (if enabled)
   - `AGENT_ALLOWLIST_VERSION` increases
   - Admin calls refresh endpoint with `x-force-key: AGENT_ALLOWLIST_FORCE_KEY`

### API Gateway/Edge Usage (Pattern)
Middleware checks:
- Verify bearer/HMAC token signature (local secret) to avoid per-request DB lookups.
- Check `agent_id` existence and `enabled` in cached manifest.
- Optionally enforce `scopes`.

```ts
// Pseudocode
import { getAllowlist } from "_shared/allowlist";

export async function guard(req: Request): Promise<Response | null> {
  const hdr = req.headers.get("authorization") || "";
  const agentId = req.headers.get("x-agent-id") || ""; // or from token claims
  if (!verifySignature(hdr)) return json({ ok: false, error: "bad_signature" }, 401);
  const manifest = await getAllowlist();
  const allowed = manifest.agents.find(a => a.agent_id === agentId && a.enabled);
  if (!allowed) return json({ ok: false, error: "agent_denied" }, 403);
  return null; // proceed
}
```

### Implementation (Distributed Agent Server)
- Code path: `src/shared/allowlist.ts` (cache util), `src/distributed-server/RealDistributedAgentServer.ts` (early HTTP middleware).
- Env required: `SUPABASE_SERVICE_ROLE_KEY` to query RPC.
- Toggle: `AGENT_ALLOWLIST_ENABLE=1` to enforce deny for non-allowed agent IDs.

#### Operational Endpoints (Distributed)
- Manual refresh: `POST /api/allowlist/refresh`
  - Returns 2xx when refresh succeeds.
  - When allowlist denies the current agent, endpoint may respond with `403 { ok:false, error:"agent_denied" }` until enabled.

#### Smoke Procedure (Remote)
1. Disable agent in Supabase:
   `bash scripts/ops/allowlist-toggle.sh --id <agent_id> --enabled false --version <n>`
2. Call refresh endpoint (expect 2xx or 403 depending on enforcement):
   `curl -X POST http://<svc>:3100/api/allowlist/refresh`
3. Call protected route with header:
   `curl -H 'x-agent-id: <agent_id>' http://<svc>:3100/api/ci/gate` → expect 403 when disabled, 200 when enabled.

### Realtime Invalidation
- Enable `AGENT_ALLOWLIST_REALTIME_INVALIDATE=1` to subscribe to changes on `cogo.allowed_agents`.
- On insert/update/delete, clear in-memory cache so next read repopulates.

### Rollout/Upgrade Strategy
- Namespace channels by environment/project: `env.project.{dev|stage|prod}.{project_id}.{agent_id}`
- Use generation suffix for blue/green agents (e.g., `agent-x-a`, `agent-x-b`).
- Update `allowed_agents` first, then broadcast `config.invalidate` over realtime for immediate adoption.
- Emergency kill-switch: set `enabled=false` or bump `AGENT_ALLOWLIST_VERSION`.

### Security Notes
- Do not rely solely on allowlist; always verify token signatures (HMAC/JWT) first.
- Use short-lived tokens (5–15 minutes) and rotate secrets.
- Log deny/allow events into `bus_events` for auditing: `agent_auth_{allow|deny}` with `agent_id`, `trace_id`.

### Troubleshooting
- "Every request hits DB": ensure `AGENT_ALLOWLIST_CACHE_MODE` is not `off` and TTL is reasonable.
- "Cache not updating": check realtime addon, table replication, or bump `AGENT_ALLOWLIST_VERSION`.
- "Unexpected denies": inspect manifest via RPC response and verify `agent_id`/`scopes`.

### Supabase Config Checklist
- Store the above env keys in project secrets (Edge & Database where needed).
- Create `cogo.allowed_agents` and the `get_allowed_agents_manifest` RPC.
- Optionally enable Realtime on the table for invalidation.

### Local vs Remote
- Local dev can keep `off` for immediate DB reflection or short TTL.
- Remote (MicroK8s) should use `ttl` + realtime invalidation for performance and freshness.


