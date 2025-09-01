## Figma Integration Protocol (User Chat vs IDE Integration)

Date: 2025-08-25

### Channels
- User Chat (conversation UX)
  - Endpoint: /functions/v1/chat (via chat-gateway)
  - Auth: Browser/Plugin Anon (dev), JWT (prod)
  - SSE events: meta, llm.delta, llm.done

- IDE Integration (data sync UX)
  - Endpoints: /functions/v1/figma-compat/* (convert, ingest, presign, generate, figma/from-uui)
  - Auth: IDE user session (RLS), SRK only for projection/legacy write paths
  - Outbox: cogo.project_updates → Projection worker → public.*

### JSON Contracts
- cogo_ui_json: primary UI JSON for COGO
- uui_json: normalized UI structure for conversions
- figma_like: minimal Figma-compatible preview structure

### Separation of Concerns
- Chat: user-facing prompts and responses; does not directly mutate public.*
- IDE: reads/writes public.*; agent changes flow via outbox→projection

### New Endpoints
- POST /figma-compat/figma/from-uui → { figma_like[] }
- POST /figma-compat/uui/generate → { uui_json, cogo_ui_json } (demo)
- (planned) POST /figma-compat/uui/generate/llm → LLM-backed generation


