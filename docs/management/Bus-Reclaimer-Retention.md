## Bus Reclaimer & Retention Policy

### Reclaimer
- Stuck criterion: status=claimed and `claimed_at` older than 180s, no recent progress → re-queue
- Action:
  - Set `status=queued`, increment `attempts`, clear `claimed_by/claimed_at`, set `retry_at=now`
  - Emit `reclaimed` event in `bus_events`
- Schedule: every 1 minute (CronJob)

### Retry/Backoff (reference)
- Max attempts: 3 (executor/codegen/buildtest/sandbox)
- Base backoff: 5s, exponential, capped at 60s

### Retention
- Hard delete older rows by table:
  - `agent_messages`: 7 days
  - `bus_events`: 14 days
  - `jobs`: 7 days
  - `worker_heartbeats`: 2 days
- Run at 03:00 daily
- Exceptions: Skip deletion for rows part of traces updated within last 24h (future enhancement)

### DLQ
- Table: `agent_messages_dlq(orig_id, service, role, shard, attempts, reason, payload, created_at)`
- Movement rule: `status=failed` and `attempts>=3`
- Recovery: Replay tool reads DLQ and re-enqueues with new `trace_id`

### Scripts
- `src/scripts/ops/reclaimStuckMessages.ts`
- `src/scripts/ops/retentionCleanup.ts`
- `src/scripts/ops/moveToDlq.ts`


