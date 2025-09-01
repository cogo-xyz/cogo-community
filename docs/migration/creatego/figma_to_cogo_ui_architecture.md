### Figma → COGO UI JSON (UUIS) Architecture, Design, and Implementation Plan

#### Objective and Scope
- **Objective**: Convert Figma JSON into platform-neutral COGO Universal UI Schema (UUIS) using a Rule + Knowledge RAG centered pipeline, with LLM optional for refinement.
- **Scope**: AST normalization → rules-based mapping → layout/event mapping → design token referencing (W3C DTCG) → schema validation → artifacts/metrics/events. BDD/ActionFlow are downstream and integrate later.

#### High-Level Architecture
- Inputs: Figma MCP (WebSocket) response or directly provided `figma_json`
- Core modules: `FigmaAstNormalizer` → `UiRulesEngine` → `UiLayoutMapper` → `UiEventMapper` → `UiTokensResolver` → `UiValidator`
- Outputs: Validated UUIS JSON artifacts, Supabase `bus_events`, Prometheus metrics
- Runtime: Supabase Bus (`UiConversionWorker`), `MCPGatewayBusWorker`, pgvector/Neo4j for RAG, Style Dictionary for multi-platform token builds

#### Data Pipeline
1) Acquisition
   - From MCP Gateway (`toolset=figma`, `tool=get_selection|get_document_info`) or direct `payload.figma_json`
   - Include `trace_id`, `idempotency_key`, `attempts`
2) Normalization
   - `FigmaAstNormalizer`: stabilize node shapes, extract Auto Layout, Variants, Styles, resolve incomplete fields
3) Rules Application
   - `UiRulesEngine`: map Figma nodes to UUIS SingleWidget/Component/Page types with props/events
   - Priority-based rules, conditions (variants, naming conventions, roles)
4) Layout / Events / Tokens
   - `UiLayoutMapper`: Auto Layout → Flex/Row/Column (gap, padding, alignment, resizing)
   - `UiEventMapper`: standardized action vocabulary (NAVIGATE, UPDATE_STATE, DISPATCH_EVENT, VALIDATE, CONDITION, FOCUS_ELEMENT), propagation (`onChildEvent:<name>`, debounce)
   - `UiTokensResolver`: replace literal values with DTCG token references (no hard-coded values in UUIS)
5) Validation & Emission
   - `Ajv` validation against `uuis.schema.json`
   - Save artifacts: `artifacts/ui/<ts>/{request.json, figma.json, uuis.json, summary.json, error.json}`
   - Emit `bus_events` and record metrics (latency histogram, success/fail counters)

#### UUIS Schema Principles
- Three layers: `SingleWidget`, `Component`, `Page` (children: `[SingleWidget|Component]`)
- Events: declarative triggers with safe, finite action types; supports propagation and debounce
- Design tokens: reference only (W3C DTCG compliant RAW_JSON); no literal colors/spacing in UUIS

#### Rules Engine: Rule + Knowledge RAG
- Rules
  - Declarative rules: `configs/figma_rules/*.json` (node-type → UUIS type/props/events)
  - Priority, weight, conditions (variants, naming, semantic roles)
- RAG Augmentation
  - pgvector: retrieve similar historical mappings/patterns
  - Neo4j: leverage component relations/compositions for semantic disambiguation
- Decision Strategy
  - Deterministic rule selection first → fallback to RAG hints when ambiguous → persist decisions as learnable examples

#### Design Tokens with Style Dictionary
- Inputs: DTCG RAW token JSONs (`tokens/raw/**/*.json`)
- Builds:
  - Web: `artifacts/tokens/web/tokens.css` (CSS vars), `tokens.json`
  - React: `artifacts/tokens/react/tokens.ts`
  - Flutter: `artifacts/tokens/flutter/cogo_theme.dart` (custom format)
