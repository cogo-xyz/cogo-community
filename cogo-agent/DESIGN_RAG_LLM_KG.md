### COGO Agent: Unified RAG + LLM + KG Design

#### Goals
- Make RAG + LLM + KG foundational across all agent tasks (variables, symbols, BDD, actionFlow, chat), not just BDD.
- Enforce strict schema, symbol policy, and parity gates while enabling domain-grounded generation.
- Separate storage responsibilities: agent/meta in `cogo` schema; user artifacts in `public` schema.

#### Data placement
- cogo schema (agent/meta)
  - `cogo.vector_documents`: embedded summaries of agent corpus (schemas, symbol policy, prompts, domain templates, action catalogs).
  - Metrics via `bus_events`: RAG/LLM latency, retrieval stats, parity outcomes, worker metrics.
  - Neo4j (KG): SystemSymbol, Action, ActionFlow, BddScenario, and template relationships.
- public schema (per project)
  - `public.cogo_documents`: artifacts (pages, variables, symbols, BDD, actionFlow) with `project_id` and tags.
  - Access via RLS; all reads/writes scoped by `project_id`.

#### Artifacts and shapes (canonical)
- variables@1: list of `#_` system keys; no runtime-only roots.
- symbols@1: user symbol names `#name` and bound system keys `#_root.key`.
- bdd@1: array of `{ name, gherkin_text }`.
- action.flow@1: canonical JSON with sorted keys for stable equality.

#### Vectorization pipeline
- Inputs: agent corpus (internal docs/templates), project artifacts (summaries of UI pages, events, variables/symbols, BDD, flows).
- Summarizer: compact English outline per item (name, tags, symbol mentions, events/actions).
- Embed: use `/functions/v1/embed` with `EMBED_DIM=1024` (BGE-M3 compatible) → upsert into `cogo.vector_documents`.
- Maintenance: run `refresh_vector_documents_tsv(_batch)` to populate `text_tsv` for hybrid query.

#### Retrieval packer (shared)
- Inputs: `project_id`, optional `page_id`, `task_type` (vars/symbols/bdd/actionflow/chat), symbol/event hints.
- Filters: restrict to `project_id` and relevant tags; include agent corpus templates for the domain (ecommerce).
- Ranking: hybrid score; boost documents mentioning current symbols/events/actions.
- Output: ordered contexts payload with capped sizes for prompt budgets.

#### LLM orchestration (via chat-gateway)
- `json-generate` and other functions call `chat-gateway` with a structured request:
  - `instructions`, `prompt` (policy + packed contexts), and `response_format` (strict JSON schema).
- `chat-gateway` turns the request into an LLM call (orchestrator or `/llm/chat`) and returns structured JSON.
- Users depend only on `chat-gateway`; no separate per-task endpoints are exposed.

#### KG model (Neo4j)
- Nodes: `Artifact{path}`, `SystemSymbol{name}`, `Symbol{name}`, `Action{id}`, `ActionFlow{id}`, `BddScenario{name}`.
- Rels:
  - `(:Artifact)-[:CONTAINS]->(:SystemSymbol)`
  - `(:Symbol)-[:BINDS]->(:SystemSymbol)`
  - `(:BddScenario)-[:COVERS]->(:Action)`
  - `(:ActionFlow)-[:HAS_STEP]->(:Action)`
- Source: `kg.upsert_request` events from Edge; a worker consumes and upserts.

#### Security and tenancy
- All reads/writes scoped by `project_id`.
- `public.cogo_documents` under RLS; `cogo.*` for agent/meta only.
- Edge Functions use service role for privileged operations.

#### Observability and gates
- Emit: `retrieval_ms`, `strategy`, `contexts`, model, tokens (if available), parity results.
- Gates:
  - variables/symbols/actionFlow: exact equality vs Documents.
  - BDD: semantic coverage (normalized text inclusion).
  - KG: upsert success rate; retry/DLQ within thresholds.

#### Versioning and cache
- Include `schema_id`, `prompt_id`, `version`, `trace_id` on artifacts.
- ETag support (json-get/list, artifacts-list, trace-status); conditional requests honored.


