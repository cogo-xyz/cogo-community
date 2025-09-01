## Backend Schema Mapping: public → cogo

Purpose: Decouple agent core state (`cogo`) from platform-facing data (`public`). Agents write events/state to `cogo` only; platform workers project to `public`.

### Domain separation (policy-aligned)

- public domain (user-owned application data)
  - Examples: projects, project_pages, pages, components, action_flows, symbols, themes, assets
  - RLS enabled; IDE and end-users write here under user/role policies
  - Agents do NOT write directly to `public.*` (except projection worker with SRK)

- cogo domain (agent/platform internals)
  - Examples: jobs, job_events, bus_events, project_updates (outbox), vector stores, knowledge/evidence, ingestion caches, conversion artifacts
  - RLS off (service role only); authoritative source for machine-generated changes
  - Feeds projections into `public.*` for IDE/runtime consumption

- No 1:1 renaming
  - Do not mechanically map `public.*` → `cogo.*`
  - Keep user-facing entities in `public.*`; model canonical machine state in `cogo.*` where needed

### Recommended rules

- Agent write domain: cogo.* (RLS off; service role only)
- Platform read domain: public.* (RLS on; IDE/End-users)
- Projection pattern: Outbox in `cogo.project_updates` → platform worker consumes → writes to `public.*`
- Compatibility: temporary views may be used during migration, but `public.*` remains the user-owned source for app data. Prefer outbox→projection over views for steady-state.

### Outbox: cogo.project_updates

- Purpose: capture project-level changes as immutable events
- Schema: id, occurred_at, project_uuid, project_id, source, event_type, payload, status, retries, next_attempt_at, trace_id
- Indexes: (status,next_attempt_at), (project_uuid,project_id), occurred_at, event_type
- Enqueue: `cogo.enqueue_project_update(...)`

### Trigger examples (to add when base tables exist)

```sql
CREATE OR REPLACE FUNCTION cogo.trg_projects_outbox() RETURNS trigger AS $$
BEGIN
  PERFORM cogo.enqueue_project_update(NEW.project_uuid, NEW.id, 'agent', 'project.upsert', to_jsonb(NEW), current_setting('request.headers.x-trace-id', true));
  RETURN NEW;
END; $$ LANGUAGE plpgsql;
CREATE TRIGGER projects_outbox AFTER INSERT OR UPDATE ON cogo.projects FOR EACH ROW EXECUTE FUNCTION cogo.trg_projects_outbox();
```

### Migration checklist

- Identify and stop any agent writes to `public.*`
- Create/augment `cogo.*` canonical tables and indexes (agent/platform scope)
- Introduce `cogo.project_updates` outbox (already defined) and build projection worker
- Keep IDE/Starter reads on `public.*` (RLS), write only via user sessions
- Remove any legacy compatibility views once projection is authoritative


