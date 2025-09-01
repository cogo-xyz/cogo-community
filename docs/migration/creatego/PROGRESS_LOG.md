### CreateGo-Agent → COGO Migration Progress Log

This document records all items implemented for the CreateGo → COGO migration, with clear status and cleanup guidance. Items marked as legacy or misaligned with the finalized Figma→UUIS pipeline are moved to backups for safe removal later.

#### Scope of Work Completed
- Planning & Docs
  - `docs/COGO_MIGRATION_CREATEGO.md` (top-level plan)
  - `docs/migration/creatego/overview.md` (strategy overview)
  - `docs/migration/creatego/migration_plan.md` (step-by-step plan)
  - `docs/migration/creatego/supabase_schema_inventory.md` + `supabase_inventory.json`
  - `docs/migration/creatego/neo4j_model_mapping.md` + `neo4j_inventory.json`
  - `docs/migration/creatego/realtime_protocol_catalog.md` + `realtime_inventory.json`
  - `docs/migration/creatego/figma_to_cogo_ui_architecture.md` (Figma→UUIS design)

- UI Conversion Pipeline (COGO-native)
  - Services: `src/services/ui/FigmaToUiConverter.ts`, `UiBddGenerator.ts`, `UiActionSynthesizer.ts`, `UiTypes.ts`
  - Workers: `src/workers/UiConversionWorker.ts`, `UiBddWorker.ts`, `UiActionWorker.ts`
  - API: `src/routes/uiRoutes.ts` (POST /api/ui/*)
  - Scripts: `src/scripts/ui/enqueueUiConversion.ts`, `enqueueUiBdd.ts`, `enqueueUiAction.ts`
  - Metrics: `src/services/metrics/Metrics.ts` (UI metrics)
  - Minimal server mount: `src/servers/minimal/index.ts`

- Migration Inventory & Generators
  - Scripts: `src/scripts/migration/inventorySupabase.ts`, `inventoryNeo4j.ts`, `inventoryRealtime.ts`
  - Doc augmenter: `src/scripts/migration/augmentDocsFromInventory.ts`
  - Draft generators: `src/scripts/migration/generateSupabaseCompatSql.ts`, `generateNeo4jCompatCypher.ts`
  - Neo4j HTTP client: `src/services/graph/Neo4jHttpClient.ts`

- Configs
  - `configs/route_policies.json` (UI routes allowlist)
  - `configs/mcp.json` (MCP endpoints)
  - `configs/retry_policy.json`, `configs/circuit_breaker.json`, `configs/sandbox_limits.json`

#### Legacy Bridge (for CreateGo Realtime) – Status
- Files (moved to backups):
  - `src/workers/CreateGoBridgeWorker.ts`
  - `src/services/legacy/creatego/ProtocolAdapter.ts`
  - `configs/creatego_realtime.json`
- Rationale: Current architecture prioritizes MCP-based Figma intake and the COGO-native UI pipeline. The CreateGo realtime bridge is optional and not required for the MCP-first flow; kept for reference under backups and can be restored if needed.

#### Remaining Work (High-level)
- Implement Figma AST normalization and rule engine modules (`FigmaAstNormalizer`, `UiRulesEngine`, `UiLayoutMapper`, `UiEventMapper`, `UiTokensResolver`, `UiValidator`)
- Add UUIS Ajv schema (`configs/uuis.schema.json`) and validity tests
- Integrate Style Dictionary pipeline for DTCG token builds (web/react/flutter outputs)
- RAG integration (pgvector/Neo4j) for ambiguous mappings and learning loop
- Expand ActionFlow→Neo4j mapping and constraints; OpenAPI for UI routes

#### Cleanup Guidance
- The above legacy bridge files reside in `backups/<timestamp>/...`.
- If MCP-first flow is stable across scenarios and CreateGo realtime is no longer needed, these can be deleted from backups.
- Any re-introduction should respect COGO standards (trace/idempotency/retry/circuit/metrics/artifacts).

Last updated: 2025-08-17


