## Development Plan – Actor–Critic RAG (V1)

목적: JSON 표준화된 Actor–Critic–Gate 루프와 자가강화형 RAG를 Supabase·Neo4j에 연결해, 새로운 세션에서도 이 문서만으로 즉시 개발을 시작할 수 있도록 상세 절차를 제공한다. COGO 방법론(DTA/DSL/#symbol)에 정합한다.

---

### 0) 개발 방법론(핵심→확대, 사전 분리)
- 핵심 개발 우선(Critical Path 우선): 최소 기능(Actor–Critic–Gate + RAG + 관측) 완성 전까지 범위를 넓히지 않는다
- 확대 단계는 핵심 완료 이후(P1/P2로 분리): 브랜치/예산/대시보드/도메인 Critics 등은 후속
- 서비스 오픈 전 항목은 별도 문서로 관리: 운영/보안/암호화/정책/대시보드를 Pre-Launch Checklist로 분리
  - 참조: `docs/plans/CORE_CRITICAL_PATH_V1.md`(핵심 경로), `docs/LAUNCH_CHECKLIST.md`(오픈 전 목록)

---

### 1) 개요와 성공 기준
- 핵심 아이디어: LLM의 생각(thinking)을 도구가 평가 가능한 구조화 JSON으로 표준화하고(Thinking as Data), Critics(정적/동적/도메인)가 자동 판정, Gate가 정책으로 승인/수정/분기를 결정한다.
- 성공 기준(P0)
  - JSON 메시지(Envelope/PlanStep/ToolResult/Critique/GateDecision)로 최소 1회 E2E 실행 이벤트가 Supabase에 기록됨
  - Static Critics(compile/typecheck/lint) 강제 및 1회 자동수리 동작
  - Neo4j에 Plan/Step/Thought/Tool/Run 1-hop 노드/엣지 생성
  - SLA p50/p95, 실패율, 재시도, 비용 메트릭 노출

---

### 2) 아키텍처(텍스트 다이어그램)
COGO Agent Core → Orchestrator(Actor–Critic–Gate)
- Actor: PlanStep(JSON) 생성 → ToolPlan 실행 → ToolResult(JSON)
- Critics: 결과를 기준(assertions/success_criteria)으로 판정 → Critique(JSON)
- Gate: 정책(all_required_critics_pass 등)으로 commit/retry/branch → GateDecision(JSON)
- Storage: Supabase(plans/plan_steps/tool_runs/critic_verdicts/branch_tree), Neo4j(Plan/Step/Thought/Tool/Run)

---

### 3) JSON 메시지 표준(요지)
- 공통 Envelope: version/id/correlation_id/trace_id/role/type/timestamp/payload
- Actor PlanStep.payload: step_id, intent, hypothesis, expected_outcome, assertions[], tool_plan[], rollback_plan, confidence, budget
- ToolResult.payload: step_id, tool_run_id, tool, args_hash, result{status,latency_ms,body}, metrics{tokens,cost}
- Critique.payload: step_id, critic, verdict(pass|fail|warn), score, checked[], evidence[], fixes[], cost
- GateDecision.payload: step_id, gate_policy, decision(commit|retry|branch|abort), next_action
- 참고: `docs/specs/THINKING_AS_DATA_AND_ACTOR_CRITIC_V1.md` 예시 수록

---

### 4) 데이터 스키마(이미 제공/적용)
- Supabase: `docs/supabase/sql/DEEP_AGENTS_SCHEMA.sql`
  - plans, plan_steps, tool_runs, critic_verdicts, branch_tree, agent_subagents, agent_tools, file_snapshots
- Supabase: `docs/supabase/sql/ROUTING_POLICIES_V2.sql`(merge_strategy, valid_from/to)
- Neo4j: Plan/Step/Thought/Critique/Tool/InductiveBias + Agent/Task/Artifact/Knowledge 제약/인덱스 적용됨

---

### 5) 구현 체크리스트(파일 단위)
아래 경로/이름은 권장안이며, 변경 시 문서 동시 갱신.

5.1 타입·밸리데이터(런타임 검증)
- `src/types/actorCritic/MessageEnvelope.ts`
- `src/types/actorCritic/PlanStep.ts`
- `src/types/actorCritic/ToolResult.ts`
- `src/types/actorCritic/Critique.ts`
- `src/types/actorCritic/GateDecision.ts`
- 각 파일에 TS 타입, JSON Schema, `is*` 타입가드, `validate*` 유틸 포함

5.2 이벤트 저장 유틸(모듈화)
- `src/services/events/SupabaseEventWriter.ts`
  - writePlan/ writeStep/ writeToolRun/ writeCritique/ writeGateDecision
- `src/services/events/Neo4jEventWriter.ts`
  - upsertPlan/ upsertStep/ linkThought/ linkToolRun(최소 1-hop)
- `src/services/events/EventBus.ts`
  - 위 라이터들을 묶어 트랜잭션적 호출(In best-effort)

5.3 Critics & Gate
- `src/services/critics/CompileCritic.ts`(tsc)
- `src/services/critics/TypecheckCritic.ts`(tsc-noEmit 또는 tsserver)
- `src/services/critics/LintCritic.ts`(eslint)
- `src/services/gate/GateEngine.ts`(정책 엔진: all_required_critics_pass, weighted_threshold)
  - 입력: Critique[], 예산(토큰/비용/시간), 컨텍스트
  - 출력: GateDecision

5.4 배선(훅 추가)
- 인덱싱 워커: `src/workers/IndexingJobWorker.ts`
  - 파일 단위 처리 시작/성공/실패 시 PlanStep/ToolResult/Critique/GateDecision 이벤트 방출
- LLM 호출 경로: `src/scripts/llm/chatReal.ts`, `src/scripts/llm/embedReal.ts`
  - 호출 전 PlanStep, 호출 후 ToolResult, 계약 검증 Critique, GateDecision 기록

5.5 관측(메트릭)
- `src/services/metrics/Metrics.ts` 확장
  - stepLatencyHistogram, toolLatencyHistogram, stepFailureCounter, retryCounter, costCounter
  - 라이터·크리틱·게이트에서 관측치 업데이트

---

### 6) 실행 절차(새 세션용)
사전: Supabase URL/Keys, Edge URLs, Neo4j 접속, 키 Vault 등록 완료 상태

1. 색인·리트리버 스모크(이미 존재 스크립트)
- 문서/코드 임베딩: `npm run vectors:embed`
- 유사 검색: `npm run vectors:search -- "Metrics"`

2. LLM 경로 스모크(이미 존재 스크립트)
- 임베딩 실호출: `npm run llm:embed:real -- openai/text-embedding-3-large "hello"`
- 채팅 실호출: `npm run llm:chat:real -- anthropic/claude-3.5-sonnet "Say hello"`

3. Actor–Critic–Gate 경로 스모크(구현 후)
- Indexing 워커 실행 → 이벤트가 Supabase/Neo4j에 적재되는지 확인
- LLM 호출 스크립트 실행 → PlanStep/ToolResult/Critique/GateDecision 이벤트 확인

4. 관측 확인
- `/metrics` 히스토그램/카운터에 Step/ToolRun SLA/실패/재시도/비용 반영

---

### 7) 수용 기준(상세)
- 이벤트
  - Envelope/PlanStep/ToolResult/Critique/GateDecision 저장 및 상호 참조 키(step_id, run_id) 일관
  - evidence는 결과 참조(툴 런, 로그, 아티팩트 해시)로 남김
- 크리틱/게이트
  - 필수 Static Critics 패스 없이는 Gate commit 금지
  - 실패 시 1회 수리 후 재판정, GateDecision 기록
- 메트릭/대시보드
  - Step p50/p95, 실패율, 재시도, cost-per-success 최소 1개 플로우에 대해 시각화 가능

---

### 8) COGO 방법론 정합성
- DTA/DSL 산출물을 플랜 산출 아티팩트로 관리, DSLValidator 규칙 통과 의무
- #symbol 스코프 준수 및 바인딩(#__appData/#__uiState/#__tempData)
- Supabase에 산출물 메타 링크(artifacts↔plan_steps/tool_runs/critic_verdicts)

---

### 9) 리스크·대응
- 이벤트 과다로 인한 오버헤드 → 비동기/배치/샘플링
- 플래키 크리틱 → precision/recall 모니터링, 격리/완화
- 비용 상향 → 예산 가드(토큰/비용/시간) 및 라우팅 정책 조정

---

### 10) 일정(2–3 스프린트)
- 스프린트 1(P0 코어): 타입/밸리데이터, 이벤트 라이터, Static Critics, 배선, 기본 메트릭
- 스프린트 2(P1 MVP): Beam=2 분기, 예산/시간 가드, 대시보드, CI 스모크
- 스프린트 3(P2 준비): 도메인 Critics 슬롯, 암호화/KMS, 프록시/쿼터

부록 A. 참고 파일
- 설계: `docs/specs/THINKING_AS_DATA_AND_ACTOR_CRITIC_V1.md`
- Supabase SQL: `docs/supabase/sql/DEEP_AGENTS_SCHEMA.sql`, `docs/supabase/sql/ROUTING_POLICIES_V2.sql`
- 기능 문서: `docs/ENV_SETUP.md`, `docs/LAUNCH_CHECKLIST.md`, `docs/DEVELOPMENT_EXECUTION_PLAN_VNEXT.md`


