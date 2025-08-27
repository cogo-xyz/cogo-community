# Agent Observability Plan (Phase 1: Agent-only, Analysis + Real-time Response)

## Scope (now)
- Collect only Agent error and quality signals
- IDE/Flutter telemetry is out-of-scope for Phase 1 (planned later)

## Objectives
- Real-time response: alerting inputs via metrics (success/error rate, latency)
- Analysis: short-term root-cause via structured error logs

## Data to collect (Agent)
- Error events (JSONL):
  - fields: ts, scope='agent', name, ok=false, error(message), meta(trace_id, run_id, flow_id, step, target, status)
- Quality snapshots (JSON):
  - actionflow success_rate, total_runs, error_count, avg_steps, avg_step_latency_ms

## Current implementation (Phase 1)
- Error logs
  - Local artifacts (JSONL): `artifacts/errors/YYYY-MM-DD/agent.jsonl`
  - Writer: `src/tools/errors/ErrorLogger.ts`
  - Emit points: ActionFlowRunner on run errors
- Quality
  - Scripts: `report:aflow:weekly` (existing), plus snapshot scripts can be added if needed
  - Artifacts path: `artifacts/metrics/agent/YYYY-MM-DD/*.json`

## Future (Phase 2/3)
- Edge error-ingest (gzip NDJSON batch, rate-limit, dedup) → DB (short-term), Storage (long-term)
- DB schema: `cogo.error_logs_raw` (daily partition, TTL 14d), `cogo.error_logs_daily` (aggregates)
- Incident mode: sampling of low severity, dedup by stack hash
- IDE telemetry ingestion (Redux state snapshot with masking)

## Runbook (Phase 1)
- Errors summary: `npm run errors:summary`
- Weekly metrics bundle: `npm run ops:weekly:bundle`
