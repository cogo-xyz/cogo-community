# Agent Auth CI Gate

## Purpose
- Prevent regressions in agent authentication performance and reliability.
- Validate HMAC + timestamp + nonce flow under SSE-heavy patterns.

## How to Run (Local)
```bash
# Required env
export SUPABASE_EDGE=...    # https://<ref>.functions.supabase.co
export SUPABASE_ANON_KEY=...
export AGENT_ID=...
export AGENT_SECRET=...

# Optional thresholds
export AGENT_GATE_N=20
export AGENT_GATE_P50_MS=1500
export AGENT_GATE_P95_MS=3000
export AGENT_GATE_ERROR_RATE_MAX=0.1
export AGENT_GATE_REQUIRE_REPLAY=0  # 1 to require replay detection

npm run agent:gate
# Artifact: ./artifacts/agent-auth/report.json
```

## What It Checks
- healthz reachable
- (optional) metrics reachable
- N HMAC calls OK with p50/p95 below thresholds
- errorRate <= max
- (optional) nonce replay detection

## GitHub Actions
- Workflow: `.github/workflows/agent-auth-ci.yml`
- Required secrets: `SUPABASE_EDGE`, `SUPABASE_ANON_KEY`, `AGENT_ID`, `AGENT_SECRET`
- Uploads artifact `agent-auth-report`

## Troubleshooting
- 401/403: ensure headers `Authorization: Bearer <ANON>`, `apikey: <ANON>`
- `agent_secret_not_found`: seed `cogo.agent_tokens` or enable dev `EDGE_ALLOW_HEADER_SECRET=true` (dev only)
- BOOT_ERROR: redeploy function and check duplicates in code; verify function secrets

## Roadmap
- Add load profile (concurrency) and percentile by size
- Record p99 and skew violations count

## Latest Dev Test Snapshot

- Date: 2025-08-23 (local)
- RAG Gate:
  - p50 ≈ 1829ms, p95 ≈ 1954ms, avgItems ≈ 1, ok: true
  - Command: `npm run -s rag:gate`
- LLM Gate:
  - p50 ≈ 350ms, p95 ≈ 386ms, errors: 0, ok: true
  - Command: `npm run -s llm:gate`
- Agent Gate:
  - runs: 20, errors: 0, p50 ≈ 210ms, p95 ≈ 353ms, replayDetected: false, ok: true
  - Prep: rotate secret via Edge `POST /agent/secret/rotate` (agent_id: `7b897582-f74f-4712-ad5d-7cc03f28d796`)
  - Command:
    ```bash
    AGENT_ID=7b897582-f74f-4712-ad5d-7cc03f28d796 \
    AGENT_SECRET=<new_secret_from_rotate> \
    npm run -s agent:gate
    ```
