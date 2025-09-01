# COGO Agent — RAG + Figma Context
## AS-IS → TO-BE Refactoring Design & Development Plan

### 0. Goals and Non‑Goals
- Goals
  - Standardize RAG ingestion/search on Supabase Edge Functions + Realtime async streams
  - Unify embedding dimensions to 1024 for BGE-M3 compatibility [[BGE-M3 uses 1024 dims; project standard]]
  - Integrate Figma → Cogo UI → RAG ingestion pipeline with idempotent workers
  - Improve observability (events/metrics) and rate-limit policies
- Non‑Goals
  - Browser MCP, sandbox execution, and large LangGraph flows (kept as separate agents)
  - Production-grade HMAC/JWT hardening (documented, deferred to prod rollout)

### 1. AS‑IS Overview
#### 1.1 Edge Functions and Clients
- Chat: `supabase/functions/chat` (SSE), `chat-gateway` (forwarder), `chatting` (legacy proxy)
- Embed: `supabase/functions/embed` (SSE), DeepInfra OpenAI‑compatible
- Figma Context: `supabase/functions/figma-context` with `/start`, `/stream`, `/status`, `/apply`
- Clients: `SupabaseEdgeChatService`, `SupabaseEdgeEmbeddingService` (currently returns placeholders for query vectors)

#### 1.2 Distributed Agents / Workers
- Indexing: `DistributedIndexingAgent` (chunk → embed → vector store)
- Research/GraphRAG: `DistributedResearchAgent`, `DistributedGraphRAGAgent`
- Figma Apply: `FigmaApplyWorker` persists `pages`/`components` (replace strategy)

#### 1.3 Data & Schema
- Vector store tables: `agent_knowledge_vectors`, `vector_documents`, `code_vectors`, etc.
- Some SQL artifacts still use `vector(1536)` despite BGE-M3 = 1024 dims (mismatch)
- Figma state: `figma_jobs`, `figma_job_chunks`, plus `pages`, `components`

#### 1.4 Observability & Policies
- `bus_events` used across chat/embed/figma; metrics server aggregates
- Rate limits for chat/embed; figma has basic limits
- Security: optional HMAC, JWT verify disabled on certain functions (dev), to be hardened in prod

### 2. Key Gaps and Risks
1) Embedding dimension mismatch (`vector(1536)` vs 1024) causing correctness/perf issues
2) Missing query‑embedding return path from Edge (client uses placeholder)
3) No unified RAG Edge endpoints for ingestion/search (agent‑only entrypoints)
4) Figma→RAG ingestion missing (no pipeline to vectorize Figma components text/meta)
5) Limited end‑to‑end tests/metrics for RAG ingestion/search

### 3. TO‑BE Architecture
#### 3.1 Edge‑Centric RAG IO (SSE + Async)
- Ingest
  - `POST /functions/v1/rag/ingest/start` → returns job_id
  - `POST /functions/v1/rag/ingest/stream` (optional SSE) or `enqueue` (non‑SSE) to push items
  - `GET /functions/v1/rag/ingest/status?job_id=...`, `POST /.../cancel`
  - Emits `rag_ingest_requested|started|chunk_done|done|failed`
- Search
  - `POST /functions/v1/rag/search` → top‑K results (optionally SSE to stream ranked hits)
  - Query embedding generated server‑side; optional `return_query_vector` for diagnostics

#### 3.2 Figma → RAG Integration
- After `/figma-context/apply`, emit `rag_ingest_requested` with page/components metadata
- New `FigmaRagIngestWorker`:
  - Extract text/name/role/bbox from `components`, chunk, embed (BGE‑M3), upsert into `vector_documents`
  - Idempotency by `(source_id, version, chunk_idx)` unique key; replace strategy for a page version

#### 3.3 Embedding Standardization
- Global standard: BGE‑M3 (1024 dims) [[memory]]
- All tables/functions switched to `vector(1024)`; indexes recreated (IVFFLAT/HNSW)
- `SupabaseEdgeEmbeddingService.generateEmbedding()` returns real vectors (no placeholders)

