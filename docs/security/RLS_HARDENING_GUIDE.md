## RLS Hardening Guide (Jobs / Artifacts / Workers)

This guide proposes production-ready Row Level Security (RLS) policies to replace the current DEV-open policies. Apply after E2E readiness and CI coverage are stable.

### Principles
- Realtime/Broadcast: use publishable key.
- DB/Storage writes: use service role key on trusted servers/workers only.
- Clients must not arbitrarily insert `jobs` or write `artifacts`.

### Roles (suggested)
- service: trusted backend/workers (Edge Functions, server, worker processes).
- client: untrusted frontends.

### Rollout Steps
1) Keep current DEV-open policies until production freeze.
2) Create production policies alongside (disabled comment block).
3) Switch by dropping DEV-open and enabling production policies.
4) NOTE: Per product decision, this step will be executed right before public launch. See `docs/LAUNCH_CHECKLIST.md`.

### SQL Template (apply in SQL Editor)

```sql
-- 1) Enable RLS (already enabled in dev schema)
alter table public.jobs enable row level security;
alter table public.artifacts enable row level security;
alter table public.worker_devices enable row level security;
alter table public.worker_heartbeats enable row level security;

-- 2) Drop DEV-open policies if exist
drop policy if exists dev_open_jobs on public.jobs;
drop policy if exists dev_open_artifacts on public.artifacts;
drop policy if exists dev_open_worker_devices on public.worker_devices;
drop policy if exists dev_open_worker_heartbeats on public.worker_heartbeats;

-- 3) Production policies (example)
-- NOTE: Replace `auth.role()` checks with your actual role/claim mapping
-- Option A: service-only write, public read (adjust to your needs)

-- Jobs
create policy jobs_read_public on public.jobs for select using (true);
create policy jobs_insert_service on public.jobs for insert to authenticated using (auth.role() = 'service') with check (auth.role() = 'service');
create policy jobs_update_service on public.jobs for update to authenticated using (auth.role() = 'service');
create policy jobs_delete_service on public.jobs for delete to authenticated using (auth.role() = 'service');

-- Artifacts
create policy artifacts_read_public on public.artifacts for select using (true);
create policy artifacts_insert_service on public.artifacts for insert to authenticated using (auth.role() = 'service') with check (auth.role() = 'service');
create policy artifacts_update_service on public.artifacts for update to authenticated using (auth.role() = 'service');
create policy artifacts_delete_service on public.artifacts for delete to authenticated using (auth.role() = 'service');

-- Worker devices / heartbeats (usually service-only)
create policy worker_devices_rw_service on public.worker_devices for all to authenticated using (auth.role() = 'service') with check (auth.role() = 'service');
create policy worker_heartbeats_rw_service on public.worker_heartbeats for all to authenticated using (auth.role() = 'service') with check (auth.role() = 'service');

-- If you use org/user scoping, add additional predicates (e.g., executor_id, user_id) instead of `true`.
```

### Testing
- Run CI integration suite with service key available.
- Verify that anon client cannot insert into `jobs` or `artifacts` anymore.
- Ensure workers (service role) still function end-to-end.

### Rollback
- Recreate DEV-open policies if needed during investigation:
```sql
create policy dev_open_jobs on public.jobs for all using (true) with check (true);
create policy dev_open_artifacts on public.artifacts for all using (true) with check (true);
create policy dev_open_worker_devices on public.worker_devices for all using (true) with check (true);
create policy dev_open_worker_heartbeats on public.worker_heartbeats for all using (true) with check (true);
```


