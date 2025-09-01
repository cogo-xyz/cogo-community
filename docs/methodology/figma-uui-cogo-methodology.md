## Methodology: Figma ↔ UUI JSON ↔ Cogo UI JSON (LLM-assisted)

Goal: Define an end-to-end, error-resilient method to generate, annotate, convert, and validate UI across Figma, UUI JSON, and Cogo UI JSON, supporting both forward (Figma → UUI → Cogo) and reverse (Cogo → UUI → Figma) flows.

### A. Principles
- Single Source of Truth (SSOT): Semantics live with the artifact being converted (Figma nodes or JSON).
- Deterministic Mapping: 1:1 rules for node→JSON fields; avoid guesswork.
- Validation Gates: Fail early if required semantics are missing.
- Round-trip Fidelity: Conversions must be idempotent within acceptable tolerance (positioning, sizing).

### B. Flows
- Forward (Design-first): Figma → UUI JSON → Cogo UI JSON → App
- Reverse (Model-first): LLM → Cogo UI JSON → UUI JSON → Figma

### C. Minimal Required Semantics (Design-first)
- Page identity: `page.name` normalized; stable `page.id` or deterministic key.
- Page order: explicit page index (or encoded in name suffix).
- Frame roles: `HEADER`, `FOOTER`, `DRAWER`, `CONTENT` annotations.
- Component identity: stable `id`, `type`, `index_in_page`.
- Library references: mark frames that originate from library pages.

### D. Figma Semantic Conventions
- Layer naming tokens (suffix in name):
  - Page frame: `[PAGE]` e.g., `Home [PAGE]`
  - Roles: `[HEADER]`, `[FOOTER]`, `[DRAWER]`
  - Library: `[LIB]` for library page instances
  - Component type hints: `[TEXT]`, `[IMAGE]`, `[BUTTON]`, `[CONTAINER]`
- Plugin metadata (preferred): key-value pairs stored as plugin data
  - `cogo:id`, `cogo:type`, `cogo:role`, `cogo:index`, `cogo:libPageId`
- Page indexing:
  - Name suffix `#<n>` e.g., `Home#1 [PAGE]` or plugin `cogo:pageIndex`

### E. Mapping Rules (Figma → UUI JSON → DB)
- Figma Frame → `pages`
  - `name` → `pages.name`
  - `absoluteBoundingBox.width/height` → `pages.width/height`
  - fills.solid → `pages.bg_clr`
- Figma Node → `components`
  - `absoluteBoundingBox.{x,y}` → `dx,dy`
  - `absoluteBoundingBox.{width,height}` → `width,height`
  - `type` normalized → `type` (TEXT→`text`, RECTANGLE→`container`, IMAGE→`image`)
  - TEXT.characters → `options.text`
  - style tokens → `options.style` (fills, strokes, radius)
- Hierarchy
  - parent frame id → `page_id`
  - visual order → `index_in_page`
- Upsert keys (DB)
  - `pages`: `(id)` else `(name,width,height)`
  - `components`: `(page_id,id)` else `(page_id,index_in_page)`

### F. Validation Gates
1) Semantics gate (design-time)
   - Ensure required tokens/plugin data exist per page/frame/component.
2) Shape gate (convert-time)
   - UUI JSON schema validation (types, required fields, ranges).
3) DB gate (persist-time)
   - Supabase table/column presence, unique constraints satisfied.
4) Round-trip gate (quality)
   - Convert Figma→UUI→Figma (synthetic) or Cogo→UUI→Figma and compare:
     - position/size tolerance ≤ 2px; component count match; role frames present.

### G. Reverse Flow (Cogo → UUI → Figma)
- LLM produces Cogo UI JSON with full semantics (page list, components, roles).
- Deterministic renderer converts to UUI JSON.
- Figma generator creates frames/nodes with plugin metadata set from JSON semantics.
- Human-in-the-loop (optional) confirms layout fixes; re-export preserves metadata.

### H. MCP Integration Points
- Generation prompts (LLM) must explicitly instruct semantic tagging (names, roles, indices).
- Figma MCP plugin:
  - Lint command to validate tokens/plugin data; fix suggestions.
  - Export command → UUI JSON (with explicit mapping); import command ← UUI JSON.
  - RT channel to report lint/errors to orchestrator.

### I. Testing & Tooling
- Schema verifier: `npm run -s verify:cogo-ui:schema` (DB tables/columns)
- (Planned) UUI JSON Schema: `docs/schemas/uui.json`
- (Planned) Validator CLI: `npm run -s validate:cogo-ui:json FILE=...`
- (Planned) Import dry-run: `npm run -s import:cogo-ui:dry FILE=... PROJECT_ID=...`
- Golden tests: sample designs → expected JSONs and round-trip checks.

### J. Acceptance Criteria
- Conversions pass: semantics gate, shape gate, DB gate, round-trip gate.
- No untagged pages/frames/components in export.
- Errors surfaced via RT/Metrics with `trace_id`.

### K. Rollout Plan
1) Adopt layer naming + plugin metadata conventions.
2) Add MCP lint/export commands.
3) Implement converter and validators.
4) Enable round-trip tests in CI.
5) Document and enforce via release checklist.
