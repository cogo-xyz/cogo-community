## Core Critical Path (Pre-Launch, Phase P0)

Status: P0 baseline complete (E2E green). Proceeding to Pre-Launch list next.

Focus: Finish the minimum Actor–Critic–Gate + RAG loop and observability so that we can iterate safely.

### Scope (must-have before widening)
- [x] JSON message types & validators (Envelope/PlanStep/ToolResult/Critique/Gate)
- [x] Event writers (Supabase/Neo4j) and EventBus
- [x] Wire LLM paths (chat/embed) to PlanStep→ToolResult→Critique→Gate
- [x] Wire Indexing worker to minimal events and gate
- [x] E2E tests
  - [x] Actor–Critic E2E (LLM)
  - [x] Indexing E2E (polling)
- [x] Metrics baseline (HTTP/Job + Tool latency, Step retry)
- [ ] Minimal dashboard update (tool latency/step retry/cost)

### Stretch for P0 (nice-to-have, if time permits)
- [ ] Tool cost aggregation (per-provider/model daily)
- [ ] Retry-once repair prompt (LLM) with evidence injection
- [ ] CI gating on E2E pass (non-blocking in PR, blocking in protected branch)

### Out of scope (move to P1)
- Beam/MCTS branching (beam=2) and budget/time guards
- Full dashboard and alerts
- Domain critics beyond code-static checks

### Execution Notes
- Keep minimal JSON schema stable; only additive fields allowed.
- Prefer best-effort writes (no hard blocking on analytics paths).


