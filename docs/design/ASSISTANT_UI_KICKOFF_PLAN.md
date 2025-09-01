
# Assistant UI Kickoff Plan (COGO)

## 1) Overview
- Goal: Build an operations dashboard for the COGO distributed agent system using the existing Realtime + Supabase architecture.
- Stack: Vite + React + TypeScript + Tailwind. Data from Supabase tables and Agent HTTP endpoints.

## 2) Scope (MVP)
- Overview: KPIs (Jobs, Success/Fail, Realtime events), latency p50/p95, basic timeseries.
- Agents: List all agents with /health + /metrics summary, comm stats.
- Jobs: List/filter by status, details panel, status timeline.
- Artifacts: List/filter, signed URL preview (image), download link.
- MCP Monitor: Recent Browser/Figma tasks and artifacts.
- Realtime: Presence summary, live counters (optional).

## 3) Dependencies / Readiness
- Backend readiness:
  - Agents expose `/health` and `/metrics` (Prometheus text) — already present.
  - Supabase tables: `jobs`, `artifacts`, `worker_heartbeats`, `worker_devices` — migrations added.
  - Storage bucket (artifacts) — configured.
- Env readiness:
  - VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY
  - VITE_AGENT_ENDPOINTS (JSON: [{ name, type, baseUrl }])

## 4) API Contract Snapshot
- GET /health → { status, agent, agentId, comm, uptime, timestamp }
- GET /metrics → Prometheus text including:
  - cogo_jobs_queued_total, cogo_jobs_succeeded_total, cogo_jobs_failed_total
  - cogo_job_latency_ms (histogram)
  - cogo_http_request_duration_ms (method, route, status)
- Supabase tables (read-only in UI):
  - jobs(id, type, status, payload, result, error, created_at, updated_at)
  - artifacts(job_id, name, url, size, mime, created_at)
  - worker_devices(worker_id, display_name, capabilities, last_seen_at)
  - worker_heartbeats(worker_id, ts, metrics)

## 5) Architecture (UI)
- services/
  - supabaseClient.ts — singleton client from env
  - metricsClient.ts — fetch /metrics, parse into JSON snapshot
  - agentsConfig.ts — endpoints config
- components/
  - MetricCard, TimeSeriesChart, Histogram, AgentStatusCard, JobsTable, ArtifactViewer
- pages/
  - Dashboard, Agents, Jobs, Artifacts, Realtime, McpMonitor
- routing: react-router (SPA)

## 6) Data Strategy
- KPIs: combine metrics counters + Supabase counts
- Timeseries: derive from `jobs` timestamps (bucket by minute/hour), latency from histogram
- Live updates: optional Supabase Realtime on `jobs` + polling `/metrics`

## 7) Security & CORS
- UI domain added to CORS allowlist on agents
- Read-only anon key in browser; sensitive ops remain server-side

## 8) Mock Strategy
- If env missing: mock providers for all pages with sample JSON
- Toggle via `VITE_USE_MOCK=true`

## 9) Milestones & Timeline
- M1 (day 1-2): services + env + Dashboard KPI
- M2 (day 3-4): Agents + Jobs (list/detail)
- M3 (day 5): Artifacts + MCP Monitor
- M4 (day 6): Realtime presence + polish, accessibility pass

## 10) Risks & Mitigations
- Metrics parsing drift → keep parser tolerant, add tests
- Realtime noise → debounce counters, cap updates
- Sensitive data in browser → only anon/read paths exposed

## 11) Acceptance Criteria
- KPI tiles accurate within ±1 polling interval
- Job detail shows latest status/result and artifact links
- /metrics renders basic charts without errors
- Works with mock mode when env missing

## 12) Runbook
- Copy `.env.example` to `.env` in assistant-ui
- `npm install && npm run dev`
- Ensure agents reachable and Supabase env valid
