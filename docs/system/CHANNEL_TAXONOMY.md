# Realtime Channel & Presence Taxonomy

- agents:{agentId}
  - broadcast: task.assign, task.result, task.error
  - presence: agent status (idle|busy|error), worker meta
- jobs:{jobId}
  - broadcast: job.progress, job.done, job.error (mirrors DB job_events)
- system:events
  - broadcast: bus mirror (subset), deployment signals, rate-limit alerts

Presence fields
- agent_id, role, shard, status(idle|busy|error), exe_pid, last_heartbeat

Conventions
- All payloads SHOULD include trace_id when available
- job.progress: { pct?: number, detail?: string, ts }
- job.done: { status: succeeded|failed, ts }
