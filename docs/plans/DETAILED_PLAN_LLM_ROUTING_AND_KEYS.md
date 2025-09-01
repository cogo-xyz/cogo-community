## Centralized LLM Routing & Key Management – Detailed Plan (Supabase + Edge Functions)

Goal: Centralize secrets, policies, and routing decisions; keep agents stateless/minimal; enable Orchestrator to make intelligent decisions based on policy, health, and cost.

### Scope
- Keys: storage/rotation/audit/quota per provider/model/env/tenant.
- Routing: provider/model selection by context length, latency/cost targets, domain tags, health.
- Orchestrator: calls `router-select` → `key-vault` → LLM; fallback direct path.

### Data Model (Supabase)
- `secure_keys` (+ `secure_keys_audit`) – already provided; V2 adds rich fields (status/version/usage/region/resource/model etc.).
- `llm_providers`(provider, base_url, regions[], headers_template, pricing json, enabled).
- `llm_models`(provider, model, service chat|embeddings, context_limit, cost_per_1k, default_region, enabled).
- `routing_policies`(name, priority, enabled, match_conditions jsonb, action jsonb).
- `provider_health`(provider, region, latency_ms, error_rate, updated_at).
- `usage_counters`(date, provider, model, tenant_id, input_tokens, output_tokens, cost, calls).

### Edge Functions
- `key-vault` (done): GET lookup by name/alias/provider/service/resource/env; POST upsert; audit touch.
- `router-select` (new):
  - Input: { service, intended_model?, context_tokens, sla_ms?, cost_sensitivity?, domain_tags?, region?, tenant_id? }
  - Logic: evaluate `routing_policies` → filter by `llm_models.enabled` and `context_limit` → rank by `provider_health` and cost → select top-1
  - Output: { provider, model, region, base_url, headers_template }

### Orchestrator Integration
- Decision flow: Orchestrator → `router-select` → `key-vault` → LLM HTTP call.
- Fallback: fixed-safe model; or direct call using `KeyClient.findBy({provider,service,resource})`.
- Tracing: propagate `trace_id`/`correlation_id`; log to `usage_counters`.

### MVP Checklist
- SQL: create `llm_providers`, `llm_models`, `routing_policies`, `provider_health`, `usage_counters`.
- Edge: implement `router-select` minimal (policy-less default ranking by health>cost>context).
- Client: small helper to call router & vault; cache 5–15m.
- Tests: smoke test script for chat + embeddings route selection.

### Security & Ops
- RLS: functions use service role; app uses anon with restricted views.
- Rotation: upsert new version, mark old as disabled after cutover.
- Quotas: enforce at function/proxy; alert on threshold.
- Dashboards: health + usage panels.

### Timeline (Incremental)
- Week 1: SQL + `router-select` skeleton + Orchestrator wire-up.
- Week 2: Health/usage feed; policy DSL v1; basic dashboard.
- Week 3+: A/B, budget caps, streaming proxy.


