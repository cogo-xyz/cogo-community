## BDD Pipeline Guide

This guide summarizes how to run the end-to-end BDD pipeline, verify, gate, archive, and publish results.

### Prerequisites
- SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY (for SQL apply)
- SUPABASE_EDGE, SUPABASE_ANON_KEY (for SSE embed/search)
- NEO4J_URI, NEO4J_USER, NEO4J_PASSWORD, NEO4J_DB (for KG apply)
- Optional webhook:
  - WEBHOOK_TYPE=slack|googlechat|github
  - or WEBHOOK_URL=https://example.com/webhook

### End-to-End (local dir)
```
npm run bdd:all --DIR=./workspace/bdd/samples
```
Outputs to `artifacts/bdd/`:
- manifest.jsonl, rag_upsert.sql, neo4j.cypher
- kg_report.{json,md}, kg_metrics.{json,md}, kg_graph.mmd
- bdd_comprehensive.{json,md}, bdd_graph.mmd
- summary/summary.md, summary/junit.xml

### Verify + Gate only
```
npm run bdd:verify:bundle
npm run bdd:gate
```
Thresholds: RAG_MIN_HIT_RATE (default 0.5), MIN_FLOWS=1, MIN_STEPS=1

### Archive and Publish
```
npm run bdd:archive
npm run bdd:publish --DIR=./workspace/bdd/samples
```
Publish runs: all → archive → notify.

### Weekly Ops Bundle integration
`npm run ops:weekly:bundle` includes BDD report/graphs/summary. If `BDD_DIR` is set, it also runs `bdd:dir:e2e` and `bdd:publish`.

### Artifacts Serving (local metrics server)
- Serve static: `/artifacts` (ARTIFACTS_BASE or ./artifacts)
- Summary endpoints:
  - `/api/artifacts/smoke/summary`
  - `/api/artifacts/gate/summary`

Start metrics server locally:
```
npm run server:metrics
# Then open http://localhost:3100/artifacts and /api/artifacts/gate/summary
```

### CI Recommendations
- Add a PR job to run:
  - `npm run ci:pr:compat` (legacy flows)
  - `npm run ci:pr:bdd` (compile→manifest→kg emit)
  - `npm run ci:pr:bdd:dir --DIR=./workspace/bdd/samples` (optional full)
- Upload `artifacts/bdd/summary/junit.xml` for test reporting.


