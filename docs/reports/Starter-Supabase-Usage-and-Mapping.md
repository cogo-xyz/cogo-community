## Starter Supabase Usage and public→cogo Mapping

Date: 2025-08-25

### Observed setup
- Repo: creatego-starter
- pubspec dependencies: `supabase:^2.1.0`, `hive`, `shared_preferences`, etc.
- Auth/config: `lib/utils/constants_json.dart` references `supabaseUrl` and `supabaseAnonKey`.
- Supabase client usage: multiple scripts and Dart modules construct `SupabaseClient(supabaseUrl, supabaseAnonKey)`.

### Referenced tables (from code)
- pages
- project_pages
- components (with custom converter `componentsFromJsonV2`)
- action_flows
- symbols
- project_config
- themes (via `themeRes` path)

These are currently accessed under `public` schema via default `from('...')` calls.

### Mapping recommendation (read-only Starter)
- Keep Starter/IDE reads from `public.*` with RLS.
- Migrate core write domain to `cogo.*` and project into `public.*` via projection worker subscribed to `cogo.project_updates`.
- For Starter tooling that writes directly (e.g., `bin/db_to_*` scripts), mark as legacy or route writes through an agent API that enqueues outbox events.

### public→cogo counterpart candidates
- public.pages → cogo.pages
- public.project_pages → cogo.project_pages
- public.components → cogo.components
- public.action_flows → cogo.action_flows
- public.symbols → cogo.symbols
- public.project_config → cogo.project_config
- public.themes → cogo.themes

Note: user/identity tables (profiles, organisations) may remain in `public` and be referenced by `cogo` via FKs when needed.

### Projection flow (CQRS)
1) Agent writes state/events to `cogo.*` and `cogo.project_updates` (outbox).
2) Platform projection worker consumes outbox, upserts denormalized rows into `public.*`.
3) Starter/IDE reads from `public.*` only.

### Next steps
- Confirm exact column shapes per table and define `cogo.*` DDL aligning with Starter read needs.
- Add projection worker spec and minimal implementation (subscribe/ack/retry). 
- Replace any direct Starter write paths with agent API calls (if any remain).


