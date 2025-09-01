### Schema Ownership Matrix (public vs cogo)

- 목적: 유저 대면 데이터와 에이전트 메타/추적 데이터를 명확히 분리하고, 보안·거버넌스·확장성 확보.

#### 원칙
- public 스키마: 사용자 프로젝트 산출물과 운영 데이터의 단일 진실원.
- cogo 스키마: 에이전트 실행 메타데이터, 추적, 아티팩트 인덱싱 등 내부 운영 데이터.
- 교차 참조는 `project_id`, `page_id`, `component_id`를 기본 키로 사용. Figma node-id는 cogo 측 메타에만 저장하고 public은 참조만.

#### 테이블 책임(예시)
- public
  - projects, pages, components, assets, variables, data_actions
  - 관계 및 버전: 프로젝트/페이지/컴포넌트의 버전·릴리즈 정책
  - 사용자 편집/승인 히스토리
- cogo
  - artifacts(id, trace_id, task_type, project_id, page_id, name, mime, size, storage_path, sha256, meta, created_at)
  - traces, bus_events, jobs, rag_jobs
  - node_page_link_meta(figma_file_key, figma_node_id, project_id, page_id, meta)

#### 데이터 흐름
- Edge 함수는 대용량 산출물(UI JSON, 리포트)을 Storage에 저장 후 `cogo.artifacts`에 메타를 기록.
- public은 최종 승인된 결과만 반영(예: 새로운 페이지/컴포넌트). 중간 산출물은 cogo에 잔존.

#### 보안/RLS
- public: 프로젝트 소유자/협업자 기준 RLS.
- cogo: 내부 시스템 역할 기반 + 서명 URL로 외부 접근 제한.

#### 마이그레이션 가이드
- 기존 public에 있던 임시/중간 산출물은 `cogo.artifacts` 메타로 이전 권장.


