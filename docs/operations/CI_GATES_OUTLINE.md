## CI/Gates Outline for Distributed Agents

### Goals
- Build date-tagged images for orchestrator/indexing/research/executor.
- Spin up via dedicated compose (non-blocking) and verify health.
- Run service gates (latency/error-rate thresholds) and archive artifacts.

### Pipeline Stages
1) Setup
   - Checkout, Node 20, cache restore (npm, tsbuild, Docker layers).
   - `.env`/secrets provision via CI secret store.
2) Build
   - `docker build` for 4 images with `DATE=$(date +%Y%m%d)`.
3) Compose Up
   - `docker compose -f infra/compose/docker-compose.pipeline.yml up -d`.
4) Health Checks
   - `curl -fs localhost:6001/health` ... `6005/health`.
5) Gates
   - `npm run agent:gate` (Agent Auth), `npm run llm:gate`, optional `npm run rag:gate`.
6) Artifacts
   - `npm run metrics:snapshot` and upload `/artifacts`.
7) Teardown
   - `docker compose -f infra/compose/docker-compose.pipeline.yml down -v`.

### Thresholds (example)
- Agent Gate: p50 ≤ 1500ms, p95 ≤ 3000ms, error-rate ≤ 10%.
- LLM Gate: p50 ≤ 1500ms, p95 ≤ 3500ms, error-rate ≤ 10%.

### Safety & Secrets
- No `rsync --delete` against `$HOME`; use archive-based rollouts only.
- Secrets in CI env/secret store; never commit/paste keys.

### Useful Scripts
- `npm run agent:gate`
- `npm run llm:gate`
- `npm run metrics:snapshot`
- `npm run smoke:distributed`


