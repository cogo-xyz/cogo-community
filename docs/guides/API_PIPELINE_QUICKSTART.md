# Pipeline Quickstart (Codegen → Build/Test → Gate)

## 0) Start services

- Using docker compose (requires SUPABASE env):

```bash
docker compose -f docker-compose.pipeline.yml up
```

## 1) Check integration status

```bash
curl -s http://localhost:3000/api/integration/status | jq
```

## 2) Run pipeline (commit gate not enforced)

```bash
curl -s -X POST http://localhost:3000/api/pipeline/codeBuildTest \
  -H 'content-type: application/json' \
  -d '{"taskId":"task-demo-1"}' | jq
```

- Response includes `trace_id`, `ids`, `decision`, `events`.

## 3) Run pipeline with gate enforcement

```bash
curl -s -X POST 'http://localhost:3000/api/pipeline/codeBuildTest?enforce=true' \
  -H 'content-type: application/json' \
  -d '{"taskId":"task-demo-2"}' | jq
```

- If gate does not pass, returns HTTP 422 with `{ error: "gate_not_passed" }`.

## 4) Inspect trace events

```bash
TRACE=REPLACE_WITH_TRACE
curl -s "http://localhost:3000/api/metrics/trace/$TRACE" | jq
```

## Notes
- To use the real `cogo-worker`, set:
  - `ENABLE_COGO_WORKER=true`
  - `COGO_WORKER_URL=http://cogo-worker:8080`
  - `COGO_WORKER_TIMEOUT_MS=60000`
- All events carry `trace_id` and are visible via `/api/metrics/bus/events?trace=...`.
