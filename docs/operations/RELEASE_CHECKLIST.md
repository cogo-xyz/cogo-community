# Release Checklist (Chat Protocol & Edge Functions)

Use this checklist to safely roll out the upgraded chat protocol and Edge functions.

## Configuration
- [ ] Set SUPABASE_URL, SUPABASE_PROJECT_ID
- [ ] Set SUPABASE_ANON_KEY (client) and SUPABASE_SERVICE_ROLE_KEY (server)
- [ ] Optional DEV flags (staging only): DEV_CLI_SIMULATE, DEV_ABORT_AFTER_MS, DEV_DISABLE_FALLBACK
- [ ] Enable metrics: INTENT_METRICS_ENABLE=true (optional)

## Capabilities & Registry
- [ ] Verify GET /intent-resolve/info returns requires_source=registry
- [ ] If registry not available, confirm fallback with ?include_fallback=1
- [ ] Confirm editor_context_support=true, sse_events includes ready

## Storage & Attachments
- [ ] Supabase Storage bucket present for artifacts (e.g., figma, artifacts)
- [ ] Ingest flow OK (presign → PUT → ingest → result with content_type/size)

## SSE & CLI Simulation
- [ ] design-generate and figma-context/stream stream ready, meta, keepalive, aborted (when configured)
- [ ] dev_cli_simulate works in streams (IDE UI dev mode)

## Tests & CI
- [ ] Run locally: JUNIT=1 bash scripts/test/edge-all.sh (green)
- [ ] GitHub Actions workflow .github/workflows/edge-all.yml green
- [ ] Repo secrets set: SUPABASE_PROJECT_ID, SUPABASE_ANON_KEY

## Docs & Examples
- [ ] Review docs/agents/COGO_AGENT_CHAT_MESSAGE_SPEC.md
- [ ] Review docs/guides/IDE_Chat_Integration.md
- [ ] Review docs/operations/Capabilities_Operations_Guide.md
- [ ] Optional: Run npm run sse:example (requires SUPABASE_EDGE/ANON)

## Post-Release
- [ ] Monitor bus_events for capabilities_info and error rates
- [ ] Verify artifacts retention and access controls
- [ ] Update CHANGELOG with release tag
