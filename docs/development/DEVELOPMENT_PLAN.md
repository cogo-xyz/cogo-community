## COGO Agent Core – Development Goals and Plan (cogo0)

This document defines concrete objectives, prioritized roadmap, acceptance criteria, KPIs, and a test plan to realize the knowledge-driven, self-improving distributed agent (cogo0) and the platform-level knowledge RAG.

All content is written in English; user-facing summaries will be provided separately in Korean when needed.

---

### 1) Objectives (What we will achieve)

1. Knowledge-first COGO Agent (Self-upgrading)
   - Ingest the agent’s own codebase, schemas, and docs into pgvector + Neo4j.
   - Enable grounded RAG to answer and propose incremental improvements.
2. COGO Platform Knowledge Graph & Vector KB
   - Ingest platform DSL/architecture/runtime docs into pgvector + Neo4j.
   - Provide grounded Q&A with citations to source files and line ranges.
3. Self-Improvement Loop (HITL-gated)
   - From metrics/tests/code analysis → propose small PR diffs → run tests → human approval → merge → refresh KB.
4. User Service Readiness
   - Expose grounded chat/assist endpoints aware of COGO Agent + Platform capabilities.
5. Domain RAG Templates
   - Build Ecommerce and SNS domain ontologies + DSL templates to instantly scaffold applications.

---

### 2) Non-Goals (for clarity)

- Building full production UI here (handled by external IDE/UI project).
- Large, automatic code refactors without human approval.
- Replacing existing auth/storage stacks.

---

### 3) Milestones and Deliverables

#### Milestone P0 – Runtime Hardening & Real Connections (2 weeks)
- Deliverables
  - Queue hardening: unify `claim_one_job` (final version selected: v2) and add regression tests.
  - Events integrity: `job_events` triggers standardized; unique event per transition; indexed.
  - Heartbeat & leases: `worker_heartbeats_v2` verified; lease expiry tests; DLQ edge functions deployed.
  - Real integrations: connect embeddings (BGE-M3 1024D), pgvector, and Neo4j driver in agents (replace mocks behind interfaces).
- Acceptance Criteria
  - Double-claim prevented in concurrent test; idempotency respected.
  - Event log ordering and count match transitions across 1K jobs load test.
  - Vector functions return 1024D consistently; hybrid search returns expected recall on seed set.
  - Neo4j round-trip for CRUD on core labels (Agent/Task/Document/CodeSymbol) succeeds.

#### Milestone P1 – Knowledge Ingestion Pipelines (2–3 weeks)
- Deliverables
  - Code & Docs ingestion → pgvector: `vector_documents`, `code_vectors` with 1024D; chunking policy documented.
  - Symbol/AST extraction → Neo4j: Function/Class/Module nodes + DEPENDS_ON edges; Doc→Chunk→Symbol links.
  - Incremental updates: Git-diff aware ingestion with changed files only; background job scheduling.
- Acceptance Criteria
  - 95%+ files indexed; ingestion completes <15m for repo of current size; update delta <2m for 50 changed files.
  - Neo4j contains consistent counts vs. parser output; referential integrity checks pass.

#### Milestone P2 – Grounded Chat & Builder (2 weeks)
- Deliverables
  - `/api/ai/chat` answers with citations to file+line or doc IDs; include confidence and snippet.
  - Ranking: hybrid (BM25+vector) with lightweight reranker; top-k mixing.
  - “Builder prompts” draft to turn requirements → DSL skeleton using domain templates.
- Acceptance Criteria
  - Answerable queries (internal KB) hit@3 ≥ 0.8 on curated set; 0 hallucination tolerance (must cite).
  - Response SLA p95 < 2.5s for top-k=8 with caching.

#### Milestone P3 – Self-Improvement Loop (2 weeks)
- Deliverables
  - Metrics collectors: test failures, error logs, performance regressions.
  - Change proposer: generate minimal diffs (edits) with rationale and rollback plan.
  - Review workflow: HITL approval, auto-tests, merge, KB refresh.
- Acceptance Criteria
  - At least 3 improvements merged via loop; mean PR size < 50 LOC; revert path verified.
  - KB refresh latency < 5m post-merge.

