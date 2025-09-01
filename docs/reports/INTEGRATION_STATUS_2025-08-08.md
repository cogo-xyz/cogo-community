## Realtime MCP Integration Status (Updated 2025-08-09)

### Summary
- Browser MCP: Successful real run and artifact upload to Supabase Storage using service role key.
  - Test URL: `https://httpbin.org/html`
  - Result: Screenshot captured, signed URL generated, `artifacts` DB row inserted.
- Figma MCP: Successful end-to-end export for selected nodes.
  - File: `u9VG9NhC6C8hVJYx8o9rpS`
  - Nodes: `1:8, 1:2, 1:4`
  - Result: 3 PNG artifacts uploaded and recorded.
- Supabase
  - Created Storage bucket `artifacts` (public=true for dev).
  - Applied tables and DEV-open RLS policies: `jobs`, `worker_devices`, `worker_heartbeats`, `artifacts`.
  - Realtime uses publishable key; Storage/DB writes use secret (service role) key on trusted workers only.

### Collab API (new)
- Dev server: `npm run dev:collab` → `/api/collab/health|task.assign|task.result|job/:id|jobs/recent|artifacts/by-job/:id`
- Verified E2E: assign → result → query reflected in Supabase `jobs`/`artifacts`

### Commands Executed
- Create bucket (service role):
  - `npx ts-node src/scripts/createArtifactsBucket.ts`
- Schema check:
  - `npx ts-node src/scripts/checkSupabaseSchema.ts`
- Run Browser worker (real mode):
  - `npx ts-node src/tests/BrowserMcpWorkerBridge.ts`
- Run Figma worker:
  - `npx ts-node src/tests/FigmaMcpWorkerBridge.ts`
- Integration test (browser + figma):
  - `npx ts-node src/tests/McpIntegrationTest.ts`

### Configuration Notes
- Keys:
  - Realtime: `SUPABASE_ANON_KEY` (publishable)
  - Writes/Storage: `SUPABASE_SERVICE_ROLE_KEY` (secret, server-side only)
- Artifacts bucket: `artifacts`
- Worker mode: broadcast (DB polling path also available via `WORKER_MODE=db`)
- Timeouts: Browser navigation `BROWSER_NAV_TIMEOUT_MS` tuned for stability in CI

### Known Gaps
- Main server `src/index.ts` fails to compile due to missing modules (TS2307). Plan: split entrypoints and guard dynamic imports.

### References
- Example test page: [Example Domain](https://example.com/)
- Alternate stable test page: `https://httpbin.org/html`
- Figma team/files (provided by user):
  - Team list: https://www.figma.com/files/team/971314428972739725/all-projects?fuid=1375675195126048191
  - Material 3 kit file example: https://www.figma.com/design/1ZlR8gTA86lsWkv3cXSCKU/PPM-Material-3-Design-Kit--Community-?node-id=49823-12497&t=yZgAzSb3VZhWMAGE-0

### Next TODOs
1) Security & RLS
   - Replace DEV-open policies with role-based RLS for `jobs`, `artifacts`, `worker_*` tables.
   - Timing: do this right before public launch (see `docs/LAUNCH_CHECKLIST.md`).
   - Ensure service key never logged; move secrets to secure env for CI/CD.
2) CI/CD
   - Add schema check step and (optional) migration apply step.
   - Add artifacts bucket creation step for ephemeral envs.
   - Start Browser/Figma workers and run integration tests; ensure cleanup.
3) Browser Worker
   - Remove forced-success fallback in production.
   - Improve screenshot options (viewport, fullPage toggle, retries) and error labeling.
4) Figma Worker
   - Smarter node selection, handle non-renderable types, add rate-limit/backoff.
   - Support more export sizes/formats and batch uploads.
5) Observability
   - Expand Prometheus metrics: per-task latency, failures, storage upload stats.
6) Docs
   - Update `docs/REALTIME_CHANNELS_AND_USAGE.md` with the confirmed E2E success paths and example payloads.


