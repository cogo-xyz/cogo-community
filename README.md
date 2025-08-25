# COGO Community

Public monorepo for COGO plugins, SDKs, and examples.

## Packages
- packages/figma-plugin: Figma plugin for UUI/COGO conversion, ingest, and SSE tests

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
- docs/integration/FIGMA_PLUGIN_USER_GUIDE.md
- docs/examples/FIGMA_PLUGIN_EXAMPLES.md

## Notes
- In development, direct Edge/Anon inputs are acceptable. For production, prefer short‑lived JWT/HMAC.
- Events and audit logs are emitted into the `cogo` domain (e.g., `bus_events`).

