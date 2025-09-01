# CI Secrets and Branch Protection

This guide explains required GitHub Actions secrets and recommended branch protection settings for the Collab/EF verification pipeline.

## Required GitHub Secrets
Add these in: Repository → Settings → Secrets and variables → Actions → New repository secret

- SUPABASE_URL: e.g., https://<project-ref>.supabase.co
- SUPABASE_SERVICE_ROLE_KEY: service role key (server-only)
- SUPABASE_ANON_KEY: anonymous key
- SUPABASE_JWT_SECRET: HS256 secret for local JWT mode (dev)

Notes
- Do not commit these values to the repo.
- The workflow conditionally runs EF checks only when SUPABASE_URL and SUPABASE_ANON_KEY exist.
- Storage sign-artifact step requires SUPABASE_SERVICE_ROLE_KEY.

## Branch Protection (recommended)
Settings → Branches → Add rule → target: main
- Require a pull request before merging: enabled
  - Require approvals: 1+ (recommended 2)
  - Dismiss stale approvals when new commits are pushed: enabled
- Require status checks to pass before merging: enabled
  - Select: Collab API Verify (workflow: collab-verify.yml)
- Require branches to be up to date before merging: enabled
- Do not allow bypassing the above settings: enabled

## CI Overview
The workflow .github/workflows/collab-verify.yml performs:
1) Types generation from OpenAPI
2) Start Collab dev server
3) Collab flow verification (assign/result/summary)
4) Jest smoke/flow tests
5) EF verification (metrics/jobs/workers/dlq)
6) Storage upload and sign-artifact (if secrets present)

## Local Pre-deploy Check
- Run: npm run predeploy
- Expects BASE_URL (default http://localhost:3100). Uses SUPABASE_JWT_SECRET and (optionally) SUPABASE_* keys.
