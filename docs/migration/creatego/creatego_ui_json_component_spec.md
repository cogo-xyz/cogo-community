### CreateGo UI JSON Component Spec (Reference Snapshot)

- Source (canonical): [component-doc.md](https://github.com/creatego-io/creatego-ide/blob/main/Documents/component-doc.md)
- Purpose: Keep a stable reference to the currently defined CreateGo (cogo) UI JSON component specification for migration and compatibility.

#### Notes for COGO Migration
- Treat this document as the ground truth for legacy CreateGo UI JSON semantics during migration.
- Align mappings into COGO UUIS three layers: SingleWidget, Component, Page.
- Preserve event semantics and action naming; translate to UUIS action vocabulary where applicable (NAVIGATE, UPDATE_STATE, DISPATCH_EVENT, VALIDATE, CONDITION, FOCUS_ELEMENT).
- All visual values must be expressed as design token references (W3C DTCG) in UUIS; avoid literal values.

#### Compatibility Checklist (to be maintained)
- Type mapping: CreateGo `type` → UUIS `type` (e.g., button/text/input/image/container/stack)
- Props mapping: component-specific properties → UUIS `props` with token aliasing
- Events mapping: CreateGo event handlers → UUIS `events` with standardized actions
- Layout mapping: Auto Layout/Flex attributes → UUIS container props
- Schema deltas: Any additional/legacy fields preserved under `$legacy` namespace if needed

#### Migration Tasks (incremental)
- Extract concrete examples from the source doc and add golden test fixtures under `tests/ui/fixtures/`.
- Extend `configs/figma_rules/*.json` using the spec’s component definitions.
- Add renderer guidance notes for React/Flutter where implementation-specific props exist.
- Maintain a living mapping table: `docs/migration/creatego/ui_mapping_table.md` (CreateGo → UUIS)

This is a living reference file; for authoritative updates, always consult the source link above and record meaningful deltas here.


