# Sandbox Worker (Python WebSocket)

This document explains how to use the Python WebSocket Sandbox from `cogo-worker` as the standard sandbox worker for the distributed system.

- Source folder: `cogo-worker/`
- Primary servers:
  - `websocket_sandbox_server.py` (WebSocket sandbox runtime)
  - `realtime_link.py` (Supabase bridge: subscribe→dispatch→report)
- Routing key: `(service=sandbox, role=run, shard=0)`
- Events: `sandbox_done`, `sandbox_retry`, `sandbox_failed`

## Local (dev) run
1) Install deps
```bash
cd cogo-worker
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```
2) Start WebSocket sandbox
```bash
python websocket_sandbox_server.py  # default 0.0.0.0:8765 (see script)
```
3) Start Supabase bridge
```bash
# From repo root (or keep venv active inside cogo-worker)
SUPABASE_URL=... \
SUPABASE_SERVICE_ROLE_KEY=... \
AGENT_SERVICE=sandbox AGENT_ROLE=run AGENT_SHARD=0 \
SANDBOX_WS_URL=ws://127.0.0.1:8765 \
python cogo-worker/realtime_link.py
```
4) Smoke (enqueue → done)
```bash
# From repo root, env loaded
npm run smoke:sandbox
```
- Asserts `bus_events` includes `sandbox_done` for the queued message id within timeout.

## Docker (optional local compose)
If you prefer containers, two services can be used:
- `sandbox-ws`: builds from `cogo-worker` and runs `websocket_sandbox_server.py`
- `sandbox-bridge`: runs `realtime_link.py` with Supabase env and `SANDBOX_WS_URL=ws://sandbox-ws:8765`

See `docker-compose.local.yml` for service definitions.

## Notes
- Python WS sandbox is the authoritative runtime for sandbox tasks. The Node `SandboxBusWorker.ts` is optional and not required in production.
- All sandbox messages must include `trace_id` for observability. TTL handling is managed in the bridge and downstream updates (`agent_messages.result_*`, `bus_events`).
