## Figma ↔ UUI (COGO UUIS) Type Mapping Guide

This document is the source-of-truth for how Figma node types and names map to UUI (COGO UUIS) component types. It consolidates the current rules defined in `configs/figma_rules/*.json` and the transformation logic in `src/ast/uuis/passes/RulesPass.ts` and `src/services/ui/UiRulesEngine.ts`.

### Scope
- Input: Figma REST JSON (document/selection)
- Normalization: `FigmaAstNormalizer` → `UiRulesEngine` → UUIS AST pipeline passes
- Output: UUI `UiJson` nodes with `type: "cogo:*"`

### Primary Sources
- Rules JSON: `configs/figma_rules/{basic,components,inputs,containers,icons,images,cards,lists}.json`
- Rule application (AST pipeline): `src/ast/uuis/passes/RulesPass.ts`
- Rule application (converter path): `src/services/ui/UiRulesEngine.ts` (legacy/simple path)

### Environment Flags (Behavioral)
- `UUI_RULES_COMPONENTS_ENABLED` (default: false) — include `components.json` high-level mappings (tabs/modal/navbar/header/footer/badge/chip/avatar/table)
- `UUI_RULES_HOT_RELOAD_MS` (default: 0) — hot-reload window for rule file changes
- `UUI_RULES_ENV` — select environment-tagged rules (if any)
- `UUI_RULES_NAME_MATCH` (default: true) — enable name-based pattern matches
- `UUI_RULES_MERGE_MODE` (default: `override`, alt: `additive`) — props merge policy

---

### Mapping Table (Current)

| Figma Input | Matching Condition | UUI Output | Notes |
| --- | --- | --- | --- |
| TEXT | type=TEXT | `cogo:text` | Basic text node |
| TEXT → TextField | type=TEXT, name matches `(email|username|search|input|textfield)` | `cogo:textfield` | From `inputs.json` |
| FRAME/GROUP/COMPONENT/INSTANCE | container types | `cogo:stack` | Default container |
| RECTANGLE | type=RECTANGLE | `cogo:box` | Base rule; see conflict with images below |
| IMAGE | type=IMAGE | `cogo:image` | Image mapping |
| ELLIPSE | type=ELLIPSE | `cogo:image` | Image mapping fallback |
| RECTANGLE → Image | type=RECTANGLE | `cogo:image` | From `images.json`; can compete with `cogo:box` depending on precedence |
| VECTOR | type=VECTOR | `cogo:icon` | Icon mapping |
| FRAME → Card | container types, name matches `(card|product|item)` | `cogo:card` | From `cards.json` |
| FRAME → List | container types, name matches `(list|items|grid)` | `cogo:list` | From `lists.json` |
| FRAME → Tabs | container types, name matches `(tabs|tabbar)` | `cogo:tabs` | `components.json` (gated by flag) |
| FRAME → Modal | container types, name matches `(modal|dialog)` | `cogo:modal` | `components.json` (gated) |
| FRAME → Navbar | container types, name matches `(navbar|navigation)` | `cogo:navbar` | `components.json` (gated) |
| FRAME → Header | container types, name matches `(header)` | `cogo:header` | `components.json` (gated) |
| FRAME → Footer | container types, name matches `(footer)` | `cogo:footer` | `components.json` (gated) |
| FRAME/ELLIPSE → Avatar | name matches `(avatar|profile)` | `cogo:avatar` | `components.json` (gated) |
| FRAME → Badge | name matches `(badge)` | `cogo:badge` | `components.json` (gated) |
| FRAME → Chip | name matches `(chip|pill)` | `cogo:chip` | `components.json` (gated) |
| FRAME → Table | name matches `(table|datagrid)` | `cogo:table` | `components.json` (gated) |
| Otherwise | no match | `cogo:box` | Fallback |
| Normalization fallback | unknown type | `cogo:unknown` | During normalize pass |

Assembly-only UUI types (not directly produced by Figma type): `cogo:fragment`, `cogo:slot` (used by fragment assembly pass).

---

### Rule Loading & Precedence
AST pipeline (`RulesPass`) uses dynamic ordering with feature gates:
- Effective file order (when `UUI_RULES_COMPONENTS_ENABLED=true`):
  1) `components.json` (most specific)
  2) `inputs.json`, `cards.json`, `lists.json`, `icons.json`, `images.json`, `containers.json`, `basic.json`
- Name-based rules are attempted before type-based rules. If no rule matches, a fallback rule of `'*' → cogo:box` applies.
- Type match supports arrays in `ifType` (see `RulesPass.ruleMatchesType`).

Converter path (`UiRulesEngine`) is simpler and does not implement full precedence controls used by `RulesPass`. CI and gate rely on the AST pipeline path for determinism.

---

### Props Mapping Conventions
- String templates in rule `props` may use `$text` and `$name`, with fallback syntax like `"$text|$name"` to pick the first non-empty.
- Final `props` may carry `__rules_v` (rules version hash) injected by `RulesPass` for traceability.

---

### Known Gaps / Caveats
- RECTANGLE may map to `cogo:box` or `cogo:image`. Effective result depends on file ordering and the chosen precedence path. Prefer image-specific rules to come before the base rectangle rule (handled in `RulesPass`).
- Advanced component mappings (tabs/modal/navbar/header/footer/badge/chip/avatar/table) require `UUI_RULES_COMPONENTS_ENABLED=true`.
- Name-based detection depends on Figma layer naming conventions; ensure designers follow naming guidelines to enable intended mappings.

---

### Verification & CI
- Gate (hash verify + short SSE):
  - `npm run -s ci:uui:gate`
  - With golden updates: `npm run -s ci:uui:gate:update`
- Full UI CI:
  - `npm run -s ci:ui:full`
- Key endpoints:
  - Preview: `GET /api/uui/fragment/preview?url=...&key=...&verify=1`
  - Stream: `GET /api/uui/stream?url=...&key=...&maxChunks=2`
  - Metrics summary: `GET /api/metrics/summary`

Recommended env for deterministic CI: `UUI_RULES_HOT_RELOAD_MS=0`, `UUI_PIPELINE_EARLY_EXIT_NO_CHANGE=true`, `UUI_HASH_LAYOUT_ONLY=true`.

---

### Maintenance Workflow
1) Propose changes in `configs/figma_rules/*.json` (new mappings or regex updates).
2) If enabling advanced components, set `UUI_RULES_COMPONENTS_ENABLED=true` locally or in CI as needed.
3) Run gate locally to validate deterministic outputs and hash checks.
4) Update goldens if intentional changes: run `ci:uui:gate:update` and `ci:ui:full`.
5) Document the change (this file) if you add new `cogo:*` types or adjust naming conventions.

---

### Examples (Fixtures)
See `tests/ui/fixtures/*.golden.json` and `*.ast.golden.json` for end-to-end examples of type mappings:
- `figma_minimal` → `cogo:stack`, `cogo:text`, `cogo:textfield`, `cogo:button`
- `figma_card` → `cogo:card` with `cogo:text` children
- `figma_components_extended` → containers + `cogo:image`/`cogo:text` (advanced types enabled via flag)

---

### Related Code
- Normalization: `src/services/ui/FigmaAstNormalizer.ts`
- Rules (converter path): `src/services/ui/UiRulesEngine.ts`
- Rules (AST pipeline): `src/ast/uuis/passes/RulesPass.ts`
- UUI Schema: `configs/uuis.schema.json`
- AST Orchestrator: `src/ast/uuis/UuisAstOrchestrator.ts`


