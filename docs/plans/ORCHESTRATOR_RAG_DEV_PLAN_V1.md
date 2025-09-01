## Orchestrator + Knowledge-first RAG Development Plan (V1)

### 목표/범위
- 분산 Orchestrator가 이벤트 기반으로 역할(intent)을 자율 결정하고, 역할별 템플릿으로 RAG 응답을 생성하며, Critics/Gates로 품질을 담보하고 실패 시 자율 보정한다.
- 계층형 LLM 라우팅(저비용→고성능)과 GraphRAG(코드·스키마 도달성)를 결합해 상용 수준의 지연/비용/품질 균형을 달성한다.

### 진행 현황(요약)
- Orchestrator 결정 E2E: 최신 `decision` 이벤트 생성 확인(로그 저장)
- ChatGatewayWorker 운영: Realtime+Polling 정상, assistant 지속 삽입/HEALTH 로그 확인
- RAG JSON Strict: 중앙 Key-Vault 포함 스모크 2/2 통과
- Vector RPC: `match_code_vectors`(dim=1020), `get_vector_dim()` 배포·검증 완료
- Schema 링크: 실제 링크 76/1000(7.6%), reachable 7.4% (분석 기준)

### 핵심 설계(알고리즘)
- Hybrid(규칙 + 경량 LLM 분류 + Bandit) + Actor‑Critic‑Gate + GraphRAG
  - 규칙: 키워드/도메인(예: `schema`, `table`, `columns`, `sql`, `foreign key` → `schema.rag`)
  - 경량 LLM(Gemini 2.5 Flash Lite): 모호할 때 1‑shot JSON 분류(의도·confidence·must_include)
  - Bandit(후속): 실패 유형별 행동(증거주입/재색인/모델전환/프롬프트 보정) 탐색 최적화
  - GraphRAG: vector+keyword → Neo4j hop‑expansion(`contains/calls/uses_schema`) → rerank
  - Critics/Gates: compile/groundedness/citation → 실패 시 자율 보정 루프

### 모델 계층(제안)
- Chat/경량 판단: Gemini 2.5 Flash Lite
- Plan/Design/리스크: Claude Sonnet 4 (2025‑05‑14)
  - 최종 확정 전 평가 대상: GPT‑5(가용 시), Gemini 2.5 Pro
- Code/Debug/리팩토링: Qwen3 Coder(Fireworks)
- 폴백: Haiku → GPT‑4o‑mini → Qwen (라우터/헬스/쿨다운 반영)

### 역할 판단(RoleDecider)
- 입력: 사용자 요청/메타(RAG 신호)
- 출력(JSON): `intent`(chat|plan.design|code.debug|schema.rag), `confidence`, `must_include[]`, `constraints`
- 순서: Rule → Gemini 분류(JSON Strict) → RAG 힌트로 보정
- 파일: `src/orchestrator/RoleDecider.ts` (신규)

### 프롬프트 템플릿(역할별)
- 공통: JSON Strict(필드: intent, answer, citations[], confidence, actions[]), 근거는 citations[]에만
- Chat(Gemini): 간결/결정론/증거부족 시 선언
- Plan/Design(GPT‑5): 계획/위험/마일스톤/액션(JSON actions) + 근거
- Code/Debug(Qwen): 최소 edits/컴파일·테스트 전략 + 근거
- 저장: `docs/prompts/{chat,plan,code}.md` / 매핑: `src/orchestrator/PromptRegistry.ts`
- 기존 “소스 생성 role/프롬프트” 반영(필수 리뷰):
  - 위치/이름/의도/출력/제약 인벤토리화 → 템플릿에 병합 → 변경 체크리스트로 검증

### 실행 플로우(라이브 통합)
1) `orchestratorLive.ts`에서 Job/Chat 이벤트 수신 → RoleDecider → PromptRegistry 로드 → `askRag`(MUST_INCLUDE/증거주입/JSON Strict)
2) Critics/Gates(compile, groundedness, citation) → 실패 타입 매핑(증거보강/재색인/링크/모델 교체/프롬프트 보정)
3) Job 상태 FSM(queued→running→succeeded/retrying/dlq), 레이트/오버로드 쿨다운, 임대/복구/타임아웃 관리

