## Repository Restructure Plan (Cogo Platform Alignment)

### Target Layout
```
/ (repo root)
  /apps
    /agent-core           # this repo (moved)
      /src
      /supabase/functions
      /docs
      /scripts
      /Dockerfile.*
  /packages
    /edge-clients         # extracted from src/services/edge/*
  /infra
    /compose              # docker-compose bundles (dev/gates/prod-sim)
  /docs
    /runbook              # consolidated runbooks
  /.github
    /workflows            # unified CI
```

### Phases
- Phase 1 (non-breaking):
  - Create `apps/agent-core` and move current repo content under it.
  - Extract `packages/edge-clients` from `src/services/edge/*` and refactor imports.
  - Centralize `Dockerfile.*` under `apps/agent-core`.
- Phase 2 (platform alignment):
  - Add `infra/compose` with standard compose bundles (dev, gates, prod-sim).
  - Migrate CI to a single workflow building orchestrator/indexing/research/executor images and running gates.
- Phase 3 (optional):
  - Extract shared config/types to `packages/*` and refactor references.

### Action Checklist
- Create `apps/agent-core` and relocate code with path updates.
- Extract `edge-clients` package and publish internal version.
- Update NPM scripts and any paths in Dockerfiles/compose.
- Add compose bundles under `infra/compose` (done: pipeline bundle exists).
- Run lint/build early; fix path breakages.

### Commands (documentation; do not execute here)
```bash
# 1) Create directories
mkdir -p apps/agent-core packages/edge-clients infra/compose

# 2) Move code (dry-run first with rsync --dry-run; never --delete to $HOME)
rsync -av --exclude '.git' ./ apps/agent-core/

# 3) Extract edge clients
mkdir -p packages/edge-clients/src
rsync -av apps/agent-core/src/services/edge/ packages/edge-clients/src/

# 4) Update imports
# Use tsconfig paths and a codemod to replace "src/services/edge/*" -> "@edge-clients/*"

# 5) Compose bundles
ls infra/compose
```

### Risks & Mitigations
- Path breakages after move → run `npm run lint` and `npm run build` early; incremental edits.
- Docker context mistakes → verify `context` and `COPY` paths in Dockerfiles.
- CI cache invalidation → pin cache keys to lockfiles and Dockerfile hashes.

### Policy Notes
- Safe deployment: archive-based rollout, no `rsync --delete` against `$HOME`.
- Secrets handling: never commit/paste keys; use `.env`/secret manager only.


