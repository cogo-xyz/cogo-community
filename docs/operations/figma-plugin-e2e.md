## Figma Plugin → COGO UI JSON E2E Runbook

### Purpose
Validate the real service path from Figma Plugin to Supabase Edge function and ensure responses include `cogo_ui_json` suitable for downstream UUI rendering and metrics.

### Prerequisites
- Supabase project accessible; `.env` contains `SUPABASE_EDGE` and `SUPABASE_ANON_KEY`.
- Deployed Edge Function: `figma-compat` (Deno). Aliases supported: `/figma-plugin/compat/*` → routes inside `figma-compat`.
- Optional: Legacy writes/storage tables if enabled via env on the Edge side (`LEGACY_*`). Not required for success.

### Endpoints (alias → internal)
- POST `/figma-plugin/compat/uui/variables/derive` → `/figma-compat/uui/variables/derive`
- POST `/figma-plugin/compat/uui/symbols/map` → `/figma-compat/uui/symbols/map`
- POST `/figma-plugin/compat/uui/bdd/generate` → `/figma-compat/uui/bdd/generate`
- POST `/figma-plugin/compat/uui/bdd/refine` → `/figma-compat/uui/bdd/refine`
- POST `/figma-plugin/compat/uui/actionflow/refine` → `/figma-compat/uui/actionflow/refine`

All endpoints return `{ ok: true, result: { ..., cogo_ui_json: {...} }, trace_id, ... }` on success.

### Minimal Request Example
```json
{
  "user_id": "user",
  "session_id": "sess-123",
  "projectId": "your-project-id",
  "page_id": 1,
  "page_name": "Page",
  "variables": {},
  "creatego_json": [{ "type": "container", "children": [{ "type": "text", "text": "Hello" }] }]
}
```

### Expected Response Shape (excerpt)
```json
{
  "ok": true,
  "result": {
    "note": "uui.variables_derive",
    "cogo_ui_json": {
      "version": "1.0",
      "page": { "id": 1, "name": "Page" },
      "tree": [ { "id": "container_0", "type": "container", "children": [ { "id": "text_0", "type": "text", "props": { "text": "Hello" } } ] } ]
    }
  },
  "trace_id": "..."
}
```

### How to Run (CLI)
- Ensure `.env` has `SUPABASE_EDGE`, `SUPABASE_ANON_KEY`, `PROJECT_ID`.
- Run local smoke:
```bash
source ./.env
npm run -s mcp:smoke:uui:edge
```

### Bottlenecks & Remedies
- Idempotency enforced: If Edge env `REQUIRE_IDEMPOTENCY=true`, include `Idempotency-Key` header or body `idempotencyKey`.
- Supabase writes disabled: If `LEGACY_*` envs are not set on Edge, write/upload is skipped (non-blocking). Success depends only on conversion.
- CORS/Headers: Ensure Figma plugin origin allowed; current Edge returns permissive CORS (`*`).
- Worker queues (Chat path): Unrelated to `figma-compat`. For chat `pending`, ensure `BusEventsBroadcaster` and `ChatGatewayWorker` are running.
- 404 alias: If `/figma-plugin/compat/*` 404s at gateway level, call `/functions/v1/figma-compat/...` directly; alias is handled inside the function once the request reaches it.

### Verification Checklist
- [ ] Response `ok: true`
- [ ] `result.cogo_ui_json.version === "1.0"`
- [ ] `tree` contains mapped nodes (`container`, `text`, `image`, `button`, `input`, or `node` fallback)
- [ ] `page.id` and `page.name` propagated


