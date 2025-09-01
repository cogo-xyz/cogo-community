## Migration: public direct writes → cogo CQRS with Projection

Date: 2025-08-25

### Phase 0 – Inventory
- List all tables written by IDE/Starter (public.*)
- Identify any agent services writing to public.* and stop them

### Phase 1 – Foundation
- Create `cogo.*` canonical tables and indexes required by agents
- Deploy `cogo.project_updates` outbox (done)

### Phase 2 – Projection Worker
- Implement worker to consume outbox → upsert into public.*
- Add retries, backoff, DLQ

### Phase 3 – Cutover
- IDE/Starter continue to read/write public.* (RLS)
- Agents write only to cogo.* and enqueue outbox events
- Remove any legacy views bridging cogo→public

### Phase 4 – Hardening
- RLS audit for public.*
- Add idempotency & unique keys for projection targets
- Add metrics and alerts

### Validation
- E2E tests: figma ingest → outbox → projection → IDE render
- Chat/Embed: ensure cogo updates do not bypass projection
