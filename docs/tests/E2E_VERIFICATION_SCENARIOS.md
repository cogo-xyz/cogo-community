## E2E Verification Scenarios

Date: 2025-08-25

### Chat SSE
- POST /functions/v1/chat with text/messages → expect meta/delta/done SSE frames
- Idempotency-Key reuse → same trace_id

### Embed SSE
- POST /functions/v1/embed with items[].text → expect chunked progress/done

### Figma Compat
- POST /functions/v1/figma-compat/uui/generate → 200 with uui_json/cogo_ui_json
- Convert/Ingest → cogo updates → outbox → projection → public.* → IDE read

### Realtime/Trace
- Subscribe to trace channel by trace_id → see agent orchestration events

### Docker Stack
- Build images, compose up, metrics on 3200
- Run smoke: HOST=http://localhost:3200 npm run smoke:edge:bundle
