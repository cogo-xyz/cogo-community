## COGO Edge Functions – Overview

### Purpose
- Summarize core Supabase Edge Functions used as short-lived gateways for ingestion, chat streaming, RAG/graph queries, and job enqueueing.
- Long-running or heavy work (build/test, indexing, research, sandbox) is delegated to distributed agents.

### Common Rules
- All responses include `trace_id` when available; propagate across chained calls
- Authentication: `Authorization: Bearer <ANON>` and `apikey: <PUBLISHABLE>` in development
- Artifacts policy:
  - Large/structured outputs are stored in Storage; responses return `artifacts.links`
  - Small previews may be embedded as JSON snippets under `artifacts.*_preview`
  - Security: signed URLs with short TTL, MIME allowlist, size limits
  - TTL via `ARTIFACTS_SIGN_TTL_SEC`; bucket via `ARTIFACTS_BUCKET`
  - Intent enforcement (optional): `EDGE_REQUIRE_INTENT_KEYS=true` → reject when `intent.keywords` missing/invalid
  - Idempotency store (optional): table `cogo.idempotency_keys`; duplicate key short-circuits non-stream calls

### Reading Order (Quick)
1) `chat-gateway` – streams to `/chat` and returns SSE
2) `orchestrator-chat` – enqueues chat intents to `public.agent_messages`
3) `figma-compat` – UUI/COGO tools (symbols, variables, BDD, ActionFlow, presign/ingest)
4) `rag` – RAG query (JSON/SSE)
5) `graph` – Neo4j HTTP gateway (bridge→v2→tx/commit)
6) enqueue/ops: `build-enqueue`, `execute-enqueue`, `indexing-enqueue`, `research-enqueue`, `jobs-*`, `dlq-*`, `workers-active`, `metrics-overview`, `artifacts-list`, `sign-artifact`, `leases-release`, `health-refresh`, `self-check`, `key-vault`

---

### Core Functions

#### chat-gateway
- Role: Front proxy to `/chat` with SSE passthrough. Forces `stream=true` when Accept is `text/event-stream`.
- Auth: Uses incoming `Authorization` if present, else Service Role Key.
- Failure modes: upstream timeout → 504; upstream error → 502; JSON mode normalizes `output.text`.

Quick test
```bash
curl -N \
  -H "Accept: text/event-stream" \
  -H "Authorization: Bearer <ANON_OR_SERVICE>" \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"ping"}]}' \
  https://<SUPABASE_PROJECT>.functions.supabase.co/chat-gateway
```

#### orchestrator-chat
- Role: Ingress for external chat intents → enqueue to `public.agent_messages` (service=orchestrator, role=decide, shard=0).
- Guards: payload size, per-tenant rate-limit, idempotency (via `idempotency-key`).

Quick test
```bash
curl -sS \
  -H "Authorization: Bearer <ANON_OR_SERVICE>" \
  -H "Content-Type: application/json" \
  -d '{"tenant":"default","intent":"chat","payload":{"text":"hello"}}' \
  https://<SUPABASE_PROJECT>.functions.supabase.co/orchestrator-chat | jq
```

#### figma-compat
- Role: UUI/COGO conversion and utilities.
- Endpoints (POST unless specified):
  - `/figma-compat/uui/symbols/map`
  - `/figma-compat/uui/variables/derive`
  - `/figma-compat/uui/bdd/generate`, `/figma-compat/uui/bdd/refine`
  - `/figma-compat/uui/actionflow/refine`
  - `/figma-compat/uui/generate`, `/figma-compat/uui/generate/llm`
  - `/figma-compat/uui/presign`, `/figma-compat/uui/ingest` (large payload flow)
  - `/figma-compat/uui/ingest/result` (GET)
