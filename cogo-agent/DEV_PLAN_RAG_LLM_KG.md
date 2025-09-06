### Development Plan: RAG + LLM + KG Rollout

#### Bundle A: RAG bootstrap
- Implement `src/shared/retrieval/packer.ts` used by Edge Functions (chat, json-generate, figma-compat):
  - Inputs: project_id, page_id?, task_type, hints; Output: ranked contexts.
- Add script `src/scripts/rag/upsertVectorDocs.ts` to summarize+embed+upsert into `cogo.vector_documents` from `public.cogo_documents`.
- Ensure `EMBED_DIM=1024`; add cron/batch to run `refresh_vector_documents_tsv_batch`.

#### Bundle B: KG upsert worker
- Create worker at `workers/kg/worker.js` (Node + PM2):
  - Consume `kg.upsert_request` → fetch artifact JSON → upsert SystemSymbol/Symbol/Action/Flow/BddScenario nodes and relationships.
  - Emit claim/exec/retry metrics; DLQ handling.

#### Bundle C: Domain grounding
- Import ecommerce templates (login/social login/catalog/PDP/cart/checkout/refund/notifications/bulk) into `public.cogo_documents` for seed; vectorize via Bundle A.
- Update prompts in `json-generate` to incorporate domain templates through retrieval packer; enforce symbol policy.

#### Bundle D: Parity and validation
- Keep strict parity gates via `docsParityCompare.ts`.
- Extend normalizers as needed; run gates in `scripts/quality/run_everything.sh`.

#### Bundle E: Observability
- Emit RAG/LLM metrics to `bus_events`; add dashboards and CI-lite gate on pass thresholds.

#### Milestones
1) Pack retrieval + vector upsert runner.
2) KG upsert worker running; action/flow/symbol graph materialized.
3) Domain templates ingested; BDD/actionFlow parity improves on full corpus.
4) Quality gate green; documentation updated.


