## Security Notes

- Never commit secrets. Load `SUPABASE_URL` and keys from environment or secret manager.
- Use Anon key for browser clients; Service Role only on server/Edge.
- Prefer RLS with `public.cogo_documents` and project-scoped access.
- Enable JWT verify/HMAC in production; keep disabled only for local dev.
- Use `Idempotency-Key` for retry-safe writes; validate `If-Match/If-None-Match` headers.
- For Web examples, store config in `localStorage` only for dev; use a secure config endpoint in production.
