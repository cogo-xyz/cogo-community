## Domain Separation Policy: public vs cogo

Date: 2025-08-25

### Principles
- public: user-owned application data, RLS enforced, session auth only
- cogo: agent/platform internals, service-role only, no user writes

### Rules
- Agents do not write to public.* (except projection worker)
- IDE/Starter do not write to cogo.*
- Changes from agents flow via `cogo.project_updates` → projection → public.*

### Security
- Store secrets in env/manager; never in code
- Enforce short-lived JWT in prod; allow relaxed dev mode

### Observability
- All events tagged with trace_id
- Metrics on throughput, retries, DLQ size
