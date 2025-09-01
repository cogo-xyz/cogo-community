-- Minimal table for service thresholds (project-scoped)
-- Safe to run in Supabase SQL editor

create table if not exists public.service_thresholds (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null,
  service_key text not null, -- e.g., 'variables_derive', 'symbols_map', '__chat__'
  kind text, -- optional: 'uui' | 'chat'
  p95 numeric, -- milliseconds
  error_rate numeric, -- 0..1
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_service_thresholds_project on public.service_thresholds(project_id);
create index if not exists idx_service_thresholds_key on public.service_thresholds(service_key);

-- Upsert helper example
-- insert into public.service_thresholds (project_id, service_key, kind, p95, error_rate)
-- values ('00000000-0000-0000-0000-000000000000', 'variables_derive', 'uui', 8000, 0.1)
-- on conflict (id) do nothing;


