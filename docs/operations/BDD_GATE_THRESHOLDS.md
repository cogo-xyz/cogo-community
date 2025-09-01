## BDD Gate Thresholds

Environment variables to control the BDD verification gate:

- RAG_MIN_HIT_RATE: overall min hit rate (default 0.5)
- RAG_EASY_MIN: min hit rate for easy queries (default RAG_MIN_HIT_RATE)
- RAG_MED_MIN: min hit rate for medium queries (default RAG_MIN_HIT_RATE)
- RAG_HARD_MIN: min hit rate for hard queries (default 0.8 * RAG_MIN_HIT_RATE)
- MIN_FLOWS: minimum number of compiled flows (default 1)
- MIN_STEPS: minimum number of steps (default 1)
- KG_MIN_EDGES: minimum number of KG transition edges (default 0)
- STEP_MIN_COUNTS: JSON string specifying minimum counts per step type, e.g. `{ "api_call": 1, "navigate": 1 }`

Outputs are written under `artifacts/bdd/summary/` with JUnit XML and Markdown.


