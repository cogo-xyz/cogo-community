## Examples Index

### docs/cogo-agent/examples/simple-screen
- Generated artifacts (persist):
  - `variables.doc.json`
  - `symbols.doc.json`
  - `actionFlow.v1.json`
  - `actionFlow.v1.expanded.json` (REST callback with query/headers/body)
  - `events.map.json`
  - `scenarios.bdd.json`, `scenarios.bdd.list.json`

### docs/cogo-agent/examples/flutter_web_chat
- Flutter Web app using `chat-gateway` (JSON handoff), i18n toggle, runtime settings UI.
- Zip: `docs/artifacts/flutter_web_chat.zip`

### figma-compat (UUI)
- Presign upload → upload UI JSON → ingest → check result
- Endpoints: `/figma-compat/uui/presign`, `/figma-compat/uui/ingest`, `/figma-compat/uui/ingest/result`
- See: `CURL_SNIPPETS.md` and Postman collection

### kg-upsert-schedule (dev)
- Triggers ingest requests for recently updated docs
- Endpoints: `GET/POST /kg-upsert-schedule`
- See: `CURL_SNIPPETS.md` and Postman collection

### Quality scripts
- `run_edge_pipeline.sh`: generate→persist→fetch→validate
- `run_corpus.js`: UI corpus generate/validate/metrics
- `run_everything.sh`: smoke→pipeline→corpus→package→export
