## Realtime Channel & RLS Policy (SSE-first)

### Realtime
- Client path uses SSE; Realtime remains optional for server-to-client broadcasts.
- Channels (optional): `session:{session_id}`. Only Edge publishes; clients subscribe if needed.

Permissions:
- Clients: subscribe only to own `session:{session_id}`
- Edge: publish to `session:{session_id}`
- TTL for channel tokens; enforce per-session rate limits

### RLS (Database)
- Only Edge writes to `messages`, `message_embeddings`, `document_embeddings`.
- Clients may SELECT rows scoped to their `session_id`.

Policy Examples (pseudo):
```sql
-- messages
create policy client_read_own_messages on messages
  for select using ( auth.uid() = messages.user_id and messages.session_id = current_setting('request.session_id', true) );

revoke insert, update, delete on messages from anon, authenticated;
-- Edge uses service role (bypasses RLS) for writes

-- embeddings
revoke all on message_embeddings from anon, authenticated;
create policy client_read_own_embeddings on message_embeddings
  for select using ( message_embeddings.session_id = current_setting('request.session_id', true) );
```

### Idempotency & Tracing
- All writes include `trace_id`, `request_id`, `idempotency_key` (nullable) for dedup and observability.

### Rate Limiting
- Enforce per-session limits at Edge (chat/min, embed/min, concurrent streams). Reject with 429 and emit SSE `error`.


