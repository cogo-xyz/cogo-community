# CI Smoke (Central Key-Vault) Setup

This repository includes two smoke workflows:

- .github/workflows/smoke.yml
  - Offline smokes (RAG JSON strict + typecheck optional)
- .github/workflows/smoke-central.yml
  - Central Key-Vault mode (requires GitHub Secrets)
  - Runs:
    - RAG JSON strict with central key-vault
    - Orchestrator decide E2E (if service role key provided)

## Required GitHub Secrets

Set these repository-level secrets:

- SUPABASE_URL: e.g., https://cjvgmyotqxfpxpvmwxfv.supabase.co
- KEY_VAULT_URL: e.g., https://cjvgmyotqxfpxpvmwxfv.supabase.co/functions/v1/key-vault
- SUPABASE_ANON_KEY: project anon JWT
- SUPABASE_PUBLISHABLE_KEY: publishable key
- SUPABASE_SERVICE_ROLE_KEY: service role key (optional; enables orchestrator decide E2E)

## What the workflows do

- RAG JSON strict (central)
  - Initializes AI clients via key-vault/env
  - Validates JSON-only output against the contract (intent, answer, citations[], confidence)
  - Uploads rag-smoke.central.json as artifact

- Orchestrator decide E2E (central)
  - Enqueues orchestrator.decide job and runs a bounded orchestrator tick
  - Fetches latest decision event and saves orchestrator-e2e.out as artifact

## Notes

- Do not store secrets in workflows or code. Use GitHub Secrets only.
- Service role key is only needed for the orchestrator E2E job flow.
- Keep ANON/PUBLISHABLE for Edge Function/Key-Vault usage as per security policy.


