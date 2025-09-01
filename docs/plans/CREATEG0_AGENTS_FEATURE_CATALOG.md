## CreateGo-Agents Feature Catalog → cogo-agent Mapping

Date: 2025-08-25

### Source paths
- /Users/hyunsuklee/Desktop/Dev/cogo-project/CreateGo-Agents
  - figma_to_creatego_agent.py (conversion pipeline)
  - api_gateway.py (ingress/gateway)
  - actionflow_ws_agent.py (actionflow)
  - cogo_json_tools/* (JSON tools/utilities)
  - prompts/* (variables, symbols, bdd, action flow)

### Replacement targets (cogo-agent)
- Conversion: Supabase Edge `figma-compat` (UUI ⇄ COGO UI JSON)
- Gateway: `chat-gateway`/`chat` SSE entrypoints
- Action Flow: Executor workflows (UiActionWorker)
- JSON Tools: `src/shared/ui/ast`, `supabase/functions/figma-compat/*`
- Prompts: consolidate under `docs/prompts` and embed in figma-compat where needed

### Gaps/TBD
- ActionFlow refinement parity tests
- Prompt variants coverage and sampling controls
- Any Python-only visualizer tooling (box_visualizer)


