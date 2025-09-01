-- LLM routing metadata schema (providers/models/policies/health/usage)
-- Execute in Supabase SQL editor

create table if not exists public.llm_providers (
  id uuid primary key default gen_random_uuid(),
  provider text not null unique, -- e.g., anthropic, openai, openrouter, groq
  base_url text,
  regions jsonb default '[]'::jsonb,
  headers_template jsonb default '{}'::jsonb, -- e.g., {"authorization":"Bearer {{API_KEY}}"}
  pricing jsonb default '{}'::jsonb,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.tg_llm_updated_at()
returns trigger language plpgsql as $$ begin new.updated_at := now(); return new; end $$;

drop trigger if exists trg_llm_providers_updated on public.llm_providers;
create trigger trg_llm_providers_updated before update on public.llm_providers for each row execute function public.tg_llm_updated_at();

create table if not exists public.llm_models (
  id uuid primary key default gen_random_uuid(),
  provider text not null references public.llm_providers(provider) on update cascade,
  model text not null,
  service text not null check (service in ('chat','embeddings')),
  context_limit integer,
  default_region text,
  cost_per_1k numeric,
  enabled boolean not null default true,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(provider, model)
);

drop trigger if exists trg_llm_models_updated on public.llm_models;
create trigger trg_llm_models_updated before update on public.llm_models for each row execute function public.tg_llm_updated_at();

create table if not exists public.routing_policies (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  priority integer not null default 100,
  enabled boolean not null default true,
  match_conditions jsonb not null default '{}'::jsonb, -- e.g., {"domain_tags":["code"],"max_cost_per_1k":0.5}
  action jsonb not null default '{}'::jsonb, -- e.g., {"prefer":[{"provider":"anthropic","model":"claude-3.5-haiku"}]}
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_routing_policies_updated on public.routing_policies;
create trigger trg_routing_policies_updated before update on public.routing_policies for each row execute function public.tg_llm_updated_at();

create table if not exists public.provider_health (
  id bigserial primary key,
  provider text not null,
  region text,
  latency_ms integer,
  error_rate numeric,
  updated_at timestamptz not null default now()
);
create index if not exists idx_provider_health_key on public.provider_health(provider, region);

create table if not exists public.usage_counters (
  id bigserial primary key,
  day date not null default current_date,
  provider text not null,
  model text not null,
  tenant_id text,
  calls bigint not null default 0,
  input_tokens bigint not null default 0,
  output_tokens bigint not null default 0,
  cost numeric not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists idx_usage_counters_key on public.usage_counters(day, provider, model);

alter table public.llm_providers enable row level security;
alter table public.llm_models enable row level security;
alter table public.routing_policies enable row level security;
alter table public.provider_health enable row level security;
alter table public.usage_counters enable row level security;

-- Deny-by-default policies
do $$ begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='llm_providers') then
    create policy "llm_providers_no_access" on public.llm_providers for all using (false) with check (false);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='llm_models') then
    create policy "llm_models_no_access" on public.llm_models for all using (false) with check (false);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='routing_policies') then
    create policy "routing_policies_no_access" on public.routing_policies for all using (false) with check (false);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='provider_health') then
    create policy "provider_health_no_access" on public.provider_health for all using (false) with check (false);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='usage_counters') then
    create policy "usage_counters_no_access" on public.usage_counters for all using (false) with check (false);
  end if;
end $$;

comment on table public.llm_providers is 'LLM providers metadata and defaults';
comment on table public.llm_models is 'LLM models catalog with service/chat/embeddings and limits';
comment on table public.routing_policies is 'Routing policy rules (match/action)';
comment on table public.provider_health is 'Latency and error health per provider/region';
comment on table public.usage_counters is 'Daily usage/cost counters';


