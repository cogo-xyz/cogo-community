## Distributed Agents Deployment Status (Dev)

- Date: <fill when running>
- Cluster: MicroK8s (remote dev)

### Services Health
- cogo-orchestrator-svc:3100/health → 200
- cogo-indexing-svc:3100/health → 200
- cogo-research-svc:3100/health → 200
- cogo-executor-svc:3100/health → 200

### Supabase Egress
- GET /auth/v1/health → 401 (expected, confirms external connectivity)

### Fixed Agent IDs (from deployments)
- orchestrator: AGENT_ID=cogo-orchestrator-01
- indexing: AGENT_ID=cogo-indexer-01
- research: AGENT_ID=cogo-research-01
- executor: AGENT_ID=cogo-executor-01

### Recent Logs (tail) Snapshot
- All four deployments show heartbeat-only lines, no errors observed.

### Notes
- Ports unified to 3100 across all agent services.
- Secrets provided via `cogo-secrets` (not included in this document).

### Next Suggested Checks
- Optional: Trigger a minimal internal flow (enqueue test event) and verify processing.
- Optional: Expose ingress if external access is required (currently ClusterIP).


