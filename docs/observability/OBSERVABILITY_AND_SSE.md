## Observability & SSE

Date: 2025-08-25

### Metrics
- Metrics server on 3200: /api/metrics/summary, /api/metrics/trace/{id}
- Alerts: local-only endpoints; not Edge

### Trace
- All pipeline events carry trace_id
- Accessible via SSE/Realtime and HTTP summary

### SSE
- chat: meta/delta/done
- embed: progress/done
- figma-context: job status stream

### Testing
- HOST=http://localhost:3200 npm run smoke:edge:bundle
- Verify chat/embed SSE; uui generate; metrics summary OK
