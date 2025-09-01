# Observability and Policy Enforcement (Gate, Metrics, Audit)

This document defines the observability surfaces, policy enforcement points, and acceptance/gate criteria for distributed agents.

## Metrics Surfaces
- `/api/metrics/bus/latency` – p50/p90 by `(service, role)`
- `/api/metrics/bus/events` – counts of `execute_*`, failures by reason
- `/api/metrics/workflows/*` – workflow-level timings and gate verdicts

## Audit Events (`public.bus_events`)
- Event types (current):
  - Dispatcher: `execute_enqueued`, `execute_failed`, `execute_done`
  - Codegen: `codegen_done`, `codegen_failed`
  - Build/Test: `buildtest_done`, `buildtest_failed`
- Columns:
  - `event_type`, `message_id`, `service`, `role`, `shard`, `reason`, `payload`
  - `payload` contains contextual fields (e.g., `assignment`, `latency_ms`, `source_message_id`, `report_url`)

## Policy Enforcement
- Assignment envelope: `payload.__assignment` with `model`, `budget.maxCostUsd`, `budget.maxTokens`, `ttl_ms`
- Workers MUST enforce; violations:
  - Budget exceed → fail with `error=budget_exceeded`
  - TTL exceed → fail with `error=ttl_exceeded`
  - Model mismatch → fail with `error=model_policy_violation`

## Gates (Acceptance Criteria)
- Build/Test gate: must pass with zero critical errors
- Latency gate: queue wait p90 within SLO
- Decision quality gate: no regression vs baseline in weekly window

## Dashboards
- `/dashboard/local` and `/dashboard/workflows/codeBuildTest`
- Cards: queue latency, failure trend, decision quality, gate status

## Alerting
- Google Chat (preferred)
  - Name: COGO Ops Alerts (`cogo-ops-alerts`)
  - Key-Vault key: `googlechat:notify:webhook_url` (env-scoped)
  - Env var: `GOOGLE_CHAT_WEBHOOK_URL`
  - URL example (store by reference only): `https://chat.googleapis.com/v1/spaces/AAQAV1lsEsc/messages?key=...&token=...`
- Slack (optional)
  - Env var: `SLACK_WEBHOOK_URL`

