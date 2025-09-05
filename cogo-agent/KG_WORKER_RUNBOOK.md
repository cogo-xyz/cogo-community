## KG Upsert Worker Runbook (poller mode)

Start (Docker Compose):
```bash
docker compose -f container/compose/kg-upsert.yml up -d
```

Env (required):
- `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`
- `CREATEGO_NEO4J_URI` (Bolt) and/or `CREATEGO_NEO4J_HTTP_URL`
- Optional: `KG_UPSERT_POLL_MS` (default 300000), `KG_UPSERT_LIMIT` (default 25)

PM2 (inside container):
- Process managed by pm2-runtime via `pm2/ecosystem.kg.config.cjs`
- Logs:
```bash
docker compose -f container/compose/kg-upsert.yml logs -f kg-upsert-poller
```

Stop:
```bash
docker compose -f container/compose/kg-upsert.yml down
```

Notes:
- Uses `cogo.bus_events` with `event_type='json.ingest_request'` and emits `kg.ingested` as soft mark.
- Idempotent MERGE upserts for `Project`→`Document`→`DocVersion`.
- Prefer Scheduled Function (5-min) handoff in production for controlled load.


