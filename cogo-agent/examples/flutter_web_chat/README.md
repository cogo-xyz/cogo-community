## Flutter Web Chat Reference

This example shows a minimal Flutter Web chat app integrating with the COGO chat gateway contract by default and supporting optional SSE echo mode for development.

Key points:
- Uses `/functions/v1/chat-gateway` with the documented gateway contract.
- JSON handoff is the default (orchestrator mode). SSE echo is optional for local/dev.
- Web constraints-friendly: no local FS/process, uses browser networking only.
- Simple i18n toggle (`en`/`ko`) via in-memory strings.
- Runtime settings UI (gear icon): persists `SUPABASE_URL`, `SUPABASE_KEY`, `COGO_PROJECT_ID` in `localStorage` as `cogo_supabase_url`, `cogo_supabase_key`, `cogo_project_id`.

### Structure
- `lib/main.dart`: Minimal chat UI (input + send + messages list), gateway call, runtime settings dialog.
- `pubspec.yaml`: Minimal Flutter config.

### Configure
- Click the settings (gear) icon in the app and fill:
  - Supabase URL
  - Supabase Key (Anon or Service Role in dev)
  - Project ID (COGO project UUID)
- Values persist in browser `localStorage` and are reused on reload.

### Run (reference)
1) Create a Flutter project or open this folder within an existing Flutter app.
2) Copy `lib/main.dart` and `pubspec.yaml` contents into your app (merge as needed).
3) Ensure Flutter Web is enabled: `flutter config --enable-web`
4) Run: `flutter run -d chrome`

### Gateway JSON example (equivalent to app call)
```bash
curl -sS -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" -H "Content-Type: application/json" \
  -d '{"payload":{"projectId":"'$COGO_PROJECT_ID'","text":"hello"}}' \
  "$SUPABASE_URL/functions/v1/chat-gateway" | jq .
```

### SSE echo (dev only)
```bash
curl -sS -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" -H "Content-Type: application/json" -H "Accept: text/event-stream" \
  -d '{"text":"hello stream"}' "$SUPABASE_URL/functions/v1/chat?sse=1"
```

### Notes
- App uses gateway JSON handoff path by default to align with orchestrator.
- SSE path is provided for quick dev feedback (echo mode).


