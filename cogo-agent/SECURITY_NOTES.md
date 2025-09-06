### Security Notes – Concurrency and Caching

- Strict Preconditions (Production):
  - Set `EDGE_STRICT_PRECONDITIONS=true` to enforce concurrency on writes
  - `If-Match` required for updates to prevent lost updates; stale versions → `412 Precondition Failed`
  - Missing `If-Match` where required → `428 Precondition Required`
  - `expected_version` supported and returns `409 Conflict` on mismatch

- Caching / Conditional Requests:
  - `json-get`, `json-list`, `artifacts-list`, `trace-status` support ETag headers
  - `HEAD` returns `ETag`, `POST/GET` accept `If-None-Match` and return `304 Not Modified`
  - ETag format is weak and includes stable identifiers and last-updated timestamps (ISO8601)

- Debugging:
  - Set `DEBUG_ETAG_IN_BODY=true` to include `etag` in JSON responses for troubleshooting (do not enable in production)

## Security Notes

- Never commit secrets. Load `SUPABASE_URL` and keys from environment or secret manager.
- Use Anon key for browser clients; Service Role only on server/Edge.
- Prefer RLS with `public.cogo_documents` and project-scoped access.
- Enable JWT verify/HMAC in production; keep disabled only for local dev.
- Use `Idempotency-Key` for retry-safe writes; validate `If-Match/If-None-Match` headers.
- For Web examples, store config in `localStorage` only for dev; use a secure config endpoint in production.

### Reserved System Symbols (`#_`)

- System-scoped namespaces use `#_` prefix. Allowed roots for persisted artifacts:
  - `#_uiState`, `#_appData`, `#_params`
- Reserved runtime scratchpads (engine-managed; do not persist in artifacts):
  - `#_results`, `#_currentResult`, `#_parentCallbacks`, `#_cachedResult`, `#_dataAction`
- Validation rejects forbidden/unsafe usage; generator emits `#_` for system-bound variables; KG tags system symbols for observability.
