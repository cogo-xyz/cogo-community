## Next Steps (Post-UUI Gate Stabilization)

Priority-ordered tasks to continue development efficiently.

### 1) MCP (Later; requires Docker)
- Preconditions: Docker daemon + FIGMA_API_KEY ready
- Actions: `npm run mcp:stack:up` → `npm run mcp:ping` → add to gate (`mcp:ping` optional step)
- Output: MCP metrics in `/api/metrics/summary.mcp`, artifacts under `artifacts/mcp/*`

### 2) UI BDD + ActionFlow (Local Only)
- Implement richer `UiBddGenerator.generate` (map UI events/state → Gherkin-like BDD)
- Implement `UiActionSynthesizer.synthesize` (BDD → ActionFlow JSON) with validation
- Add smoke scripts:
  - `src/scripts/ui/enqueueUiBdd.ts`, `enqueueUiAction.ts` (already present)
  - Local smoke: `npx ts-node src/scripts/ui/convertLocal.ts` → feed into BDD/ActionFlow

### 3) CI: Strict Verify Lane
- Add verify-only lane that fails on mismatch without updating goldens
- Gate: ensure `ci:uui:gate` runs before verify lane

### 4) Docs polish
- Expand `docs/COGO_AGENT_OVERVIEW.md` with RAG/KG/Autonomy sections cross-linking UUI
- Finalize UUI Streaming/Cache doc with examples (from DEVELOPMENT.md)

### 5) Indexing integration
- `src/indexing/ui/UUISAstIndexer.ts` – finalize and add e2e against UUI goldens

### Commands
```bash
# Gate + CI
HOST=http://localhost:3007 ENFORCE=true START_IF_DOWN=1 LAYOUT_ONLY=true UPDATE_GOLDEN=1 npm run -s ci:uui:gate
HOST=http://localhost:3007 npm run -s ci:ui:full

# BDD/ActionFlow smoke (example)
npx ts-node src/scripts/ui/convertLocal.ts | tee /tmp/uui.json
node -e 'const s=require("./dist/services/ui/UiBddGenerator.js");'
```


