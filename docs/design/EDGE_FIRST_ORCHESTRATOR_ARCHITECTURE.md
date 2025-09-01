# Edge-first Orchestrator Architecture

Updated: 2025-08-23

## Goals
- Move LLM/RAG/Role selection to Supabase Edge (Functions + Realtime + SSE)
- Keep LangGraph workflows and orchestration in distributed agents
- Achieve determinism, scale, and centralized control/observability

## High-level Design
- Edge Services
  - role-select: intent → role_id (LLM + RAG context)
  - chat/embedding/rag: SSE-first, HTTP fallback
  - graph: HTTP v2 (Aura) env-only
  - events: Realtime channels (trace_id per request)
- Orchestrator (Agent)
  - consumes Edge results via SSE/Realtime
  - runs LangGraph workflows; nodes that require AI call Edge
  - handles retries/backoff, idempotency, circuit breaker

## Request Flow
1) Client → Edge(chat): analyze intent, stream tokens + role_id
2) Edge → Realtime: post events with `trace_id`
3) Orchestrator subscribes to `trace_id` channel; starts LangGraph
4) LangGraph nodes call Edge (chat/embed/rag/graph) asynchronously
5) Results/metrics flow back via Realtime and stored snapshots

## Data & Keys
- No DB reads in hot Edge; env-only config for providers
- Role prompts/packages stored as JSON in RAG (Edge endpoint fetch)
- Idempotency keys for requests; artifacts for traces

## Observability
- Per-request `trace_id` across Edge/Agent/DB
- Metrics: p50/p95 latency, error rate, throughput, tokens
- Artifacts: prompts, partial outputs, decisions

## Failure Handling
- Edge: rate limit/backoff; short timeouts
- Agent: queue + retries + compensation; dead-letter
- Rollback: versioned Edge endpoints; agent-side feature flags

## Security
- Bearer + apikey headers; project-level SRK only where needed
- No keys in agent code; env or KeyClient
- Strict CORS and per-route auth

## Migration Notes
- secure_keys eliminated from hot path
- graph endpoint env-only (done)
- llmRoutes secure_keys fallback removed (done)
- next: role-select/chat/embed Edge endpoints, LangGraph edge-call node
