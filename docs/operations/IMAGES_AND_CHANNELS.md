# Docker Images and Realtime Channels (Dev/Prod)

> Note: This content has been unified into `docs/policies/Agent-Images-and-Realtime-Registry.md`. Please consult the unified document for the latest information.

개발/운영에서 빌드/배포할 Docker 이미지들과 각 이미지에 포함되는 Agent, 구독/발행하는 Realtime Bus 경로를 표로 정리합니다. 실 비밀/키는 저장하지 않으며, 필요한 환경 변수만 명시합니다.

## 1) 이미지 목록 (권장 레지스트리: `ghcr.io/<org>`)

| 이미지 (repo) | 태그 정책 | 엔트리포인트 | 포트 | 필수 ENV | 비고 |
|---|---|---|---|---|---|
| `ghcr.io/<org>/cogo-agent-core` | dev: `dev-YYYYMMDDHHmmss` / prod: `vX.Y.Z` | dev: `npm run start:minimal` / prod: `node dist/index.js` | 3000 | `PORT`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `ARTIFACTS_BASE` | 최소 서버/라우트 및 운영 API 서버 |
| `ghcr.io/<org>/cogo-executor-dispatcher` | dev/prod 동일 | prod: `node dist/workers/ExecutorDispatcher.js` | (없음) | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `AGENT_SERVICE=orchestrator`, `AGENT_ROLE=execute`, `AGENT_SHARD=0` | 집행 표준화/TTL/백오프/감사 |
| `ghcr.io/<org>/cogo-codegen-worker` | dev/prod 동일 | prod: `node dist/workers/CodegenBusWorker.js` | (없음) | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `AGENT_SERVICE=codegen`, `AGENT_ROLE=generate`, `AGENT_SHARD=0`, `ARTIFACTS_BASE` | Codegen 실행(옵션: `ENABLE_COGO_WORKER`) |
| `ghcr.io/<org>/cogo-buildtest-worker` | dev/prod 동일 | prod: `node dist/workers/BuildTestBusWorker.js` | (없음) | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `AGENT_SERVICE=code`, `AGENT_ROLE=build-test`, `AGENT_SHARD=0`, `ARTIFACTS_BASE` | Build/Test 실행(옵션: `ENABLE_COGO_WORKER`) |

태깅 권장:
- Dev: `dev-<YYYYMMDDHHMMSS>` (예: `dev-20250815133045`)
- Prod: SemVer + git sha (예: `v2.3.0` 또는 `v2.3.0-<shortsha>`)

## 2) Agent ↔ 이미지 매핑

| Agent (논리명) | Service | Role | Shard | 배포 이미지 | 엔트리/커맨드 |
|---|---|---|---|---|---|
| Orchestrator API | - | - | - | `ghcr.io/<org>/cogo-agent-core` | dev:`npm run start:minimal` / prod:`node dist/index.js` |
| Executor Dispatcher | orchestrator | execute | 0 | `ghcr.io/<org>/cogo-executor-dispatcher` | `node dist/workers/ExecutorDispatcher.js` |
| Codegen Worker | codegen | generate | 0 | `ghcr.io/<org>/cogo-codegen-worker` | `node dist/workers/CodegenBusWorker.js` |
| Build/Test Worker | code | build-test | 0 | `ghcr.io/<org>/cogo-buildtest-worker` | `node dist/workers/BuildTestBusWorker.js` |

## 3) Realtime Bus 경로 (public.agent_messages)

- 라우팅 키: `(service, role, shard, tenant?)`
- 각 워커는 아래 경로를 구독(Sub)하고, 처리 단계에 따라 게시(Pub)합니다.

### 3.1 구독(Sub) 경로

| 컴포넌트 | 구독 경로 (service/role/shard) | 설명 |
|---|---|---|
| Executor Dispatcher | `orchestrator/execute/0` | Orchestrator의 집행 요청 수신, 타겟 라우트로 중계 |
| Codegen Worker | `codegen/generate/0` | 코드 생성 작업 수신 |
| Build/Test Worker | `code/build-test/0` | 빌드/테스트 작업 수신 |

### 3.2 발행(Pub) 경로/이벤트

| 발행 주체 | 게시 대상/유형 | 내용 |
|---|---|---|
| Orchestrator(API/Workflow) | 버스 라우트: `orchestrator/execute/0` | Executor Dispatcher에게 집행 요청 게시 |
| Executor Dispatcher | 버스 라우트: `payload.target` (예: `codegen/generate/0`, `code/build-test/0`) | 유효성/TTL/백오프 후 타겟 워커로 게시 |
| Codegen Worker | 버스 라우트: `code/build-test/0` (후속 단계) | Codegen 완료 후 Build/Test 단계 트리거(필요 시) |
| 모든 단계 | 감사 이벤트(`public.bus_events`) | `execute_*`, `codegen_*`, `buildtest_*` 등 이벤트 기록(아래 표) |

### 3.3 감사 이벤트 타입 (public.bus_events)

| 카테고리 | 이벤트 타입 | 설명 |
|---|---|---|
| Execute | `execute_enqueued` | Dispatcher가 타겟 라우트 게시 완료 |
|  | `execute_retry` | 재시도(backoff) 발생 |
|  | `execute_failed` | 집행 실패(최대 시도 초과 등) |
|  | `execute_done` | 집행 완료(최종 타겟 게시의 확인 등) |
| Codegen | `codegen_retry` | 재시도(backoff) |
|  | `codegen_failed` | Codegen 실패 |
|  | `codegen_done` | Codegen 완료(아티팩트/경로 포함) |
| Build/Test | `buildtest_retry` | 재시도(backoff) |
|  | `buildtest_failed` | 빌드/테스트 실패 |
|  | `buildtest_done` | 빌드/테스트 완료(리포트/경로 포함) |

모든 이벤트/메시지에 `trace_id`를 포함해 파이프라인 상관관계가 가능해야 합니다.

## 4) K8s 배포 스니펫 (예시)

- API(개발): `npm run start:minimal`, `MINIMAL_OPTIONAL_LOAD=false`
- 워커(운영/개발): 각 전용 이미지 + entrypoint로 배포

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

## 5) 태그/토큰 관리 (요약)
- 이미지 태그/다이제스트 및 pinned_tag 관리는 `docs/policies/Agent-Image-Registry-Table.md` 테이블 설계에 따릅니다.
- 레지스트리 접근 토큰은 K8s Secret 등 외부 보관소에만 존재하고, 본 문서/코드에는 참조값만 유지합니다.
