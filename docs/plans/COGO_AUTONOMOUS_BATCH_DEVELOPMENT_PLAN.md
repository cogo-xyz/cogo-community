# COGO 자율·지식+지능 분산형 Agentic 플랫폼 배치 개발 계획서

## 0. 개요
- **목표**: Edge-first + Realtime 기반의 분산 에이전틱(cogo-agent)과 cogo-platform을 결합하여, JSON-first(UX/UI, Data, Action & Action Flow) 앱 합성과 자율 업그레이드(CBO 루프)를 실현.
- **근거 문서**: `docs/design/COGO_AUTONOMOUS_DISTRIBUTED_AGENTIC_PLAN.md`
- **완료 기준(상위)**
  - Edge/Orchestrator/분산 에이전트 스모크 및 관측 게이트 녹색
  - 합성 JSON v1 스키마 고정, 렌더/액션 성공률 목표 달성
  - CBO 루프 1차 도입(드리프트 감지→개선 제안→가드 배포)

---

## 1. 배치 구조(마일스톤)
- **M1: Edge-first 안정화(완료+보강, 1주)**
  - 목표: 표준 에러/멱등성/SSE/관측 스펙 고정, 오케스트레이터 녹색 유지
  - 게이트: `smoke:edge:observability`, `edge_orch_graph_bundle` 녹색
- **M2: 분산 에이전트 리팩토링(2주)**
  - 대상: Indexing/Research/Executor/GraphRAG을 Edge-first 패턴으로 통일
  - 게이트: 에이전트별 E2E P95 ≤ 5s, 에러율 < 1%
- **M3: 합성 MVP(2~3주)**
  - 산출: UI/Data/Action/Action Flow JSON v1, Fusion/Renderer/Action Runner, LangGraph 합성 노드
  - 게이트: 렌더/액션 성공률 ≥ 95%, 근거 불일치 ≤ 5%, E2E P95 ≤ 5s
- **M4: 플랫폼 통합(1주)**
  - 내용: 디렉토리 개편(move-only) + cogo-platform 모듈 경계 정립, 문서/CI 경로 갱신
  - 게이트: 전체 스모크 녹색, 경로 누락 테스트 통과
- **M5: CBO 자율 업그레이드 루프(2주)**
  - 내용: 드리프트 감지, 개선 제안, 가드 롤아웃(플래그/카나리), 회귀/롤백 자동화
  - 게이트: 제안→승인→배포 성공률 ≥ 90%, 회귀 실패율 ≤ 5%
- **M6: 품질/관측/보안 강화(지속)**
  - 내용: SLO/대시보드/비용 관리/시크릿 스캔/레이트리밋

---

## 2. M1: Edge-first 안정화(보강)
- **범위**: Edge Functions(chat/embed/rag/role-select/graph), Node 클라이언트, 오케스트레이터 증거 주입/백오프/타임아웃, 관측 번들
- **주요 작업**
  - 에러 포맷 `{ok,error,code,via}` · 멱등성 `idempotency-key` · SSE 메타 이벤트 검증 스모크 보강
  - Metrics 서버와 trace 상관 검증, bus_events 집계 확인
- **게이트/체크**
  - `npm run -s smoke:edge:observability` / `edge_orch_graph_bundle` 녹색
  - Neo4j 제약/백업 스크립트 성공, 환경 검증 통과

---

## 3. M2: 분산 에이전트 리팩토링(공통 체크리스트)
- **공통 원칙**
  - Edge-first 호출 집약(LLM/RAG/Embed/Role-select → Edge Functions 클라이언트)
  - Realtime Jobs: enqueue→lease/claim→execute→result; idempotency; DLQ
  - 관측/회복력: trace/idempotency 전파, 재시도·지수 백오프·타임아웃, 표준 에러 매핑
- **에이전트별**
  - Indexing: 파일 스캔→청킹→BGE-M3 임베딩→pgvector 적재, Neo4j 구조/관계 쓰기, 증분 인덱싱/아티팩트 보관
  - Research: 하이브리드 RAG 전략 라우팅, 외부 커넥터 키·레이트리밋 표준화
  - Executor: 샌드박스 실행 격리, 리소스 제한, 결과 아티팩트 표준화
  - GraphRAG: Neo4j HTTP v2 접근, 타임아웃/에러 표준화, 캐시/쿼터 고려
- **수정 포인트**
  - 채널 네이밍/Presence/Broadcast/DB 트리거 연결
  - `WorkerLink`/`SupabaseRealtimeBus`/`ExecutorDispatcher` 재점검 및 통일 인터페이스 도입
- **게이트**
  - 에이전트 스모크: P95 ≤ 5s, 성공률 ≥ 95%, 에러율 < 1%
  - 번들 스모크(분산 전체): enqueue→claim→execute→result 성공율 ≥ 95%

