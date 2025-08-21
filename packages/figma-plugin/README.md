# Cogo Figma Plugin

Convert Figma selection to UUI JSON and Cogo UI JSON. Supports large payloads via ingest (presign → upload → ingest → result).

## Setup
- Import plugin: Figma → Plugins → Development → Import plugin from manifest… → `packages/figma-plugin/manifest.json`
- Fill settings in the UI:
  - Supabase Edge URL (e.g. `https://<ref>.functions.supabase.co`)
  - Anon Key
  - Project ID
- Settings are persisted locally in the plugin UI.

## Features
- Convert Selection → returns both `uui_json` and `cogo_ui_json`
- Ingest Large JSON → presign → PUT upload → ingest → result polling
- Result actions: Open/Copy artifact URL, Copy storage key, Copy trace_id
- Retries with backoff for network steps

## Endpoints used
- `POST /figma-compat/uui/symbols/map`
- `POST /figma-compat/uui/presign`
- `POST /figma-compat/uui/ingest`
- `GET  /figma-compat/uui/ingest/result?traceId=...`

## Build
```bash
npm install
npm run build
```
`dist/` will contain `code.js` and `ui.html`.

## Package (zip for release)
```bash
npm run pack
# output: releases/cogo-figma-plugin-<version>.zip
```

## Notes
- The plugin communicates with a Supabase Edge Function. Ensure the endpoints are deployed and reachable.
- For production, configure CORS and rate limits on the metrics/edge servers as needed.
