## Development Execution Plan – Next Iteration (Distributed Agent)

본 문서는 “세션이 끊겨도 이 문서만으로 즉시 재개”를 목표로 한, 분산 에이전트 시스템의 다음 개발 계획서입니다. 아래 순서를 그대로 따라가면 됩니다. 모든 명령은 프로젝트 루트에서 실행하세요.

### Document Hub (start here)
- Self‑Correction Feedback Loop v1: docs/specs/SELF_CORRECTION_FEEDBACK_LOOP_V1.md
- LLM Response JSON Contract v1: docs/specs/LLM_RESPONSE_JSON_V1.md
- Message Envelope v1: docs/specs/MESSAGE_SCHEMA_V1.md
- Supabase Chat/Feedback/Jobs Schema v1: docs/specs/SUPABASE_CHAT_AND_FEEDBACK_SCHEMA_V1.md
- KG Scope v1 (TS + PY): docs/specs/KG_SCOPE_V1.md
- CBO Schema v3: docs/schemas/CBO_SCHEMA.md
- Project Roadmap (KG + Chat): docs/plans/PROJECT_ROADMAP_KG_CHAT.md

### TL;DR 재개 포인트
- 1단계(빠른 검증): 분산 스모크/모니터/품질 라이트 원샷 실행으로 상태 확인
  - 로컬 원샷: `METRICS_PORT=3101 QUALITY_LIGHT_LIMIT=2 QUALITY_MIN_RAN=2 npm run ci:run:prlite:local`
  - 결과 파일: `smoke-output.json`, `monitoring-report.json`, `reports/quality/light-summary.json`, `reports/pr-lite-summary.json`
- 2단계(작업 선택): 아래 “P1 스트림”에서 미완료 항목을 하나 선택 → 체크리스트 대로 수행
- 3단계(게이트): `npm run ci:aggregate:prlite` 로 합격/실패 판단(임계값은 아래 참조)

### Knowledge Graph (KG) – Scope and Next Actions (TS + PY)
- Scope (must-only)
  - Languages: TypeScript (now), Python (next). Mark with `metadata.language: 'ts'|'py'`.
  - Paths (execution-first): `src/servers/**`, `src/services/**`, `src/knowledge/**`, `src/scripts/rag/**`, `src/workers/**`, `src/routes/**`, `src/ai/**`, `src/types/**`, and Python agent/runtime dirs.
  - Exclude: tests/samples/legacy/backups and generated artifacts.
- CBO Objects (minimal required fields)
  - id (stable hash), kind (module/class/interface/type/function/method/schema.*), name, file_path, signature, start_line/end_line, params_json, returns_json, fields_json, metadata.language.
- Relations (minimal set)
  - contains, imports, extends/implements, calls (only when uniquely resolved), uses_type, returns_type, implements/uses_schema (code ↔ app JSON schema).
- Evidence policy
  - Prioritize schema → contains → local_file → calls → imports → neo4j.
  - Default filter: `metadata.language in ('ts','py')` (TS-first until PY is populated).
- Gates (nightly)
  - Coverage (TS): params ≥ 70%, returns ≥ 80%, fields ≥ 80%, lines 100%.
  - IO Gate (TS+PY): start at 70% (raise to 80% once stable).
  - Schema Conformance (when schema ingestion lands): action/flow/DDD ↔ handler mapping ≥ 60%.

Next actions in this iteration (ready-to-run)
- Phase 1: 분산 Agent v1(자기 색인 + 채팅) 선 구축
  1) Orchestrator/Indexer/Chat Gateway 최소 라인 가동
  2) TS 자기 색인(`buildCboV2.ts`) → Supabase CBO/Neo4j/RAG 투영
  3) Supabase 채팅: `chat_sessions/chat_messages` + 워커 구독 → `askRag` 스트리밍 응답
- Phase 2: KG 하드닝/게이트 고정
  - Coverage/IO Gate 임계 설정(라이트=리포트, 나이트리≥70%)
- Phase 3: cogo-platform 분석 → App JSON Schema 1급 인제스트
  - schema.ui/variables/actions/actionFlow/bdd/ddd → CBO `schema.*` + `implements/uses_schema` 연결
- Phase 4: Python 인제스트(1차) 및 혼합 KG 투영, 이후 2차(type hints/calls)

### 전제 조건
- 분산 모드 사용, 단일 서버 금지
- Supabase/Neo4j 접근 권한 및 서비스 키 준비
- Edge Functions(`key-vault`, `router-select`)는 개발 모드(`verify_jwt: false`)로 동작 가능

