## Supabase CLI – Update & Local Pipeline Guide

### Update
```bash
npm i -g supabase@latest
supabase --version
```
- Keep CLI updated to avoid deploy/runtime incompatibilities.

### Environment
- macOS/zsh users can export in `~/.zshrc`:
```bash
export SUPABASE_PROJECT_ID=...
export SUPABASE_ANON_KEY=...
export SUPABASE_ACCESS_TOKEN=...
```

### Deploy core functions (one line)
```bash
EDGE_REQUIRE_INTENT_KEYS=false EDGE_REQUIRE_INTENT_REQUIRES=true INCLUDE_CLI_ACTIONS=true UUI_FALLBACK_ENABLE=true \
bash scripts/deploy/edge-deploy.sh
```

### Secrets (examples)
```bash
supabase secrets set EDGE_VERIFY_JWT=false EDGE_REQUIRE_HMAC=false EDGE_RATE_LIMIT_PER_MIN=120
supabase secrets set INTENT_REGISTRY_TTL_SEC=60 INTENT_METRICS_ENABLE=true
```

### Integrated tests
```bash
JUNIT=1 bash scripts/test/edge-all.sh | cat
bash scripts/ci/junit-gate.sh artifacts-local/ops/edge-all.junit.xml
```

### Troubleshooting
- Permission denied: `chmod +x scripts/deploy/*.sh scripts/test/*.sh`
- Context drift on edits: re-open files and use fallback edit tool
- Relation missing: create `cogo` schema and required tables before seeds


