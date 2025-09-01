# Distributed Agent – Next Steps Plan

## Overview
This document captures the next recommended development batches for the distributed agent system. It focuses on orchestrator decision quality, executor/sandbox standardization, RAG integration, scaling signals, security/policy hardening, DLQ/replay operations, and CI gate reinforcement.

## Batch A: Orchestrator Decision Quality
- Goals
  - Explainable decisions (scores/reasons), canary, idempotency keys
- Tasks
  - Record candidate scores/reasons in `bus_events` (orchestrate_*)
  - Use `registry_agents.canary_pct` to route canary traffic
  - Standardize `idempotency_key` on messages
  - Extend event payload: `tenant`, `intent`, `attempts`
- Verification
  - `/api/metrics/orchestrator/summary` exposes by-intent/by-tenant aggregates
  - `scenario:full` PASS

## Batch B: Executor Pipeline (Distributed)
- Goals
  - Standardize Orchestrator→Executor→BuildTest on Supabase Realtime
- Tasks
  - Normalize message schema (accept/ack/status/trace propagation)
  - Retry/circuit keys: `executor.execute.{shard}`
- Verification
  - End-to-end artifacts created from executor path
  - `bus_events` contains normalized transitions

## Batch C: Sandbox (WebSocket) Integration
- Goals
  - Only websocket sandbox worker, standard limits
- Tasks
  - Enforce `sandbox_limits.json` (time/size/network)
  - On failure, write `error.json` with `trace_id`/reason
  - DLQ on repeated failures
- Verification
  - Limit violations produce correct artifacts and DLQ entries
  - `alerts:evaluate` triggers when thresholds exceeded

## Batch D: RAG/GraphRAG Workflow
- Goals
  - ChatGateway→RAG→Orchestrator cohesion with trace/idem/tenant
- Tasks
  - Standardize RAG query schema, artifacts for indexing/graph
  - Retry policy for `rag.query`
- Verification
  - `/api/metrics/summary` shows RAG success rate/latency
  - Multi-query scenario aggregated in artifacts

## Batch E: Scale/Sharding & Autoscale Signals
- Goals
  - Shard-aware routing and backlog-based scale signals
- Tasks
  - Enforce shard labeling
  - Expose backlog metrics (queued/claimed/latency)
  - Google Chat alert `scale_suggested` when thresholds exceed
- Verification
  - Load tests produce scale suggestion alerts
  - Summary API includes backlog/worker health

## Batch F: Security/Policy (Ops Mode)
- Goals
  - Non-GET admin token guard, route policies deny-by-default
- Tasks
  - `REQUIRE_ADMIN_FOR_NON_GET=true` in ops/CI; `x-admin-token` required
  - Policy reload audit events in `bus_events`
- Verification
  - Unauthorized non-GET returns 401
  - Policy reload events recorded

## Batch G: Reliability/Recovery (DLQ)
- Goals
  - Operational replay flow and tooling
- Tasks
  - `/api/dlq/replay` filters: tenant/intent/time window
  - `dlq:replay:smoke` idempotent and artifacted results
- Verification
  - Sample DLQ replays produce artifacts and success rate stats

## Batch H: CI Reinforcement & Scheduling
- Goals
  - Strong PR gate and scheduled ops
- Tasks
  - `CI Gate` with Supabase ON-mode branch
  - Weekly artifacts cleanup via `ops:artifacts:cleanup` (TTL configurable)
- Verification
  - PR requires `CI Gate` success
  - Scheduled cleanup logs retained

## Common Standards
- Message schema: `id`, `service/role/shard`, `tenant`, `intent`, `trace_id`, `idempotency_key`, `attempts`
- Retry policy: `configs/retry_policy.json` (backoff with cap)
- Circuit breaker: `configs/circuit_breaker.json` (key: `service.role.shard`)
- Artifacts: BuildTest/Codegen/RAG schemas with `.meta.json`
- Metrics: `/api/metrics/summary` aggregates totals, circuits, orchestrator, rag, backlog

## Implementation Order
1) A → B → C (core execution path) → D (RAG) → E (scale) → F (security) → G (recovery) → H (CI)
2) After each batch: `npm run -s scenario:full`, `npm run -s scenario:docker`, `npm run -s gate:unified`
3) Failures trigger alerts and are captured by artifacts/events

## Acceptance Criteria
- Gate: lint 0, build/test OK, Supabase ON-mode → orchestrator events > 0
- Failure/Open-circuit thresholds within limits (`MIN_FAIL_RATE`, `CIRCUITS_MAX`)
- Security: non-GET without token → 401; deny-by-default effective
- DLQ: replay success tracked and artifacted
