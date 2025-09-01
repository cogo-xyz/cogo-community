### BDD Compiler Development Plan (Core)

Goals
- Parse extended BDD (Given/When/Then + And/But/Otherwise/Else/Unless/Except)
- Generate ActionFlow DSL with guards/branches/variables
- Validate, simulate, and verify against KG/RAG

Milestones
1) Parser skeleton (rules + tokens) → skeleton IR
2) LLM semantic resolver (prompt+constraints) → enriched IR
3) DSL generator + JSON Schema validation
4) Dry-run simulation + error model
5) KG/RAG checks + repair loop
6) E2E for 10 scenarios (acceptance gate)

Acceptance
- 10/10 scenarios pass E2E
- Invalid DSL 100% rejected with standardized error codes

CI/Gates
- `ci:aflow` extended to include BDD compile smoke bundle
- Budget: error=0, pending=0, p95 step latency within target