### 큐/실행 분리(Plan vs Work)
- 목적: 계획/디자인과 실행(코드/빌드/테스트)을 분리해 지연·비용·장애 격리 및 SLO 차등 적용
- 방법: 단일 `jobs` 테이블 유지, `executor_id`로 분리 운영
  - Plan 큐: `EXECUTOR_PLAN_ID=cogo-plan` (job: `orchestrator.decide(plan)`, `figma.*` 등)
  - Work 큐: `EXECUTOR_WORK_ID=cogo-work` (job: `code.debug`, `code.build.test`, `index.*` 등)
- 워커: 오케스트레이터를 executor별로 별도 프로세스 기동
- 대시보드: `/api/jobs/recent?executor=cogo-plan|cogo-work` 카드 분리

### RAG/스키마 파이프라인(운영)
- SQL 인제스터(`schema:ingest:sql`)로 테이블/컬럼/FK를 `schema.sql.table`로 KG 반영
- 링크(`schema:link`): 스코어링/룰맵으로 `uses_schema` 생성
- 분석(`quality:analyze:schemaLinks`): 잠재 상한/도달성/권장 목표 산출

### 품질/메트릭/수용 기준
- JSON Strict 실패율 < 1%
- Groundedness ≥ 0.9, Citation Precision ≥ 0.9, Evidence 부족율 < 5%
- p95 end‑to‑end < 10s(단일 작업), DLQ < 1%
- Link coverage/Reachable paths: 현 7.6%/7.4% → 1차 목표 10%/10%
- 메트릭: Routing accuracy, JSON failure, groundedness, citation precision/recall, evidence 부족율, p95 latency, cost/task, retry 성공률, link coverage/reachables

### 평가 시나리오(스모크/리그레션)
- A. Schema Q&A(운영 경로/MUST_INCLUDE/SQL 증거) → 100% 정확
- B. Plan/Design(GPT‑5) → 액션·리스크·citation 포함
- C. Code/Debug(Qwen) → 최소 edits/컴파일 패스
- D. Rate‑limit/Overload → 폴백/쿨다운 성공률·지연
- E. Graph 도달성 → calls→uses_schema 경로 존재 검증

### 타임라인(권장)
- D+0: Orchestrator E2E/Worker/RAG Strict/Vector RPC/Schema Link/중앙 스모크 CI 기동
- D+1: RoleDecider PoC, PromptRegistry 초안, 라우팅 매핑, `smoke:schema:ask` CI 추가
- D+2: Orchestrator 통합(역할 훅/지연 튜닝), Critics 연결
- D+3: 메트릭/대시보드, 링크 파이프라인 주기화, 기존 프롬프트 전수 리뷰 반영

### 체크리스트(필수)
- [ ] RoleDecider: 룰/경량 분류 JSON Strict 준수(샘플 30개 ≥ 90% 일치)
- [ ] PromptRegistry: 각 역할 템플릿 JSON 계약·금지규칙·MUST_INCLUDE 반영
- [ ] 기존 “소스 생성 role/프롬프트” 대조표 작성·리뷰 통과
- [x] Critics/Gates 활성화 및 실패→보정 액션 경로 시험
- [ ] 스모크 4종(chat/plan/code/schema) CI 통과

### 실행 커맨드(요약)
- 스키마 파이프라인: `npm run -s schema:ingest:sql && npm run -s schema:link && npm run -s quality:analyze:schemaLinks`
- 링크/분석(직접): `npx ts-node src/scripts/schema/linkCodeToSchemas.ts && npx ts-node src/scripts/quality/analyzeSchemaLinks.ts`
- RAG 스모크(중앙): `npx ts-node src/scripts/rag/smokeCheckJsonStrict.ts`
- 오케(라이브 E2E): `npm run orchestrator:e2e:decide -- "<question>"`
- CI 스모크(오케): `npm run smoke:orchestrator:decide`
- ChatGatewayWorker: `npx ts-node src/workers/ChatGatewayWorker.ts`

