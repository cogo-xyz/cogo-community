## Development Summary — Edge-only Figma Integration

### Scope
- Implement and stabilize Edge-only flow for Figma Context and Design Generation.
- Minimize Figma Plugin UI to presence and connection control only.
- Provide CLI-based end-to-end test scripts and concise guides.
- Make Assistant-UI optional (Edge-first validation possible without UI).

### Key Deliverables
1) Edge Functions
- figma-context (start/stream/status/apply)
  - SSE stream stability and limits (idle/max lifetime/conn caps)
  - Synthetic mode for testing without FIGMA_API_KEY
  - Verified: start→stream→status works (synthetic 50 nodes) and completes with `done`
- design-generate (SSE aggregator)
  - Robust body parsing for SSE (removed duplicate req.json read)
  - `?prompt=` query support for easy CLI invocation
  - Verified SSE sequence: meta → rag.item* → rag.done → llm.done → ui.generate → done
- Presence API (figma-plugin bridge)
  - Register/Unregister/Heartbeat (TTL, in-memory/DB)

2) Figma Plugin (tools/figma-plugin/cogo-plugin)
- UI reduced to essentials: Edge URL, Anon Key, Project UUID, Presence register/unregister, status log
- Code changes for runtime compatibility: removed optional chaining/spread; esbuild target lowered
- Route manifest/ui.html path issues fixed

3) Assistant-UI (optional)
- Added Figma Context Live Subscribe controls (Job ID/Trace, status)
- Edge-only safe defaults: disabled realtime; API health checks suppressed when disabled
- Avoids `/api/agents` calls in Edge-only mode to prevent proxy errors

4) Docs & Scripts
- `docs/EDGE_TEST_GUIDE.md`: Hands-on test steps for design-generate and figma-context
- `scripts/test/edge-design-generate-sse.sh`: One-liner SSE test for design-generate
- `scripts/test/edge-figma-context-e2e.sh`: Start→stream(loop)→status test for figma-context

### Configuration
- Required headers for Edge calls: `apikey: <ANON>`, `Authorization: Bearer <ANON>`
- Edge BASE: `https://<project>.functions.supabase.co/functions/v1`
- Optional: `FIGMA_API_KEY` (for real Figma fetch). Synthetic mode available without it

### Test Quickstart
- Design Generate (SSE)
  - See `scripts/test/edge-design-generate-sse.sh`
- Figma Context
  - See `scripts/test/edge-figma-context-e2e.sh`

### Known Limitations
- Assistant-UI: Dashboard/Agents/Tasks pages rely on backend `/api/*`; in Edge-only validation they are disabled/omitted.
- Figma real fetch requires Edge env `FIGMA_API_KEY`.

### Next Steps (Optional)
- Assistant-UI: dedicate an “Edge Lab” page focused only on SSE tests (no backend proxy)
- Add minimal UI for design-generate SSE preview (mirroring CLI output)
- Harden plugin reconnection policy: automatic presence heartbeat + idle auto-unregister


