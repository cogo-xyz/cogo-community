# Agent and Docker Image Tagging Registry (Token Reference Table)

> Note: This document has been unified into `docs/policies/Agent-Images-and-Realtime-Registry.md`. Please refer to the unified document for the latest source of truth.

본 문서는 분산 Agent별 Docker 이미지 태깅과 레지스트리 접근 토큰(참조)을 중앙 테이블로 관리하는 정책과 스키마를 정의합니다. 보안 상 실제 토큰 값은 저장하지 않으며, 외부 비밀 저장소(예: K8s Secret, Vault, Supabase Key Vault)의 "참조값"만 저장합니다.

## 원칙
- 실제 토큰/비밀은 코드/DB에 저장하지 않는다(참조만). 노출 시 즉시 회전.
- 이미지는 레지스트리별 네임스페이스/조직 단위로 관리한다.
- Agent는 `service/role/shard` 표준과 매핑되는 이미지 레포와 현재 태그를 갖는다.
- 배포 이력과 롤백을 위해 태그/다이제스트 히스토리를 저장한다.
- K8s Pull Secret 매핑은 네임스페이스/시크릿명 참조로 관리한다.

## 관리 테이블 (개요)
- registry_accounts: 레지스트리 계정/네임스페이스와 비밀 참조
- agent_catalog: 에이전트별 기본 레포/태그/계정 매핑
- image_tag_history: 에이전트별 태그/다이제스트 이력과 롤아웃 상태
- k8s_pull_secret_links: 레지스트리 계정 ↔ K8s Secret 매핑(네임스페이스 단위)

### registry_accounts
| 컬럼 | 타입 | 설명 |
|---|---|---|
| id | uuid pk | 계정 ID |
| provider | text | ghcr/dockerhub/ecr/gcr 등 |
| registry_url | text | 예: `ghcr.io` |
| namespace | text | 조직/계정명 (예: `my-org`) |
| credential_ref | text | 비밀 참조(예: `k8s:cogo-dev/ghcr-pullsecret` 또는 `vault:path`) |
| read_only | boolean | Pull 전용 여부 |
| description | text | 비고 |
| created_at | timestamptz | 생성일 |

### agent_catalog
| 컬럼 | 타입 | 설명 |
|---|---|---|
| id | uuid pk | 에이전트 카탈로그 ID |
| agent_name | text | `cogo-<domain>-<role>` |
| service | text | 라우팅키 service |
| role | text | 라우팅키 role |
| repo | text | 이미지 레포 (예: `ghcr.io/my-org/cogo-agent-core`) |
| default_tag | text | 기본 태그 (예: `dev`) |
| pinned_tag | text | 현재 고정 태그 (예: `dev-20250815123000`) |
| registry_account_id | uuid fk | registry_accounts.id |
| autodeploy_enabled | boolean | 자동 롤아웃 허용 여부 |
| created_at | timestamptz | 생성일 |
| updated_at | timestamptz | 수정일 |

### image_tag_history
| 컬럼 | 타입 | 설명 |
|---|---|---|
| id | uuid pk | 이력 ID |
| agent_id | uuid fk | agent_catalog.id |
| tag | text | 이미지 태그 |
| digest | text | 이미지 다이제스트(옵션) |
| built_by | text | 빌드 주체(CI 사용자/봇) |
| built_at | timestamptz | 빌드 시각 |
| changelog_url | text | 변경 로그/릴리스 노트 링크 |
| rollout_status | text | staged/active/rolled_back/failed |
| trace_id | text | 파이프라인 추적 ID |

### k8s_pull_secret_links
| 컬럼 | 타입 | 설명 |
|---|---|---|
| id | uuid pk | 링크 ID |
| registry_account_id | uuid fk | registry_accounts.id |
| kube_namespace | text | K8s 네임스페이스 |
| secret_name | text | imagePullSecret 이름 |
| last_synced_at | timestamptz | 동기화 시각 |
| managed_by | text | manual/controller |

## 운영 흐름
1) CI/CD에서 이미지 빌드/푸시 후 `image_tag_history`에 태그/다이제스트 기록, `agent_catalog.pinned_tag` 갱신.
2) 배포 파이프라인이 `agent_catalog`의 현재 `pinned_tag`를 읽어 K8s에 적용.
3) 롤백 시 `image_tag_history`에서 이전 `active` 태그를 `pinned_tag`로 즉시 복귀.
4) 새 레지스트리 계정 추가 시 `registry_accounts` 생성 및 `k8s_pull_secret_links`로 NS-시크릿 연결.

## 보안/권한
- 실제 비밀은 `credential_ref`로만 참조. 예: `k8s:cogo-dev/ghcr-pullsecret`.
- 테이블에는 RLS 적용(작성자/시스템 역할만 쓰기 가능). 감사 컬럼/이벤트 기록.

## K8s와 연동
- `k8s/deployment.yaml`의 image 필드는 `agent_catalog.repo:agent_catalog.pinned_tag` 조합 사용 권장.
- `imagePullSecrets`는 `k8s_pull_secret_links`를 통해 관리되는 Secret 이름을 사용.

## 수용 기준(Dev)
- 신규 태그 푸시 후 1분 내 `agent_catalog.pinned_tag` 갱신, 롤아웃 성공.
- 롤백 명령 시 1분 내 이전 태그로 복귀.
- 비밀/토큰은 DB에 저장 금지(참조만). 유출 테스트 시 차단.
