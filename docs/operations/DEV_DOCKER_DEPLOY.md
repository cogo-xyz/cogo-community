## Dev Server: Docker Build → Transfer/Import → Deploy(K8s) → Test

This runbook documents the full flow to build images locally, move them to the dev server (MicroK8s), import to the container runtime, apply manifests, and run smoke tests. All steps are scripted; see the referenced scripts below.

### Prerequisites
- Remote dev server with MicroK8s installed (e.g., 1.27.x).
- Passwordless sudo for `/snap/bin/microk8s` configured via visudo.
- Kubernetes secret `cogo-secrets` exists with keys: `supabase-url`, `supabase-anon-key`, `supabase-service-role-key`.
- Local can SSH using a password file (e.g., `$HOME/.ssh/.pass.yoshop`).
- Ports unified to 3100 for all agent services.

### Images and Dockerfiles
- Images (tag: `:dev`):
  - `cogo-agent-core/orchestrator:dev` (Dockerfile.orchestrator)
  - `cogo-agent-core/indexing:dev` (Dockerfile.indexing)
  - `cogo-agent-core/research:dev` (Dockerfile.research)
  - `cogo-agent-core/executor:dev` (Dockerfile.executor)

> Note: Remote dev server is amd64. Build executor as linux/amd64 when deploying:
> - Build amd64 image locally: `bash scripts/dev/build-executor-amd64.sh`
> - Import to remote: `bash scripts/dev/import-executor-remote.sh --host <ip> --port <sshPort> --user <user> --pass-file <path>`
> - Update deployment to the amd64 tag (example):
>   `microk8s kubectl set image deploy/cogo-executor cogo-executor=cogo-agent-core/executor:dev-amd64-<TS>`

### Scripts: Step-by-step
- Build images locally: `scripts/dev/build-images.sh`
- Save images to tars: `scripts/dev/save-images.sh`
- Transfer tars to remote: `scripts/dev/transfer-images.sh --host <ip> --port <sshPort> --user <user> --pass-file <path>`
- Import images (remote): `scripts/dev/import-images-remote.sh --host <ip> --port <sshPort> --user <user> --pass-file <path>`
- Apply manifests (remote): `scripts/dev/apply-manifests-remote.sh --host <ip> --port <sshPort> --user <user> --pass-file <path>`
- Post-deploy smoke tests (remote): `scripts/dev/smoke-tests-remote.sh --host <ip> --port <sshPort> --user <user> --pass-file <path>`

### Example (Dev Server)
```bash
# 0) Build
bash scripts/dev/build-images.sh

# 1) Save
bash scripts/dev/save-images.sh

# 2) Transfer
bash scripts/dev/transfer-images.sh --host 121.167.147.128 --port 22022 --user yoshop --pass-file "$HOME/.ssh/.pass.yoshop"

# 3) Import
bash scripts/dev/import-images-remote.sh --host 121.167.147.128 --port 22022 --user yoshop --pass-file "$HOME/.ssh/.pass.yoshop"

# 4) Apply manifests
bash scripts/dev/apply-manifests-remote.sh --host 121.167.147.128 --port 22022 --user yoshop --pass-file "$HOME/.ssh/.pass.yoshop"

# 5) Smoke tests
bash scripts/dev/smoke-tests-remote.sh --host 121.167.147.128 --port 22022 --user yoshop --pass-file "$HOME/.ssh/.pass.yoshop"
```

### Notes
- Image import leverages `/snap/bin/microk8s ctr image import` on the remote.
- If you see `exec format error` in pod logs, your image arch mismatched the node. Use the amd64 build steps above.
- For local ActionFlow E2E: `bash scripts/ops/smoke-actionflow-local.sh`.
- For remote one-shot runner Job: `bash scripts/ops/run-aflow-job-remote.sh --host ... --project "$PROJECT_ID"`.