#### 3.4 Observability & Policies
- Events: add `rag_search_executed`, extend figma/rag ingest events
- Metrics server: `/api/metrics/rag` (ingest counts/latency, search RT/topK distribution)
- Rate limits: per‑function ENV (INGEST_RATE_LIMIT_PER_MIN, RAG_SEARCH_RATE_LIMIT_PER_MIN)

### 4. Data Model & Migrations
Targets to unify to `vector(1024)`:
- `agent_knowledge_vectors.embedding`
- `vector_documents.embedding`
- `code_vectors.embedding`
- `rag_knowledge.embedding` (if used)
- `documents.embedding` (internal examples)
Also update functions:
- `match_documents(query_embedding vector(1024), ...)`
- `match_code_vectors(query_embedding vector(1024), ...)`
- `search_rag_knowledge(query_embedding vector(1024), ...)`
- `hybrid_search_rag_knowledge(query_text text, query_embedding vector(1024), ...)`
Index recreation (order): drop dependent indexes → alter column type → recreate IVFFLAT/HNSW with tuned params.
Zero‑downtime guidance: create shadow columns/indexes, backfill, swap; or brief read‑only window.

### 5. Edge API Specification (Draft)
```
POST /functions/v1/rag/search
Body: { query: string, top_k?: number, threshold?: number, filter?: object, return_query_vector?: boolean }
Resp: { ok: boolean, items: Array<{ id, content, metadata, similarity }>, query_vector?: number[] }

POST /functions/v1/rag/ingest/start
Body: { source: 'figma'|'docs'|..., idempotency_key?: string }
Resp: { ok: boolean, job_id: string }

POST /functions/v1/rag/ingest/stream
Body: { job_id: string, items: Array<{ id, text, metadata, chunk_idx, total_chunks }> }
SSE: events: ready, chunk_done, progress, done, error
```

### 6. Workers
#### 6.1 FigmaRagIngestWorker
- Input event: `rag_ingest_requested` with `page_id`, `components[]`, `version`
- Process: normalize → chunk → embed → upsert into `vector_documents`
- Idempotent replace by `(source_id, version)`; delete old components before insert
- Telemetry: events + metrics; errors with context

### 7. Implementation Plan (Phased)
1) Migrations
   - Inventory all `vector(1536)` usages → change to `vector(1024)`; recreate indexes/functions
   - ENV/docs/OpenAPI sync
2) Edge endpoints
   - Add `/rag/search`, `/rag/ingest/*` skeletons with SSE and events
3) Client/services
   - Update `SupabaseEdgeEmbeddingService.generateEmbedding()` to return real vectors
   - Add `SupabaseEdgeRagService` (search/ingest)
4) Figma ingestion
   - Emit `rag_ingest_requested` on `/figma-context/apply`
   - Implement `FigmaRagIngestWorker`
5) Observability
   - Extend `bus_events`; metrics server `/api/metrics/rag`
6) Tests
   - E2E: Figma URL → SSE → apply → RAG ingest → search hit
   - Rate‑limit spike; query latency; topK distribution
7) Rollout
   - Stage env verification → prod with rollback guide

### 8. Test Plan
- Unit: Edge handlers (payload, SSE frames), worker idempotency
- Integration: DeepInfra embeddings, vector search correctness (thresholds)
- E2E: Figma → RAG pipeline, search relevance (manual spot‑checks)
- Performance: ingest throughput, search p95 latency

### 9. Rollout & Backout
- Rollout: apply migrations during maintenance window; deploy functions/workers; run smoke/E2E
- Backout: keep pre‑migration snapshots; revert functions; restore indexes/column type if required

### 10. Configuration (Summary)
- Embedding: `EMBEDDING_API_BASE`, `EMBEDDING_MODEL_DEFAULT="BAAI/bge-m3"`, `EMBEDDING_API_KEY`
- Dimensions: `VECTOR_DIMENSIONS=1024` (code, tests, docs)
- RAG limits: `RAG_SEARCH_RATE_LIMIT_PER_MIN`, `INGEST_RATE_LIMIT_PER_MIN`
- Security (prod): enable `verify_jwt`, HMAC request signing

---
References
- BGE‑M3 1024‑dim project standard [[BGE‑M3 embeddings; stored in pgvector]]
- Existing Edge SSE implementations: chat, embed, figma‑context
- Current agents: DistributedIndexingAgent, DistributedResearchAgent, DistributedGraphRAGAgent

