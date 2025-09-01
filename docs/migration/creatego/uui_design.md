### UUI Design & Development Plan

Objectives
- Separate presentation(Design) from behavior(Action) while preserving CreateGo compatibility
- Page/fragment streaming, subtree hashing for incremental parsing/rendering
- Multi-platform bindings (Flutter, React+Tailwind, Kotlin, Swift) via a single UUI schema

Key Concepts
- Document: version, features, themeRef, assets, routes, index(pages, fragments)
- Page/Fragment: id, kind, contentHash, deps, root(UiNode), behaviors, bindings, platform overrides, $legacy
- UiNode: type/props/style/layout/slots/children, events(Action refs), bindings
- Actions: typed union(UPDATE_STATE, DISPATCH_EVENT, NAVIGATE, VALIDATE, CALL_REMOTE, RUN_WORKFLOW, SEQ/BRANCH/PARALLEL)

Streaming & Incremental
- Fragments transport: pageChunk/pagePatch with contentHash/parentHash
- Client assembles fragments, validates incrementally, and re-renders only changed subtrees

Compatibility
- CreateGo JSON → UUI adapter with $legacy preservation
- Optional reverse adapter for legacy consumers

Pipeline
- Normalize → Rules → Layout → Event → Token → Bindings → PlatformOverride → SubtreeHash → SchemaGuard

CI & Metrics
- Golden tests for pages/fragments/patches, Ajv validation gate, hash reuse rate metrics


