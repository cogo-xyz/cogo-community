## Router-Select Scoring v2 (Policy/Cost/Latency/Health)

Purpose
- Rank LLM candidates by policy compliance, cost, latency, health, and region preference. Provide graceful degradation when intended model is unavailable.

Data Sources (Supabase)
- `llm_providers(provider_id, regions[], base_url, quotas, headers)`
- `llm_models(model_id, provider_id, capabilities[], context_window, input_usd_per_1k, output_usd_per_1k, max_tokens)`
- `routing_policies(tenant_id, allow[], deny[], max_latency_ms, max_error_rate, region_prefs{region:weight}, hard_pins{intent→model})`
- `provider_health(provider_id, region, p50_ms, p95_ms, error_rate, success_rate, updated_at)`
- `usage_counters(tenant_id, provider_id, model_id, tokens_in, tokens_out, usd)`

Inputs (Request)
```json
{
  "tenant_id": "t1",
  "intent": "chat|code|research|rerank",
  "expected_tokens": { "in": 800, "out": 1200 },
  "latency_slo_ms": 2000,
  "priority": "low|normal|high",
  "intended_model": "optional-model-id",
  "region": "optional-region"
}
```

Candidate Set
- Join allowed providers/models filtered by policy deny/allow.
- Filter by max_latency_ms and max_error_rate (using health p95 and error_rate).
- If `intended_model` present and allowed, place it as candidate even if near-threshold; will be penalized but not removed unless hard violation.

Scoring (0..1, higher better)
- policy_score: 1.0 if allowed; 0 if denied; partial if near limits (latency/error) → `max(0, 1 - penalty)`
- cost_score: normalize by estimated USD: `estimate = in/1000*input_usd + out/1000*output_usd`; lower cost → higher score via min-max across candidates
- latency_score: from `p95_ms` vs `latency_slo_ms`; 1 if p95 <= SLO, decays as it exceeds SLO
- health_score: from `(1 - error_rate)` with decay for stale `updated_at`
- region_score: from `region_prefs` (default 0.5; preferred region near 1.0)

Final
```
score = Wp*policy + Wc*cost + Wl*latency + Wh*health + Wr*region - penalties
defaults: Wp=0.35, Wc=0.2, Wl=0.2, Wh=0.2, Wr=0.05
penalties: budget_exceeded(0.3), rate_limited(0.2), cold_start(0.1)
```

Constraints & Exclusions
- Hard policy violation (deny list, compliance, quota hard cap) → exclude.
- If no candidates remain, return fallback policy with explicit reason codes.

Fallback/Degrade
- If `intended_model` fails health/error constraints: prefer same provider alternative; else cheapest healthy among allowed.
- Include `reason": "degraded_from_intended"` in response metadata.

Output (Response)
```json
{
  "request_id": "ulid",
  "ranked": [
    { "provider": "anthropic", "model": "claude-3-5-sonnet", "region": "us-east-1", "base_url": "...", "headers": {"x-api-key": "vault://..."}, "score": 0.87, "est_cost_usd": 0.0042, "p95_ms": 1450, "error_rate": 0.01 },
    { "provider": "openai", "model": "gpt-4o", "region": "us-west-2", "score": 0.82 }
  ],
  "metadata": { "policy_version": 2, "scoring": "v2", "flags": { "ROUTER_SCORE_V2": true } }
}
```

API Contract (Edge Function `router-select`)
- POST `/` with Inputs → 200 OK Response above
- `Content-SHA256` header over body for integrity (optional)

Feature Flags / Env
- `ROUTER_SCORE_V2=true|false` (switch scoring)
- `ROUTING_REQUIRE_RANKED` (min candidates threshold; default 1)

Observability
- `/api/metrics/routing?service=chat` exposes top-3 with scores, p95, error_rate, cost estimate.
- Metrics: `cogo_router_rank_score{provider,model,region}`, `cogo_router_failover_total{reason}`

Acceptance Tests
1) Intended model healthy → ranked first; no degrade.
2) Intended model unhealthy (error_rate high) → degrade with reason, cost/latency within policy.
3) Deny-list model excluded despite low cost.
4) No candidates → explicit empty with reasons; HTTP 200 + error payload.
5) Budget exceeded → penalty applied or excluded per policy.


