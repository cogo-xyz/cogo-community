## Recommended Release & Publish Flow

End-to-end flow to safely release from `cogo-agent-core` and publish public artifacts to `cogo-community`.

### 1) Develop & Test in cogo-agent-core
- Implement features (Edge/Workers/SDK contracts) and update docs.
- Run unified gates:
```bash
npm run gate:unified
```

### 2) Deploy Supabase (gated)
```bash
bash scripts/deploy-supabase.sh
# ENV: RUN_GATES=1 DEPLOY_SQL=1 DEPLOY_EDGE=1 EDGE_LIST="chat orchestrator-chat"
```

### 3) Tag Release
- Create a git tag or use semantic-release to tag and generate release notes.

### 4) Publish to cogo-community (public-safe)
```bash
export COGO_COMMUNITY_DIR=/Users/<you>/Desktop/Dev/cogo-project/cogo-community
bash scripts/publish-community.sh
```

### 5) Verify Public Consumers
- In `cogo-client`, update submodule or dependency pins to the new tag/commit.
- Run client-side smoke tests (TS/Flutter examples).

### 6) Rollback (if needed)
- Revert to previous tag (Edge functions and SQL are idempotent; ensure flags/feature toggles are ready).

### Notes
- Secrets and Edge configs are managed only in `cogo-agent-core`.
- Public artifacts never include secrets or internal scripts.


