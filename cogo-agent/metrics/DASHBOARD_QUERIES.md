## Metrics Dashboard Queries (Supabase SQL)

Use these queries to build a minimal metrics dashboard (validate pass rate, latency, generation throughput) based on `public.bus_events`.

### 1) Validate pass rate (by day)
```sql
select
  date_trunc('day', created_at) as day,
  avg( (payload->>'validate_ok')::boolean::int ) as pass_rate,
  count(*) as total
from public.bus_events
where event_type = 'json.validate_result'
group by 1
order by 1 desc
limit 30;
```

### 2) Generation latency percentiles (ms)
```sql
select
  date_trunc('hour', created_at) as hour,
  percentile_disc(0.50) within group (order by (payload->>'gen_ms')::numeric) as p50_ms,
  percentile_disc(0.95) within group (order by (payload->>'gen_ms')::numeric) as p95_ms,
  count(*) as n
from public.bus_events
where event_type = 'json.generate_done'
group by 1
order by 1 desc
limit 48;
```

### 3) Chat pipeline throughput (handoff per hour)
```sql
select
  date_trunc('hour', created_at) as hour,
  count(*) as handoffs
from public.bus_events
where event_type = 'chat.handoff'
group by 1
order by 1 desc
limit 48;
```

### 4) Error breakdown (last 24h)
```sql
select
  event_type,
  count(*) as n
from public.bus_events
where created_at > now() - interval '24 hours'
  and (event_type like '%.failed' or event_type in ('error','handoff_failed'))
group by 1
order by n desc;
```

### 5) Recent traces
```sql
select
  message_id as trace_id,
  min(created_at) as first_seen,
  max(created_at) as last_seen,
  count(*) as events
from public.bus_events
where created_at > now() - interval '24 hours'
group by 1
order by last_seen desc
limit 50;
```

### 6) Orchestrator tick health (Node worker)
```sql
select
  date_trunc('minute', created_at) as minute,
  avg((payload->'metrics'->>'tick_ms')::numeric) as avg_tick_ms,
  sum(case when (payload->'metrics'->>'tick_ok')::boolean then 1 else 0 end) as ok_count,
  sum(case when coalesce((payload->'metrics'->>'tick_failed'),'false')::boolean then 1 else 0 end) as fail_count,
  count(*) as total
from public.bus_events
where event_type = 'metrics.ingest'
  and coalesce(payload->'tags'->>'runner','') = 'orchestrator-node'
  and created_at > now() - interval '24 hours'
group by 1
order by 1 desc
limit 120;
```

### 7) DLQ retry outcomes (Node worker)
```sql
select
  date_trunc('minute', created_at) as minute,
  sum(case when (payload->'metrics'->>'dlq_retry_ok')::boolean then 1 else 0 end) as ok,
  sum(case when coalesce((payload->'metrics'->>'dlq_retry_ok'),'false')::boolean then 0 else 1 end) as fail,
  count(*) as total
from public.bus_events
where event_type = 'metrics.ingest'
  and coalesce(payload->'tags'->>'runner','') = 'orchestrator-node'
  and coalesce(payload->'tags'->>'kind','') = 'dlq-retry'
  and created_at > now() - interval '24 hours'
group by 1
order by 1 desc
limit 120;
```

### 8) ETag regression status (aggregator)
```sql
select
  date_trunc('hour', created_at) as hour,
  avg(case when (payload->'metrics'->>'etag_regression_ok')::boolean then 1 else 0 end) as ok_rate,
  count(*) as runs
from public.bus_events
where event_type = 'metrics.ingest'
  and coalesce(payload->'tags'->>'runner','') = 'etag-regression'
  and created_at > now() - interval '7 days'
group by 1
order by 1 desc
limit 168;
```

### 9) PRD precondition enforcement rates (412/428)
```sql
select
  date_trunc('hour', created_at) as hour,
  avg(case when coalesce((payload->'metrics'->>'prd_if_match_412'),'false')::boolean then 1 else 0 end) as if_match_412_rate,
  avg(case when coalesce((payload->'metrics'->>'prd_missing_if_match_428'),'false')::boolean then 1 else 0 end) as missing_if_match_428_rate,
  count(*) as runs
from public.bus_events
where event_type = 'metrics.ingest'
  and coalesce(payload->'tags'->>'runner','') = 'prd-preconditions'
  and created_at > now() - interval '7 days'
group by 1
order by 1 desc
limit 168;
```