#### Milestone P4 – Domain RAG Templates: Ecommerce (2 weeks)
- Deliverables
  - Ontology: Product/Order/Cart/User/Inventory/Payment.
  - DSL templates: screens, actions, flows; sample dataset + seed queries.
  - One-click scaffold from requirement → project skeleton.
- Acceptance Criteria
  - “Build basic shop” query produces runnable skeleton within 60s; pass functional smoke.

#### Milestone P5 – Domain RAG Templates: SNS (2 weeks)
- Deliverables
  - Ontology: User/Post/Comment/Like/Follow/Feed.
  - DSL templates + flows; scaffold pipeline.
- Acceptance Criteria
  - “Build basic SNS” query produces runnable skeleton within 60s; pass functional smoke.

---

### 4) Detailed Work Items (by area)

#### Queue/Workflow Hardening
- Consolidate `claim_one_job` to v2; remove deprecated variants and update callers.
- Add tests: concurrent claims (N=64), lease expiry, DLQ routing, idempotency key.
- Index & retention policies on `job_events` and artifacts; TTL edge function checks.

#### Knowledge Ingestion
- Chunking policy (semantic paragraphs; max 2–3KB; 64 token overlap); code chunks align to function/class.
- Embeddings: BGE-M3 1024D; batch size tuning; retry/backoff.
- AST/Symbol extraction (Tree-sitter) → Neo4j mapping; constraints & indexes.
- Incremental sync: detect file changes; recalc vectors; upsert graph nodes/edges.

#### Retrieval & Ranking
- Hybrid search SQL RPC alignment; BM25 + vector + rerank; per-type boosts (doc/code/symbol).
- Citations: include file path + line span; enforce grounding in answer template.

#### Self-Improvement
- Metric sources: unit/integration/E2E, lints, perf probes.
- Proposal generator: small edits only; attach tests; auto-rollback recipe.
- Governance: approval gate, audit logs, changelog, KB refresh job.

#### Domain Templates
- Ontology Cypher + DSL JSON packs; seed data; sample flows (auth/cart/checkout, feed/timeline).
- Scaffold generator: parameterize project name/features; output baseline project.

---

### 5) Test Plan

- Unit: SQL functions (claim, search), parsing utilities, chunking.
- Integration: ingestion → pgvector/Neo4j, hybrid search correctness, event triggers.
- E2E: Research→Indexing→GraphRAG workflow; grounded Q&A with citations; scaffold generation.
- Performance: search p95 latency; ingestion throughput; queue under load.
- Security: RLS/permissions, least-privilege DB roles, input validation.

---

### 6) KPIs & SLOs

- Retrieval quality: hit@3 ≥ 0.8 (curated evaluation set), 0 uncited claims.
- Ingestion: full run < 15m; delta < 2m (50-file change); failure rate < 1% with retries.
- Queue: double-claim rate 0; job success ≥ 99%; event integrity 100% under test.
- Self-improvement: ≥ 3 merged PRs/month via loop; mean PR size < 50 LOC; revert success 100%.
- Domain scaffold: time-to-skeleton ≤ 60s; smoke pass rate ≥ 95%.

---

### 7) Risks & Mitigations

- Embedding/Search drift → enforce 1024D; unify views/RPCs; add evaluation harness.
- Graph inconsistency → uniqueness constraints; validation queries; nightly checks.
- Hallucinations → mandatory citations; answer templates; refusal without evidence.
- Operational load → caching, batch sizes, backpressure thresholds.
- Security → RLS validation; secrets handling; least-privilege DB roles.

---

### 8) Dependencies & Environments

- BGE-M3 embedding service (or equivalent 1024D provider)
- pgvector enabled with tuned indexes
- Neo4j 5.x with APOC (optional) and proper constraints
- Supabase Edge Functions for DLQ/metrics

---

### 9) Execution Timeline (indicative)

- Weeks 1–2: P0
- Weeks 3–5: P1
- Weeks 6–7: P2
- Weeks 8–9: P3
- Weeks 10–11: P4
- Weeks 12–13: P5

---

### 10) Immediate Next Actions

1. Lock final `claim_one_job` variant and write regression tests.
2. Wire real embedding + pgvector + Neo4j adapters behind existing interfaces.
3. Implement ingestion job (docs+code) with chunking policy and delta sync.
4. Add grounded citations to `/api/ai/chat` responses (file+line/doc IDs).
5. Draft Ecommerce ontology + DSL templates; agree on MVP scope.


