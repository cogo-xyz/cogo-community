## Grafana Dashboard – Notes

Suggested panels (Prometheus):
- cogo_jobs_succeeded_total / cogo_jobs_failed_total – rate over 1m/5m
- cogo_job_latency_ms – heatmap/percentiles (P50/P90/P99)
- cogo_job_backoff_total – rate; correlate with failures
- cogo_worker_concurrency, cogo_jobs_inflight – current usage
- DB backlog: jobs{status="queued"} via SQL/Prometheus exporter

Next:
- Provide ready-to-import JSON with common panels
- Add annotations for deploys (GitHub Actions)


