## Ports & Endpoints Allocation (Local vs Production)

- API (agent core)
  - Local: host 3001 -> container 3000 (`/api/*`)
  - Prod: 3000 behind reverse proxy (TLS)

- Metrics server
  - Local: 3100
  - Prod: internal only (no public exposure)

- MCP (local developer tools)
  - Figma MCP: Local 3007 -> container 3000 (was 3002; moved to avoid collisions)
  - Browser MCP: Local 3003 -> container 3000

- Sandbox WS
  - Local: 8765
  - Prod: internal network only

- Supabase Edge Functions (remote)
  - Agent Auth: `/functions/v1/agent`
    - `GET /healthz`
    - `POST /enroll/start`, `POST /enroll/complete`
    - `POST /session/start`, `POST /session/extend`
    - `POST /token/refresh`
    - `POST /protected/echo`
  - RAG: `/functions/v1/rag`
    - `GET /healthz`, `POST /search`, `POST /cache/bust`
  - LLM: `/functions/v1/llm`
    - `GET /healthz`, `POST /chat`, `POST /chat/stream`(SSE), `POST /embed`
  - Chat Gateway: `/functions/v1/chat-gateway` (ingress → forwards to /chat)
  - Chatting (legacy): `/functions/v1/chatting` (deprecated proxy; Sunset: 2025-12-31; use `/functions/v1/chat`)

Guidelines
- Avoid port 3002 for local tools; reserve 3007 for Figma MCP to prevent conflicts.
- Expose only necessary ports publicly; prefer reverse proxy + TLS in production.
- Document any new service with host:container mapping and rationale.

Production Policy
- Only public: reverse proxy 443→API 3000; block metrics (3100) externally.
- MCP WS endpoints are developer-only; do not expose in production.
- Maintain env-driven endpoints: `MCP_FIGMA_WS_URL` (default `ws://localhost:3007`), `MCP_BROWSER_WS_URL`.
