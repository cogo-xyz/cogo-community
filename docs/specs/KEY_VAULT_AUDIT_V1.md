## Key-Vault v1 (Versioned Keys, Validation, Audit)

Purpose
- Centralize secret material; enable safe read/write with validation, expiry, rotation, and full audit. No long-lived keys on agents.

Tables (Supabase)
- `secure_keys`
  - key_id (pk), provider, scopes[], version_int, ciphertext (prod) | value (dev), checksum_sha256, expires_at, rotate_after, status (active|revoked|expired), created_by, updated_by, updated_at
- `secure_keys_audit`
  - event_id (pk), key_id, action (read|write|rotate|revoke|fail), actor, ts, reason, client_ip, success, metadata

API (Edge Function `key-vault`)
- POST `/upsert` { provider, scopes, value|ciphertext, expires_at, rotate_after } → { key_id, version_int }
- POST `/get` { provider, model?, scope? } → { key_id, version_int, value|ciphertext_ref, checksum_sha256, expires_at }
- POST `/rotate` { key_id } → { key_id, version_int }
- POST `/revoke` { key_id, reason } → { key_id, status }

Validation
- On write: compute `checksum_sha256`; reject if malformed or near-expiry (policy threshold).
- On read: verify not expired/revoked; include `checksum_sha256` for client validation.
- Always write an audit event; on failure, write `action=fail` with reason.

Security & RLS
- Agents never query tables directly; only via Edge Function with service role on server-side.
- Dev mode: allow plaintext `value`; Prod mode: require `ciphertext` (KMS envelope) with `kms_key_id` metadata.
- RLS: restrict table access to function owner; audits readable by ops only.

Versioning & Rollout
- Bump `version_int` on every upsert/rotate; previous versions remain for rollback.
- Clients may pin a version or accept latest; support gradual migration.

Observability
- Metrics: `key_vault_reads_total`, `key_vault_writes_total`, `key_vault_fail_total{reason}`.
- Audit sampling to logs for anomaly detection.

Acceptance Tests
1) Write→Read roundtrip: checksum matches, audit has write+read.
2) Expired key: read rejected with `expired` reason, audit logged.
3) Rotate: version increases; old version accessible if pinned; audits for rotate+read.
4) Revoke: further reads denied; audit reason recorded.


