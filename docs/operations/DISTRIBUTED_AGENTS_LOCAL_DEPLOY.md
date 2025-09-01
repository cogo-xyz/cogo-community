# Distributed Agents – Local Deploy (cogo0-agent)

Updated: 2025-08-23

- Stack name: cogo0-agent
- Ports: orchestrator 6101, indexing 6102, research 6103, executor 6105, metrics 3200
- Neo4j:
  - NEO4J_URI=neo4j+s://001b3e63.databases.neo4j.io
  - NEO4J_USERNAME=neo4j
  - NEO4J_DATABASE=neo4j
- Supabase:
  - SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY

## Build & Up

```bash
docker compose -p cogo0-agent -f infra/compose/docker-compose.cogo0.yml build
docker compose -p cogo0-agent -f infra/compose/docker-compose.cogo0.yml up -d
```

## Health

- Orchestrator: http://localhost:6101/healthz
- Metrics: http://localhost:3200/metrics

## Down

```bash
docker compose -p cogo0-agent -f infra/compose/docker-compose.cogo0.yml down -v
```

## Edge Call Node (chat/rag)
- Added  node type to 
- Supported edge functions: chat, embed, rag (graph placeholder)
- Added CI smoke: 
- How to run: 🚀 Initializing LangGraph Workflow Engine...
🧠 USE_EDGE_LLM=true → skip local SDK init; using Edge
✅ LangGraph Workflow Engine initialized successfully
📋 Registered workflow: edge_smoke
🚀 Executing workflow for role: cogo-orchestrator-agent
📋 Executing node: edge_chat (edge_call)
✅ Node edge_chat completed successfully
📋 Executing node: edge_rag (edge_call)
✅ Node edge_rag completed successfully
{
  "ok": true,
  "executionTime": 485,
  "errors": [],
  "resultKeys": [
    "edge_chat",
    "edge_rag"
  ]
}

## Clients
- 
- 
-  (overloads for /rag and /rag/search)

## Notes
- Requires env: SUPABASE_EDGE, SUPABASE_ANON_KEY
- Optional: AGENT_ID, AGENT_SECRET for signed requests

### Edge+Orchestrator+Graph Bundle
- Run health: `npm run health:curl`
- Validate env: `./scripts/validate-cogo0-env.sh`
- Run bundle: `npm run -s smoke:edge+orch+graph`

### cogo0 compose
- Up:    `npm run cogo0:up`
- Down:  `npm run cogo0:down`
- Logs:  `npm run cogo0:logs`
- Health: `npm run health:curl`

### Trace & Idempotency
- Clients pass `trace_id` in body and `idempotency-key` header
- Verify: `SUPABASE_EDGE=https://cjvgmyotqxfpxpvmwxfv.functions.supabase.co SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNqdmdteW90cXhmcHhwdm13eGZ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI1OTc1MTgsImV4cCI6MjA2ODE3MzUxOH0.ewOqV1vMk9fjqWK0zd-SkUIzR8v6A54UbYvw_fKnxDY npx ts-node src/scripts/ci/chatIdempotencySmoke.ts`

### Observability Bundle
- Run: `npm run -s smoke:edge:observability`
- Includes: chat SSE/meta, chat idempotency, trace→metrics, graph error mapping, orchestrator ingress trace, embed SSE

### Orchestrator Trace Smoke
- Run: `METRICS_HOST=http://localhost:3200 SUPABASE_EDGE=https://cjvgmyotqxfpxpvmwxfv.functions.supabase.co SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNqdmdteW90cXhmcHhwdm13eGZ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI1OTc1MTgsImV4cCI6MjA2ODE3MzUxOH0.ewOqV1vMk9fjqWK0zd-SkUIzR8v6A54UbYvw_fKnxDY npx ts-node src/scripts/ci/orchestratorIngressTraceSmoke.ts`

### Role-Select & Route Node
- Workflow: edge_call(role-select) → route(selectedRoleId) → rag(asKnowledge, onlyIfRole) → chat
- Run route smoke: 

### Edge bus_events (Observability)
- Enable: 
- chat/embed/rag publish start/done with {trace_id, latency_ms, idempotency_key}
- Verify trace: 

### Observability Bundle (All-in-One)
- Run: {
  "ok": {
    "input": 19,
    "output": 25
  },
  "meta": true,
  "delta": true,
  "done": {
    "input": 19,
    "output": 25
  },
  "counts": 6
}
{
  "ok": true,
  "a": {
    "ok": true,
    "trace_id": "trace_1756003142957",
    "text": "Echo: idempotency test",
    "usage": {
      "input": 16,
      "output": 22
    }
  },
  "b": {
    "ok": true,
    "trace_id": "trace_1756003142957",
    "text": "Echo: idempotency test",
    "usage": {
      "input": 16,
      "output": 22
    }
  }
}
[chat] {
  traceId: '1d11ab74-2f5e-4e6a-9c7a-82a2686b321e',
  frames: 6,
  deltas: 17,
  bytes: 752
}
[chat][trace] { ok: true, bytes: 73 }
[embed] {
  traceId: 'b7f239f9-00ff-4ad0-949f-828ae41ba322',
  frames: 3,
  deltas: 0,
  bytes: 440
}
[embed][trace] { ok: true, bytes: 73 }
traceSseVerify done
{
  "happy_ok": true,
  "rows": 1
}
{
  "error_mapped": true,
  "error": "{"ok":false,"rows":[],"stats":{"via":"http_tx_commit","status":403,"errors":[],"resultCount":0}}",
  "code": 403,
  "via": "http_tx_commit"
}
{
  "status": 202,
  "trace_id": "56d4b729-7710-4c53-81e3-1052dad7c459"
}
{
  "metrics_ok": true,
  "bytes": 408
}
🚀 Initializing LangGraph Workflow Engine...
🧠 USE_EDGE_LLM=true → skip local SDK init; using Edge
✅ LangGraph Workflow Engine initialized successfully
📋 Registered workflow: role_select_flow
🚀 Executing workflow for role: cogo-orchestrator-agent
📋 Executing node: role (edge_call)
✅ Node role completed successfully
📋 Executing node: rag (edge_call)
✅ Node rag completed successfully
📋 Executing node: llm (llm)
✅ Node llm completed successfully
{
  "ok": true,
  "errors": [],
  "keys": [
    "role",
    "rag",
    "llm"
  ]
}
🚀 Initializing LangGraph Workflow Engine...
🧠 USE_EDGE_LLM=true → skip local SDK init; using Edge
✅ LangGraph Workflow Engine initialized successfully
📋 Registered workflow: role_select_route_flow
🚀 Executing workflow for role: cogo-orchestrator-agent
📋 Executing node: role (edge_call)
✅ Node role completed successfully
📋 Executing node: route (route)
✅ Node route completed successfully
📋 Executing node: rag (edge_call)
✅ Node rag completed successfully
📋 Executing node: llm (llm)
✅ Node llm completed successfully
{
  "ok": true,
  "errors": [],
  "route": {
    "type": "route",
    "selectedRoleId": "cogo-orchestrator-agent",
    "from": "role"
  },
  "keys": [
    "role",
    "route",
    "rag",
    "llm"
  ]
}
{
  "ok": true,
  "names": [
    "meta",
    "rag.item",
    "rag.item",
    "rag.item",
    "rag.done"
  ],
  "counts": 5
}
{
  "ok": true,
  "mode": "strict",
  "meta": true,
  "done": true,
  "names": [
    "meta",
    "embed.chunk",
    "embed.done"
  ]
}
- Includes: role-select, route, rag STRICT, embed STRICT, chat SSE/meta, trace→metrics, graph error mapping
