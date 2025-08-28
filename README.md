# COGO Community

Public monorepo for COGO plugins, SDKs, examples, documentation, and testing scenarios.

## Packages
- **packages/figma-plugin**: Figma plugin for UUI/COGO conversion, ingest, and SSE tests

## Quick Start (Figma Plugin)
1. Figma → Plugins → Development → Import plugin from manifest
2. Select: `packages/figma-plugin/manifest.json`
3. Open the plugin and set:
   - Edge URL: Supabase Functions base (e.g., `https://<ref>.functions.supabase.co`)
   - Anon Key: Supabase anon key (dev OK)
   - Agent ID (optional): `x-agent-id` header for multi-instance (e.g., `cogo0`)
   - Project ID: Target project UUID
4. Try:
   - Convert Selection → UUI & COGO
   - Generate / Generate via LLM
   - Upload & Ingest (large JSON)
   - Chat SSE, Figma Context SSE

## Documentation

### User Guides & Manuals
- **Figma Plugin Integration**: `docs/integration/FIGMA_PLUGIN_USER_GUIDE.md`
- **User Manuals**: `docs/manuals/COGO_User_Manual.md`
- **Developer Manual**: `docs/manuals/Developer_Manual.md`
- **Designer Chatting Guide**: `docs/manuals/Designer_Chatting_Guide.md`
- **User Scenarios**: `docs/manuals/COGO_User_Scenarios.md`

### Examples
- **Figma Plugin Examples**: `docs/examples/FIGMA_PLUGIN_EXAMPLES.md`

### Testing & Scenarios
- **Quick Start Testing**: `docs/QUICKSTART_TESTING.md`
- **BDD to ActionFlow Guide**: `docs/BDD_TO_ACTIONFLOW.md`
- **Figma Scenarios**: `docs/scenarios/figma/README.md`
- **Login Scenarios**: `docs/scenarios/login/README.md`
- **Chat Scenarios**: `docs/scenarios/chat/README.md`

### Development & Operations
- **Agent Observability Plan**: `docs/AGENT_OBSERVABILITY_PLAN.md`
- **Nightly Flow Runbook**: `docs/runbook/NIGHTLY_FLOW.md`
- **Security Metrics**: `docs/runbook/SECURITY_METRICS.md`

### API Testing
- **Postman Collection**: `docs/postman/COGO.postman_collection.json`

## Notes
- In development, direct Edge/Anon inputs are acceptable. For production, prefer short-lived JWT/HMAC.
- Events and audit logs are emitted into the `cogo` domain (e.g., `bus_events`).

