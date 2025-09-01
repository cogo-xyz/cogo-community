## Projection Worker Spec (cogo → public)

Date: 2025-08-25

### Purpose
- Consume `cogo.project_updates` outbox
- Materialize user-facing denormalized records into `public.*`

### Inputs
- Table: `cogo.project_updates`
  - status: pending|processing|failed|done
  - event_type: project.upsert|page.upsert|component.upsert|actionflow.upsert|symbol.upsert
  - payload: minimal change-set or full snapshot

### Processing
- Lease N oldest `pending` by `occurred_at` with `FOR UPDATE SKIP LOCKED`
- Set `status=processing`, `next_attempt_at=NULL`
- Upsert into `public.*` based on `event_type`
- Set `status=done` on success

### Retries & Backoff
- On failure: increment `retries`, set `status=pending`, `next_attempt_at=now()+interval '2^retries minutes'` (cap)
- Move to DLQ after MAX_RETRIES

### Idempotency
- Use `(project_uuid, payload->>'entity_id', event_type, payload->>'version')` as idempotent key
- Maintain idempotency ledger table (optional) or rely on natural uniques in `public.*`

### Security
- Runs with service role; writes only to `public.*`
- Reads `cogo.*`

### Observability
- Emit bus events: start/success/failure
- Metrics: processed/s, failures, retries, p95 lat

### Notes
- Keep payload shape aligned with IDE read models
