# Distributed Agents – Naming, Roles, Deployment, and Dev Guide

This document defines the standardized agent names, roles, message routing, edge ingress, and deployment practices for the distributed COGO agent platform. It supersedes ad-hoc worker names and aligns with the “Single Realtime per container + Central Message Bus” architecture.

## 1) Naming & Role Taxonomy

Use `cogo-<domain>-<role>` process names and a strict routing key schema in the bus. Core agents:

- cogo-orchestrator-brain
  - Role: Orchestrator (Sense/Diagnose/Plan/Allocate/Observe/Evaluate/Update)
  - Bus subscription: `service=orchestrator, role=decide, shard=0`
- cogo-executor-dispatcher
  - Role: Executor (publish assignments to bus, apply budget/TTL/model policies)
  - Dedicated process recommended (separate from orchestrator) for policy isolation and scaling
- cogo-gateway-chat
  - Role: Gateway for chat assignments (RAG+KG hybrid answering)
  - Bus subscription: `service=gateway, role=chat, shard=N`
- cogo-rag-embed
  - Role: Vector embedding of documents/code
  - Bus subscription: `service=rag, role=embed, shard=N`
- cogo-kg-builder
  - Role: Code KG build & reporting (local import graph; Neo4j optional later)
  - Bus subscription: `service=kg, role=build, shard=N`
- cogo-rag-dispatcher (optional)
  - Role: DB events → bus messages (vector_documents/code_vectors to rag/kg)
- cogo-bus-reclaimer
  - Role: Requeue stuck claimed messages after RECLAIM_AFTER_MS
- cogo-bus-retention
  - Role: Delete old done/failed after RETENTION_DAYS
- cogo-metrics-server
  - Role: REST dashboard and metrics aggregation for ops
  - Exposes: `/api/metrics/*`, `/dashboard/*`; collects bus latency p50/p90, failure rates, gate outcomes
- (Roadmap) cogo-sandbox-manager
  - Role: WebSocket control plane for sandbox workers (start/stop/limits/logs)

Routing keys (strict): `(service, role, shard, tenant)`.
Keep one realtime subscription per container (table=public.agent_messages, row filters by routing keys).

## 2) Message Bus Contract

- Table: `public.agent_messages`
- Columns (subset): `id, created_at, service, role, shard, tenant, payload, status, claimed_by, claimed_at, done_at, error, attempts, last_error_at, retry_at, result_snippet, result_url`
- Assignment envelope (policy-carrying) – placed inside payload:

```
{
  "__assignment": {
    "agent_id": null,
    "version": null,
    "model": null,
    "budget": { "maxCostUsd": 0.10, "maxTokens": 200000 },
    "ttl_ms": 60000
  }
}
```

Workers MUST honor `__assignment` fields when present (budget/TTL/model enforcement).

Events (audit) to insert into `public.bus_events`:
- `execute_enqueued`, `execute_retry`, `execute_failed`, `execute_done`

## 3) Edge Ingress (Supabase Edge Functions)

- Purpose: accept external requests and enqueue bus messages for orchestrator
- Function: `orchestrator-chat`
  - Request: `POST` with body `{ tenant, intent, payload }`
  - Headers: `Authorization: Bearer <ANON JWT>` and `apikey: <PUBLISHABLE>`
  - Behavior: insert into `agent_messages` with `(service,role,shard) = ("orchestrator","decide",0)` and `status = 'queued'`
  - Response: `202 Accepted` with `{ id }`
- Alternative (migration path): add `action: "orchestrate"` to existing `chat-gateway` edge function to enqueue the same bus message

Runtime env (Edge): `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` (server-side DB write only).

## 4) Orchestrator Intelligence (Local-first Dev)

