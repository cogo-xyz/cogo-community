## Idempotency Store (Proposal)

### DDL (cogo schema)
```sql
create table if not exists cogo.idempotency_keys (
  key text primary key,
  created_at timestamptz not null default now(),
  ttl_sec integer not null default 300
);
-- Optional: auto-expire job (via cron/pg-bgw)
-- delete from cogo.idempotency_keys where created_at < now() - (ttl_sec || ' seconds')::interval;
```

### Usage
- On write endpoints, attempt insert(key). Duplicate violation → already processed.
- TTL is advisory for cleanup.


