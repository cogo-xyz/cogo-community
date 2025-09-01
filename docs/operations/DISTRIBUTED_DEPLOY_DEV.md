## Distributed Agents - Dev Deployment (MicroK8s)

### Overview
This guide automates building, shipping, and deploying distributed agents (orchestrator, indexing, research, executor) to a remote MicroK8s cluster in development. It reuses sudo NOPASSWD for `/snap/bin/microk8s` to import images without prompts.

### Prerequisites
- docker buildx (to build linux/amd64 on mac)
- sshpass installed
- Remote sudoers configured for passwordless microk8s: `yoshop ALL=(ALL) NOPASSWD: /snap/bin/microk8s`
- Secrets `cogo-secrets` present on cluster (`supabase-url`, `supabase-service-role-key`)

### One-command Deploy
```bash
PASS_FILE="$HOME/.ssh/.pass.yoshop" \
REMOTE_IP=121.167.147.128 REMOTE_PORT=22022 REMOTE_USER=yoshop \
bash scripts/deploy/dev/deploy-distributed.sh
```

What it does:
- Builds linux/amd64 images for orchestrator/indexing/research/executor
- Saves to TAR and uploads to `~/tmp` on the remote
- Imports images via `sudo /snap/bin/microk8s ctr image import`
- Applies `k8s/distributed.yaml`
- Waits for rollouts and prints statuses

### Agent IDs & Environment
The manifest sets default `AGENT_ID`s:
- `cogo-orchestrator-01`, `cogo-indexer-01`, `cogo-research-01`, `cogo-executor-01`

Customize by editing `k8s/distributed.yaml` before running the script. Ensure `ENABLE_SUPABASE=true` and `SUPABASE_URL`/`SUPABASE_SERVICE_ROLE_KEY` are provided via `cogo-secrets`.

### Re-deploy Updates
Re-run the same command after code changes. The script rebuilds, re-imports, reapplies, and waits for rollout.

### Ports & Access
- Each pod listens on `3100` (internal). Expose via Ingress as needed.

### Troubleshooting
- If pods CrashLoop, run: `microk8s kubectl logs deploy/<name> --tail=200`
- If Service endpoints empty, ensure pod Ready and port `3100` matches container `PORT=3100`.
- If image not found, confirm `ctr image import` succeeded and image name tags match manifest.