- File: `src/orchestrator/OrchestratorBrain.ts` (workflow + ε-greedy exploration)
- Policies: `src/orchestrator/routing_policies.ts` (budget/risk/SLO/explore)
- Scorers: `src/orchestrator/scorers/{health,quality,cost,kg}.ts`
- API: `POST /api/orchestrator/decide`, `GET /api/orchestrator/state`, `POST /api/orchestrator/decide-enqueue`
- Executor: `src/orchestrator/Executor.ts` (builds `__assignment`, enqueues target)
 - Dedicated dispatcher (server): `src/workers/ExecutorDispatcher.ts` (aka `cogo-executor-dispatcher`)

Local development focuses on intelligence (scores/policies/learning) and decision quality while server runs stable workers.

## 5) Deployment Layout (PM2/Docker)

Process matrix (server):

- cogo-orchestrator-brain → `src/workers/OrchestratorBusWorker.ts`
- cogo-gateway-chat → `src/workers/ChatGatewayBusWorker.ts`
- cogo-rag-embed → `src/workers/EmbedBusWorker.ts`
- cogo-kg-builder → `src/workers/KGBusWorker.ts`
- cogo-rag-dispatcher (optional) → `src/scripts/rag/eventDispatcher.ts`
- cogo-bus-reclaimer → periodic (every 1m) `src/scripts/bus/reclaimer.ts`
- cogo-bus-retention → daily `src/scripts/bus/retention.ts`
- cogo-metrics-server → `src/servers/metrics/index.ts` (port 3100)
 - cogo-executor-dispatcher → `src/workers/ExecutorDispatcher.ts`

Container env (examples):

- Common: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `AGENT_SERVICE`, `AGENT_ROLE`, `AGENT_SHARD=0`, `HOLDER_ID`, `BUS_POLL_MS=15000`
- Metrics: add `METRICS_PORT=3100`

One realtime subscription per process to `public.agent_messages` with RLS filters by `(service,role,shard)`.

## 6) Local vs Server Responsibilities

- Local (dev):
  - Improve orchestrator scorers/policies and decision quality
  - Test via `/api/orchestrator/*`, `ci:smoke:bus:notify`
- Server (ops):
  - Run stable workers and metrics server
  - Deploy `orchestrator-chat` Edge Function as ingress

## 7) Renaming Plan (PM2)

Current → Target process names:

- orchestrator-bus-worker → cogo-orchestrator-brain
- gateway-bus-worker → cogo-gateway-chat
- embed-bus-worker → cogo-rag-embed
- kg-bus-worker → cogo-kg-builder
- rag-event-dispatcher → cogo-rag-dispatcher
- bus-reclaimer → cogo-bus-reclaimer
- bus-retention → cogo-bus-retention
- metrics-server → cogo-metrics-server

Renames will be applied in `ecosystem.config.js` and CI/CD scripts after approval.

## 8) Testing & Ops Checks

- Edge ingress E2E:
  1) `POST /functions/v1/orchestrator-chat` → 202 { id }
  2) Orchestrator claims & plans → target enqueued → worker completes
  3) `GET /api/metrics/summary` bus.byStatus.done increases; `bus_events` shows `orchestrate_enqueued`
- Bus smokes: `npm run -s ci:smoke:bus:notify`
- Dashboards: `http://<server>:3100/dashboard/local`, `/api/metrics/bus/events`, `/api/metrics/bus/failures`

### Codegen → Build/Test E2E (new)
1) Orchestrator starts `codeBuildTest` workflow → enqueues to `(codegen/generate/0)`
2) `cogo-codegen-service` writes `edits.json` artifact URL
3) Orchestrator enqueues to `(code/build-test/0)`
4) `cogo-build-test-worker` produces build/test metrics and gate verdict
5) Metrics visible in `/api/metrics/workflows/codeBuildTest`

## 9) Governance & Learning (Roadmap)

- Online updates of routing weights from success/latency/cost
- Canary auto-pause/resume tied to gates
- Sandbox Manager (WebSocket) for tight control of execution containers

---

If approved, we will:
1) Implement `orchestrator-chat` Edge Function (code) and deploy
2) Apply PM2 renames and environment normalization
3) Update `docs/AGENT_ARCHITECTURE_OVERVIEW.md` to this standard
4) Provide Dockerfile/compose templates per process
