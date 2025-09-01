# RAG + KG Autonomy, Weekly Webhook, and Routing Ops

This document summarizes the recent changes that deliver autonomous RAG/KG operations, weekly reporting, and safe canary routing controls.

## Highlights

- Weekly summary webhook pipeline with preview and standard webhook payload support
- Metrics server extended endpoints for status, summaries, and routing controls
- Auto-pause canary based on gate pass-rate with cron job and manual CLI
- Routing events table for audit-friendly pause/resume history
- Dashboard additions to visualize weekly summary and routing events
- Benchmarks expanded to 30 cases for higher signal evaluations

## Key Components

### Metrics Server (`src/servers/metrics/index.ts`)

- Weekly Summary APIs
  - `GET /api/notify/weekly-sb/preview?limit=N` – Server-built weekly summary (dry)
  - `POST /api/notify/weekly-sb` – Sends weekly summary via standard webhooks
    - Uses `QUALITY_WEBHOOK_URLS` (comma-separated)
    - Optional HMAC: `QUALITY_WEBHOOK_SECRET`
    - Payload key configurable by `QUALITY_WEBHOOK_BODY_KEY` (default: `message`)
  - Summary content includes: Gate pass rate, build/test, lint, KG report, bench success rate, routing snapshot, recent routing events

- Routing Control APIs
  - `GET /api/orchestrator/routing/status` – Current canary ratio and paused flag
  - `GET /api/orchestrator/routing/auto-pause/preview?limit&threshold` – Suggests pause if pass-rate < threshold
  - `POST /api/orchestrator/routing/auto-pause` – Auto-pause (admin token)
  - `POST /api/orchestrator/routing/resume` – Resume canary (admin token), optional `canary_ratio`

- Metrics/Data APIs
  - `GET /api/metrics/summary` – Extended with latest KG report
  - `GET /api/metrics/routing/events?limit=N` – Recent routing events (pause/resume)
  - Local dashboard `GET /dashboard/local` – Adds Weekly Summary (server preview) and Routing Events cards

### PM2 Processes (`ecosystem.config.js`)

- `metrics-server` – Always-on metrics and ops API
- `weekly-notify` – Cron weekly notifier (Mon 09:00); calls `triggerWeeklySb.ts`
- `routing-auto-pause` – Cron every 30 min; previews and pauses when needed

### Scripts

- Weekly notify trigger: `src/scripts/notify/triggerWeeklySb.ts`
  - CLI: `npm run -s notify:weekly:trigger -- --dry --limit=60`

- Auto-pause
  - HTTP-based: `src/scripts/orchestrator/autoPauseIfNeeded.ts`
  - DB-direct fallback: `src/scripts/orchestrator/autoPauseDirect.ts`

- Core SQL apply: `src/scripts/db/applyCoreSql.ts` now includes:
  - `rpc_match_agent_knowledge_vectors.sql`
  - `runtime_locks.sql`
  - `routing_configs.sql`
  - `upgrade_reports.sql`
  - `kg_reports.sql`
  - `triggers_rag_events.sql`
  - `routing_events.sql` (new)

### SQL

- `supabase/sql/routing_events.sql` (new)
  - `routing_events(id, created_at, event_type, payload)` for pause/resume audit
- `supabase/sql/triggers_rag_events.sql` – rewritten without DO blocks, idempotent

### RAG/KG Improvements

- `SupabaseVectorStore.ts` – KG-weight boost via `KG_WEIGHT` and `KG_URIS`
- `benchRunner.ts` – 30-case benchmark

## Environment

- Supabase
  - `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` (service)
- Weekly Webhook
  - `QUALITY_WEBHOOK_URLS` – Comma separated standard webhook endpoints
  - `QUALITY_WEBHOOK_BODY_KEY` – Payload key name (default: `message`)
  - `QUALITY_WEBHOOK_SECRET` – Optional HMAC secret
  - `QUALITY_NOTIFY_ADMIN_TOKEN` – Admin token for privileged endpoints
- Auto Pause
  - `AUTO_PAUSE_LIMIT` (default `200`)
  - `AUTO_PAUSE_THRESHOLD` (default `85`)

## Operational Cheatsheet

- Preview weekly message
  - `curl -s "http://localhost:${METRICS_PORT:-3100}/api/notify/weekly-sb/preview?limit=120" | jq -r '.message'`

- Send weekly (standard webhook)
  - `QUALITY_NOTIFY_ADMIN_TOKEN=<token> curl -s -X POST http://localhost:${METRICS_PORT:-3100}/api/notify/weekly-sb -H 'content-type: application/json' -d '{"dry":false,"limit":200,"idem":"weekly-$(date +%Y%m%d)"}' | jq .`

- Routing status / events
  - `curl -s http://localhost:${METRICS_PORT:-3100}/api/orchestrator/routing/status | jq .`
  - `curl -s http://localhost:${METRICS_PORT:-3100}/api/metrics/routing/events?limit=5 | jq .`

- Auto-pause (manual)
  - `QUALITY_NOTIFY_ADMIN_TOKEN=<token> curl -s -X POST http://localhost:${METRICS_PORT:-3100}/api/orchestrator/routing/auto-pause -H 'content-type: application/json' -d '{"limit":200,"threshold":85}' | jq .`

- Resume canary
  - `QUALITY_NOTIFY_ADMIN_TOKEN=<token> curl -s -X POST http://localhost:${METRICS_PORT:-3100}/api/orchestrator/routing/resume -H 'content-type: application/json' -d '{"canary_ratio":20}' | jq .`

- PM2
  - `npx pm2 status metrics-server weekly-notify routing-auto-pause`

## Notes

- In case of CI/terminal output issues, prefer storing API responses to files or using the GET preview endpoints.
- `routing_events` is intentionally decoupled from `job_events` to avoid `job_id` constraints and simplify audit logging.


