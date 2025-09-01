## cogo-agent-core Repository Reorg Plan

Date: 2025-08-25

### Goals
- Prepare for CreateGo → COGO migration phases
- Separate OSS consumables (SDK/clients/docs) from core/private modules
- Clarify boundaries: edge functions, agents, projection worker, plugin assets

### Phases
- Phase A (now): Introduce new top-level layout (non-breaking), add READMEs
- Phase B: Move code into new layout; update build/compose scripts
- Phase C: Extract public client/docs to `cogo-community` repo

### Target Layout (proposed)
- apps/
  - orchestrator/
  - research/
  - indexing/
  - executor/
  - metrics/
  - projection-worker/
- edge/
  - chat/
  - chat-gateway/
  - embed/
  - figma-compat/
  - figma-plugin/
- packages/
  - shared-types/
  - ui-ast/
  - sdk-node/
- docs/
  - (existing, plus architecture/migration)
- supabase/
  - functions/ (symlink or move from edge/* if required)
  - sql/
  - migrations/
- tools/
  - figma-plugin/
  - scripts/
- infra/
  - compose/
  - k8s/

### Non-Goals (this phase)
- No runtime config changes
- No renaming of published artifacts yet

### Boundaries & Sync
- src/: cogo agent domain code only (domain logic, shared utils, adapters)
- apps/: process entry-points referencing src/
- edge/: source-of-truth for Edge Functions
- supabase/functions: deployment mirror (sync from edge/ before deploy)
- supabase/sql & supabase/migrations: canonical DB assets (DDL/RPC/indexes)
- Add script: `npm run edge:sync` to copy edge/* → supabase/functions/* prior to `supabase functions deploy`

### Next
- Create skeleton directories and READMEs
- Update migration hub with links
