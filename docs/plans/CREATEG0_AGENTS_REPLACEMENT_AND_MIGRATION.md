## CreateGo-Agents Replacement and Migration Plan

Date: 2025-08-25

### Objective
- Replace `/Users/hyunsuklee/Desktop/Dev/cogo-project/CreateGo-Agents` functionality with cogo-agent first.
- Freeze CreateGo IDE migration to last step.

### Stage 1 – Replacement (cogo-agent focus)
- Analyze CreateGo backend service responsibilities and map to cogo-agent capabilities
  - Conversion (Figma→UUI→COGO UI JSON): via `figma-compat`
  - Chat/Embedding pipelines: `chat`, `embed`, distributed agents
  - Storage/Indexing: cogo schema (vectors, knowledge)
- Implement missing features in cogo-agent-core
- Validate with E2E tests and plugin flows

### Stage 2 – Projection & Policy
- Enforce domain separation: agents write cogo.*; IDE writes public.*
- Run projection worker from `cogo.project_updates` into `public.*`

### Stage 3 – Migration (incremental)
- Packages/Starter alignment to public.* read models
- IDE migration last
  - Replace creatego_supabase models with policy-aligned access
  - Remove direct SRK patterns if any

### Deliverables
- Docs hub: `docs/CREATEG0_MIGRATIONS_PROJECT.md`
- Reorg plan: `docs/REPO_REORG_PLAN.md`
- Outbox DDL: `supabase/sql/2025-08-25_cogo_project_updates_outbox.sql`
- Projection worker spec: `docs/schemas/PROJECTION_WORKER_SPEC.md`
- E2E scenarios & integration docs
