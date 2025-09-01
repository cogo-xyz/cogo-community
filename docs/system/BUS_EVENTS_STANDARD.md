# Bus Events Standard

## Event types
- job.*
  - job.progress { job_id, pct?: number, detail?: string, ts, trace_id }
  - job.succeeded { job_id, result?, ts, trace_id }
  - job.failed { job_id, error, ts, trace_id }
  - job.sse.open|done|abort|stop { job_id, ts, trace_id }
- research.*, indexing.*, build.*, execute.*
  - research.enqueue, research.partial, research.done
  - indexing.done, build.done, execute.done

## Fields
- Required cols: event_type, service, role, shard, message_id, payload(jsonb), created_at
- Payload SHOULD include trace_id when available

## Retention & Views
- Retain raw bus_events 7~14 days
- Reporting views: sse open/done/abort/stop ratios per hour/day
