## Nightly Metrics Flow (Orchestrator)

- Run
  - Local
    - `npm run -s ops:nightly`
  - With custom host/port
    - `HOST=http://localhost:3100 METRICS_PORT=3100 npm run -s ops:nightly`

- Behavior
  - Auto-start metrics server if METRICS_AUTOSTART=1
  - Waits for readiness, retries, falls back to snapshot, and allows skip
  - Outputs summary json: `artifacts/nightly/flow-summary.json`

- Notes
  - Edge functions are not used for long-running statistics.
  - For network-dependent compat checks, keep them outside nightly.


