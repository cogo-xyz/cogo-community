-- RLS Hardening SQL Template
-- Apply in Supabase SQL Editor when switching from DEV-open to production policies.

alter table public.jobs enable row level security;
alter table public.artifacts enable row level security;
alter table public.worker_devices enable row level security;
alter table public.worker_heartbeats enable row level security;

drop policy if exists dev_open_jobs on public.jobs;
drop policy if exists dev_open_artifacts on public.artifacts;
drop policy if exists dev_open_worker_devices on public.worker_devices;
drop policy if exists dev_open_worker_heartbeats on public.worker_heartbeats;

-- Example role-based policies (adjust to your claims model)
create policy jobs_read_public on public.jobs for select using (true);
create policy jobs_insert_service on public.jobs for insert to authenticated using (auth.role() = 'service') with check (auth.role() = 'service');
create policy jobs_update_service on public.jobs for update to authenticated using (auth.role() = 'service');
create policy jobs_delete_service on public.jobs for delete to authenticated using (auth.role() = 'service');

create policy artifacts_read_public on public.artifacts for select using (true);
create policy artifacts_insert_service on public.artifacts for insert to authenticated using (auth.role() = 'service') with check (auth.role() = 'service');
create policy artifacts_update_service on public.artifacts for update to authenticated using (auth.role() = 'service');
create policy artifacts_delete_service on public.artifacts for delete to authenticated using (auth.role() = 'service');

create policy worker_devices_rw_service on public.worker_devices for all to authenticated using (auth.role() = 'service') with check (auth.role() = 'service');
create policy worker_heartbeats_rw_service on public.worker_heartbeats for all to authenticated using (auth.role() = 'service') with check (auth.role() = 'service');


