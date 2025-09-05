### COGO Agent – Quickstart

This folder contains docs and examples for chat handoff, JSON CRUD, and JSON generation/validation.

Quickstart
- Verify environment: `env.development` should have SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY.
- Run example validation and persist:
  - `docs/cogo-agent/examples/run.sh`
- Full end-to-end (validate → persist → handoff → process → ready):
  - `docs/cogo-agent/run-e2e.sh`
- Edge quickstart (copy/paste): `QUICKSTART_EDGE.md`
- Onboarding: `ONBOARDING.md` (one page)

References
- JSON generation/validation plan: `COGO_JSON_GENERATION_VALIDATION.md`
- Examples: `EXAMPLES_INDEX.md`, `examples/simple-screen/`, `examples/flutter_web_chat/`
- Prompt policy and templates: `prompts/`
- SDK quickstart: `SDK_QUICKSTART.md`
- KG upsert (cron plan): `KG_UPSERT_SCHEDULED.md` (dev trigger: `/functions/kg-upsert-schedule`)
- KG worker runbook (poller): `KG_WORKER_RUNBOOK.md`
- JSON generation (Edge function): `/functions/json-generate` — POST { ui, projectId }
- Save artifacts: `node scripts/pipeline/edge_generate_save.js --project <id> --out docs/cogo-agent/examples/simple-screen`
- Endpoints summary: `ENDPOINTS.md`
- Chat reference: `CHAT_REFERENCE.md`
- CLI reference: `CLI_REFERENCE.md`
- cogo-cli-flutter remote JSON: `../packages/cogo-cli-flutter/REMOTE_JSON_CLI_REFERENCE.md`
- Dart CLI template: `../artifacts/cogo_cli_dart_template.zip` (runner: `scripts/quality/run_dart_cli_template.sh`)
- CLI e2e: `scripts/quality/run_cli_e2e.sh`
- Curl snippets: `CURL_SNIPPETS.md`
- Postman: `postman/CogoAgent.postman_collection.json` + `postman/CogoAgent.postman_environment.json`
- Troubleshooting: `TROUBLESHOOTING.md`
- Security notes: `SECURITY_NOTES.md`
- Env printer: `scripts/quality/print_env.sh`
- One-command run: `scripts/quality/run_everything.sh`
- Smoke tests: `scripts/quality/smoke_edge.sh` and `scripts/quality/smoke_chat.sh`
- Packaging: `scripts/quality/zip_flutter_web_chat.sh` → `docs/artifacts/flutter_web_chat.zip`
- Export to community: `scripts/edge/export_to_community.sh /Users/hyunsuklee/Desktop/Dev/cogo-project/cogo-community`
- Req matrix: `REQ_MATRIX.md`
- A/B and benchmarks: `scripts/quality/run_ab.sh`
- Full suite: `scripts/quality/run_full_suite.sh`
- Quality corpus: `docs/quality/QUALITY_CORPUS.md` and `scripts/quality/run_corpus.js`
