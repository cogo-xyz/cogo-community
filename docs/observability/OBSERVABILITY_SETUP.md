## Observability Setup (Prometheus + Grafana)

### 1) Prometheus

Sample `prometheus.yml` (scrape every 10s):

```yaml
global:
  scrape_interval: 10s

scrape_configs:
  - job_name: cogo-agent-core
    metrics_path: /metrics
    static_configs:
      # Replace with your agent nodes or localhost if running locally
      - targets: ["localhost:3000"]
```

Notes:
- The server exposes Prometheus metrics at `/metrics` (see `src/services/metrics/Metrics.ts`).
- If running multiple nodes, add them all under `targets`.

### 2) Grafana

1. Add Prometheus data source pointing to your Prometheus server (e.g., `http://localhost:9090`).
2. Import dashboard JSON: `docs/grafana/cogo-db-mode-dashboard.json`.
3. Panels included:
   - Jobs Succeeded/Failed (rate)
   - Job Latency (ms)
   - Backoffs (rate)
   - Inflight/Concurrency

### 3) Useful Metrics
- `cogo_jobs_succeeded_total`, `cogo_jobs_failed_total`
- `cogo_job_latency_ms` (histogram)
- `cogo_job_backoff_total`
- `cogo_worker_concurrency`, `cogo_jobs_inflight`

### 4) Tips
- For Kubernetes, expose `/metrics` via Service/Ingress or use ServiceMonitor (Prometheus Operator).
- Use dashboard variables (executorId/type) by labeling metrics in future iterations if needed.


