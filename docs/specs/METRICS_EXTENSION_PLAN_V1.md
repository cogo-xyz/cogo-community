## Metrics Extension Plan v1 (Reliability & Observability)

Objective
- Define concrete metrics, names, labels, and endpoints to cover scheduling, execution, retries, DLQ, routing, and cost visibility.

Conventions
- Prometheus-style metric names; labels kept minimal and cardinality-safe (tenant, job_type, worker, tool, provider, model).
- Histograms for latency (p50/p95 via Prometheus quantiles), counters for events, gauges for in-flight states.

HTTP Endpoints
- `/metrics` – Prometheus exposition format (existing; expand instrumentation)
- `/api/metrics/summary?from=..&to=..` – JSON summaries for dashboards and CI comments
- `/api/metrics/routing?service=chat` – Router candidate ranks/health/cost snapshot

Core Metrics (Names → Type → Labels → Notes)
1) `cogo_scheduler_claim_total` → counter → { job_type } → successful claims
2) `cogo_scheduler_claim_conflict_total` → counter → { job_type } → losers in race
3) `cogo_job_lease_renew_total` → counter → { job_type } → renewals
4) `cogo_job_lease_expired_total` → counter → { job_type } → expiry events
5) `cogo_job_latency_seconds` → histogram → { job_type, phase="queue|run" } → end-to-end split
6) `cogo_job_retries_total` → counter → { job_type, reason } → retry attempts
7) `cogo_job_failures_total` → counter → { job_type, reason } → terminal failures
8) `cogo_job_dlq_total` → counter → { job_type, stage } → DLQ stage codes
9) `cogo_worker_inflight_jobs` → gauge → { worker_id, job_type } → running jobs
10) `cogo_tool_latency_seconds` → histogram → { tool } → tool invocations
11) `cogo_tool_errors_total` → counter → { tool, reason } → tool failures
12) `cogo_llm_tokens_total` → counter → { provider, model, direction="in|out" } → token counts
13) `cogo_llm_cost_usd_total` → counter → { provider, model } → accumulated cost
14) `cogo_router_rank_score` → gauge → { provider, model, region } → latest rank score
15) `cogo_router_failover_total` → counter → { reason } → failover events

Minimal Implementation Plan
- Phase A (now): add counters/histograms in scheduler claim path, worker run path, retry/DLQ hooks.
- Phase B: instrument tool/LLM wrappers for latency/tokens/cost; expose routing ranks.
- Phase C: add `/api/metrics/summary` aggregates and JSON artifacts for CI comments.

Label Policy
- `tenant` label gated behind feature flag `METRICS_LABEL_TENANT` to avoid excessive cardinality by default.
- `worker_id` only for gauges; avoid in counters to prevent cardinality blow-up.

Dashboards (Sketch)
- Queue Health: claims, conflicts, lease renewals/expiries, queue/run latencies.
- Reliability: retries by reason, DLQ stages, failure rate, success rate.
- Cost/LLM: tokens in/out, USD by provider/model, router rank over time.

Acceptance Criteria (Phase A)
- Metrics appear at `/metrics`; p95 visible for job latency and tool latency.
- Retry/DLQ counters increase under synthetic failures.
- Summary endpoint returns JSON with passable structure for CI comments.

Feature Flags
- `METRICS_LABEL_TENANT=true|false`
- `ROUTER_SCORE_V2=true|false` (routing ranks exposed when true)