### 환경 변수 요약(필요 시 셋업)
- 필수: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `NEO4J_URI`, `NEO4J_USERNAME`, `NEO4J_PASSWORD`
- LLM 라우팅/키: `ROUTER_SELECT_URL`, `KEY_VAULT_URL`, `SUPABASE_ANON_KEY`
- 메트릭 포트: `METRICS_PORT`(기본 3101)
- 품질 라이트: `QUALITY_LIGHT_LIMIT`(기본 3), `QUALITY_CHILD_TIMEOUT_MS`(기본 30000)
- PR-Lite 게이트 임계값: `QUALITY_MIN_RAN`(기본 1), `HEALTH_TTL_MIN`(기본 1440), `ROUTING_REQUIRE_RANKED`(기본 1)

### 빠른 상태 점검 명령어
1) 분산 스모크: `npm run ci:smoke:distributed`
2) 모니터링 폴링: `npm run monitor:poll`
3) 품질 라이트: `QUALITY_LIGHT_LIMIT=2 npm run quality:run:light`
4) 집계 게이트: `QUALITY_MIN_RAN=2 HEALTH_TTL_MIN=1440 ROUTING_REQUIRE_RANKED=1 npm run ci:aggregate:prlite`
5) 메트릭 확인(요약 JSON): 브라우저/HTTP로 `/api/metrics/summary`
6) 라우팅 스냅샷: 브라우저/HTTP로 `/api/metrics/routing?service=chat`

### CI 사용법(선택적)
- 저장소 변수로 활성화: `CI_SMOKE_ENABLE`, `CI_MONITOR_POLL_ENABLE`, `CI_QUALITY_LIGHT_ENABLE`, `CI_PR_LITE_ENABLE`
- 워크플로 파일: `smoke-distributed.yml`, `monitoring-poll.yml`, `quality-light.yml`, `pr-lite.yml`

---

## P1 스트림별 상세 계획

다음 4개 스트림 중 병렬로 진행 가능. 각 항목은 “배경 → 대상 파일/코드 → 작업 절차 → 검증/수락 기준 → 롤백/주의사항” 순서로 기재합니다.

### A. LLM Routing / Key Management 고도화
- 배경: 비용·지연·오류율 기반 라우팅 정밀화, 키 관리 정책/감사 강화
- 대상
  - Edge Functions: `supabase/functions/router-select/index.ts`, `supabase/functions/key-vault/index.ts`
  - Supabase 테이블: `llm_providers`, `llm_models`, `routing_policies`, `provider_health`, `secure_keys`, `secure_keys_audit`
  - 스크립트: `src/scripts/llm/updateProviderHealth.ts`, `src/scripts/llm/setModelCosts.ts`
- 작업 절차
  1) 모델 메타데이터 확장: 입력/출력 토큰 별 단가, region 가중치, cold-start penalty 필드 추가(DB metadata 컬럼 활용)
  2) 라우팅 점수식 개선: 정책 페널티(deny, max_latency, max_error_rate) + 비용 가중 + region 선호도 + 최근 오류률 상승 시 백오프
  3) 의도 모델 고정 시 예외 처리: intended 모델이 정책/건강 불합이면 대체 후보로 graceful degrade
  4) 키 밸트: 쓰기 시 체크섬 저장, 읽기 시 유효성·만료 검사, `secure_keys_audit` 이벤트 세분화(read/write/fail)
  5) 헬스 업데이트: 실패 샘플 비율 상한, 타임아웃/네트워크 오류 별도 집계
- 검증/수락 기준
  - `npm run llm:health` 실행 시 `provider_health` 갱신, 라우터 후보 랭크 변화 확인(`/api/metrics/routing?service=chat`)
  - `ci:smoke:distributed`에서 intended/비-intended 모두 정상 응답 및 4xx/5xx 재시도/대체 라우팅 동작
- 롤백/주의
  - 점수식 변경은 feature flag로 가드: `ROUTER_SCORE_V2=true`
  - 키 업서트는 새 `version_int` 사용 후 점진 전환

### B. Indexing / Search 확장
- 배경: 코드/문서 하이브리드 검색 품질 향상(BGE-M3 + 키워드), 언어 확장(Tree-sitter)
- 대상
  - 워커: `src/workers/IndexingJobWorker.ts`
  - 임베딩/스토어: `src/agents/indexing/embeddings/*`, `src/knowledge/SupabaseVectorStore.ts`
  - 스크립트: `src/scripts/quality/runCodeSearch.ts`
- 작업 절차
  1) Tree-sitter 파서 확장: Python/TypeScript 추가 태그 추출(클래스/함수/임포트)
  2) 문서/코드 메타 태깅 표준화: `metadata.tags` 스키마 정리, 경로/언어/심볼 타입 포함
  3) 하이브리드 검색: 키워드 인덱싱 컬럼 추가 및 랭킹 결합(간단 가중 합산 → 이후 BM25)
  4) 인덱싱 잡 재시도/idempotency 강화, 미세 청크 전략(헤더 경계 기반)
