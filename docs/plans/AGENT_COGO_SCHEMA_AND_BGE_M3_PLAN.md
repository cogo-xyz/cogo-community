### COGO Agent Domain in cogo Schema & BGE-M3 (1024) Hybrid Search Plan

Objective: Ensure all agent-related state lives under the `cogo` schema, and standardize embeddings on BAAI/bge-m3 (1024 dims) with hybrid (dense + keyword) search, while preserving IDE upserts to `public` only.

#### 1) Domain Separation (Authoritative vs Materialized)
- cogo (authoritative, service-role writes only):
  - Tables: `cogo.agent_devices`, `cogo.agent_tokens`, `cogo.project_updates`(outbox), `cogo.bus_events`, vectors/knowledge stores
  - Writers: Edge functions/agents only (SRK)
- public (materialized, IDE-owned):
  - IDE upserts runtime/UI tables only (RLS on)
  - Views to bridge from `cogo.*` when needed for read

Status check (source):
- Agent auth: `supabase/migrations/20250823_agent_auth.sql` creates `cogo.agent_devices`, `cogo.agent_tokens` (OK)
- Outbox: `supabase/sql/2025-08-25_cogo_project_updates_outbox.sql` creates `cogo.project_updates` + public view (OK)
- Bus events: stored under `cogo.bus_events` usage via JS (OK)

Actions:
- [ ] Guarantee no agent tables under `public.*`
- [ ] Public views only for read/debug; no writes to `cogo.*` from IDE

#### 2) Embedding Standardization: BGE-M3 1024
- Target: All vector columns to `vector(1024)`; hybrid search using keyword + dense.
- Current state:
  - New migrations use 1024 (e.g., `supabase/migrations/20250821_pgvector_rag_schema.sql`, `20250823_rag_vector_compat.sql`) → OK
  - Legacy definitions still reference 1536 in `src/database/schema.sql` and some docs → NEEDS UPDATE

Tables (authoritative under `cogo.*`):
- `cogo.vector_documents(embedding vector(1024))`
- `cogo.agent_knowledge_vectors(embedding vector(1024))`
- `cogo.knowledge_graph_vectors(embedding vector(1024))`
- `cogo.code_vectors(embedding vector(1024))`

RPC/Functions (examples):
- `match_code_vectors(query_embedding vector(1024), match_count int)`
- `match_agent_knowledge_vectors(query_embedding vector(1024), ...)`

Actions:
- [ ] Create idempotent migrations to ALTER any 1536→1024 with safe sequence:
  1) Drop dependent public views
  2) ALTER TABLE ... ALTER COLUMN embedding TYPE vector(1024)
  3) Recreate HNSW/IVFFLAT indexes
  4) Recreate public views
- [ ] Ensure all RPC signatures use `vector(1024)`
- [ ] Update code/docs that mention 1536

#### 3) Hybrid Search (Dense + Keyword)
- Dense: pgvector cosine/HNSW
- Keyword: `tsvector` (full-text) or trigram index on normalized text
- Combined scoring (example):
```
WITH q AS (
  SELECT to_tsvector('simple', $1) AS qtext, $2::vector(1024) AS qvec
)
SELECT id,
       0.5 * (1 - (embedding <=> q.qvec))
     + 0.5 * (ts_rank_cd(text_tsv, plainto_tsquery('simple', $1))) AS score
FROM cogo.vector_documents d, q
WHERE d.text_tsv @@ plainto_tsquery('simple', $1)
ORDER BY score DESC
LIMIT $3;
```

Actions:
- [ ] Add `text_tsv tsvector` columns and GIN indexes for keyword fields
- [ ] Provide SQL helpers for weighted hybrid queries per table

#### 4) API & Edge Alignment
- Edge functions already emit to `cogo.bus_events` and write outbox in `cogo.project_updates`.
- Ensure `/agent/*` endpoints only touch `cogo.agent_*` tables.
- Figma compat endpoints prioritize `cogo_ui_json` and keep writes in `cogo` domain or storage artifacts; IDE writes to `public`.

Actions:
- [ ] Quick audit: forbid any server-side write to `public.*` from agent paths
- [ ] Keep public writers in IDE or projection worker dedicated to materialization

#### 5) Tests & Gates
- Smoke: chat/embed SSE, projection bundle, uui generate/llm
- Vector: insert/query sanity (1024 dims) and hybrid keyword match
- Agent auth: enroll/session/jwt/hmac dev toggles

Actions:
- [ ] Add CI checks to fail if 1536 appears in SQL or RPC signatures
- [ ] Add hybrid search regression with fixture queries

#### 6) Rollout Plan
1) Apply agent auth/Outbox migrations to `cogo.*`
2) Migrate vector schemas to 1024; rebuild indexes; update RPCs
3) Re-sync Edge and regenerate OpenAPI → types
4) Run smoke bundles and hybrid tests; publish results under `/artifacts`

#### 7) Risks & Mitigations
- Mixed dims (1536/1024) → block with lints + CI; provide ALTER scripts
- View dependencies on ALTER → orchestrate drop/create windows idempotently
- Keyword quality → tune text normalization, weights per domain


