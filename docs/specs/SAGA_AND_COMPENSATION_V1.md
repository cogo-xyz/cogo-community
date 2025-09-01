## Idempotency, Retry/Backoff, DLQ Stages, and Compensation v1

Goals
- Prevent duplicate side effects, provide bounded retries with jitter, classify failures into DLQ stages, and define compensating actions for multi-step workflows.

Idempotency
- Keys: idempotency_key per job, and per step for multi-action workflows.
- Storage: persist key + last_result hash + expiry; repeated requests with the same key must be no-ops.
- Scope: API ingress, scheduler, worker RPCs, and external side-effect calls.

Retry/Backoff
- Exponential backoff with jitter: next_delay = min(max_delay, base^(attempt) * random(0.5, 1.5)).
- Classify retryable vs non-retryable via error taxonomy; default retryable: network, 429/5xx, transient timeouts.
- Cap attempts per step; log attempt, delay, and reason.

DLQ Stages (Standard Codes)
- parse_error
- validation_failed
- dependency_unavailable
- timeout
- exhausted_retries
- policy_violation
- infrastructure_failure
- compensation_failed

Compensation Patterns
- Undo/compensate per step with clear side-effect maps.
- Saga log: { step, action, status, attempt, ts, correlation_id, payload_hash }.
- Roll-forward vs roll-back decision: prefer roll-forward if state is externally visible and consistent.

Workflow Template
1) validate(input) → idempotency check (job key)
2) step A (with idempotency key) → success?
   - no → classify error → retry/backoff or DLQ
3) step B (with idempotency key)
4) commit
5) on failure after A: run compensate(A)
6) on failure after B: run compensate(B), then compensate(A) if needed

Observability
- Metrics: attempts, retry_delays, retry_success_rate, compensation_invocations, compensation_success_rate, DLQ_by_stage.
- Tracing: propagate correlation_id from job → steps → compensation.

Acceptance Criteria
- Duplicate submissions with same idempotency_key result in a single side effect.
- Retries respect jittered backoff and max attempts; DLQ classifications are populated.
- Compensation functions are invoked under failure paths and report success/failure.

## Idempotency, Saga, and Compensation – v1

Goals
- Prevent duplicate effects across jobs/events/workflows.
- Ensure failure handling via retries, backoff, and compensation.

Idempotency Keys
- jobs: `idem_job:<tenant>:<type_prefix>:<job_id>`
- events: `idem_evt:<tenant>:<stream>:<event_id>`
- workflows: `idem_flow:<tenant>:<flow_id>:<step>`

Patterns
- Try/Confirm/Cancel (TCC) for external side‑effects.
- Outbox pattern for atomic publish (DB transaction → outbox → publisher).

Retry/Backoff
- Exponential with jitter; classify errors as retryable vs non‑retryable.
- Max attempts configurable per job type; record attempts and last_error.

DLQ (Staged)
- Stages: input → fetch → exec → output → commit.
- Record: `stage`, `reason`, `attempts`, `trace_id`, `correlation_id`, `payload_hash`.

Compensation
- For each step with side‑effects, define compensating action.
- Compensation is idempotent and safe to re‑run.

Observability
- Emit counters for retries, backoffs, DLQ writes; histograms for stage latency.
- Tracing spans: claim → execute → publish; propagate `trace_id`/`correlation_id`.

Security / Tenancy
- JWT scoped to job type/tenant; RLS enforces tenant isolation.
- Service role usage minimized; prefer fine‑grained policies.

