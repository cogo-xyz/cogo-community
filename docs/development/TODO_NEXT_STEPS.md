## TODO – Next Steps (Post E2E Success)

### Security / RLS Hardening
- Replace DEV-open policies with role-scoped RLS for `jobs`, `artifacts`, `worker_devices`, `worker_heartbeats`.
- Introduce JWT claims/roles for workers vs. clients.
- Remove forced-success paths from production builds.

### CI/CD
- Add steps: schema check → storage bucket create → start workers → run integration tests → cleanup.
- Mask and scope secrets; avoid logging service keys.
- Add gated DB-mode integration workflow (fixed). Use step-level gate for secrets.

### Worker Resilience
- Browser: retry/backoff for navigation, configurable viewport, conditional headful mode.
- Figma: rate-limit handling, richer export options (scale, format), batch artifact recording.
- Python: structured heartbeats and capability advertisement via `worker_devices`.

### Observability
- Extend Prometheus metrics for per-task outcomes and storage latencies.
- Add dashboards (Grafana) and alerts for realtime disconnects and DB backlogs.
- Add worker heartbeat explorer (`list:heartbeats`) and DLQ explorer (`list:dlq`).

### Documentation
- Keep `REALTIME_CHANNELS_AND_USAGE.md` synced with latest payloads.
- Add troubleshooting guide for CHANNEL_ERROR and Storage/RLS issues.


### GitHub Repository Dispatch Integration (Pending)
- PAT model decision: prefer Classic PAT for simplicity
  - Scopes: `repo`, `workflow`
- Ensure repository access for token owner:
  - If org repo (`cogo-xyz/cogo-agent-core`): add token owner as Admin or via Team with Admin role
  - If user repo (`JamesLee77/cogo-agent-core`): transfer to org or add `cogo-0` as Collaborator (Admin)
- Fine-grained alternative:
  - Repository access: select `cogo-xyz/cogo-agent-core`
  - Permissions: Actions=Read&Write, Contents=Read&Write
- Verification checklist:
  - `curl -H "Authorization: Bearer <PAT>" https://api.github.com/repos/<OWNER>/<REPO> -i` → 200
  - Worker env: `WEBHOOK_TYPE=github GITHUB_OWNER=<OWNER> GITHUB_REPO=<REPO> GITHUB_TOKEN=<PAT>`
  - Enqueue job → Actions “Job Status Dispatch” appears → Issue `[Job Status] <jobId>` updated/closed
- Temporary fallback:
  - Use `WEBHOOK_TYPE=http` + `WEBHOOK_URL` to validate end-to-end without GitHub

### GitHub Actions Fix (Pending)
- Problem: Using `secrets.*` in job-level `if:` causes "Unrecognized named-value: 'secrets'".
- Resolution: Gate at step-level with env-injected secrets, not job-level `if:`.
- Suggested pattern:
  ```yaml
  jobs:
    test-db-worker:
      runs-on: ubuntu-latest
      env:
        SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
        SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
        SUPABASE_SERVICE_ROLE_KEY: ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}
      steps:
        - uses: actions/checkout@v4
        - id: gate
          name: Check secrets
          run: |
            missing=""
            [ -z "${SUPABASE_URL}" ] && missing="1"
            [ -z "${SUPABASE_ANON_KEY}" ] && missing="1"
            [ -z "${SUPABASE_SERVICE_ROLE_KEY}" ] && missing="1"
            if [ -n "$missing" ]; then echo "run=false" >> $GITHUB_OUTPUT; else echo "run=true" >> $GITHUB_OUTPUT; fi
        - name: Skip note
          if: steps.gate.outputs.run == 'false'
          run: echo "Secrets not set; skipping DB Mode Integration"
        - name: Actual test steps
          if: steps.gate.outputs.run == 'true'
          run: echo "run tests ..."
  ```


