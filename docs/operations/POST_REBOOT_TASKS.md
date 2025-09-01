# Post-Reboot Tasks

This document lists the immediate tasks to perform after a local reboot to continue development.

## 1) Distributed Docker Build & Deploy Test

Goal: Validate distributed agents (orchestrator/indexing/research/executor) build and run via Docker, without blocking the dev terminal.

### Prereqs
- Docker Desktop running
- `.env` (or shell exports) includes:
  - `SUPABASE_EDGE`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`

### Build
```bash
# Build images (tag with date suffix)
DATE=$(date +%Y%m%d)
APP=cogo-agent-core
DOCKER_BUILDKIT=1 docker build -t $APP/orchestrator:$DATE -f Dockerfile.orchestrator .
DOCKER_BUILDKIT=1 docker build -t $APP/indexing:$DATE -f Dockerfile.indexing .
DOCKER_BUILDKIT=1 docker build -t $APP/research:$DATE -f Dockerfile.research .
DOCKER_BUILDKIT=1 docker build -t $APP/executor:$DATE -f Dockerfile.executor .
```

### Local Deploy (Compose)
```bash
# Prefer using a dedicated compose file to avoid port conflicts (3001:3000 rule)
export SUPABASE_EDGE SUPABASE_URL SUPABASE_ANON_KEY SUPABASE_SERVICE_ROLE_KEY
export DATE=$(date +%Y%m%d)
cat > docker-compose.pipeline.yml <<'YML'
version: "3.9"
services:
  orchestrator:
    image: cogo-agent-core/orchestrator:${DATE}
    environment:
      - SUPABASE_URL
      - SUPABASE_ANON_KEY
      - SUPABASE_EDGE
    ports:
      - "6001:3000"
  indexing:
    image: cogo-agent-core/indexing:${DATE}
    environment:
      - SUPABASE_URL
      - SUPABASE_ANON_KEY
      - SUPABASE_EDGE
    ports:
      - "6002:3000"
  research:
    image: cogo-agent-core/research:${DATE}
    environment:
      - SUPABASE_URL
      - SUPABASE_ANON_KEY
      - SUPABASE_EDGE
    ports:
      - "6003:3000"
  executor:
    image: cogo-agent-core/executor:${DATE}
    environment:
      - SUPABASE_URL
      - SUPABASE_ANON_KEY
      - SUPABASE_EDGE
    ports:
      - "6005:3000"
YML

# Bring up
docker compose -f docker-compose.pipeline.yml up -d

# Health checks
curl -s localhost:6001/health | jq -c .
curl -s localhost:6002/health | jq -c .
curl -s localhost:6003/health | jq -c .
curl -s localhost:6005/health | jq -c .

# Bring down (after validation)
docker compose -f docker-compose.pipeline.yml down -v
```

### Alternative: Use prepared compose bundle and scripts
```bash
# Non-blocking local pipeline (build → up → health → down)
npm run pipeline:local

# Only run gates (expects services reachable or EDGE endpoints configured)
npm run gates:run

# Manual compose with repo bundle
docker compose -f infra/compose/docker-compose.pipeline.yml up -d
bash scripts/health-curl-checks.sh
docker compose -f infra/compose/docker-compose.pipeline.yml down -v
```

Notes:
- Do not use `rsync --delete` for deployment to $HOME. Use archive-based rollout with release dirs and symlink switch.
- Secrets are never committed; use `.env` or secret managers.

## 2) Repo Restructure for Cogo Platform Integration

Goal: Align `cogo-agent-core` directory layout with the broader cogo platform so that services, images, and CI can be shared with minimal friction.

### Proposed Target Layout
```
/ (repo root)
  /apps
    /agent-core           # this repo (renamed/moved)
      /src
      /supabase/functions
      /docs
      /scripts
      /Dockerfile.*
    /orchestrator-ui      # placeholder for UI app (if applicable)
  /packages
    /shared-config        # eslint/prettier/tsconfig/shared
    /shared-types         # shared zod/types
    /edge-clients         # Edge client SDKs (llm/rag/agent)
  /infra
    /compose              # docker-compose files (dev/prod variants)
    /k8s                  # Kubernetes manifests (optional)
  /docs
    /runbook              # consolidated runbooks
  /.github
    /workflows            # unified CI (build/test/gates, image publish)
```

### Migration Plan
- Phase 1 (non-breaking, same repo):
  - Introduce `/apps/agent-core` folder and move current content there (paths updated in scripts).
  - Create `/packages/edge-clients` by extracting `src/services/edge/*` and publish as internal package.
  - Centralize `Dockerfile.*` under `/apps/agent-core` and adjust compose.
- Phase 2 (platform alignment):
  - Add `/infra/compose` with standard compose bundles (dev, gates, prod-sim).
  - Migrate CI to a single workflow that builds images for orchestrator/indexing/research/executor and runs gates.
- Phase 3 (optional):
  - Extract shared config/types to `/packages/*` and refactor imports.

### Action Items Checklist
- Create `apps/agent-core` and relocate code with path updates.
- Extract `edge-clients` package and refactor imports.
- Update NPM scripts and CI to new paths.
- Add compose bundles under `/infra/compose`.
- Validate build and gates end-to-end.

### Risks & Mitigations
- Path breakages after move → run `npm run lint` and `npm run build` early; use incremental PRs.
- Docker context mistakes after move → ensure correct context and COPY paths in Dockerfiles.
- CI cache invalidation → pin caching keys to `package-lock.json` and Dockerfile hashes.
