# Capabilities Operations Guide

This runbook explains how to operate and troubleshoot the capabilities handshake for IDE/CLI integrations.

## Overview
- Endpoint: `GET /intent-resolve/info` (aka capabilities)
- Purpose: Advertise server features (task types, intent keywords, SSE events, limits), editor context support, and DEV flags.

## Key Fields
- `sse_events`: Standard event catalog (includes `ready`, `meta`, `progress`, `cli.*`, `keepalive`, `aborted`, `error`, `done`).
- `editor_context`: How client can supply and expect echo of editor context.
- `task_type_details`: Per task-type requirements loaded from registry.
- `requires_source`: `registry` when loaded from DB; `fallback` when default map is used.
- `dev_flags`: Detailed schema for DEV toggles by endpoint.
- `dev_flags_summary`: Quick boolean map to see whether DEV toggles are enabled on this server.

## Registry Source and Fallback
- The server tries to load `requires` from the table `cogo.intent_keyword` using Service Role credentials.
- When the DB lookup is not possible (e.g., missing `SUPABASE_SERVICE_ROLE_KEY`), the server returns a safe default map.
- Use query `?include_fallback=1` to force fallback output in dev/test environments.

## Configuration Checklist (Production)
1) Set `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` in Edge Functions runtime.
2) Ensure table `cogo.intent_keyword` is deployed and has up-to-date rows (`keyword`, `requires`, `notes`).
3) Verify endpoint:
   - `GET /intent-resolve/info` → `requires_source` should be `registry`.
   - `task_type_details.*.requires` should reflect DB contents.

## Verification Commands
```bash
BASE="https://$SUPABASE_PROJECT_ID.functions.supabase.co/functions/v1"
ANON="$SUPABASE_ANON_KEY"

# Quick view
curl -sS "$BASE/intent-resolve/info" -H "Authorization: Bearer $ANON" | \
  jq '{sse_events, editor_context, requires_source, dev_flags_summary}'

# Fallback (dev/test)
curl -sS "$BASE/intent-resolve/info?include_fallback=1" -H "Authorization: Bearer $ANON" | \
  jq '{requires_source, task_type_details}'
```

## Troubleshooting
- `requires_source: null` or `task_type_details: null`:
  - Cause: test/staging environment does not inject Service Role; function returns minimal contract.
  - Action: configure `SUPABASE_SERVICE_ROLE_KEY` and redeploy. Meanwhile, rely on `?include_fallback=1`.

- SSE events missing `ready`:
  - Ensure deployed functions are the latest. The spec requires `ready` and tests assert it.

- DEV flags not visible:
  - `dev_flags_summary` reflects env toggles. For local testing, set `DEV_CLI_SIMULATE`, `DEV_ABORT_AFTER_MS`, `DEV_DISABLE_FALLBACK`.

## Metrics
- When `INTENT_METRICS_ENABLE=true` and Service Role is configured, the server records a `bus_events` row on each `/intent-resolve/info` call with:
  - `event_type`: `capabilities_info`
  - `payload`: `{ task_type_count, intent_keywords_count, requires_source, sse_events_count, dev_flags_summary }`
- Use your analytics pipeline to track adoption and spot regressions (e.g., requires_source switching to fallback unexpectedly).

## Notes
- Do not expose Service Role keys to clients. The capabilities endpoint uses server-side access.
- Keep the registry cache TTL (`INTENT_REGISTRY_TTL_SEC`) modest in production (e.g., 60–300s).


