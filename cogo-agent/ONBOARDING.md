## Onboarding – COGO Agent

### 1) Clone & Env
```bash
cd cogo-agent-core
cp .env.sample .env
# edit .env: SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY, COGO_PROJECT_ID
```

### 2) Validate Edge Functions
```bash
set -a; source .env; set +a
bash scripts/quality/smoke_edge.sh "$COGO_PROJECT_ID"
bash scripts/quality/smoke_chat.sh "$COGO_PROJECT_ID"
```

### 3) Generate & Persist Examples
```bash
set -a; source .env; set +a
BASE_PATH="docs/cogo-agent/examples/simple-screen" COGO_PROJECT_ID="$COGO_PROJECT_ID" \
SUPABASE_URL="$SUPABASE_URL" SUPABASE_SERVICE_ROLE_KEY="$SUPABASE_SERVICE_ROLE_KEY" \
bash scripts/quality/run_edge_pipeline.sh
```

### 4) Web Chat (Flutter)
- Open `docs/cogo-agent/examples/flutter_web_chat/README.md`
- Run `flutter run -d chrome` (settings 버튼에서 URL/KEY/PROJECT 저장)

### 5) One-command Runner
```bash
set -a; source .env; set +a
bash scripts/quality/run_everything.sh
```

### 6) Docs
- `QUICKSTART_EDGE.md`, `CLI_REFERENCE.md`, `CURL_SNIPPETS.md`, `TROUBLESHOOTING.md`, `SECURITY_NOTES.md`
