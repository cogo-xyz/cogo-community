# BDD #action Symbol Plan (AST, pgvector, Neo4j)

## Goals
- Concise BDD action calls via `#` syntax, safe symbol binding, CreateGo builtin parity.
- Compiler: BDD → AST → COGO DSL; preserve source map.
- Observability: RAG (pgvector) + Knowledge Graph (Neo4j) integration.

## Syntax (Summary)
- Call: `#act.nav.go(path="/home")` (alias: `#nav.go(...)`)
- Params: key=value; values can be literals, `#var`, objects `{}`, arrays `[]`.
- Controls:
  - If: `#if(expr) then <action> else <action>`
  - Switch: `#switch(expr) case v1: <action> case v2: <action> default: <action>`
  - While: `#while(expr) do <action>`
- Chain: `<action> -> <action>` maps to onSuccess.

## Mapping to COGO DSL
- `#nav.go(path="/p")` → `{type:navigate, params:{path:"/p"}}`
- `#ui.showPopup(...)` → `{type:emit, params:{event:"ui.popup", payload:{...}}}`
- `#ui.showError(...)` → `{type:emit, params:{event:"ui.error", payload:{...}}}`
- `#link.open(url:"https://...")` → `{type:emit, params:{event:"ui.open_link", payload:{url}}}`
- `#http.call(baseUrl:#api, path:"/auth", method:"POST", body:{...}, saveTo:"#loginUser")`
  → `{type:api_call, params:{...}}`
- `#expr.set(#k, v)` → `{type:expression, params:{execute:"#k=v"}}`
- If/Switch/While → `if/switch/while` with guards/branches/steps.

## AST
- Nodes: Scenario, Step, ActionCall(name, ns, args), Arg(key, value), Value(lit|var|obj|arr), If, Switch, While, Chain.
- Source map: line/column for each node.

## Parser/Compiler
- Tokenize `#name(.name)*(` then parse arglist; JSON-like object/array; `#var` captured.
- Normalize aliases (`#nav.go` → `#act.nav.go`).
- Compile to COGO DSL using mapping tables (builtin parity ensured).

## Builtin Parity (CreateGo)
- navigate(routePath) ✔
- showPopup(title?, message) → ui.popup ✔
- showErrorPopup(message, title?, buttonText?) → ui.error ✔
- goToLink(link) → ui.open_link ✔
- restApi(...) → api_call(+retries, timeoutMs) ✔
- conditional/loop/switch JSON forms matched in converter ✔

## pgvector (RAG)
- Index: BDD text, ActionCall signatures, guards, compiled DSL snippets.
- Table: `cogo.vector_documents(doc_id, kind, text, embedding, tsv)`; BGE-M3(1024), hybrid with tsvector.
- Uses: autocomplete, param recommendation, error-to-scenario retrieval, compile diff similarity.

## Neo4j (KG)
- Nodes: ActionFlow, ActionStep, BuiltInAction, Variable, Expression, ApiEndpoint, ErrorKind.
- Rels: CONTAINS, CALLS, BINDS, USES_API, FAILS_AS.
- Sync: Postgres outbox → projection worker → Neo4j upsert (idempotent).
- Uses: impact analysis, unmapped builtin detection, release notes.

## CI/Gates
- `bdd:compile:test`, `bdd:ast:snapshot`: parser determinism.
- `rag:vector:verify`: vectors exist, hybrid indexes present.
- `neo4j:apply:ci`: constraints and minimal counts.
- Artifacts: `artifacts/bdd/{ast.json, dsl.jsonl, junit.xml, summary.md}`.

## Security
- No secrets in BDD; http.call requires jwt via `#var` only.
- Timeouts, retries, circuit breaker sane defaults.

## Next
- Implement parser/AST scaffolding, small E2E set, wire CI.
