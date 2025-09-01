## Remote Apply Runbook (K8s)

Purpose: Apply cogo-agent-core resources to a remote Kubernetes cluster using rendered kustomize manifests and cluster-side kubectl.

### Prerequisites
- Cluster kubeconfig with context (e.g., `dev-cluster`)
- Target namespace (e.g., `cogo-dev`)
- Supabase secrets available to create `supabase-secrets` (URL, SERVICE_ROLE_KEY)

### Manifest Rendering (local)
```bash
kubectl kustomize k8s/ > /tmp/cogo-agent-core.k8s.yaml
```

### Transfer to Remote
```bash
scp /tmp/cogo-agent-core.k8s.yaml <user>@<host>:/tmp/
```

### Apply on Remote (SSH into remote)
```bash
kubectl config use-context dev-cluster
kubectl get ns cogo-dev >/dev/null 2>&1 || kubectl create ns cogo-dev

# Supabase secrets (replace with real values or use CI secrets)
kubectl -n cogo-dev create secret generic supabase-secrets \
  --from-literal=SUPABASE_URL="$SUPABASE_URL" \
  --from-literal=SUPABASE_SERVICE_ROLE_KEY="$SUPABASE_SERVICE_ROLE_KEY" \
  --dry-run=client -o yaml | kubectl -n cogo-dev apply -f -

# Apply rendered manifest (includes Deployment, Service, and CronJobs)
kubectl -n cogo-dev apply -f /tmp/cogo-agent-core.k8s.yaml --validate=false

# Verify
kubectl -n cogo-dev get deploy,po,cronjob
```

### Included CronJobs
- Acceptance gates: 5 min windowed checks
- Bus reclaimer: 1 min interval
- Retention: daily 03:00
- DLQ replay: every 10 min (move→replay)

### Rollback
- Keep prior manifest copies (timestamped). Re-apply previous file to rollback.

### Notes
- For production, use image tags (e.g., `main-<sha>`/`semver`) promoted via Registry API before applying.
- Secrets should be managed via your secret manager or sealed secrets in GitOps flows.


