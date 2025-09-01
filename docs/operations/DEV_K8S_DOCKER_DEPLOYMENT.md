# Development Server Deployment (Kubernetes + Docker)

This guide documents how to deploy cogo-agent-core to a development server using Docker images and Kubernetes. It follows our policies: image-based rollout, centralized secrets, and Realtime-first workflows.

## 1) Overview
- Packaging: Docker images (dev or prod flavor)
- Orchestration: Kubernetes (Deployment + Service; optional Ingress)
- Communication: Supabase Realtime (`public.agent_messages`) for inter-agent flows
- Dev convenience: Minimal HTTP endpoints may be exposed; production should prefer Edge ingress

## 2) Build and Tag Images

Option A (Development image; ts-node runtime, faster iteration):
```bash
# From repo root
docker build -f Dockerfile.dev -t <REGISTRY>/<NAMESPACE>/cogo-agent-core:dev-$(date +%Y%m%d%H%M%S) .
# e.g. docker build -f Dockerfile.dev -t registry.local/cogo/cogo-agent-core:dev-20250815 .
```

Option B (Production-style image; compiled `dist/` runtime):
```bash
docker build -f Dockerfile -t <REGISTRY>/<NAMESPACE>/cogo-agent-core:prod-$(date +%Y%m%d%H%M%S) .
```

Push to registry:
```bash
docker push <REGISTRY>/<NAMESPACE>/cogo-agent-core:<TAG>
```

## 3) Kubernetes Prereqs
- Kubernetes context is set to the development cluster.
- Namespace (example: `cogo-dev`) is created:
```bash
kubectl create namespace cogo-dev || true
kubectl config set-context --current --namespace=cogo-dev
```

### Secrets (Centralized; no secrets in code)
Create `cogo-secrets` with required keys (base64-encoded values):
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: cogo-secrets
type: Opaque
data:
  supabase-url: <base64-encoded-supabase-url>
  supabase-service-role-key: <base64-encoded-service-role-key>
  # Optional: add model/router keys as needed
  # claude-api-key: <base64>
  # gemini-api-key: <base64>
```
Apply:
```bash
kubectl apply -f k8s/deployment.yaml # if Secret embedded
# or save to secrets.yaml and apply:
# kubectl apply -f secrets.yaml
```

## 4) Configure Image and Deploy
Update the `image` in `k8s/deployment.yaml` (dev example):
```yaml
containers:
  - name: cogo-agent-core
    image: <REGISTRY>/<ACCOUNT_OR_ORG>/cogo-agent-core:dev-20250815
```

Apply manifests (namespace `cogo-dev` example):
```bash
kubectl create namespace cogo-dev || true
kubectl -n cogo-dev apply -k k8s/
```

Check rollout:
```bash
kubectl rollout status deployment/cogo-agent-core
kubectl get pods -o wide
```

## 5) Service Exposure (Dev)

- Service (ClusterIP): `k8s/deployment.yaml` includes a `Service` with port 80 → 3000.
- Ingress (optional): configure host in the manifest. For quick testing without Ingress:
```bash
kubectl port-forward deploy/cogo-agent-core 3001:3000
# Then access http://localhost:3001
```

## 6) Health and Probes
- Minimal server exposes a lightweight HTTP endpoint:
  - `GET /api/integration/status` returning JSON with `initialized`, `optionalLoaded`, `ts`.
- Probes (dev default): TCP on port 3000.
  - In production, prefer HTTP probes against a stable health endpoint.

## 7) Environment Variables (Dev Defaults)
- Mandatory (in Secret):
  - `SUPABASE_URL`
  - `SUPABASE_SERVICE_ROLE_KEY`
- Optional:
  - `ENABLE_COGO_WORKER` (default `false` in dev)
  - `COGO_WORKER_URL`, `COGO_WORKER_TIMEOUT_MS`
  - `ARTIFACTS_BASE=/app/artifacts-local`
  - `PORT=3000`
- Minimal server option:
  - `MINIMAL_OPTIONAL_LOAD=false` to skip loading optional agent modules for clean dev boot

## 8) Realtime Smoke Tests (Dev)
Run from inside the API pod (ensures cluster networking and env):
```bash
POD=$(kubectl get pods -l app=cogo-agent-core -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it "$POD" -- sh -lc '
  npm run -s smoke:dispatcher:e2e && \
  npm run -s smoke:workflows:e2e && \
  npm run -s smoke:gate:trace
'
```

Monitor logs and events:
```bash
kubectl logs -f deploy/cogo-agent-core
kubectl get events --sort-by=.lastTimestamp | tail -n 20
```

## 9) Observability
- Use metrics endpoints if enabled; otherwise use pod logs and Supabase dashboards.
- All bus/workflow events should carry `trace_id`. In dev, verify using metrics APIs (if routes are enabled) or DB queries.

## 10) Rollback
```bash
kubectl rollout undo deployment/cogo-agent-core
# Or set image back:
kubectl set image deployment/cogo-agent-core cogo-agent-core=<REGISTRY>/<NAMESPACE>/cogo-agent-core:<PREV_TAG>
```

## 11) Policies & Notes
- Never commit or paste secrets. If leaked, rotate immediately.
- Development may expose minimal HTTP endpoints to speed iteration; production should use Edge ingress + Realtime.
- Inter-agent communication must use Supabase Realtime (no direct HTTP coupling between agents).
- Prefer image-based deployment for all environments. Bind mounts are for local-only docker-compose.


