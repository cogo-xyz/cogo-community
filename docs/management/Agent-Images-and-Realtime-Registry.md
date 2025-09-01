# Agent Images, Realtime Channels, and Registry Policy (Unified)

This document unifies: agent Docker images, Supabase Realtime bus channels (subscribe/publish), and the image-tagging/registry/token policy (table schemas).

## Principles
- Realtime-first: Inter-agent comms must use `public.agent_messages` (subscribe/publish via routing keys).
- Edge → Orchestrator: Edge Functions enqueue intents onto the bus; Orchestrator decides and triggers execution.
- Image-based deployment: Dev/Prod rollouts/rollbacks are done by tags, not bind mounts.
- Secrets by reference only: Tokens/keys live in Secret Managers (K8s Secret/Vault). We store references, not values.

## Table Schemas (references only)

### registry_accounts
| column | type | notes |
|---|---|---|
| id | uuid pk | account id |
| provider | text | ghcr/dockerhub/ecr/gcr |
| registry_url | text | e.g., `ghcr.io` |
| namespace | text | org/account name |
| credential_ref | text | e.g., `k8s:cogo-dev/ghcr-pullsecret`, `vault:path` |
| read_only | boolean | pull-only |
| description | text | notes |
| created_at | timestamptz | created |

### agent_catalog
| column | type | notes |
|---|---|---|
| id | uuid pk | catalog id |
| agent_name | text | `cogo-<domain>-<role>` |
| service | text | routing key: service |
| role | text | routing key: role |
| repo | text | e.g., `ghcr.io/my-org/cogo-agent-core` |
| default_tag | text | e.g., `dev` |
| pinned_tag | text | e.g., `dev-20250815123000` |
| registry_account_id | uuid fk | → registry_accounts.id |
| autodeploy_enabled | boolean | allow auto rollout |
| created_at | timestamptz | created |
| updated_at | timestamptz | updated |

### image_tag_history
| column | type | notes |
|---|---|---|
| id | uuid pk | history id |
| agent_id | uuid fk | → agent_catalog.id |
| tag | text | image tag |
| digest | text | image digest (optional) |
| built_by | text | CI user/bot |
| built_at | timestamptz | build time |
| changelog_url | text | release notes link |
| rollout_status | text | staged/active/rolled_back/failed |
| trace_id | text | pipeline trace id |

### k8s_pull_secret_links
| column | type | notes |
|---|---|---|
| id | uuid pk | link id |
| registry_account_id | uuid fk | → registry_accounts.id |
| kube_namespace | text | namespace |
| secret_name | text | imagePullSecret name |
| last_synced_at | timestamptz | last sync |
| managed_by | text | manual/controller |

## Docker Images (recommended registry: `ghcr.io/<org>`)

| image | tag policy | entrypoint | port | required ENV | notes |
|---|---|---|---|---|---|
| `ghcr.io/<org>/cogo-agent-core` | dev:`dev-YYYYMMDDHHmmss`, prod:`vX.Y.Z` | dev:`npm run start:minimal`, prod:`node dist/index.js` | 3000 | `PORT`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `ARTIFACTS_BASE` | API/minimal server |
| `ghcr.io/<org>/cogo-executor-dispatcher` | dev/prod | `node dist/workers/ExecutorDispatcher.js` | - | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `AGENT_SERVICE=orchestrator`, `AGENT_ROLE=execute`, `AGENT_SHARD=0` | execution policy |
| `ghcr.io/<org>/cogo-codegen-worker` | dev/prod | `node dist/workers/CodegenBusWorker.js` | - | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `AGENT_SERVICE=codegen`, `AGENT_ROLE=generate`, `AGENT_SHARD=0`, `ARTIFACTS_BASE` | codegen |
| `ghcr.io/<org>/cogo-buildtest-worker` | dev/prod | `node dist/workers/BuildTestBusWorker.js` | - | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `AGENT_SERVICE=code`, `AGENT_ROLE=build-test`, `AGENT_SHARD=0`, `ARTIFACTS_BASE` | build/test |

Tagging: Dev `dev-<YYYYMMDDHHMMSS>`, Prod SemVer (+short sha optional).

## Agent ↔ Image Mapping

| agent | service | role | shard | image | entry |
|---|---|---|---|---|---|
| Orchestrator API | - | - | - | `cogo-agent-core` | dev:minimal / prod:dist |
| Executor Dispatcher | orchestrator | execute | 0 | `cogo-executor-dispatcher` | dispatcher |
| Codegen Worker | codegen | generate | 0 | `cogo-codegen-worker` | codegen |
| Build/Test Worker | code | build-test | 0 | `cogo-buildtest-worker` | buildtest |

## Realtime Bus Contracts
- Routing key: `(service, role, shard, tenant?)`.
- Edge → Orchestrator: intent messages are enqueued to bus.
- Orchestrator → Dispatcher: publish to `orchestrator/execute/0`.
- Dispatcher → Target: publish to `payload.target` (e.g., `codegen/generate/0`, `code/build-test/0`).
- All messages/events must include `trace_id`.

### Subscribe (Sub)
| component | route | notes |
|---|---|---|
| Executor Dispatcher | `orchestrator/execute/0` | execution requests |
| Codegen Worker | `codegen/generate/0` | codegen jobs |
| Build/Test Worker | `code/build-test/0` | build/test jobs |

### Publish (Pub) and Audit Events
| publisher | to/event | notes |
|---|---|---|
| Orchestrator | `orchestrator/execute/0` | trigger dispatcher |
| Dispatcher | `payload.target` | forward to target worker |
| Codegen | `code/build-test/0` | trigger next stage |
| Common | `public.bus_events` | `execute_*`, `codegen_*`, `buildtest_*` with `trace_id` |

## K8s Snippet (example)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cogo-codegen-worker
spec:
  replicas: 1
  selector:
    matchLabels: { app: cogo-codegen-worker }
  template:
    metadata:
      labels: { app: cogo-codegen-worker }
    spec:
      containers:
      - name: codegen
        image: ghcr.io/<org>/cogo-codegen-worker:dev-20250815
        env:
        - { name: SUPABASE_URL, valueFrom: { secretKeyRef: { name: cogo-secrets, key: supabase-url } } }
        - { name: SUPABASE_SERVICE_ROLE_KEY, valueFrom: { secretKeyRef: { name: cogo-secrets, key: supabase-service-role-key } } }
        - { name: AGENT_SERVICE, value: "codegen" }
        - { name: AGENT_ROLE, value: "generate" }
        - { name: AGENT_SHARD, value: "0" }
        - { name: ARTIFACTS_BASE, value: "/app/artifacts-local" }
```

## Rollout Flow and Acceptance
- New tag pushed → record `image_tag_history` → update `agent_catalog.pinned_tag` → deploy.
- Rollout succeeds within 1 minute; on failure, rollback to last `active` tag.

## Security
- No secrets in code/docs/DB. Use `credential_ref` to point to K8s Secret/Vault only.
