## Distributed Agents: Functions, Contracts, Events, Smokes, Acceptance

This document summarizes per-agent responsibilities, bus contracts, audit events, smoke tests, and acceptance criteria.

### Orchestrator (cogo-orchestrator-decide)
- Responsibilities: Plan route, enqueue execution spec, propagate `trace_id`
- Subscribe: `orchestrator/decide/0`
- Publish: `orchestrator/execute/0` (via planner/executor)
- Events: `orchestrate_decision`, `orchestrate_enqueued`, `orchestrate_failed`
- Smokes: `npm run -s smoke:workflows:e2e` (includes plan→enqueue), `npm run -s smoke:dispatcher:e2e`
- Acceptance: Decision events recorded with `trace_id`; dispatcher E2E PASS; p90 wait within target

### Executor Dispatcher (cogo-executor-dispatcher)
- Responsibilities: Validate `__assignment`, enforce TTL, backoff/retry, route to target
- Subscribe: `orchestrator/execute/0`
- Publish: Target route from payload `(service, role, shard)`
- Events: `execute_enqueued`, `execute_retry`, `execute_failed`, `execute_done`
- Smokes: `npm run -s smoke:dispatcher:e2e`, `npx ts-node src/scripts/ci/smokeDispatcherTTL.ts`
- Acceptance: < 5% failure in recent window; TTL failures recorded; backoff working

### Gateway Chat (cogo-gateway-chat)
- Responsibilities: Intake chat, optional RAG, update result; TTL, `trace_id` propagation
- Subscribe: `gateway/chat/0`
- Events: `gateway_done`, `gateway_failed`
- Smokes: Included in `runLocalSmokes.ts` (Edge→Orch→Gateway); metrics: `/api/metrics/gateway/events`
- Acceptance: Edge→Gateway E2E PASS; gateway events visible via metrics

### Codegen Worker (cogo-codegen-service)
- Responsibilities: Generate edits; REST to `cogo-worker` when `ENABLE_COGO_WORKER=true`, else mock write
- Subscribe: `codegen/generate/0`
- Events: `codegen_done`, `codegen_retry`, `codegen_failed`
- Smokes: `npm run -s smoke:workflows:e2e`, `npx ts-node src/scripts/ci/smokeCodegenRetry.ts`
- Acceptance: Artifacts path recorded; retries on worker errors; TTL enforced

### Build/Test Worker (cogo-build-test-worker)
- Responsibilities: Build/Test; REST to `cogo-worker` when enabled, else mock report
- Subscribe: `code/build-test/0`
- Events: `buildtest_done`, `buildtest_retry`, `buildtest_failed`
- Smokes: `npm run -s smoke:workflows:e2e`, `npx ts-node src/scripts/ci/smokeBuildTestRetry.ts`
- Acceptance: Gateable decision available; report saved; retries on worker errors

### Sandbox (Python WS + Realtime bridge) and Node Sandbox Worker
- Responsibilities: Execute sandbox tasks, write artifacts
- Subscribe: `sandbox/run/0`
- Events: `sandbox_done`, `sandbox_failed`, `sandbox_retry`
- Smokes: `npx ts-node src/scripts/ci/smokeSandbox.ts`
- Acceptance: Sandbox outputs saved under artifacts; TTL/retry enforced

### Pipeline and Gates
- Endpoints: `/api/pipeline/codeBuildTest` (`?enforce=true`), `/api/workflows/gate`
- Metrics: `/api/metrics/trace/{traceId}`, `/api/metrics/workflows/codeBuildTest`, `/api/metrics/bus/events`, `/api/metrics/gateway/events`
- Acceptance: Enforce path returns 200 on commit, 422 on policy fail; events correlate by `trace_id`