- Guards: body size limit for small JSON; idempotency optional; projectId enforcement optional.
- Side-effects (optional via env): legacy table write, artifact upload, components upsert, bus events.
 - CLI Actions:
   - Templates: `cogo.intent_action_template`에서 활성 템플릿을 로드하여 응답에 병합
   - Fallbacks: 템플릿이 비어있거나 비활성인 경우 안전 기본 액션을 포함(bdd.generate/refine=echo 안내, actionflow.generate=upsert)

Quick tests
```bash
# health
curl -sS https://<PROJ>.functions.supabase.co/figma-compat/healthz | jq

# symbols map (small payload)
curl -sS -H "Authorization: Bearer <ANON_OR_SERVICE>" -H "Content-Type: application/json" \
  -d '{"page_id":1,"cogo_ui_json":[]}' \
  https://<PROJ>.functions.supabase.co/figma-compat/uui/symbols/map | jq

# presign + ingest (large payload)
curl -sS -H "Authorization: Bearer <SERVICE>" -H "Content-Type: application/json" \
  -d '{"projectId":"demo","fileName":"ui.json"}' \
  https://<PROJ>.functions.supabase.co/figma-compat/uui/presign | jq
```

#### rag
- Role: Demo RAG; JSON or SSE(`rag.item`/`rag.done`).
- Features: optional in-memory idempotency cache; observable events when enabled.

Quick tests
```bash
curl -sS -H "Authorization: Bearer <ANON_OR_SERVICE>" -H "Content-Type: application/json" \
  -d '{"q":"hello","limit":3}' \
  https://<PROJ>.functions.supabase.co/rag | jq

curl -N -H "Authorization: Bearer <ANON_OR_SERVICE>" -H "Accept: text/event-stream" \
  -d '{"q":"stream","limit":3}' \
  https://<PROJ>.functions.supabase.co/rag
```

#### graph
- Role: Neo4j HTTP gateway.
- Order: `GRAPH_BRIDGE_URL` → Aura Query API v2 → `/tx/commit` fallback.
- Output: `{ ok, rows, stats }`, or `{ ok:false, stats.message:'neo4j_not_configured' }` when unset.

Quick test
```bash
curl -sS -H "Authorization: Bearer <ANON_OR_SERVICE>" -H "Content-Type: application/json" \
  -d '{"cypher":"MATCH (n) RETURN n LIMIT 1"}' \
  https://<PROJ>.functions.supabase.co/graph/query | jq
```

---

### Enqueue & Ops (개요)
- Enqueue: `build-enqueue`, `execute-enqueue`, `indexing-enqueue`, `research-enqueue` → 분산 에이전트가 처리.
- Ops/Visibility: `jobs-admin`, `job-status`, `job-events`, `jobs-recent`, `workers-active`, `metrics-overview`, `dlq-list`, `dlq-retry`, `artifacts-list`, `sign-artifact`, `leases-release`, `health-refresh`, `self-check`, `key-vault`.

---

### Configuration Notes
- Dev 토글: `EDGE_AUTH_OPTIONAL`, `EDGE_OBS_PUBLISH`, `REQUIRE_IDEMPOTENCY`, `DEBUG_SCHEMA_ENABLE` 등.
- Keys: 절대 소스/문서에 키를 직접 기록하지 말고 환경/비밀 관리로만 주입.
- Realtime/Ingress: `SUPABASE_URL`, `SUPABASE_ANON_KEY`; 서버-DB 보호 작업은 `SUPABASE_SERVICE_ROLE_KEY` 필요.
 - Intent Registry(제안): `cogo.intent_keyword`, `cogo.intent_action_template`를 참조하여 `intent.keywords` 검증 및 `cli_actions`/`agent.requests` 자동 생성 가능.
 - Flags:
   - `EDGE_REQUIRE_INTENT_KEYS`(default=false): `intent.keywords` 필수화
   - `EDGE_REQUIRE_INTENT_REQUIRES`(default=false): 레지스트리 `requires` 충족 검증 필수화
   - `INCLUDE_CLI_ACTIONS`(default=true): 응답에 `cli_actions` 포함
   - `INTENT_REGISTRY_TTL_SEC`(default=60): intent-resolve 레지스트리 TTL(초)
   - `INTENT_METRICS_ENABLE`(default=true): intent-resolve 메트릭(bus_events) 기록
   - `EDGE_VERIFY_JWT` / `EDGE_REQUIRE_HMAC`(prod 권장): JWT/HMAC 검증 활성화
   - `EDGE_RATE_LIMIT_PER_MIN` / `EDGE_CORS_ALLOW_ORIGINS`: 레이트 제한/허용 오리진 설정

