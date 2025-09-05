## Troubleshooting

### Requests hang or block
- Add curl timeouts: `--connect-timeout 10 --max-time 30 --fail`.
- Ensure headers: `Authorization: Bearer <KEY>`, `apikey: <KEY>`, `Content-Type: application/json`.
- Healthcheck:
```bash
curl -sS "$SUPABASE_URL/functions/v1/json-generate/healthz" | jq .
```

### 401/403 Unauthorized
- Use Service Role in dev (`SUPABASE_SERVICE_ROLE_KEY`) or adjust function `verify_jwt=false` for local testing.
- Verify `apikey` header matches token.

### 404 not_found on json-get
- Confirm `project_id` and `path` exact match; check `json-list`.

### 412/409 Precondition/version mismatch
- Remove `If-Match` or update with current ETag; check `expected_version`.

### 422 Validation failed
- Compare schema and payload; use `json-validate` with the correct `schema_id`.

### CORS issues (browser)
- Use `chat-gateway` instead of direct `/chat` call; ensure shared CORS headers are deployed.

### Performance / rate limits
- Batch generate with `json-generate` `batch` body; apply idempotency keys on repeated writes.
