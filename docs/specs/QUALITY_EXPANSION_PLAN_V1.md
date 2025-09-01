## Quality Expansion Plan v1 (Scenarios & Critics)

Objective
- Expand scenario-based quality coverage and externalize critic weights/policies. Standardize reports consumable by CI and dashboards.

Scenarios
- Increase curated scenarios from 10 → 15 with clear domain labels (routing, indexing, reasoning, compile, contract).
- Schema: `scenarios/*.json` with fields { name, domain, inputs, expected, success_condition, timeout_ms, skip }.

Critics (Examples)
- GroundednessCritic: checks citations presence and source alignment.
- CitationCritic: verifies file+line or doc IDs exist and are within top‑k.
- CompileCritic: compiles minimal code snippets when applicable.
- SimpleContractCritic: validates JSON contracts against schema.

Weights & Policy
- Expose `W_GROUNDEDNESS`, `W_CITATION`, `W_COMPILE`, `W_CONTRACT` via env; defaults documented.
- Aggregate score emits pass/fail and per-critic contributions.

Runners
- `runScenario.ts` (single), `runAllScenarios.ts` (batch), `runLight.ts` (subset).
- Outputs to `reports/quality/{date}/...` + `reports/quality/light-summary.json`.

Reporting
- Summary JSON: { pass_rate, failed_cases[], top_failures[], per_domain_stats }.
- PR comment content prepared from summary for readability.

Acceptance Criteria
- `quality:run:all` green on mandatory subset; light at least 2 scenarios pass in PR‑Lite.
- Critics configurable via env; summary JSON emitted; CI job attaches artifacts.

Feature Flags
- `QUALITY_SCENARIO_SKIP_UNSTABLE=true|false`
- `QUALITY_LIGHT_LIMIT` for PR‑Lite selection.