### 10) ETag 304 hit rates by endpoint (aggregator details)
```sql
select
  date_trunc('hour', created_at) as hour,
  avg(case when (payload->'metrics'->>'json_get_304')::boolean then 1 else 0 end) as json_get_304_rate,
  avg(case when coalesce((payload->'metrics'->>'json_list_304'),'false')::boolean then 1 else 0 end) as json_list_304_rate,
  avg(case when coalesce((payload->'metrics'->>'artifacts_list_304'),'false')::boolean then 1 else 0 end) as artifacts_list_304_rate,
  avg(case when coalesce((payload->'metrics'->>'trace_status_304'),'false')::boolean then 1 else 0 end) as trace_status_304_rate,
  count(*) as runs
from public.bus_events
where event_type = 'metrics.ingest'
  and coalesce(payload->'tags'->>'runner','') = 'etag-regression'
  and created_at > now() - interval '7 days'
group by 1
order by 1 desc
limit 168;
```

### 11) Chat RAG usage and latency
```sql
select
  date_trunc('hour', created_at) as hour,
  avg((payload->'payload'->>'contexts')::numeric) as avg_contexts,
  avg((payload->'payload'->>'retrieval_ms')::numeric) as avg_retrieval_ms,
  sum(case when coalesce(payload->'payload'->>'retrieval_strategy','') <> '' then 1 else 0 end) as rag_used,
  count(*) as handoffs
from public.bus_events
where event_type = 'chat.handoff'
  and created_at > now() - interval '7 days'
group by 1
order by 1 desc
limit 168;
```

### 12) JSON generate RAG/build metrics
```sql
select
  date_trunc('hour', created_at) as hour,
  avg(coalesce((payload->'payload'->>'retrieval_ms')::numeric, 0)) as avg_retrieval_ms,
  avg(coalesce((payload->'payload'->>'build_ms')::numeric, 0)) as avg_build_ms,
  avg(case when coalesce(payload->'payload'->>'rag_strategy','none') <> 'none' then 1 else 0 end) as rag_used_rate,
  count(*) as runs
from public.bus_events
where event_type = 'json.generate_done'
  and created_at > now() - interval '7 days'
group by 1
order by 1 desc
limit 168;
```

### 13) RAG endpoint latency (events)
```sql
select
  date_trunc('hour', created_at) as hour,
  avg(coalesce((payload->'payload'->>'latency_ms')::numeric, 0)) as avg_rag_latency_ms,
  count(*) as calls
from public.bus_events
where event_type in ('rag.done')
  and created_at > now() - interval '7 days'
group by 1
order by 1 desc
limit 168;
```

### 14) KG upsert outcomes (Node worker)
```sql
select
  date_trunc('hour', created_at) as hour,
  sum(case when coalesce((payload->'metrics'->>'kg_upsert_ok'),'false')::boolean then 1 else 0 end) as ok,
  sum(case when coalesce((payload->'metrics'->>'kg_upsert_ok'),'false')::boolean then 0 else 1 end) as fail,
  count(*) as total
from public.bus_events
where event_type = 'metrics.ingest'
  and coalesce(payload->'tags'->>'runner','') = 'kg-node'
  and created_at > now() - interval '7 days'
group by 1
order by 1 desc
limit 168;
```

### 15) Quality gates (RAG/KG)
```sql
select
  date_trunc('hour', created_at) as hour,
  avg((payload->'metrics'->>'rag_p95_ms')::numeric) as rag_p95_avg,
  avg((payload->'metrics'->>'kg_fail_rate')::numeric) as kg_fail_rate_avg,
  avg(case when (payload->'metrics'->>'gates_ok')::boolean then 1 else 0 end) as gates_pass_rate,
  count(*) as runs
from public.bus_events
where event_type = 'metrics.ingest'
  and coalesce(payload->'tags'->>'runner','') = 'quality-gates'
  and created_at > now() - interval '7 days'
group by 1
order by 1 desc
limit 168;
```


