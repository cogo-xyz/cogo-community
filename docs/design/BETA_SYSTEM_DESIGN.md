## 1. 베타 시스템 구축

- 목표: 분산 Agent + 지식 RAG 기반 품질 게이트를 갖춘 베타 운영 환경 구축(도커 배포, 자동화 CI/스케줄 포함)
- 핵심 구성
  - 메트릭 서버: `src/servers/metrics/index.ts` (Prometheus, REST, 대시보드)
  - Edge Functions: router-select, key-vault (호출 헤더: Authorization=ANON, apikey=PUBLISHABLE)
  - 품질 게이트: CI Q1(기본 70%), Supabase 직접 조회 기반 `ci:gate:q1:sb`
  - 스케줄: Nightly 스냅샷, Weekly 잡 큐잉(GitHub Actions 등록)
  - 알림: 주간 요약 + 최근 gate_fix 아티팩트 링크(스크립트/서버 엔드포인트)
- 배포(서버)
  - Dockerfile(메트릭 서버), docker-compose(plan-runner, 선택: quality-runner)
  - `.env`(서버): `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY`, `SUPABASE_PUBLISHABLE_KEY`, `ROUTER_SELECT_URL`, `KEY_VAULT_URL`, `METRICS_PORT`
  - 포트: 3100 노출 → `http://<server-ip>:3100/dashboard/local`

## 2. 개발 PC와 베타 서비스 역할

- 역할 분리(Executor ID 기준)
  - 베타 서비스(서버): 계획/품질 중심
    - `EXECUTOR_ID=cogo-plan` 오케스트레이터 라이브 러너(계획 결정, 품질 잡 트리거)
    - (선택) `EXECUTOR_ID=cogo-work` 품질 집계 러너만 제한적으로 운영
  - 개발 PC(로컬/도커): 실행/디버그 중심
    - `EXECUTOR_ID=cogo-work` 빌드/테스트/코드 디버그 전용 러너
    - 필요 시 `LIVE_INCLUDE_TYPES=code.build.test,code.debug`로 타입 범위 제한
- 운영 포인트
  - 잡 라우팅은 `executor_id`로 분리 → 서버는 계획/품질, 로컬은 실행을 담당
  - 로그/디버깅: 서버는 docker logs + 파일 마운트, 로컬은 터미널/인스펙트 사용
  - 보호: Service Role key는 서버에만, 로컬/브라우저는 ANON/PUBLISHABLE 사용

## 3. 엔트리 → 의존 그래프 확장(지식 RAG 수집 전략)

- 시드(엔트리)
  - 서버 엔트리: `src/index.ts`, `src/servers/metrics/index.ts`
  - 러너 엔트리: `src/scripts/distributed/orchestratorLive.ts`
- 정적 그래프(필수)
  - tsconfig(baseUrl/paths) 반영 모듈 그래프(파일 import 관계)
  - AST 기반 심볼/호출 그래프(함수·클래스 정의/호출/참조) → `ast_nodes`, `code_relationships`
  - 동적 로딩은 maybe 엣지로 표시
- 런타임 보강(권장)
  - 스모크 시 호출 트레이스 로깅 → 실행 빈도/경로 점수 부여 → 정적 그래프와 병합
- 인덱싱 정책(포함/제외)
  - 포함: `src/**/*.ts`, `docs/{specs,schemas,plans}/**/*.md`, `supabase/{sql,functions}/**`
  - 제외: `backups/**`, `backup/**`, `logs/**`, `reports/**`, `artifacts-local/**`, `react/**`, `mcp-servers/**`
- 청크·메타
  - 코드: 심볼 단위(AST 청크) + 파일경로/심볼명/서명 메타
  - 문서: 헤더(##) 단위 청크 + 헤더 체인/파일경로 메타
  - 스키마/함수: 문/함수 단위 청크 + 오브젝트명 메타
- 파이프라인
  1) 정적 그래프 생성 → 위상 정렬로 엔트리 근접 가중치 부여
  2) 런타임 엣지 병합 → 우선순위 재정렬
  3) 임베딩·업서트 → Supabase(pgvector), Neo4j 링크 유지

---
참고 문서: `docs/README_BETA_OPS.md`, `docs/API_METRICS_AND_NOTIFY.md`, `docs/OPERATIONS_RUNBOOK.md`, `docs/DEVELOPMENT_EXECUTION_PLAN_VNEXT.md`


