# Orchestrator Protocol Specification (Edge + Realtime + SSE)

Updated: 2025-08-23

## 1. Goals
- Deterministic, scalable, observable messaging between Edge services and distributed orchestrator
- Clear separation: Edge for AI services (LLM/RAG/Graph/Role), Orchestrator for workflows (LangGraph)
- Idempotent, resumable, replayable message flows

## 2. Channel Topology
- Project channels (broadcast): `project:{project_id}:events`
- Task channels (scoped): `task:{task_id}:events`
- Trace channels (ephemeral per request): `trace:{trace_id}`
- Agent control channels: `agent:{agent_id}:ctrl`

Notes:
- Orchestrator subscribes to `project:*` (or shard-filtered) and dynamically subscribes to `task:{task_id}` and `trace:{trace_id}` during execution
- Edge emits to `trace:{trace_id}` for low-latency SSE bridging and to `task:{task_id}` for persistence hooks

## 3. Envelope
```json
{
  "envelope_version": "v1",
  "trace_id": "uuid",
  "task_id": "uuid",
  "session_id": "uuid|optional",
  "project_id": "string|optional",
  "event_type": "role.selected|llm.delta|llm.done|rag.done|graph.done|workflow.step|workflow.done|error",
  "ts": 1730000000000,
  "source": { "service": "edge|agent|orchestrator", "role": "role-id|module", "instance": "pod-id" },
  "headers": { "idempotency_key": "...", "ttl_ms": 60000 },
  "payload": {}
}
```
- All messages MUST include `trace_id`, `event_type`, `ts`
- `idempotency_key` required for Edge → Orchestrator messages (dedup)

## 4. Event Types & Payloads
### 4.1 role.select.request
- Edge receives intent; Orchestrator may request enrichment
```json
{
  "intent_text": "...",
  "candidate_roles": [ { "role_id": "...", "triggers": ["..."] } ]
}
```

### 4.2 role.selected
```json
{
  "role_id": "...",
  "confidence": 0.87,
  "prompt_template_id": "...",
  "rag_context_ref": "rag://collection/keys?..."
}
```

### 4.3 llm.delta / llm.done
```json
// delta
{ "token": "....", "index": 123 }
// done
{ "text": "...", "usage": { "input": 123, "output": 456 } }
```

### 4.4 rag.done
```json
{ "items": [ { "id":"doc1", "score":0.81, "snippet":"..." } ] }
```

### 4.5 graph.done
```json
{ "rows": [["v1","v2"]], "stats": { "via":"http_query_v2", "status":202 } }
```

### 4.6 workflow.step / workflow.done
```json
// step
{ "node_id":"call-edge-llm", "status":"ok|fail", "latency_ms":321, "data":{}} 
// done
{ "result": {"summary":"..."}, "metrics": {"p50_ms":..., "errors":0} }
```

### 4.7 error
```json
{ "code":"rate_limit", "message":"...", "retry_after_ms": 2000 }
```

## 5. Orchestrator State Machine (LangGraph)
States: `INIT → ROLE_SELECT → CONTEXT_ENRICH → PLAN → EXECUTE(N*) → AGGREGATE → COMPLETE|FAILED`
- INIT: subscribe to `trace:{trace_id}`; validate request
- ROLE_SELECT: send Edge role-select; wait llm.done/role.selected
- CONTEXT_ENRICH: Edge rag/graph; upon rag.done proceed
- PLAN: Planner builds LangGraph plan for selected role
- EXECUTE: nodes of type `edge_call` (chat/embed/rag/graph) or `tool_call`
- AGGREGATE: merge results; compute metrics
- COMPLETE/FAILED: emit workflow.done or error; unsubscribe

Transitions are event-driven from Realtime messages keyed by `trace_id`. Each node carries `timeout_ms`, `retry`, `compensate` policies.

## 6. Delivery Semantics
- At-least-once delivery via Realtime; dedup by (`trace_id`,`event_type`,`headers.idempotency_key`,`payload.hash`)
- Orchestrator maintains `seen_keys` cache (LRU)
- Retry/backoff: Edge includes `retry_after_ms`; Orchestrator schedules

## 7. AuthN/AuthZ
- Edge routes require `Authorization: Bearer <ANON>` + `apikey`
- Internal agent control uses SRK only where necessary (never on client routes)
- Channel ACL: task/trace channels scoped by `project_id`/`session_id`

## 8. Telemetry
- All events include `trace_id`, `ts`
- Aggregates exposed at `/api/metrics/trace/{trace_id}`
- Token usage attached to llm.done; stored in artifacts store

## 9. Versioning & Compatibility
- Envelope: `envelope_version: v1`
- Route versioning: `/v1/chat`, `/v1/role/select`, etc.
- Backward compatibility for `delta` formats

## 10. Validation & Gates
- Gate: 100 requests, p50<1500ms, error<2%, no duplicated events
- Replay test: re-emit llm.delta/done; orchestrator dedup holds

## 11. Open Tasks
- Implement `/role/select` Edge endpoint (SSE)
- Add `edge_call` node type to LangGraph engine
- Realtime channel ACL & shard strategy
