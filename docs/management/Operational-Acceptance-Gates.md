## Operational Acceptance Gates (OAG)

Purpose: Continuously validate system health in production via automated gates using metrics APIs. Failures trigger alerts and optional protective actions.

### Metrics and Thresholds
- Window: sliding 60 minutes (`WINDOW_MIN=60`)
- Thresholds (prod):
  - `FAIL_RATE_MAX=0.05` (<= 5%)
  - `WAIT_P90_MAX_MS=5000` (<= 5s)
  - `DECISION_QUALITY_MIN=85` (>= 85%)
- Scope: Core bus routes only
  - `orchestrator/execute`, `codegen/generate`, `code/build-test`, `gateway/chat`

### Execution
- Entrypoint: `src/scripts/ci/enforceAcceptanceGates.ts`
- Env (examples):
  - `PORT=3000`
  - `WINDOW_MIN=60`
  - `FAIL_RATE_MAX=0.05`
  - `WAIT_P90_MAX_MS=5000`
  - `DECISION_QUALITY_MIN=85`
- Exit: Non-zero on violation → suitable for Cron/Jobs and alerting

### Scheduling
- Recommended: every 5 minutes
- Environments:
  - Production: enforce + alert
  - Staging: enforce + alert (no auto-action)
  - Development: relaxed thresholds for fast feedback

### Alerting and Recording
- On failure: post `gate_violation` to `public.bus_events` with `payload` including failing checks and thresholds
- Notify: Slack/Email/Alertmanager (out of scope here)

### API Endpoints Used
- `/api/metrics/bus/latency?service=...&role=...&since_min=...`
- `/api/metrics/orchestrator/decision-quality?since_min=...`

### Example: K8s CronJob (reference)
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cogo-acceptance-gates
spec:
  schedule: "*/5 * * * *"
  jobTemplate:
    spec:
      backoffLimit: 0
      template:
        spec:
          restartPolicy: Never
          containers:
            - name: gates
              image: ghcr.io/<org>/cogo-agent-core:<tag>
              env:
                - name: PORT
                  value: "3000"
                - name: WINDOW_MIN
                  value: "60"
                - name: FAIL_RATE_MAX
                  value: "0.05"
                - name: WAIT_P90_MAX_MS
                  value: "5000"
                - name: DECISION_QUALITY_MIN
                  value: "85"
              command: ["node", "dist/scripts/ci/enforceAcceptanceGates.js"]
```

### Example: Local Run
```bash
PORT=3001 WINDOW_MIN=60 FAIL_RATE_MAX=0.05 WAIT_P90_MAX_MS=5000 DECISION_QUALITY_MIN=85 \
  npx ts-node src/scripts/ci/enforceAcceptanceGates.ts
```


