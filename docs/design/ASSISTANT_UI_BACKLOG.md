
# Assistant UI Backlog (MVP → Next)

## Epics & Stories (MVP)

### Epic: Dashboard Overview
- Story: View KPIs (queued/succeeded/failed, realtime count)
- Story: View job latency p50/p95 from histogram
- Story: View simple throughput chart per minute
- AC: values match /metrics and Supabase counts; refresh ≤30s

### Epic: Agents
- Story: List agents with status from /health
- Story: Agent card shows comm stats and key metrics
- Story: Agent detail shows raw /metrics snapshot
- AC: handles agent offline gracefully

### Epic: Jobs
- Story: List jobs with filters (status/type)
- Story: Job detail panel (payload/result/error, timeline)
- Story: Link to related artifacts
- AC: pagination and filter working; fields accurate

### Epic: Artifacts
- Story: List artifacts with basic preview (image)
- Story: Download link (signed URL)
- AC: safe rendering, size shown; broken links handled

### Epic: MCP Monitor
- Story: Show recent browser/figma tasks
- Story: Show produced artifacts per task
- AC: task types grouped; links valid

### Epic: Realtime
- Story: Presence summary of workers
- Story: Live updates to counters (optional)
- AC: toggleable live mode; no UI jank

## Technical Tasks (MVP)
- Setup Supabase client and env handling
- Implement /metrics parser (Prometheus→JSON)
- Build design system primitives (cards, tables, charts)
- Routing skeleton and layouts
- Error boundary + loading states
- Unit tests for metrics parser and services

## Next (Post-MVP)
- Dark mode; theming
- Advanced charts (heatmaps, percentile bands)
- Job replay/resubmit (admin)
- Notifications (websocket/push)
- Internationalization (reuse multilingual strategy)

## Done Definition
- All MVP pages functional with real backend
- Basic tests green; lint clean
- Documentation updated; .env.example present
