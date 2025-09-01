# Edge-first Orchestrator Migration Plan

Updated: 2025-08-23

## Phase 0 – Baseline (done)
- Graph Edge env-only (HTTP v2)✔
- secure_keys hot-path 제거✔
- Agents inject SUPABASE_EDGE✔

## Phase 1 – Role Select to Edge
- Implement Edge function: `/role/select` (LLM + RAG context)
- Input: `{intent_text, context_hints?, trace_id}`
- Output: `{ok, role_id, confidence, tokens?, trace_id}` (SSE stream)
- Store role prompts/packages in RAG JSON; Edge fetches by role_id
- Acceptance: p50<1.5s, error<2%, SSE streaming works

## Phase 2 – Chat/Embed/RAG Edge Standardization
- Unify headers & SSE protocol; add idempotency-key
- Add rate limits and backoff policies
- Add artifacts (prompt, partials) with trace links
- Acceptance: Gate: N=100, error<3%, token accounting valid

## Phase 3 – LangGraph Edge-call Node
- New node type: `edge_call` with retries, timeout, compensation
- Integrate into `LangGraphWorkflowEngine`
- Acceptance: workflows run with 0 local LLM calls

## Phase 4 – Realtime Event Bus
- Channel per `trace_id`; standard events: `role.selected`, `llm.delta`, `rag.done`
- Orchestrator subscribes; resumes nodes on events
- Acceptance: sustained load 50 rps, no dropped events in 10m

## Phase 5 – Observability & Gates
- Metrics: p50/p95, error rate, throughput, tokens
- Traces: Edge↔Agent correlation via `trace_id`
- Gates: agent:gate, llm:gate, rag:gate (updated)

## Phase 6 – Cleanup
- Remove legacy LLM direct clients from agents (keep fallback flags)
- Docs, runbooks updated; major version tag

## Risks & Mitigations
- Cold starts → pre-warm, shorter bundles
- Backpressure → queue with rate policy
- Auth issues → standard headers, project SRK only in Edge

## Rollout
- Canary by service (role-select → chat → embed → rag)
- Feature flags per agent shard
- Rollback by Edge route version
