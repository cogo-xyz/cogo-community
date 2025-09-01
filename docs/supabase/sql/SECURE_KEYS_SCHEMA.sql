-- Secure key storage (dev: plaintext, prod: ciphertext)
-- Execute in Supabase SQL editor

create table if not exists public.secure_keys (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  provider text null,
  service text null,
  env text not null default 'dev',
  is_encrypted boolean not null default false,
  plaintext text null,
  ciphertext text null,
  scopes jsonb null default '[]'::jsonb,
  metadata jsonb null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_secure_keys_env on public.secure_keys(env);

-- Trigger to update updated_at
create or replace function public.tg_secure_keys_updated_at()
returns trigger as $$
begin
  new.updated_at := now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_secure_keys_updated_at on public.secure_keys;
create trigger trg_secure_keys_updated_at
before update on public.secure_keys
for each row execute function public.tg_secure_keys_updated_at();

-- RLS
alter table public.secure_keys enable row level security;

-- Deny by default
drop policy if exists "secure_keys_no_access" on public.secure_keys;
create policy "secure_keys_no_access" on public.secure_keys
  for all using (false) with check (false);

-- Allow service role (Edge Functions) full access
-- Supabase service role bypasses RLS by design; no extra policy needed.

-- Helper view for safe projection (hides ciphertext by default)
create or replace view public.secure_keys_safe as
select id, name, provider, service, env, is_encrypted,
       case when is_encrypted then null else plaintext end as plaintext,
       created_at, updated_at
from public.secure_keys;

comment on table public.secure_keys is 'Centralized key storage. Dev: plaintext, Prod: ciphertext via Edge Function.';