---

### Endpoint Matrix

Note: All support CORS preflight (OPTIONS). Auth is optional in dev when `EDGE_AUTH_OPTIONAL=true` unless noted.

- chat-gateway
  - POST `/chat-gateway` (JSON or SSE)
  - Stream: SSE passthrough to `/chat` when Accept `text/event-stream`
  - Headers fwd: `authorization`(or service role), `apikey`, `idempotency-key`, `x-timestamp`, `x-signature`
  - Env: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `CHAT_TIMEOUT_MS`

- orchestrator-chat
  - GET `/orchestrator-chat` → liveness JSON
  - POST `/orchestrator-chat` → enqueue to `public.agent_messages` (service=orchestrator, role=decide)
  - Guards: body size (`ORCH_INGRESS_MAX_BYTES`), tenant rate-limit (`ORCH_INGRESS_RATE_PER_MIN`), idempotency via `Idempotency-Key`

- figma-compat
  - GET `/figma-compat/healthz`
  - POST `/figma-compat/uui/presign`, `/figma-compat/uui/ingest`, GET `/figma-compat/uui/ingest/result`
  - POST `/figma-compat/uui/symbols/map`, `/variables/derive`, `/bdd/generate|refine`, `/actionflow/generate|refine`, `/data_action/generate`, `/generate`, `/generate/llm`
  - Guards: `UUI_MAX_BODY_BYTES`, `REQUIRE_IDEMPOTENCY`; optional legacy writes/uploads/components upsert

- actionflow-compat
  - GET `/compat/actionflow/healthz`
  - POST `/compat/actionflow/compile` (RPC `upsert_actionflow`), `/compat/actionflow/validate`
  - POST `/compat/actionflow/run` (SSE; emits `aflow.*`; polls `bus_events`)
  - Security toggles: `EDGE_VERIFY_JWT`, `EDGE_REQUIRE_HMAC`, `EDGE_RATE_LIMIT_ENABLE`

- api-router
  - GET `/` (status), `/health`, `/agents`, `/tasks`, `/metrics/jobs`, `/metrics/sse`, `/metrics/alerts`, `/metrics/trace/{traceId}`, `/test`
  - POST `/tasks`
  - Features: dynamic CORS allowlist, optional JWT/HMAC, logs `api_usage_metrics`

- rag
  - GET `/rag/healthz`
  - POST `/rag` (JSON) or SSE when Accept `text/event-stream` (`rag.item`, `rag.done`)
  - Idempotency: in-memory cache; Obs: `EDGE_OBS_PUBLISH`

- embed
  - GET `/embed/healthz`
  - POST `/embed` (JSON or SSE `embed.chunk`, `embed.done`), dim via `EMBED_DIM`

- graph
  - GET `/graph/healthz`
  - POST `/graph/query` (prefers `GRAPH_BRIDGE_URL`; else Aura v2; fallback `/tx/commit`)
  - Env: `NEO4J_HTTP_URL`, `NEO4J_USER`, `NEO4J_PASSWORD`, `NEO4J_DB`

- chat
  - GET `/chat/healthz`
  - POST `/chat` (JSON or SSE). Demo echo tokens via `llm.delta` → `llm.done`

- role-select
  - GET `/role-select/healthz`
  - POST `/role-select` (JSON or SSE). Output `{ role_id, confidence }`

