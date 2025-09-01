### COGO UI JSON(UUIS) + AST Parsing/Transformation Batch Development Plan

#### 1) Scope & Objectives
- Build a robust, rule-driven pipeline from Figma JSON → UUIS(cogo UI JSON), with AST-centric architecture for maintainability and correctness.
- Deliver platform-neutral UUIS, token-referenced styles, and declarative events/actions ready for multi-head rendering (React/Flutter).
- Integrate with existing index agent (pgvector/Neo4j) to continuously improve rule accuracy via RAG.

#### 2) Delivered Batches (Done)
- UUIS pipeline MVP: Normalization → Rules → Layout → Events → Tokens → Ajv validation → artifacts
- External rules: basic/components/inputs/containers/icons/images/cards/lists
- Metrics/Artifacts/CI: tokens build (Style Dictionary) + golden comparison (`ci:ui`), golden update (`UPDATE_GOLDEN=1`)
- Samples/Goldens (5): minimal, align, icon_image, card, list
- Legacy cleanup: CreateGo bridge files moved to backups; docs and progress logs added

#### 3) Batch Plan – Next (UUIS + AST)
- Batch AST-1: AST foundation and parity
  - Types/Schema: `src/ast/uuis/AstTypes.ts` (Node, Props, Events, Action, Location)
  - Parser/Serializer: `UuisAstParser.ts` (JSON → AST), `UuisAstSerializer.ts` (AST → JSON)
  - Traversal: `AstVisitor.ts` (enter/exit), `AstTransforms.ts` (compose)
  - Passes:
    - `figma/NormalizePass.ts` (migrate `FigmaAstNormalizer`)
    - `rules/ApplyRulesPass.ts` (migrate `UiRulesEngine`)
    - `layout/LayoutPass.ts` (direction/justify/align/gap/padding)
    - `event/EventPass.ts` (on/propagation, parent onChildEvent)
    - `tokens/TokenAliasPass.ts` (spacing/color alias)
  - Validation: `AstValidatePass.ts` + Ajv (UUIS JSON schema)
  - Orchestration: converter uses AST pipeline end-to-end
  - Tests: add AST golden path (`ui:golden:all:ast`) parallel to JSON goldens

- Batch AST-2: Advanced behaviors
  - Rules: variants/state, widget-specific props, priority/weight, name/naming-convention enhancements
  - Events/Actions: CONDITION branches, VALIDATE chains, multiple onChildEvent subscribers
  - Performance: subtree hashing, memoization, streaming traversal for large Figma docs
  - Docs: `docs/ast/UUIS_AST_SPEC.md` (invariants, node kinds, passes)

#### 4) Index Agent Integration (Reuse + Upgrade)
- Add `UUISAstIndexer.ts` to feed UUIS AST/JSON to index agent
- pgvector: node/component embeddings (type/props/events signatures)
- Neo4j: nodes/relationships (UiNode, UiEvent, BubblesTo, onThen/onTrue/onFalse)
- Incremental & idempotent: content hash keys; artifacts under `artifacts/ui/index/<ts>`
- CI: `ci:index:ui` smoke (counts/latency), fail with diffs on regression

#### 5) Flutter Head (Next after AST-1 green)
- Style Dictionary formatter for Flutter → `cogo_theme.dart` (Reference-only, optional)
- UUIS → Flutter widgets mapping (layout/text/button/icon/image/card/list)
- Events/actions binding (UPDATE_STATE/VALIDATE/DISPATCH_EVENT)
- Snapshot tests: UUIS → widget tree expectations

#### 6) CI/Gates
- `ci:ui`: tokens build + JSON golden + AST golden
- `ci:index:ui`: sample AST indexing → counts/metrics sanity
- MCP ping step (if secrets available), artifacts summary
- Golden update allowed only with explicit `UPDATE_GOLDEN=1`

#### 6-1) Reference Artifacts Policy (All Platforms)
- Operating truth: DTCG JSON tokens + UUIS(JSON). Platform-specific code outputs are reference/test only.
- Reference generators (optional, per platform):
  - Flutter: `artifacts/reference/flutter/cogo_theme.dart`
  - Web(Tailwind): `artifacts/reference/web/tailwind.config.cogo.js`
  - React: `artifacts/reference/react/tokens.reference.ts`
  - iOS(Swift): `artifacts/reference/ios/CogoTheme.swift`
  - Android(Kotlin): `artifacts/reference/android/CogoTheme.kt`
- Script: `npm run tokens:reference` generates the above from JSON tokens; CI smoke checks generation only.

#### 7) Milestones
- M1 (AST-1): AST pipeline parity with current JSON path; CI green for 5 goldens
- M2 (AST-2): advanced events/rules + performance; 10+ composite goldens
- M3 (Indexing): UI AST indexed; RAG feedback loop online
- M4 (Flutter head): UUIS → Flutter MVP; tokens themed; snapshot tests

#### 8) Risks & Mitigation
- Figma variability → normalization rules + lenient unknown handling
- Rule drift vs goldens → strict CI; review w/ golden update gate
- Performance on large docs → streaming traversal + subtree hashing
- Env/toolchain mismatches → deps pinned (Ajv), engine warnings tolerated in dev

#### 9) Ownership & Ops
- Owners: UI pipeline (Converter/Rules/AST), Indexing UI, Flutter head
- Ops: artifacts under `artifacts/ui/*`, metrics via `cogo_ui_*`, `cogo_index_*`
- Security: ADMIN token guard, deny-by-default policy, secrets via key vault

#### 10) Commands (Quick Reference)
- Local convert: `npm run ui:convert:local`
- Goldens (all): `npm run ci:ui` (add `UPDATE_GOLDEN=1` to sync)
- Tokens build: `npm run tokens:build`