---

### 11. Validation & Comparison (Local Docker + Supabase)

#### 11.1 Environments Matrix
- Local Supabase Edge (remote project) + Local Agents (Docker)
- Profiles: avoid orchestrator/sandbox when not needed; focus on API, workers, Figma MCP
- Ports: follow `docs/runbook/ports-and-endpoints.md` (Figma MCP WS: 3007, API: 3001, Metrics: 3100)

#### 11.2 Pre‑checks
- Supabase: `SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY`, `EMBEDDING_API_BASE=https://api.deepinfra.com/v1/openai`, `EMBEDDING_MODEL_DEFAULT="BAAI/bge-m3"`, `EMBEDDING_API_KEY` (set as project secrets)
- Functions deployed: `chat`, `embed`, `figma-context` (JWT verify disabled in dev per config.toml)
- Vector dimensions unified: DB columns/functions to `vector(1024)` (post‑migration)

#### 11.3 Bring‑up (Local Docker Agents)
```bash
# rebuild images if needed
docker compose -f docker-compose.local.yml build

# up essential services (API, workers, figma MCP); use proper profiles if defined
docker compose -f docker-compose.local.yml up -d

# confirm ports
curl -s http://localhost:3100/api/health | jq . || true
```

#### 11.4 Edge SSE Verification (Baseline Readiness)
```bash
# Chat SSE
npm run -s chat:verify:edge

# Embed SSE
npm run -s embed:verify:edge

# Legacy chatting proxy (should pass with deprecation header)
npm run -s chatting:verify:edge
```
Pass criteria: `ok:true`, events include `ready`→`delta`/`data`→`done`, no upstream 401/502.

#### 11.5 Figma Context End‑to‑End
```bash
# Stream verify (uses FIGMA_URL)
APPLY_SYNTH=0 FIGMA_URL='<your-figma-url>' npm run -s figma:verify:sse

# Apply + DB verify
APPLY_SYNTH=0 FIGMA_URL='<your-figma-url>' npm run -s figma:apply:smoke
npm run -s figma:apply:db:verify
```
Pass criteria: `components_in_chunk > 0` (or dev placeholder ≥1), `components` rows inserted for target page, `figma_job_*` events present.

#### 11.6 Rate‑limit & Metrics Validation
```bash
npm run -s chat:spike:ratelimit
npm run -s embed:spike:ratelimit
npm run -s metrics:rate-limits:query

# Figma jobs aggregation
curl -s http://localhost:3100/api/metrics/figma-jobs | jq .
```
Pass criteria: near‑limit/limited 이벤트 기록, metrics API에서 집계 수치 확인.

#### 11.7 RAG A/B Comparison (Post‑RAG Endpoints)
- A (AS‑IS): Agent 직접 벡터 스토어 경로 (`SupabaseVectorStore`), 현행 검색 플로우
- B (TO‑BE): Edge `/rag/search` 경유 (서버측 임베딩 + 유사도 검색), Realtime 이벤트 기록

Procedure (once `/rag/*` ready):
1) Seed same items via `FigmaRagIngestWorker` (B) and direct store (A) or align ingestion to B only
2) 동일 쿼리 N개에 대해 응답 시간(p50/p95), 상위K 스코어 분포, 일치율@K 비교
3) 실패/결측률, 에러 이벤트 비교 (`rag_search_executed`, `rag_ingest_*`)

#### 11.8 Acceptance Criteria
- Embedding dim=1024 end‑to‑end (ENV/DB/functions/clients/docs 일치)
- SSE: chat/embed/figma-context 모두 안정적 스트림 + done, 버스 이벤트 기록
- Figma→pages/components 영속 및(옵션) RAG ingest 이벤트 큐잉
- RAG 검색 smoke (A) 통과, (B) 가용 시 동등 이상의 결과/지연

#### 11.9 Rollback
- Functions: redeploy previous version
- DB: pre‑migration snapshot/DDL로 인덱스/컬럼 타입 되돌림
- Agents: `docker compose ... down && up`로 이전 태그 재기동


