# Supabase Key Usage Policy (Authoritative)

This project uses Supabase extensively. The following policy is authoritative for local dev, CI, and Edge Functions.

## Key Types
- Publishable key: `sb_publishable_...` (low privilege; safe for clients)
- Secret key: `sb_secret_...` (elevated; server-only)
- Legacy anon key: long-lived JWT (low privilege)
- Legacy service role key: long-lived JWT (elevated; server-only)

## Edge Functions (router-select, key-vault)
- Authorization header MUST be a valid JWT; prefer legacy ANON in dev:
  - `Authorization: Bearer $SUPABASE_ANON_KEY`
- `apikey` SHOULD be `SUPABASE_PUBLISHABLE_KEY`, fallback to Secret/Anon.
- The function runtime MUST have `SUPABASE_URL` and a server key (`SERVICE_ROLE_KEY` or Secret) in its environment.

## Database Writes (Vectors, Usage, Jobs)
- Any write/upsert (e.g., `agent_knowledge_vectors`, `vector_documents`, `code_vectors`) MUST use `SUPABASE_SERVICE_ROLE_KEY` or `SUPABASE_SECRET_KEY`.
- Do NOT use `SUPABASE_ANON_KEY` for writes. Unset it for write-heavy scripts to avoid header conflicts.

## App/Server Defaults
- Use `SUPABASE_SERVICE_ROLE_KEY` for server-side Supabase clients.
- Keep ANON for Edge Function JWT calls, with PUBLISHABLE in `apikey`.

## Recommended Environment Variables
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_PUBLISHABLE_KEY`
- `SUPABASE_ANON_KEY` (for Edge Function calls)
- `ROUTER_SELECT_URL=$SUPABASE_URL/functions/v1/router-select`
- `KEY_VAULT_URL=$SUPABASE_URL/functions/v1/key-vault`
- `KEY_ENV=dev`, `KEY_BEARER=$SUPABASE_ANON_KEY` (for server to fetch keys via Key-Vault)

## Do / Don't
- Do: Use SERVICE_ROLE/SECRET for DB writes; ANON for browser-like Edge calls.
- Do: Prefer PUBLISHABLE for `apikey`, fallback to Secret/Anon.
- Don't: Mix ANON in write scripts; it will cause `Invalid API key` errors.


