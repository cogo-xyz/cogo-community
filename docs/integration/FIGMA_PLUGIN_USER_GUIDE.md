### COGO Figma Plugin — User Guide

This guide explains how to install, configure, and use the COGO Figma Plugin to convert Figma selections to UUI/COGO JSON, ingest large JSON, and test chat/context SSE.

#### 1) Prerequisites
- Supabase project with Edge Functions deployed (`chat`, `figma-compat`, optional `figma-plugin` endpoints)
- Edge URL and Anon Key (development: direct input acceptable)
- Optional Agent ID (multi-instance routing), e.g., `cogo0`

#### 2) Installation
- Open Figma → Plugins → Development → Import plugin from manifest
- Select: `tools/figma-plugin/cogo-plugin/manifest.json`

#### 3) Configuration Fields
- Edge URL: Supabase Functions base, e.g., `https://<ref>.functions.supabase.co`
- Anon Key: Supabase anon (development only). In production, use short‑lived JWT issued by backend.
- Agent ID (optional): Sent as `x-agent-id` header
- Project ID: Target project UUID (required, must be a valid UUID). Non‑UUID will be rejected.
- Metrics Host (optional): `http://localhost:3100` for trace deep-links

#### 4) Core Flows
- Convert Selection → UUI & Cogo
  - Select nodes in Figma
  - Click “Convert Selection → UUI & Cogo”
  - Calls `POST /figma-compat/uui/symbols/map` with `cogo_ui_json` from selection
  - Output shows `uui_json` and `cogo_ui_json` with copy buttons
- Generate (Deterministic)
  - Enter prompt and/or seed `COGO UI JSON`
  - Click “Generate (deterministic)” → `POST /figma-compat/uui/generate`
- Generate via LLM
  - Enter prompt (required) and optional seed `COGO UI JSON`
  - Click “Generate via LLM” → `POST /figma-compat/uui/generate/llm`
- Upload & Ingest (Large JSON)
  - Provide JSON or use selection
  - If direct body is large, server may return `413` with suggestion to use ingest
  - Presign → Upload → Enqueue via `POST /figma-compat/uui/ingest` → Poll `/figma-compat/uui/ingest/result`
- Chat SSE
  - Sends `text` to `/chat-gateway` and streams SSE frames
- Figma Context SSE
  - Streams context via `/figma-context/stream`

#### 5) Headers and Auth
- Development: Use Anon Key; production should use short‑lived JWT and HMAC as per policy
- Agent ID: If provided, added to all requests as `x-agent-id`
 - Required headers (dev): `Authorization: Bearer <ANON_KEY>`, `apikey: <ANON_KEY>`

#### 6) Troubleshooting
- 401/403: Check Anon Key or environment toggles (`EDGE_VERIFY_JWT`, `EDGE_REQUIRE_HMAC`)
- 404: Verify function path and `edge:sync/seed` alignment
- SSE stalls: Check CORS and ensure Accept: `text/event-stream`
- Empty output: Ensure selection is non-empty or provide valid JSON
 - 413 Payload Too Large: Switch to ingest flow (presign → upload → enqueue → poll)

#### 7) Metrics & Trace
- All actions return `trace_id` for correlation. If Metrics Host is set, “Open Trace” links to `/api/metrics/trace/{traceId}`

#### 9) Local Verification
- Use the provided Node script to verify connectivity and headers:
  - File: `tools/figma-verify.mjs`
  - Env: `SUPABASE_EDGE` or `SUPABASE_PROJECT_ID`, and `SUPABASE_ANON_KEY`
  - Run: `node tools/figma-verify.mjs`
  - Expect: 200 with `{ ok: true, trace_id }` for both `symbols.map` and `uui.generate`

#### 8) Notes
- All server-side logs and events are emitted to `bus_events` in the `cogo` domain
- COGO JSON schema is prioritized; CreateGo legacy is deprecated