### 운영 스위치 & 환경 변수(권장)
- 라우터/키관리:
  - `ROUTER_SELECT_URL=$SUPABASE_URL/functions/v1/router-select`
  - `KEY_VAULT_URL=$SUPABASE_URL/functions/v1/key-vault`
- 오케스트레이터/RAG:
  - `ORCHESTRATOR_DECIDE_ANSWER=true` (결정 직후 답변 생성/게이트 평가)
  - `RAG_FORCE_LOCAL=true|false` (로컬 폴백 사용)
  - `RAG_INTENDED_MODEL=haiku|sonnet|...` (라우팅 힌트)
- 프로바이더 차단(무키 환경 대비):
  - `DISABLE_OPENAI=true`, `DISABLE_ANTHROPIC=true`, `DISABLE_GEMINI=true`, `DISABLE_FIREWORKS=true`
- ChatGateway 위임:
  - `CHAT_DELEGATE_TO_ORCHESTRATOR=true`
  - `CHAT_ORCHESTRATOR_TIMEOUT_MS=8000`

### 스모크/검증 명령(실서비스 라우팅)
- 실모델 스모크(E2E):
```bash
ROUTER_SELECT_URL=$SUPABASE_URL/functions/v1/router-select \
KEY_VAULT_URL=$SUPABASE_URL/functions/v1/key-vault \
SUPABASE_URL=$SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY=$SUPABASE_SERVICE_ROLE_KEY \
DISABLE_OPENAI=true npm run -s smoke:orchestrator:decide:real
```
- 의도 행렬 스모크(로컬 폴백 허용): `npm run -s smoke:intent:matrix`
- Gemini 단독 스모크: `GEMINI_API_KEY=... npm run -s llm:gemini:smoke`

### 모델 선택 평가 계획(Pre‑GA)
- 목표: 상용 서비스 출시 전, plan/design 의사결정 모델을 Claude Sonnet 4, GPT‑5(가용 시), Gemini 2.5 Pro 중에서 비교 평가해 최종 확정
- 범위: 계획 정확도, 액션 품질, 근거/인용 정확도, 비용/지연 균형
- 실행:
  - 비교 스크립트: `npm run -s plan:compare:models`
  - 라우팅 스모크: `npm run -s smoke:intent:real` (의도/라우팅), `npm run -s smoke:gate:fix` (게이트 보정), `npm run -s smoke:plan:code` (plan→code 체인)
- 결정: 충분한 테스트/리뷰 후 최종 모델 확정. 확정 전까지 기본(plan/design)은 Claude Sonnet 4 사용

### Chat API(테스트용)
- `POST /api/chat/session` → `{ ok, session }` (새 세션 생성)
- `POST /api/chat/message` (body: `{ session_id, text }`) → `{ ok, message }`
- `GET /api/chat/:sessionId/messages` → `{ ok, rows }`

### 대시보드 요약 API
- `GET /api/metrics/summary` (jobs/cbo 요약)
- `GET /api/jobs/recent`, `GET /api/jobs/:id/events`

### 참고 문서(링크)
- RAG JSON 계약: `docs/specs/LLM_RESPONSE_JSON_V1.md`
- 자기 보정 루프: `docs/specs/SELF_CORRECTION_FEEDBACK_LOOP_V1.md`
- Supabase Chat/Feedback 스키마: `docs/specs/SUPABASE_CHAT_AND_FEEDBACK_SCHEMA_V1.md`
- CBO 스키마: `docs/schemas/CBO_SCHEMA.md`
- 로드맵/허브: `docs/DEVELOPMENT_EXECUTION_PLAN_NEXT.md`, `docs/plans/PROJECT_ROADMAP_KG_CHAT.md`


