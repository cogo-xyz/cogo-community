## COGO JSON CLI (bash wrapper)

This lightweight CLI wraps Edge Functions for JSON CRUD, generate, and validate.

### Prereqs
- Env: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` (or `SUPABASE_ANON_KEY` in dev), `COGO_PROJECT_ID`.
- Tooling: `jq`, `curl`.

### Commands
- Set:
```bash
bash scripts/quality/json_cli.sh set docs/foo.json ./local.json
```
- Merge (deep default):
```bash
bash scripts/quality/json_cli.sh merge docs/foo.json ./patch.json deep
```
- Remove by pointers:
```bash
bash scripts/quality/json_cli.sh remove docs/foo.json /a/b /c
```
- Get:
```bash
bash scripts/quality/json_cli.sh get docs/foo.json
```
- List:
```bash
bash scripts/quality/json_cli.sh list docs/
```
- Generate (in-memory):
```bash
bash scripts/quality/json_cli.sh generate '' ./ui.json
```
- Generate and persist under base path:
```bash
bash scripts/quality/json_cli.sh generate docs/cogo-agent/examples/simple-screen ./ui.json --persist
```
- Validate:
```bash
bash scripts/quality/json_cli.sh validate action.flow@1 ./actionFlow.v1.expanded.json
```

### Notes
- Responses are piped into `jq` for readability.
- For conditional headers or idempotency, extend commands with `-H` in scripts as needed.
