## Deployment Checklist (DEV → STG → PRD)

- Safe rollout
  - Package release: tar.gz excluding VCS/node_modules/artifacts
  - Upload to server and extract under `~/deploy/<app>/releases/<ts>`
  - Symlink switch: `ln -sfn releases/<ts> current`
  - Run from `current` (e.g., docker compose up -d)
  - Never `rsync --delete` to $HOME or broad dirs

- Secrets & Config
  - No secrets in code or chats; use `.env` or secret manager
  - Supabase keys: Anon for edge ingress, Service for DB writes
  - Rotate exposed keys and update CI/Env

- Edge Functions
  - Verify healthz for core endpoints: json-*, chat, chat-gateway, json-validate
  - CORS headers standardized; OPTIONS works
  - Observability: trace_id appears in bus_events / trace-status endpoint

- Database
  - RLS policies valid for `public.cogo_documents`
  - Vector dims / model params match docs

- Orchestrator/Workers
  - Avoid port conflicts; prefer 3001:3000 mapping
  - PM2 or supervisor for node workers (if used)

- Deployment Ops
  - Use `scripts/edge/deploy_all.sh [deploy|build] [--only=fn1,fn2] [--env=dev|stg|prd] [--report=out.json] [--webhook=<url>]`
  - Set `PARALLEL=1` for speed; `DRY_RUN=1` for preview
  - Built-in retries with backoff for transient failures
  - Optional JSON report (`--report`) captures missing/succeeded/failed
  - Optional webhook (`--webhook`) posts the JSON summary

- Quality Gates
  - Run `scripts/quality/run_everything.sh` green
  - Smoke chat (JSON+SSE) OK
  - Pipeline validation OK; corpus summary OK

- Rollback Plan
  - Keep N releases; `ln -sfn releases/<prev> current` to revert
  - DB migrations reversible
