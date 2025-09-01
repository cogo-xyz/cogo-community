# Alerts and Traces

## Endpoints

- GET `/api/metrics/summary`
  - Returns totals and circuit open counts.
- GET `/api/metrics/trace/:traceId`
  - Returns ordered `bus_events` for the trace with a compact summary.
- POST `/api/alerts/evaluate`
  - Headers: `x-admin-token` (if configured)
  - Query params: `minFailRate`, `minOpenCircuits`
  - Triggers Google Chat webhook via existing notifier when thresholds breached.
- GET `/api/dlq?service=...&role=...&shard=...&limit=...`
- POST `/api/dlq/replay/:id`
- POST `/api/dlq/replay` (bulk)
  - Body: `{ "ids": ["...","..."] }` (optional) or use query filters.

## Operational Hints

- Set `ADMIN_TOKEN` to protect DLQ and alert routes.
- Configure Circuits via `configs/circuit_breaker.json`.
- Retry policies via `configs/retry_policy.json`.
- Use `GOOGLE_CHAT_WEBHOOK_URL` and `WEBHOOK_TYPE=googlechat` for chat alerts.
