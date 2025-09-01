## Three-Repository Model: cogo-agent-core, cogo-client, cogo-community

This document defines the recommended 3-repo structure for the COGO platform to support an agentic (RAG + LLM) self-upgrade loop, strong security, and clean public distribution.

### Repositories and Roles
- cogo-agent-core (Private)
  - Single source of truth for server-side assets:
    - Supabase (schemas, SQL, Edge functions, secrets policy, Realtime broadcast, bus_events)
    - Orchestrator/Workers, pipelines, gates, observability
  - Develop → Gate → Deploy (server-first, agent-driven)

- cogo-client (Private)
  - Consumer applications and packages
  - Suggested layout:
    - `packages/` – shared UI/state/schemas/helpers
    - `ide/` – IDE app
    - `starter/` – starter or preview apps
    - `backend/` – client-side services or adapters (no Supabase schema/Edge ownership)
    - `external/cogo-agent-core` – submodule to consume SDKs directly from agent-core

- cogo-community (Public)
  - Public-safe artifacts only: SDK/CLI/Plugin + docs/samples
  - No orchestrator/workers/edge/secrets/internal ops scripts

### Why this model
- Security & Centralization: Supabase and server logic are centralized in agent-core
- Consistency: SDK contracts and transport live with the server features and gates
- Clean Public Distribution: community repo receives only public-safe artifacts
- Developer Ergonomics: client consumes SDKs via submodule path deps → minimal drift

### Client ↔ Agent-core linkage
1) Add submodule and sparse-checkout only SDKs
```bash
cd /Users/<you>/Desktop/Dev/cogo-project/cogo-client
mkdir -p packages ide starter backend external
git submodule add https://github.com/cogo-xyz/cogo-agent-core external/cogo-agent-core
cd external/cogo-agent-core
git sparse-checkout init --cone
git sparse-checkout set packages/cogo-chat-sdk-ts packages/cogo-chat-sdk-flutter
git submodule update --init --recursive
```

2) TypeScript path dependency
```json
{
  "dependencies": {
    "@cogo/chat-sdk": "file:external/cogo-agent-core/packages/cogo-chat-sdk-ts"
  },
  "scripts": {
    "postinstall": "npm --prefix external/cogo-agent-core/packages/cogo-chat-sdk-ts run build || true"
  }
}
```

3) Flutter path dependency
```yaml
dependencies:
  cogo_chat_sdk_flutter:
    path: external/cogo-agent-core/packages/cogo-chat-sdk-flutter
```

### Release & Publish flow (summary)
1) In agent-core: develop, run gates
```bash
npm run gate:unified
```
2) Deploy Supabase from agent-core (gated)
```bash
npm run deploy:supabase
```
3) Publish public artifacts to community (allowlist, secrets-safe)
```bash
export COGO_COMMUNITY_DIR=/Users/<you>/Desktop/Dev/cogo-project/cogo-community
npm run publish:community
```
4) In client: update submodule pin and run smoke tests

### Policies
- Supabase assets (SQL/Edge/secrets) exist only in agent-core
- Public distribution happens only via community allowlist copy
- SDKs maintain identical TS↔Flutter structure and semantics
- Secrets never appear in code/docs/logs; rotate immediately if exposed


