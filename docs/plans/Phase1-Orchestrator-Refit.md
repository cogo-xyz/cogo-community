# Phase 1 Orchestrator Refit – Plan (Supabase Realtime single‑pipe, intelligent orchestrator)

## Objectives (2 weeks)
- Merge to the documented architecture: container = 1 realtime connection; routing via message keys
- Add OrchestratorBrain (sense→diagnose→plan→allocate→observe→evaluate→update)
- Keep current ops stable (auto‑pause/resume/weekly) while refactoring message bus

## Deliverables
- SQL: `supabase/sql/agent_messages.sql` (message bus), `agent_shards.sql` (optional)
- Core: `src/orchestrator/OrchestratorBrain.ts`, `src/orchestrator/routing_policies.ts`
- Bus: `src/services/realtime/SupabaseRealtimeBus.ts` (single table subscription, claim/complete)
- Refactors: gateway/dispatcher/indexer/kg workers → Bus integration (remove multi‑channel)
- APIs: `POST /api/orchestrator/decide` (dry‑run), `GET /api/orchestrator/state`
- Docs: architecture alignment notes, rollout steps

## Milestones
- M1 (Day 1‑2): SQL + Bus skeleton + ChatGateway migrate to Bus (single shard)
- M2 (Day 3‑5): Dispatcher/Indexer/KG migrate; remove legacy multi‑channel code
- M3 (Day 6‑7): OrchestratorBrain minimal loop + `/api/orchestrator/decide`
- M4 (Day 8‑10): Policies/Scorers + decide quality metric in 40‑case bench
- M5 (Day 11‑14): Stabilize, docs, rollout to staging, canary 20→40

## Success Criteria
- Each container uses at most 1 realtime subscription
- Bench 40 cases: decision correctness ≥ 80% initially, trend ↑
- No message loss/dup; backlog p95 < threshold; ops stable

## Risks/Mitigations
- Event throughput: shard routing, idempotent claim, backoff
- Policy regressions: dry‑run compare vs current heuristic
- Rollout risk: staged (gateway→dispatcher→rest), canary gating
