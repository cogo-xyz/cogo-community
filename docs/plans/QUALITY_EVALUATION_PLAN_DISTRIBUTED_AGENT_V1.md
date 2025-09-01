## Quality Evaluation Plan – Distributed Intelligent Agent (V1)

Purpose: Validate that the distributed, intelligent, RAG-driven agent delivers end-user-grade quality before any production setup. Quality-first: product-worthiness over infra/budget.

### 1) Quality Goals (what “good” means)
- Task Success (Primary): End-user tasks complete correctly end-to-end
- Groundedness: Answers are supported by retrieved evidence (citations mandatory)
- Correctness/Precision: Low error rate in outputs (code compiles/tests pass; docs consistent)
- Stability/Repeatability: Low variance across runs given same inputs
- UX Quality: Concise, actionable, and formatted outputs (developer-friendly)

### 2) Scenario Taxonomy (end-user perspective)
- Code & Engineering (agent-core)
  - Bug triage & minimal fix (compile/test pass)
  - Code explanation with citations
  - Refactor small module with acceptance tests
- Research & Documentation (platform)
  - Requirements synthesis from docs with source citations
  - API usage guide generation from README/openapi
- Indexing & Retrieval
  - Repo/docs ingestion → query → grounded answers (hit@k, citation correctness)
- Collaboration
  - Task decomposition → sub-steps → evidence-backed result summary

### 3) Scenario Format (declarative JSON)
```json
{
  "id": "code.fix.compile.error.v1",
  "domain": "code",
  "inputs": {
    "repo": "cogo-agent-core",
    "description": "Fix compile error in file X; keep behavior",
    "constraints": ["keep API stable", "tests must pass"]
  },
  "expected": {
    "artifacts": ["diff"],
    "verifications": ["compile", "unit_test"],
    "quality": {
      "citations_required": false,
      "style": "concise"
    }
  }
}
```

### 4) Evaluation Harness
- Scenario Catalog: `scenarios/*.json`
- Runner: executes agent with fixed seeds/prompts → collects outputs/artifacts
- Critics (automatic):
  - Code: compile/typecheck/lint/test
  - Docs: citation check (all claims traceable)
  - Retrieval: groundedness@k, answer hit@k
- Scoring:
  - task_success (pass/fail), groundedness (0..1), precision (0..1), stability (stddev), ux_score (heuristic)
- Reports:
  - Per-scenario JSON, aggregate dashboard (pass rate, top failures, regressions)

### 5) Quality Gates (pre-production)
- Gate Q1 (Baseline): task_success ≥ 0.7 across suite, groundedness@3 ≥ 0.75
- Gate Q2 (Raising): task_success ≥ 0.8, no critical regressions 2 runs in a row
- Any failure blocks expansion; investigate top failing scenarios first

### 6) Coverage Plan
- P0 (Core suite, 10–15 scenarios): code fix/explain, doc QA, retrieval QA
- P1 (Expand 15–30): refactor, multi-file changes, deeper research tasks
- P2 (Broaden): domain-specific (e.g., accounting rules, travel constraints)

### 7) Schedule & Deliverables
- Sprint A (Now):
  - Define scenario schema + 10 core scenarios
  - Implement runner + automatic critics + JSON reports
  - Integrate with EventBus (PlanStep/ToolResult/Critique/Gate) for auditability
- Sprint B:
  - Expand suite to 20+; add citation/groundedness critics
  - Add aggregated quality dashboard (pass rate, groundedness, top failures)
- Sprint C:
  - Stability runs (N≥5) and variance stats; set Q2 gate thresholds

### 8) How this ties to RAG & Platform
- Indexing: agent-core and platform docs/repo fully ingested; queries must cite
- Retrieval: hybrid search validated by scenario scoring (hit@k, groundedness)
- Outputs: enforce JSON message standard; critics emit verdicts used in gates


