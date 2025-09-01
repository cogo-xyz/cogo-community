# COGO Agent Knowledge Graph + Supabase Chat Roadmap

## Vision
- Distributed agents self-index their own codebase (TS + PY) to build a production-grade Knowledge Graph (KG) and RAG.
- Users interact via a Supabase-backed chat UI with real-time streaming, grounded by CBO/Schema-centric evidence.

## Phases

### Phase 1: TS baseline (now)
- CBO v3 for TypeScript with stable ids, params/returns/fields/line ranges, contains/imports/calls (unique-only)
- RAG projection (schema → contains → local_file weighting), Evidence enrichment
- Coverage gates: params ≥ 70%, returns ≥ 80%, fields ≥ 80%, lines 100%
- IO Gate (TS): ≥ 70% (currently ~98%)

### Phase 2: Python ingestion
- PY builder v1: classes/functions/imports/contains/lines (tree-sitter-python)
- PY builder v2: params/returns (type hints) + calls + docstring (LibCST/ast)
- Neo4j projection with `:TS|:PY` labels, mixed RAG queries

### Phase 3: App JSON Schema as first-class
- Ingest UI/variables/actions/actionFlow/BDD/DDD into CBO as `schema.*`
- Link code ↔ schema via `implements/uses_schema`
- Schema-first evidence/ranking in RAG
- Schema conformance gate (≥ 60%)

### Phase 4: Reachable Graph & Execution-first scope
- Mark `metadata.reachable=true` from server entrypoints (ts-morph import graph)
- Evidence/quality/gates operate only on reachable nodes

### Phase 5: Supabase Chat Interface
- Tables: `chat_sessions`, `chat_messages` with RLS
- Agent workers subscribe to `role='user'` messages, stream `assistant` answers via `askRag`
- Optional Edge Function `chat-router` for LLM routing + intent detection

## Deliverables
- Scripts: TS/PY builders, schema ingester, Neo4j projector, coverage/IO gates, chat workers
- Docs: updated KG schema v3, execution plan, chat integration guide
- CI: nightly gates (coverage, IO ≥ 70%), artifacts, PR-Lite snapshots

## Milestones
- M1 (Week 1): TS baseline stabilized, IO Gate ≥ 70%, docs updated
- M2 (Week 2): PY v1 ingest + Neo4j mix, chat tables + basic worker streaming
- M3 (Week 3): Schema ingester + conformance gate, Reachable Graph v1
- M4 (Week 4): PY v2, gates to 80%, dashboard snapshots