- figma-context
  - GET `/figma-context/healthz`
  - POST `/figma-context/start` → create job; `/stream` (SSE chunk emit), `/apply` (enqueue), `/cancel`
  - GET `/figma-context/status`
  - Uses tables: `figma_jobs`, `figma_job_chunks`, `bus_events`; Figma API with `FIGMA_API_KEY`

- figma-plugin
  - GET `/figma-plugin/healthz`, `/ping`, `/tools`, `/result?id=...`, `/metrics/project`, `/trace`
  - POST `/figma-plugin/enqueue`, `/respond`, `/compat/uui/{variables/derive|symbols/map|bdd/generate|bdd/refine|actionflow/refine}`
  - Auth: optional `x-plugin-token` when `REQUIRE_FIGMA_PLUGIN_TOKEN=true`; membership check `project_members`

- key-vault
  - GET `/key-vault?name=...&env=...` or by `provider/service/resource`
  - POST `/key-vault/get`, `/key-vault/upsert`
  - Tables: `secure_keys`, `secure_keys_audit`; env override `<PROVIDER>_API_KEY`

- router-select
  - POST `/router-select` → rank LLM/Embedding providers/models
  - Sources: `llm_models`, `llm_providers`, `provider_health`, `routing_policies`; output includes `base_url`, `headers_template`

- auth-gateway
  - GET `/auth-gateway/health`
  - POST `/auth-gateway/{login|register|logout|refresh|verify}`
  - Proxy: `/api/*` routed to backend services with RBAC (roles via `user_roles` or metadata)

- design-generate
  - GET `/design-generate/healthz`
  - POST `/design-generate` (JSON or SSE): Orchestrates Chat→RAG→LLM→UI generation using shared services; frames: rag.item, rag.done, llm.done, ui.generate, done
  - Env: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`

- rag (ingest)
  - POST `/rag/ingest/start` → { trace_id?, job_id }
  - POST `/rag/ingest/stream` (JSON or SSE): items streaming; events: rag.ingest.item, rag.ingest.done
  - POST `/rag/ingest/upsert` → { items[], with_embeddings? } upserts `documents` and optionally embeddings

#### schema-introspect
- Role: Remote schema inventory helper to list columns for selected tables.
- Endpoint:
  - GET `/schema-introspect?tables=table1,table2`
- Auth:
  - Dev: anon allowed when `EDGE_VERIFY_JWT=false`
  - Prod: enable JWT/HMAC
- Input:
  - `tables` (comma-separated), e.g., `pages,components,fig2cg_ai_res`
- Output:
  - `{ ok: true, columns: { table: [{ column_name, data_type?, is_nullable?, character_maximum_length? }] }, mode }`
- Notes:
  - Uses REST probe (sample 1 row) by default
  - If DB function `public.get_columns(text[])` exists, can be switched to accurate metadata mode

#### intent-resolve
- Role: `intent.text` → `intent.keywords` 추출/정규화 및 레지스트리 검증
- Endpoint:
  - GET `/intent-resolve/healthz`
  - POST `/intent-resolve` { text, language? } → { ok, intent: { keywords[], unknown[], language }, registry_version }
- Validation:
  - `keywords[*]` ∈ `cogo.intent_keyword`; 필요 시 `requires` 체크(후속 단계)
- Usage:
  - 채팅 사전단계에서 호출하여 키워드 세트를 표준화하고, 후속 에이전트/CLI 플랜 생성에 사용

---

### Next (optional)
- Enqueue & Ops family detailization: `build-enqueue`, `execute-enqueue`, `indexing-enqueue`, `research-enqueue`, `jobs-admin`, `job-status`, `job-events`, `jobs-recent`, `dlq-list`, `dlq-retry`, `workers-active`, `metrics-overview`, `artifacts-list`, `sign-artifact`, `leases-release`, `health-refresh`, `self-check`.
- If needed, I can add each endpoint and sample requests in the same format.
