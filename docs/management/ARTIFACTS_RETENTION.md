## Artifacts Retention Policy

Purpose: Define retention and cleanup policy for local artifacts and Supabase Storage.

### Local Workspace (`artifacts-local/`)
- Intended for developer test outputs and JUnit reports
- Cleanup script: `scripts/ops/artifacts-clean.sh`
  - Environment: `RETENTION_DAYS` (default 7)
  - Deletes files older than N days

### Supabase Storage (`artifacts` bucket)
- Prefer bucket lifecycle rules for deletion (e.g., delete objects older than 30d)
- Signed URL TTL via `ARTIFACTS_SIGN_TTL_SEC` (default 600s) in functions

### Automation (CI / Scheduled)
- GitHub Actions (example) runs weekly to clean local artifacts:
```
name: artifacts-clean
on:
  schedule:
    - cron: '0 3 * * 0'
  workflow_dispatch: {}
jobs:
  clean:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Clean local artifacts
        run: RETENTION_DAYS=7 bash scripts/ops/artifacts-clean.sh
```

### Notes
- Do not delete active build artifacts referenced by open traces
- Keep JUnit XML for recent runs (e.g., last 7–14 days)


