-- Upgrade script for secure key management (embedding/LLM friendly)
-- Run after SECURE_KEYS_SCHEMA.sql

-- Columns for rich key identification and lifecycle
alter table public.secure_keys
  add column if not exists category text default 'service',
  add column if not exists key_type text default 'api_key',
  add column if not exists alias text,
  add column if not exists version_int integer not null default 1,
  add column if not exists status text not null default 'active', -- active|disabled|expired|revoked
  add column if not exists region text,
  add column if not exists resource text, -- e.g., model name like 'text-embedding-3-large', 'bge-m3'
  add column if not exists project text,
  add column if not exists tenant_id text,
  add column if not exists not_before_at timestamptz,
  add column if not exists expires_at timestamptz,
  add column if not exists last_used_at timestamptz,
  add column if not exists usage_count bigint not null default 0,
  add column if not exists rate_limit_per_minute integer,
  add column if not exists daily_quota integer,
  add column if not exists allowed_models jsonb default '[]'::jsonb,
  add column if not exists checksum_sha256 text;

-- Uniqueness and lookup indexes
create unique index if not exists uq_secure_keys_alias_env on public.secure_keys(alias, env) where alias is not null;
create index if not exists idx_secure_keys_lookup on public.secure_keys(provider, service, resource, env, status, version_int desc);
create index if not exists idx_secure_keys_status on public.secure_keys(status);

-- Audit log table
create table if not exists public.secure_keys_audit (
  id bigserial primary key,
  key_id uuid,
  name text,
  env text,
  event text not null, -- read|write|rotate|delete
  actor text,
  ip text,
  user_agent text,
  trace_id text,
  created_at timestamptz not null default now(),
  details jsonb default '{}'::jsonb
);
create index if not exists idx_secure_keys_audit_key on public.secure_keys_audit(key_id);

comment on table public.secure_keys_audit is 'Access and mutation audit trail for secure_keys.';


