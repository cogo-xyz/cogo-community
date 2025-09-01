## Indexing – Incremental & Hybrid Search v1

Goals
- Reliable incremental indexing (docs/code), replay, and hybrid search (BM25 + vector) with consistent 1024D embeddings (BGE‑M3). Provide tag/metadata standards for retrieval and evaluation.

Scope
- Applies to workers handling ingestion of repository code and documentation; storage in pgvector and metadata tables; optional Neo4j symbol graph.

Data Model (Supabase)
- `vector_documents(id, path, lang, kind, chunk_idx, content, embedding[1024], metadata jsonb, updated_at)`
- `code_vectors(id, path, lang, symbol, symbol_kind, chunk_idx, content, embedding[1024], tags jsonb, updated_at)`
- `ingestion_runs(run_id, started_at, finished_at, status, changed_files jsonb, stats jsonb)`

Chunking Policy
- Docs: 2–3KB soft limit, paragraph/heading boundaries, 64 token overlap.
- Code: function/class boundaries; fallback to 300–600 tokens, 32 token overlap.
- Store `chunk_idx`, `section`, `symbol` where applicable.

Language & Parsing
- Tree‑sitter: TypeScript/JavaScript/Python first; extract symbols (function/class/import) and attach `symbol_kind`.
- `tags` include: { lang, symbol_kind, framework?, test? }.

Incremental Indexing
1) Detect changed files via git diff or filesystem watcher.
2) For each changed file: re‑chunk → re‑embed → upsert by `(path, chunk_idx)`.
3) Deleted files: delete matching rows by path.
4) Record `ingestion_runs` with stats: added/updated/deleted counts, duration, errors.

Embeddings
- Provider: BGE‑M3 (1024D). Enforce dimension check on insert.
- Retry/backoff on network errors; batch size tunable.

Hybrid Search
- Sparse: BM25 (or Postgres full‑text) columns: `content`, `symbol`, `path` (weighted).
- Vector: cosine similarity on `embedding`.
- Fusion: simple weighted sum initially: `score = α * bm25_norm + (1-α) * vector_norm` (default α=0.5). Future: RRF or learned weights.

APIs
- `/api/search/docs?q=...&k=8` → returns chunks with path/section/snippet/tags/scores.
- `/api/search/code?q=...&k=8` → returns chunks with path/symbol/symbol_kind/tags/scores.

Evaluation Harness
- Seed queries with expected hits; compute hit@k, MRR; dump JSON reports under `reports/search/`.
- Thresholds: docs hit@3 ≥ 0.75, code hit@3 ≥ 0.7 on seed set.

Replay
- Accept a commit range or timestamp window; rebuild only affected files.
- Dry‑run mode to print planned mutations without writing.

Observability
- Metrics: `indexing_chunks_total{op=add|update|delete}`, `indexing_run_seconds`, `embedding_requests_total`, `embedding_errors_total`, `search_queries_total{type=docs|code}`.

Acceptance Criteria
- Full ingest completes < 15m for current repo; delta < 2m for 50 changed files.
- Embedding dimension always 1024; invalid rows rejected with error log.
- Hybrid search endpoints return expected results on seed set; reports generated.

Feature Flags
- `HYBRID_ALPHA` (0.0–1.0) – fusion weight.
- `INDEXING_DRY_RUN` – plan only, no writes.


