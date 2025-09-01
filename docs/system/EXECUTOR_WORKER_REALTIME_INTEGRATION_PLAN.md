
# Executor ↔ Worker Realtime Integration Plan (Supabase-first, Hybrid)

## 1) Executive Summary
- Goal: Connect Executor and Workers via Supabase Realtime (control plane) with Storage for artifacts (data plane), enabling any machine (user PC, secure server, cloud node) to join as a Worker without Docker requirements.
- Why: NAT-friendly, simplified ops/security, unified SDK (TS/Python), consistent RBAC/RLS.
- Scope includes Python Sandbox Worker, Figma MCP Worker, Browser MCP Worker, and TypeScript Executor integration with Orchestrator.

## 2) Architecture Overview
- Control-plane: Supabase Realtime Channels for assignment, cancellation, progress, heartbeat, logs (small).
- Data-plane: Supabase Storage for large artifacts via presigned URLs; optional DB-CDC for state transitions.
- Optional high-performance path: Direct WebSocket only for special streaming workloads (not in v1 scope).

### Channels (recommended naming)
- executor:<executorId>:tasks — task assignment/cancel broadcasts.
- worker:<workerId>:events — worker results, progress, logs, errors, heartbeats.
- fleet:workers:presence — presence/online workers aggregation.
- job:<jobId> — optional per-job channel for step-by-step events.

### Message Types
- task.assign, task.cancel, task.progress, task.result, task.error, heartbeat.
- Common headers: messageId, correlationId, producerId, sentAt, attempt, idempotencyKey.

## 3) Data Model (Supabase)
- jobs (source of truth)
  - id (uuid, pk), type (text), status (enum: queued|assigned|running|succeeded|failed|cancelled),
    executor_id (text), worker_id (text), payload (jsonb), result (jsonb), error (jsonb),
    idempotency_key (text unique), attempts (int), created_at/updated_at (timestamptz)
- worker_devices
  - worker_id (text, pk), display_name (text), device_fingerprint (text), role (text),
    capabilities (jsonb), last_seen_at (timestamptz), created_at
- worker_heartbeats
  - worker_id (text), ts (timestamptz), metrics (jsonb)
- artifacts
  - id (uuid, pk), job_id (uuid), name (text), mime (text), size (int), sha256 (text), url (text), created_at
- RLS: workers can only see their jobs; executors can see assigned jobs; tenancy keys in row filters.

## 4) Security & Enrollment
- Edge Function POST /devices/enroll → returns Worker JWT bound to device_fingerprint and scopes.
- Roles: worker, executor, with scoped channels (channel names include workerId/executorId).
- Secrets: stored centrally; per-job injected minimal subset.
- Audit: job status changes, artifact access, and channel events logged.

## 5) SDKs (Minimal v1)
### TypeScript SDK (Agent side)
- File: src/services/realtime/WorkerLink.ts (to be implemented)
- Functions: connectPresence(), assignTask(job), awaitResult(jobId, timeout), heartbeat(), sendLog(jobId, msg)
- Behavior: reconnect with backoff; idempotency on assign; verifies DB state after Realtime events.

### Python SDK (Worker side)
- File: cogo-worker/realtime_link.py (to be implemented)
- Functions: connect(worker_id), on_task(cb), send_result(job_id, result), send_error(job_id, err), heartbeat(metrics)
- Behavior: subscribes to executor:*:tasks filtered by capability; posts results to worker:<id>:events + updates jobs.

## 6) Workers in Scope
### A) Python Sandbox Worker
- Capabilities: compute/basic, python/sandbox.
- Handlers: calc.add, calc.mul, python.exec (restricted).
- Sandbox: venv, limited syscalls (soft), optional egress limit.

### B) Figma MCP Worker
- Base: existing mcp-servers/figma-context.
- Capabilities: mcp/figma.
- Tasks: figma.get_file, figma.list_components, figma.export_assets (result artifacts to Storage).
- Auth: Figma token via secrets; outputs presigned URLs.

### C) Browser MCP Worker
- Base: existing mcp-servers/browser-use.
- Capabilities: mcp/browser.
- Tasks: browser.navigate, browser.screenshot, browser.extract.
- Headless; screenshots/upload → artifacts.

## 7) Executor/Agent Integration
- IntegratedDistributedExecutorAgent uses TS SDK to assign jobs and await results.
- Capability matching: job requirements (e.g., mcp/figma) → presence-filtered worker pool.
- Orchestrator integration: if task.type=execution → map to job spec, set idempotencyKey, schedule via Realtime.

## 8) Testing Strategy (E2E)
- v0 Calc PoC: calc.add(2,3) result=5 through Realtime; metrics: RTT p50/p95.
- v0.1 Artifacts: Browser screenshot → Storage upload (presigned) → artifact recorded in DB.
- v0.2 Figma: get_file metadata + small export asset upload.
- Failure cases: timeout, retry, duplicate delivery (idempotency), worker disconnect.

## 9) Observability
- /health includes Realtime connectivity + worker presence counts.
- /metrics (later): counters for jobs queued/assigned/succeeded/failed, latency histograms.
- Structured logs with correlationId.

## 10) Rollout Plan (Phased)
- Phase 1 (1–2 days):
  - Create tables (jobs, worker_devices, artifacts, worker_heartbeats) and RLS.
  - TS/Python minimal SDK (heartbeat + task.assign/result + backoff).
  - Calc PoC E2E green.
- Phase 2 (2–3 days):
  - Artifacts via Storage presigned URL; Browser MCP screenshot demo.
  - Executor capability-based scheduling + presence filter.
- Phase 3 (2–3 days):
  - Figma MCP integration (list/export) with artifacts and secrets.
  - Retry/idempotency across assign/result; job lifecycle finalized.
- Phase 4 (2 days):
  - Security hardening (Edge enroll function, scopes), audit logs, metrics surface.

## 11) Risks & Mitigations
- Ordering/duplication: use DB status with idempotency keys; Realtime as notify bus only.
- Large payload limits: move to Storage with presigned links.
- Worker flakiness: heartbeats + reassign on timeout; exponential backoff.
- Secrets leakage: centralized storage + least-privilege injection per job.

## 12) Acceptance Criteria
- Executor assigns job; at least one Worker accepts; result persisted in jobs.result; artifacts (if any) retrievable via Storage.
- Presence reflects online Workers with capabilities; Orchestrator can route based on needs.
- PoC demos: calc, browser screenshot, figma export; all via Realtime control-plane.

## 13) Deliverables Checklist
- [ ] Supabase tables & RLS ready
- [ ] TS SDK WorkerLink.ts minimal
- [ ] Python SDK realtime_link.py minimal
- [ ] Calc PoC E2E
- [ ] Storage artifacts flow + Browser MCP demo
- [ ] Figma MCP demo
- [ ] Retry/idempotency, audit events
- [ ] Docs updated (SYSTEM_ARCHITECTURE, API, Security)

---
Last updated: 2025-08-08
Owner: COGO Agent Core Team


## 14) Quickstart (Local E2E)
- Copy envs: cp .env.example .env && cp .env.worker.example .env.worker
- Terminal A (Worker - Realtime): source ./.env.worker && npm run worker:py:realtime
- Terminal B (Emulator - optional): source ./.env && npm run worker:emulator
- Terminal C (Executor test): source ./.env && npm run test:calc:e2e
Notes: Set SUPABASE_URL/KEYs before running. Use rest mode if Realtime not available.
