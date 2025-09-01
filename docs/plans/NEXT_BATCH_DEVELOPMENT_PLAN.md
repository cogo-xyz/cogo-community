### Next Batch Development Plan (COGO Agent Core)

Objective: Finish CreateGo-Agent replacement, standardize embeddings on BGE-M3 (1024), finalize cogo/public domain separation, and ship verifiable E2E with gates.

#### A) Schema Finalization (cogo-first, 1024 standard)
- Ensure all agent tables live under `cogo.*`; public-only for IDE materialization
- Apply 1024 migrations; rebuild HNSW indexes; re-create public bridge views
- Update any legacy 1536 references (SQL, RPCs, docs)
- Success: RPCs accept `vector(1024)` and return results; no 1536 remnants in CI grep

#### B) API & Edge Alignment
- `/figma-compat/uui/*`: confirm payloads (`cogo_ui_json`) and add missing endpoints parity if any
- `/chat` (canonical), `/chat-gateway` (compat) verified via SSE smoke
- `x-agent-id` propagates into `bus_events` (done), audit for all uui routes
- Success: Smoke bundle green; events include `agent_id` and `trace_id`

#### C) Figma Plugin E2E
- Convert Selection, Generate, LLM Generate, Upload & Ingest, Chat SSE, Context SSE
- Docs: user guide + examples (done); publish instructions
- Success: Plugin E2E passes against Edge with Anon in dev

#### D) CreateGo-Agent Replacement Parity
- Variables/Symbols/BDD/ActionFlow parity tests (inputs from CreateGo docs)
- Map outputs to `cogo.project_updates` + `bus_events`; IDE materializes to `public.*`
- Success: ActionFlow refine parity snapshots; bus events reflect processing

#### E) Vector + Hybrid Search
- Add `tsvector` columns + GIN indexes for keyword fields
- Provide hybrid SQL helpers (dense cosine + keyword rank)
- Success: Hybrid regression passes (top-k stable over fixtures)

#### F) Agent Auth & Multi-Instance
- Ensure `cogo.agent_devices`, `cogo.agent_tokens` wired in edge `/agent/*`
- Dev toggles: `EDGE_VERIFY_JWT=false`, `EDGE_REQUIRE_HMAC=false` (prod true)
- Success: enroll/session/refresh smokes green; `x-agent-id` roundtrip

#### G) Projection & CQRS
- `cogo.project_updates` lease/process/done; projection worker emits bus events
- IDE writes/upserts to `public.*` only (policy check)
- Success: E2E projection smoke green; `status='done'` recorded, bus events emitted

#### H) Observability & Gates
- SSE meta frames (`meta`, `llm.delta`, `llm.done`) verified
- Metrics and trace endpoints produce artifacts under `/artifacts`
- Success: Gate thresholds satisfied (p95 latency, error-rate)

#### I) CI/CD & Docker
- Update OpenAPI → regenerate types; add CI greps for `vector(1536)`
- `docker-compose.pipeline.yml` validation bundle
- Success: CI green; bundle artifacts archived

#### J) Cutover & Rollback
- Feature flags per endpoint; dual-run where needed
- Rollback: re-enable legacy endpoints; keep views intact

---

### Deliverables
- Updated SQL migrations; RPCs (1024); hybrid helpers
- Edge function parity + plugin E2E
- Parity tests (Variables/BDD/ActionFlow)
- CI gates + artifacts

### Timeline (indicative)
- A–B: 1–2 days
- C–D: 2–3 days
- E–F: 2 days
- G–I: 2 days
- J: 0.5 day

### Risks & Mitigations
- View dependency on ALTER: handled via drop/rename→ALTER→recreate
- Mixed dims: CI grep + failing gate
- Keyword quality: tune `tsvector` configs and weights