---

## 4. M3: 합성 MVP(증거→JSON→검증)
- **산출물**
  - JSON 스키마 v1: UI JSON / Data JSON / Action JSON / Action Flow JSON
  - Fusion 레이어: Evidence→JSON 합성 모듈(정책/제약 반영), 근거 인용 강제
  - Renderer/Action Runner 샌드박스: 헤드리스 렌더, 액션 드라이런/모의 권한
  - LangGraph 노드: `synthesize_json` → `validate_render` → `gate_rollout`
- **스모크/게이트**
  - 렌더 성공률 ≥ 95%, 액션 성공률 ≥ 95%, 근거 불일치 ≤ 5%, E2E P95 ≤ 5s
  - Golden 스냅샷 비교 + 스키마 적합성 검사 통과
- **참고 실행**
  - Figma 인제스트: `npm run -s smoke:ingest:full`
  - 컨텍스트 검증: `npm run -s figma:verify:sse` / 상태: `npm run -s figma:status:smoke`

---

## 5. M4: 플랫폼 통합(디렉토리 개편)
- **구조(예시)**
  - `src/agents/*`, `src/orchestrator/*`
  - `src/platform/{vectors,graph,blueprint,ui-render,action-runner}`
  - `src/app/*(api)`, 필요 시 `packages/*`(workspace)
- **절차**
  1) 브랜치 `repo-structure-platform-ready` 생성
  2) `git mv` 기반 move-only 변경(로직 불변) → tsconfig paths/CI 경로 업데이트 → barrel 호환층
  3) 전체 스모크/빌드/린트 녹색 확인 → 문서/런북 경로 갱신
- **게이트**
  - 스모크 번들 녹색, 경로 누락 테스트 녹색

---

## 6. M5: CBO 자율 업그레이드 루프
- **구성**
  - 매핑: UI/Data/Action/Flow JSON → CBO(구조/제약/품질/워크플로)
  - Drift 감지: 품질 저하·오류 패턴 수집 → 개선 제안 생성
  - 가드 배포: 플래그/카나리, 회귀 스냅샷/품질 게이트/롤백 자동화
- **게이트**
  - 제안→승인→배포 성공률 ≥ 90%, 회귀 실패율 ≤ 5%

---

## 7. 품질·관측·보안(지속)
- **지표(KPI)**
  - RAG: hit@k, MRR, groundedness(근거 일치)
  - 합성: 렌더/액션 성공률, 스키마 위반율
  - 오케스트레이션: P50/P95, 성공율, 재시도·DLQ 비율, 비용/토큰
  - 분산: TTR, 중복 실행률(멱등), 임대 만료 복구 건수
  - 보안: 시크릿 스캔(0 크리티컬), RLS·레이트리밋 이벤트
  - 가치/UX: 태스크 완료율/시간, 롤백 비율, 채택 지표
- **대시보드**: Trace 카드, 품질 카드, 비용 카드, 에러 상관분석 카드

---

## 8. 일정(제안) 및 배치 순서
- **주차 1~2**: M1 보강 + M2 공통 리팩토링(Executor/Indexing 우선)
- **주차 3~4**: M2 잔여(Research/GraphRAG) + M3 합성 MVP
- **주차 5**: M4 플랫폼 통합(move-only)
- **주차 6**: M5 CBO 루프 1차 + 품질 게이트 확대
- **지속**: M6 품질/관측/보안 고도화

---

## 9. 위험/완화
- **도메인 문서 품질 편차**: 전처리/요약/품질 게이트 도입
- **합성 취약성**: Golden·렌더/액션 회귀, 단계적 롤아웃
- **분산 복잡성**: 임대/복구 시뮬/혼잡·네트워크 장애 주입, DLQ 경로 검증
- **리팩토링 영향**: move-only 분리, 호환 barrel 유지, 브랜치 전략/코드프리즈 창 설정

---

## 10. 운영 전략
- **릴리즈**: 태그 컷 → move-only PR → 기능 PR 단계 분리
- **플래그**: 합성/액션/업그레이드 기능 플래그로 점진 활성화
- **CI**: 품질 게이트(합성/RAG/분산)와 보안 스캔 상시 실행
- **문서화**: 설계/런북/운영 가이드 업데이트, 샘플/골든 유지

---

## 11. 실행 체크리스트(요약)
- Edge/Orchestrator 스펙 고정 및 관측 녹색
- 분산 에이전트 Edge-first 리팩토링 공통 체크 완료
- JSON v1 + Fusion/Renderer/Runner + LangGraph 노드
- 플랫폼 디렉토리 개편(move-only) 후 녹색
- CBO 루프 1차 도입 및 게이트 설치
- 품질/관측/보안 대시보드 및 스캔 상시화
