## IDE Supabase Access Map and Write Policy

Date: 2025-08-25

### Observed setup
- Repo: creatego-ide (Flutter web)
- Packages: `supabase_flutter`, `realtime_client`, `creatego_supabase` (models/helpers)
- Access pattern: `Supabase.instance.client` and wrappers via `SupabaseDep.impl`
- Also uses: Edge Functions invoke (deploy_android/web), RPCs, Realtime channels

### Public tables with writes (from code)
- projects: update/delete
- pages: insert/update/delete
- project_pages (aka layoutPages in code paths): insert/select
- components: delete/insert (via converters)
- action_flows: insert
- symbols: insert/delete
- organisations, organisations_members: insert/update/delete
- themes, organisations_themes, organisations_libraries: insert/update/delete
- project_activity: upsert/insert/delete
- api_keys: update
- data_type, data_field: full CRUD
- bdd_* (bdd_action_flows, scenarios links): insert/delete via RPC/queries
- imported_libraries: insert

These are user-owned entities and should remain in `public.*` guarded by RLS and session auth.

### Reads only (examples)
- profiles, various joins for pages/components, library relations

### RPC/Functions usage (examples)
- RPC: `copy_project`, `fetch_actionflows_with_bdd_links`, `fetch_bdd_scenarios_with_actionflows`
- Functions invoke: deploy android/web build workflows

### Policy (aligned with domain separation)
- IDE/Starter: Read/Write only against `public.*` under RLS with user session
- Agents: No direct writes to `public.*`
- Agents write to `cogo.*` and enqueue to `cogo.project_updates` (outbox)
- Projection worker (SRK) materializes `cogo.project_updates` → `public.*`

### Migration/Hardening checklist
- Verify IDE uses session tokens only (no SRK) for public writes
- Add/confirm RLS policies for all mutated public tables listed above
- Add idempotency on Functions invoke paths used by IDE (deploy, etc.)
- Introduce projection worker and stop any non-IDE writers to `public.*`
- Telemetry: tag IDE writes with user id + trace_id for auditing

### Notes
- Some paths unsubscribe Realtime channels (components). Consider normalized live-updates from projection worker to IDE via Realtime where helpful.


