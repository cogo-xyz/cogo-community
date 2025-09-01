-- Deep Agents core tables

create table if not exists public.plans (
  plan_id uuid primary key default gen_random_uuid(),
  task_id text,
  status text not null default 'active',
  budget jsonb default '{"max_tokens":100000,"max_cost_usd":5}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.plan_steps (
  step_id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.plans(plan_id) on delete cascade,
  idx integer not null default 0,
  intent text,
  hypothesis text,
  expected_outcome text,
  assertions jsonb default '[]',
  tool_plan jsonb default '[]',
  rollback_plan text,
  confidence numeric,
  budget jsonb,
  status text not null default 'pending',
  started_at timestamptz,
  ended_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.tool_runs (
  run_id uuid primary key default gen_random_uuid(),
  step_id uuid not null references public.plan_steps(step_id) on delete cascade,
  tool text not null,
  args jsonb,
  result jsonb,
  verdict text,
  latency_ms integer,
  success boolean,
  metrics jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.critic_verdicts (
  verdict_id uuid primary key default gen_random_uuid(),
  step_id uuid not null references public.plan_steps(step_id) on delete cascade,
  critic text not null,
  verdict text not null,
  score numeric,
  checked jsonb,
  evidence jsonb,
  fixes jsonb,
  cost jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.branch_tree (
  edge_id uuid primary key default gen_random_uuid(),
  from_step_id uuid not null references public.plan_steps(step_id) on delete cascade,
  to_step_id uuid not null references public.plan_steps(step_id) on delete cascade,
  reason text,
  score numeric,
  created_at timestamptz not null default now()
);

create table if not exists public.agent_subagents (
  name text primary key,
  description text,
  prompt_template text,
  enabled boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.agent_tools (
  tool_name text primary key,
  schema jsonb,
  enabled boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.file_snapshots (
  snapshot_id uuid primary key default gen_random_uuid(),
  step_id uuid not null references public.plan_steps(step_id) on delete cascade,
  path text,
  content_hash text,
  content_preview text,
  store_ref text,
  created_at timestamptz not null default now()
);

-- Basic indexes
create index if not exists idx_plan_steps_plan on public.plan_steps(plan_id, idx);
create index if not exists idx_tool_runs_step on public.tool_runs(step_id);
create index if not exists idx_critic_verdicts_step on public.critic_verdicts(step_id);


