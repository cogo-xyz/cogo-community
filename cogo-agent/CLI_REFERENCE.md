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

- Get (HEAD ETag):
```bash
bash scripts/quality/json_cli.sh get-head docs/foo.json
# { "etag": "W/\"<project>:docs/foo.json:<version>\"" }
```

- Get (HTTP GET honoring If-None-Match):
```bash
# First grab ETag via HEAD, then
bash scripts/quality/json_cli.sh --if-none-match="W/\"<project>:docs/foo.json:<version>\"" get-http docs/foo.json
# { "status": 304 } when unchanged, or full JSON body on 200
```
- List:
```bash
bash scripts/quality/json_cli.sh list docs/
```

- List (HEAD ETag):
```bash
bash scripts/quality/json_cli.sh list-head docs/
# { "etag": "W/\"<project>:docs/:<count>:<iso8601>\"" }
```

- List (incremental sync with updated_after):
```bash
# ISO8601 timestamp or relative seconds are accepted by the Edge wrapper
# Example using ISO8601 (UTC)
UPDATED_AFTER="2025-01-01T00:00:00Z" bash scripts/quality/json_cli.sh list docs/
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

- Validate by path (server fetch):
```bash
# If you only know project_id+path, the validator will fetch the JSON server-side
bash scripts/quality/json_cli.sh validate action.flow@1 '{"project_id":"'$COGO_PROJECT_ID'","path":"docs/cogo-agent/examples/simple-screen/actionFlow.v1.expanded.json"}'
```

- Artifacts list (pagination):
```bash
bash scripts/quality/json_cli.sh artifacts docs/cogo-agent/examples/simple-screen/ 3 0 | jq '{count,limit,offset,next_offset,items: (.items|map(.path))}'
```

- Artifacts list (HEAD ETag):
```bash
bash scripts/quality/json_cli.sh artifacts-head docs/cogo-agent/examples/simple-screen/
# { "etag": "W/\"<project>:<prefix>:<count>:<iso8601>\"" }
```

- KG upsert schedule (dev):
```bash
bash scripts/quality/json_cli.sh kg-schedule get
bash scripts/quality/json_cli.sh kg-schedule post
```

- Figma-compat (UUI):
```bash
# presign
bash scripts/quality/json_cli.sh figma presign ui.json
# ingest
bash scripts/quality/json_cli.sh figma ingest uploads/$COGO_PROJECT_ID/ui.json
# result
bash scripts/quality/json_cli.sh figma result <trace_id>
```

### Notes
- Responses are piped into `jq` for readability.
- For conditional headers or idempotency, extend commands with `-H` in scripts as needed.
- The wrapper uses `--fail`, connection and total timeouts to avoid hanging requests.
 - `json-get` and `trace-status` support GET/HEAD with ETag; use `--if-none-match` to leverage 304 caching.