- 검증/수락 기준
  - `npm run test:e2e:indexing` 및 `quality:code-search` 태그 질의가 샘플 결과 반환
  - `/api/search/code?q=SymbolName` 응답에 태그/경로 포함
- 롤백/주의
  - 새로운 컬럼/지표는 마이그레이션 스크립트와 역마이그레이션 동반

### C. Quality Expansion(시나리오/크리틱 강화)
- 배경: 시나리오 기반 품질 측정 폭 확장, 자동 크리틱 가중 정책 개선
- 대상
  - 러너: `src/scripts/quality/runScenario.ts`, `src/scripts/quality/runAllScenarios.ts`, `src/scripts/quality/runLight.ts`
  - 크리틱: `GroundednessCritic`, `CitationCritic`, `CompileCritic`, `SimpleContractCritic`
  - 시나리오: `scenarios/*.json`
- 작업 절차
  1) 시나리오 10→15개 확대, 도메인 라벨·성공 조건 명확화
  2) 가중 정책 기본값 문서화 및 환경변수로 노출(`W_*`)
  3) 리포트 집계(통과율, 실패 상위 Top-N) JSON 생성, 아티팩트 업로드 표준화
- 검증/수락 기준
  - `quality:run:all` 그린, 요약 리포트 생성(`reports/quality/*`)
- 롤백/주의
  - 시나리오 추가는 점진 적용, 불안정 항목은 `skip: true` 플래그로 관리

### D. Reliability / Observability 강화
- 배경: 운영 신뢰성(상태기계/사가/보상, DLQ), 실시간 지표 확장
- 대상
  - 메트릭 서버: `src/servers/metrics/index.ts` + `routes/*`
  - 메트릭: `src/services/metrics/Metrics.ts`
  - 상태 기계/메시지 스펙: `docs/specs/*`
- 작업 절차
  1) Job 상태 전이 로깅/이벤트 일관성 점검, DLQ 사유 코드 표준화
  2) 메트릭 추가: 도구별 p95, 단계별 재시도/실패, 비용 누적, LLM 토큰/비용
  3) `/api/metrics/*` 응답에 타임윈도우 파라미터 지원(from/to), 라우팅 스냅샷 `/api/metrics/routing`
- 검증/수락 기준
  - `monitor:poll` OK, 신규 메트릭 값 수집 및 `/metrics` 노출
- 롤백/주의
  - 지표 명세 변경 시 대시보드 스케치 문서 갱신

---

## 실행·검증 체크리스트(항목별 공통)
1) 브랜치 규칙 준수( 최소 보호 규칙 ) → PR 생성
2) 스키마/함수/스크립트 변경 → 로컬 테스트(원샷 or 개별)
3) CI Optional 스위트 수동 트리거(필요 시 저장소 변수 활성화)
4) 아티팩트 및 PR 코멘트 확인(스모크/모니터/품질)
5) 게이트 집계(`ci:aggregate:prlite`) 통과 시 머지
6) 메트릭 검증: `/metrics` 노출, `/api/metrics/summary` 토탈 증가(claims/conflicts/retries/dlq), `cogo_llm_tokens_total`, `cogo_llm_cost_usd_total` 갱신 확인
7) 라우팅 검증: `/api/metrics/routing?service=chat`에 상위 후보와 점수/비용/지연 노출

### 실패 시 롤백 가이드
- Edge Functions: 이전 버전 function 디렉터리로 되돌린 뒤 재배포
- Supabase 스키마: 역마이그레이션 SQL 적용
- 라우팅 정책: `routing_policies.enabled=false`로 즉시 비활성화

---

## 파일·명령 빠른 인덱스(자주 쓰는 것)
- 원샷 PR-Lite: `npm run ci:run:prlite:local`
- 단위 실행: `ci:smoke:distributed`, `monitor:poll`, `quality:run:light`, `ci:aggregate:prlite`
- LLM 헬스/비용: `npm run llm:health`, `npm run llm:costs`
- 메트릭 서버: `npm run server:metrics`
- 인덱싱 워커: `npm run worker:index`

---

## 부록: 임계값/변수 표(요약)
- QUALITY_MIN_RAN: 품질 라이트 최소 시나리오 수(기본 1)
- HEALTH_TTL_MIN: provider_health 허용 최신성(분, 기본 1440)
- ROUTING_REQUIRE_RANKED: 라우터 후보 최소 개수(기본 1)
- W_GROUNDEDNESS/W_CITATION/W_COMPILE/W_CONTRACT: 게이트 가중치

이 문서를 따라 작업하면 세션이 끊겨도 `빠른 상태 점검 명령어`와 `P1 스트림별 상세 계획`을 통해 즉시 재개할 수 있습니다.


