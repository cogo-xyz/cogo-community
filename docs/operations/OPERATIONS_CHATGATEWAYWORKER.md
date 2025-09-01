# ChatGatewayWorker Operations Guide

## Runtime flags
- `CHAT_DISABLE_REALTIME=true`: Disable Realtime subscription (poll-only debug mode)
- `CHAT_POLL_INTERVAL_MS` (default 60000)
- `CHAT_LOOKBACK_MIN` (default 2)
- `CHAT_PROCESS_COOLDOWN_MS` (default 15000)
- `CHAT_ASK_TIMEOUT_MS` (default 30000)

## Health and logs
- Realtime:
  - `HEALTH SUBSCRIBED { ts }`: Realtime channel subscribed
  - `realtime status: <STATUS> { ts }`: State transitions
- Polling:
  - `HEALTH POLL_TICK { ts }`: Poll loop tick
  - `HEALTH POLL_HANDLED { id, ms }`: A user message handled via polling
- Rate limit:
  - `entering cooldown due to rate limit` ⇒ cools down ~65s
- Fallback:
  - When askRag fails, deterministic fallback assistant row is inserted

## Expected behavior (prod)
- With Realtime ON: assistant message inserted within 15–60s after user message
- Polling backup: ensures processing if Realtime fails

## Quick tests
```bash
SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... SUPABASE_ANON_KEY=... npx ts-node src/workers/ChatGatewayWorker.ts | tee -a logs/chat-worker.log
SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... npx ts-node src/scripts/chat/quickAsk.ts "Where is SupabaseVectorStore.searchSimilar implemented?"
```


