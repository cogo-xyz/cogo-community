## CreateGo → COGO Migrations Project (Hub)

Date: 2025-08-25

### Scope
- Replace legacy CreateGo references with COGO
- Domain separation: `public` (user app data) vs `cogo` (agent/platform internals)
- Introduce CQRS with outbox→projection pattern
- Align IDE/Starter to read/write `public.*` under RLS; agents write to `cogo.*`

### Priorities
- 1) Replace CreateGo-Agents with cogo-agent capabilities first
- 2) Migrate packages → starter → IDE (last)

### Big Picture
- See: [docs/schemas/BIG_PICTURE_ARCHITECTURE.md](./schemas/BIG_PICTURE_ARCHITECTURE.md)
- Repo reorg plan: [docs/REPO_REORG_PLAN.md](./REPO_REORG_PLAN.md)
- Replacement & migration plan: [docs/plans/CREATEG0_AGENTS_REPLACEMENT_AND_MIGRATION.md](./plans/CREATEG0_AGENTS_REPLACEMENT_AND_MIGRATION.md)
 - Feature catalog: [docs/plans/CREATEG0_AGENTS_FEATURE_CATALOG.md](./plans/CREATEG0_AGENTS_FEATURE_CATALOG.md)

### Backend Schema & Policy
- Domain separation policy: [docs/policies/DOMAIN_SEPARATION_POLICY.md](./policies/DOMAIN_SEPARATION_POLICY.md)
- Backend mapping (policy-aligned): [docs/schemas/BACKEND_PUBLIC_TO_COGO_MAPPING.md](./schemas/BACKEND_PUBLIC_TO_COGO_MAPPING.md)
- Outbox DDL: [supabase/sql/2025-08-25_cogo_project_updates_outbox.sql](../supabase/sql/2025-08-25_cogo_project_updates_outbox.sql)
- Projection worker spec: [docs/schemas/PROJECTION_WORKER_SPEC.md](./schemas/PROJECTION_WORKER_SPEC.md)
- Migration plan: [docs/migration/PUBLIC_TO_COGO_CQRS_MIGRATION.md](./migration/PUBLIC_TO_COGO_CQRS_MIGRATION.md)

### Integration
- Figma plugin integration: [docs/integration/FIGMA_PLUGIN_INTEGRATION.md](./integration/FIGMA_PLUGIN_INTEGRATION.md)
- IDE access map (public writes inventory): [docs/reports/IDE-Supabase-Access-Map.md](./reports/IDE-Supabase-Access-Map.md)
- Starter usage & mapping: [docs/reports/Starter-Supabase-Usage-and-Mapping.md](./reports/Starter-Supabase-Usage-and-Mapping.md)

### Observability & Tests
- Observability & SSE: [docs/observability/OBSERVABILITY_AND_SSE.md](./observability/OBSERVABILITY_AND_SSE.md)
- E2E verification scenarios: [docs/tests/E2E_VERIFICATION_SCENARIOS.md](./tests/E2E_VERIFICATION_SCENARIOS.md)

### Notes
- Edge: `chat`, `chat-gateway`, `embed`, `figma-compat`
- Agents: orchestrator, research, indexing, executor, projection
- Security: dev relaxed; prod short-lived JWT, SRK for projection
