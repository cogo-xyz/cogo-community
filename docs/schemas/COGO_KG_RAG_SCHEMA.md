### COGO KG/RAG Schema

- Neo4j (KG)
  - Labels: `Concept`, `Technology`, `Pattern`, `Document`, `Code`
  - Common properties: `id`(string, unique), `name`/`title`, `summary`
  - Relationships: `RELATED_TO` (normalized), optionally weighted `score`
  - Constraints/Indexes: unique(id), name/title/path indexes

- Postgres (pgvector + hybrid)
  - `cogo.vector_documents(id, title, content, embedding vector(1024), text_tsv tsvector)`
  - RPC: `public.hybrid_search_vector_documents(query_text text, query_vec vector, top_k int)`
  - Trigger/refresh: `cogo.refresh_vector_documents_tsv`, batch variant

- Symbols & ActionFlow (CQRS)
  - `cogo.symbols(project_uuid, type, key, binding)` exposed via `public.symbols`
  - `cogo.actionflows(project_uuid, flow_id, version, flow, meta)` and `cogo.actionflow_runs`

- Mappings
  - Qdrant→pgvector: points.vector → embedding(1024) trunc/pad, payload.title/content → columns
  - KG import: CreateGo nodes/rels → Neo4j labels, relationships normalized to `RELATED_TO`

- Traceability
  - All events carry `trace_id` and are emitted to `bus_events`; projections feed `public` views.