- UUIS stores token aliases only; platform heads import built artifacts
- Reference: [style-dictionary](https://github.com/style-dictionary/style-dictionary)

#### Layout & Event Mapping (Essentials)
- Auto Layout mapping table → Flex properties and Flutter Row/Column equivalents (direction, gap, padding, justify/align, resizing)
- Parent-child event linkage via propagation model and `onChildEvent:<name>` triggers
- Dynamic placeholders: `${event.value}`, `${state.*}` within payloads

#### Services and Files (Proposed)
- `src/services/ui/FigmaAstNormalizer.ts`
- `src/services/ui/UiRulesEngine.ts`
- `src/services/ui/UiLayoutMapper.ts`
- `src/services/ui/UiEventMapper.ts`
- `src/services/ui/UiTokensResolver.ts`
- `src/services/ui/UiValidator.ts` (Ajv)
- `src/services/ui/FigmaToUiConverter.ts` (orchestration)
- `src/workers/UiConversionWorker.ts` (bus subscriber, artifacts/metrics)
- Configs: `configs/uuis.schema.json`, `configs/figma_rules/*.json`, `tools/style-dictionary/*`

#### Messaging, Workers, Routes
- Bus message (enqueue): `{ service:"ui", role:"convert", payload:{ toolset:"figma", tool:"get_selection", params?, figma_json? }, trace_id, idempotency_key }`
- Events: `ui_conversion_scheduled`, `ui_conversion_succeeded`, `ui_conversion_failed`
- API: `POST /api/ui/convert` (ADMIN token guard; route policies allowlist)
- MCP Gateway: `service=mcp`, `role=gateway` (WebSocket/child-process), with retry/circuit/metrics/artifacts

#### Observability & Artifacts
- Metrics: `cogo_ui_calls_total`, `cogo_ui_fail_total`, `cogo_ui_latency_ms` (p50/p95)
- Artifacts: deterministic directory with ISO timestamp slug; include request/response/summary/error
- Trace: propagate `trace_id`, include `attempts`, `idempotency_key`

#### Resilience & Security
- Retry/backoff: `configs/retry_policy.json` (exponential, caps)
- Circuit breaker: `configs/circuit_breaker.json` (keys like `uiconvert.*`)
- DLQ: move unrecoverable failures for postmortem
- Security: ADMIN token guard for non-GET; route policies deny-by-default; secrets via env/secret manager only

#### Development Plan (Batched)
1) Schema & Tokens
   - Finalize `uuis.schema.json`; implement Ajv validator
   - Setup Style Dictionary pipeline and CI step
2) Normalization & Rules MVP
   - Implement `FigmaAstNormalizer`, `UiRulesEngine` for core widgets (button, text, image, container, input)
   - Layout mapping for Auto Layout; basic events (click→DISPATCH_EVENT/UPDATE_STATE)
3) Worker, Artifacts, Metrics
   - Complete `UiConversionWorker` with metrics/events/artifacts
   - Expose `/api/ui/convert` with admin guard and policies
4) RAG Integration
   - Index examples to pgvector; model component relations in Neo4j
   - Apply RAG biasing for ambiguous mappings
5) Quality Gates
   - Unit/contract tests; golden-file diffs for sample Figma→UUIS
   - MCP ping in CI; metrics thresholds (Q1)
6) Extensions
   - Variants, conditional actions, VALIDATE, richer propagation patterns
   - Validate renders in React/Flutter heads using token artifacts

#### Testing & Gates
- Unit: normalization, rules, layout, events, token references
- Contract: Ajv schema conformance; artifact presence
- E2E (optional in CI): MCP `get_selection` → UUIS saved + summary verified
- Gate criteria: zero failures, 100% schema validity, metrics reported

#### Risks & Mitigations
- Figma variability → normalization rules, lenient unknown attribute handling
- Rule complexity growth → rule versioning, experiment flags, RAG precedence config
- MCP availability → `figma_json` direct input fallback, circuit breaker
- Performance → caching (tokens, component patterns), worker sharding

#### Examples
- Bus message (enqueue)
```json
{ "service":"ui","role":"convert","payload":{"toolset":"figma","tool":"get_selection","params":{"file":"abc"}},"trace_id":"t-1","idempotency_key":"i-1" }
```

- Minimal UUIS button
```json
{ "type":"cogo:button","props":{"label":"Submit","variant":"primary"},"events":[{"on":"click","action":{"type":"DISPATCH_EVENT","payload":{"eventName":"SUBMIT_FORM"}}}] }
```

#### References
- Style Dictionary (W3C DTCG-aligned token build system): [style-dictionary](https://github.com/style-dictionary/style-dictionary)


