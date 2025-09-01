-- Extend routing_policies with lifecycle and merge strategy
alter table public.routing_policies
  add column if not exists description text,
  add column if not exists valid_from timestamptz,
  add column if not exists valid_to timestamptz,
  add column if not exists merge_strategy text not null default 'first_match' check (merge_strategy in ('first_match','priority_merge','all_match'));

create index if not exists idx_routing_policies_valid on public.routing_policies((coalesce(valid_from, 'epoch'::timestamptz)), (coalesce(valid_to, 'infinity'::timestamptz)));


