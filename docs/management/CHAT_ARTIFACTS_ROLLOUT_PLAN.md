### Rollout Plan: Chatting Artifacts Standard

Scope
- Edge functions: design-generate, figma-context, figma-compat
- Docs & tests: overview/test-guide/security/ADR

Phases
1) Prepare (D0)
  - Add common rules in docs, add tests to verify `trace_id`/`artifacts`
2) Implement (D0~D1)
  - Ensure responses include `artifacts` with links + previews where applicable
3) Canary (D1)
  - Enable on a project tenant; monitor errors/latency
4) GA (D2)
  - Rollout to all tenants; keep compatibility for clients ignoring `artifacts`

Guardrails
- Signed URLs TTL short; MIME allowlist; size limit
- Fallback behavior when Storage unavailable: inline minimal previews only

Success Metrics
- SSE completion rate, artifact upload success rate, retrieval success, latency p95


