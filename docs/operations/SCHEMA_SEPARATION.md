## Supabase Schema Separation Guide

This guide defines the schema separation policy for the COGO project and the safe migration runbook. It clarifies what belongs in `cogo.*` vs `public.*`, how to expose read-only views, and how to verify state.

### Objectives
- Keep agent-internal operational data in `cogo.*`.
- Keep end-user/project data in `public.*`.
- Avoid name collisions in `public` by using opt-in views with the `cogo_` prefix.
- Make all migrations idempotent and reversible.

### Policy
- **`cogo` schema**: Agent operational tables only, e.g. `cogo.symbols`, `cogo.actionflows`, `cogo.actionflow_runs`, allowlist, error logs, metrics snapshots. Must not contain end-user project content.
- **`public` schema**: End-user/project application tables (e.g., original `public.symbols`). Optional, read-only views over `cogo.*` with non-conflicting names:
  - `public.cogo_symbols`
  - `public.cogo_actionflows`
  - `public.cogo_actionflow_runs`
- **View naming**: Always prefix with `cogo_` when exposing `cogo.*` to `public` (never redefine `public.symbols`).

### Compatibility
- Edge Functions: No direct dependency on legacy `public.symbols`/`public.actionflows`/`public.actionflow_runs`. Removing legacy public views does not impact them.
- Application code should not rely on legacy `public.symbols`. If needed, consume `public.cogo_*` views or RPCs.

### Migration Runbook (Idempotent)

```sql
-- 1) Detect current state (public side)
select c.relkind, n.nspname, c.relname
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in ('symbols','actionflows','actionflow_runs');

-- backups present?
select relname
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname='public'
  and c.relname ~ '^(symbols|actionflows|actionflow_runs)_table_backup_'
order by relname;

-- cogo side
select c.relkind, n.nspname, c.relname
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'cogo'
  and c.relname in ('symbols','actionflows','actionflow_runs');
```

```sql
-- 2) Restore original public tables (if replaced by views)
do $$
declare
  r text;
begin
  -- symbols
  if exists (
    select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname='public' and c.relname='symbols' and c.relkind='v'
  ) then
    execute 'drop view public.symbols';
  end if;
  select relname into r
  from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname='public' and c.relname ~ '^symbols_table_backup_'
  order by relname desc limit 1;
  if r is not null and not exists (
    select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname='public' and c.relname='symbols' and c.relkind<>'v'
  ) then
    execute format('alter table public.%I rename to symbols', r);
  end if;

  -- actionflows
  if exists (
    select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname='public' and c.relname='actionflows' and c.relkind='v'
  ) then
    execute 'drop view public.actionflows';
  end if;
  select relname into r
  from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname='public' and c.relname ~ '^actionflows_table_backup_'
  order by relname desc limit 1;
  if r is not null and not exists (
    select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname='public' and c.relname='actionflows' and c.relkind<>'v'
  ) then
    execute format('alter table public.%I rename to actionflows', r);
  end if;

  -- actionflow_runs
  if exists (
    select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname='public' and c.relname='actionflow_runs' and c.relkind='v'
  ) then
    execute 'drop view public.actionflow_runs';
  end if;
  select relname into r
  from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname='public' and c.relname ~ '^actionflow_runs_table_backup_'
  order by relname desc limit 1;
  if r is not null and not exists (
    select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname='public' and c.relname='actionflow_runs' and c.relkind<>'v'
  ) then
    execute format('alter table public.%I rename to actionflow_runs', r);
  end if;
end $$;
```

```sql
-- 3) Create non-conflicting public views (opt-in)
create schema if not exists cogo;

create or replace view public.cogo_symbols as
  select id, created_at, project_uuid, type, key, binding
  from cogo.symbols;

create or replace view public.cogo_actionflows as
  select id, created_at, project_uuid, flow_id, version, flow, meta
  from cogo.actionflows;

create or replace view public.cogo_actionflow_runs as
  select id, created_at, project_uuid, trace_id, flow_ref, status, vars, result, error
  from cogo.actionflow_runs;

comment on view public.cogo_symbols is 'Read-only view of cogo.symbols for platform/IDE consumption';
comment on view public.cogo_actionflows is 'Read-only view of cogo.actionflows for platform/IDE consumption';
comment on view public.cogo_actionflow_runs is 'Read-only view of cogo.actionflow_runs for platform/IDE consumption';
```

```sql
-- 4) Verify state
select table_schema, table_name
from information_schema.views
where table_schema='public'
  and table_name in ('cogo_symbols','cogo_actionflows','cogo_actionflow_runs');

select c.relkind, n.nspname, c.relname
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname='public'
  and c.relname in ('symbols','actionflows','actionflow_runs');

select
  (select count(*) from cogo.symbols) as cogo_symbols_count,
  (select count(*) from public.cogo_symbols) as view_symbols_count,
  (select count(*) from cogo.actionflows) as cogo_actionflows_count,
  (select count(*) from public.cogo_actionflows) as view_actionflows_count,
  (select count(*) from cogo.actionflow_runs) as cogo_runs_count,
  (select count(*) from public.cogo_actionflow_runs) as view_runs_count;
```

```text
5) Disable legacy conflicting migration
- File: supabase/sql/2025-08-25_cogo_symbols_actionflow_fix_views.sql
- Action: converted to a NO-OP so it will not rename/overwrite any public.* tables going forward.
```

### Security Hardening (post-development)
- Enable RLS on `cogo.*` and restrict direct table access to service roles.
- Revoke default `public`/`anon`/`authenticated` access to `cogo.*` tables.
- Optionally set `security_barrier = true` on `public.cogo_*` views.
- Grant `SELECT` on `public.cogo_*` views only to roles that need read access.

### Operations
- Idempotency: All statements above are safe to re-run.
- Rollback: Drop `public.cogo_*` views to remove public exposure. If a legacy view overwrote a table, restore from the latest `*_table_backup_*` and recreate views.
- Environments: Apply in staging first, then production. Commit DDL as migrations.

### Troubleshooting
- `public.symbols` still a view: Re-run restoration (Step 2) and ensure a `symbols_table_backup_*` exists.
- Permission errors: Check grants/RLS and ensure clients read via `public.cogo_*` if needed.
- Edge functions: Not affected unless they explicitly referenced the legacy public tables/views.

### Change Log
- 2025-08-29: Initial policy documented; legacy conflicting migration disabled; `public.cogo_*` views established.
