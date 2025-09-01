## CreateGo Agent Reference Integration Plan

This plan describes how to reference CreateGo Agent capabilities without migrating its DB/runtime, and implement them on top of COGO standards: Envelope, Supabase Realtime bus, Edge Functions, distributed Orchestrator, LangGraph, pgvector + Neo4j.

### Scope and Principles
- Reference only: do not import CreateGo schemas or Python runtime.
- Keep COGO standards: Envelope(progress/done/error/input_required), traceId/sessionId/projectId/cogoProjectId.
- Distributed execution: Orchestrator + Workers via `public.agent_messages`/`public.bus_events` with Supabase Realtime broadcasting.
- Long-term: replace HTTP proxies with native LangGraph nodes.

### Tool Mapping (from CreateGo models → COGO UUI standard)
- figma/convert_to_creatego ← JSONConversionRequest
- uui/variables_derive ← DeriveVariablesRequest
- uui/symbols_map ← SymbolMappingRequest
- uui/bdd_generate ← BDDGenerationRequest
- uui/bdd_refine ← BDDRefinementRequest
- uui/actionflow_refine ← ActionFlowRefinementRequest

Streaming/HITL mapping:
- StreamingResponseEvent → Envelope progress
- ActionFlowCompletion → Envelope done
- InputRequired* ↔ Envelope input_required and respond → resume

### LangGraph Workflow Pattern
- Nodes: validate → preprocess → tool_core → postprocess → artifact_offload
- HITL branch: input_required wait → respond → resume
- Routing keys: `(service=mcp, role=gateway|run, shard, tenant)`

### Data/Scope
- user_id/session_id/project_id → Envelope sessionId/projectId; internal projects use cogoProjectId.
- Broadcast scopes: `plugin:<sessionId>` or project/cogoProject.

### Bridge Strategy
- Short-term: `/compat/*` HTTP proxies to Python services (reference only), convert to Envelope events.
- Long-term: native LangGraph nodes replacing proxies incrementally.

### Observability/Safety
- Circuit breaker/retry per-tool keys.
- Large results: artifact offload and return URLs.
- Policies: deny-by-default + allowlist for new routes; RLS preserved.

### Done so far (implemented)
- Protocol/Realtime
  - Envelope schema, validation helpers.
  - RealtimeBroadcaster and BusEventsBroadcaster.
  - MCPGatewayBusWorker with HITL, artifact offload, cogoProjectId propagation.
- Routes/Edge/Smoke
  - Edge Function (enqueue/result/respond/compat/metrics/trace).
  - Local MCP routes: enqueue/result/feed/events/timeline/trace/summary/dashboard/admin.
  - Smoke tests including WS progress/done flow (mock OK).
- DB/Realtime hardening
  - REPLICA IDENTITY FULL, publication membership, RLS/policies, project_id indexes, cogo views, sequence privs.
  - Ensure scripts and schema snapshots.
- Backups/Docs
  - Supabase schema dumps and tagged backups (internal/external refs).
  - Protocol docs, OpenAPI for Edge, checklist.

### Next (to implement)
- Protocol schemas
  - Add variables/derive, symbols/map, bdd/generate, bdd/refine, actionflow/refine parameter schemas.
- MCP Gateway routing
  - Branch by tool; register circuit/retry keys.
- Compat routes (reference-only)
  - `/api/mcp/compat/{variables/symbols/bdd/actionflow}` → HTTP proxy; Envelope broadcasting.
- Orchestrator + LangGraph
  - Register initial two workflows (variables/derive, bdd/generate); expand to the rest.
  - HITL resume path and streaming mapping.
- Observability
  - Extend metrics categories and dashboard coverage.
- Neo4j reference schema
  - Dump constraints/indexes/labels/rel types/APOC meta to `schema/neo4j/backups/<ts>/`.
- Policy/Security
  - Update route allowlist; admin token guard for non-GET.
- Type fixes
  - Resolve optional route TS generics (e.g., alerts preview).

### Milestones and DoD
1) P1: figma/convert_to_creatego, variables/derive E2E → enqueue→progress→done; timeline/metrics/artifacts green.
2) P2: symbols/map, bdd/generate, bdd/refine.
3) P3: actionflow/refine (streaming/HITL), Neo4j schema snapshot.
4) P4: Native nodes, remove proxies; dashboards updated.


