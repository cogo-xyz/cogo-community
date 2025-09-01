## COGO Observability – Minimal Grafana Dashboard Sketch

Scope: Display core reliability and latency metrics exported at `/metrics` (Prometheus format) from the Node server.

Data source
- Prometheus (scrapes the app at `http://<host>:<port>/metrics`)
- Example scrape config (prometheus.yml):
  ```yaml
  scrape_configs:
    - job_name: 'cogo-agent-core'
      scrape_interval: 10s
      static_configs:
        - targets: ['localhost:3000']
  ```

Key metrics (already exposed)
- Counters
  - `cogo_jobs_queued_total`
  - `cogo_jobs_succeeded_total`
  - `cogo_jobs_failed_total`
  - `cogo_realtime_events_total`
  - `cogo_job_backoff_total`
- Gauges
  - `cogo_worker_concurrency`
  - `cogo_jobs_inflight`
- Histograms
  - `cogo_http_request_duration_ms` (labels: method, route, status)
  - `cogo_job_latency_ms`
  - `cogo_tool_request_duration_ms` (labels: tool, status)
  
Actor–Critic loop metrics (v1 additions)
- Counters
  - `cogo_plan_steps_retry_total`
  - `cogo_plan_steps_failed_total`
  - `cogo_tool_cost_usd_total`

Recommended panels (v1)
1) Throughput by status (Stat)
   - `rate(cogo_jobs_queued_total[5m])`
   - `rate(cogo_jobs_succeeded_total[5m])`
   - `rate(cogo_jobs_failed_total[5m])`

2) In-flight and Concurrency (Time series)
   - `cogo_jobs_inflight`
   - `cogo_worker_concurrency`

3) HTTP latency p50/p95 (Time series)
   - `histogram_quantile(0.5, sum(rate(cogo_http_request_duration_ms_bucket[5m])) by (le))`
   - `histogram_quantile(0.95, sum(rate(cogo_http_request_duration_ms_bucket[5m])) by (le))`

4) Job latency p50/p95 (Time series)
   - `histogram_quantile(0.5, sum(rate(cogo_job_latency_ms_bucket[5m])) by (le))`
   - `histogram_quantile(0.95, sum(rate(cogo_job_latency_ms_bucket[5m])) by (le))`

5) Realtime events and Backoffs (Stat/Bar)
   - `rate(cogo_realtime_events_total[5m])`
   - `rate(cogo_job_backoff_total[5m])`

6) Tool latency p95 by tool (Time series)
   - `histogram_quantile(0.95, sum(rate(cogo_tool_request_duration_ms_bucket[5m])) by (le, tool))`

7) Step retries/failures (Stat)
   - `sum(rate(cogo_plan_steps_retry_total[5m]))`
   - `sum(rate(cogo_plan_steps_failed_total[5m]))`

8) Tool cost accumulated (Stat)
   - `sum(cogo_tool_cost_usd_total)`

Importable JSON
- See `COGO_Minimal_Dashboard.json` in the same directory for an import-ready minimal dashboard (assumes Grafana datasource named `Prometheus`).

Next steps
- Add per-executor/worker labels to metrics when available.
- Add alerting in Prometheus for SLO breach: high failure rate, high latency p95, lease renewal anomalies.

