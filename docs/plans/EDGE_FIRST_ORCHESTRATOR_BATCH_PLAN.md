# Edge-first Orchestrator – Batch Development Plan

Updated: 2025-08-23

## Milestone Overview
- M0 (done): Graph env-only, secure_keys hot-path 제거, agents Edge 연결
- M1: Role-select Edge化 + RAG 소스 통일
- M2: Chat/Embed/RAG Edge 표준화(SSE/headers/idempotency)
- M3: LangGraph edge_call 노드 + 재시도/보상
- M4: Realtime event bus(Trace 채널), 관찰성/게이트
- M5: Legacy 제거/정리, 문서화, 버전 태깅

## Batch 1 (M1)
- Deliverables
  - Edge `/role/select` (SSE, intent→role_id)
  - 역할 패키지/프롬프트 RAG 저장(JSON) + Edge 조회
  - Orchestrator RoleDecider → Edge 호출 전환
- Gates
  - p50<1500ms, error<2%, SSE 정상 스트림

## Batch 2 (M2)
- Deliverables
  - `/chat`, `/embed`, `/rag` Edge 공통 헤더/리밋/백오프/유휴타임아웃
  - idempotency-key 도입 → 중복 방지
  - artifacts 저장(프롬프트/토큰/partial)
- Gates
  - 부하 N=100(동시 20), 실패율<3%

## Batch 3 (M3)
- Deliverables
  - `edge_call` 노드 타입(LangGraphWorkflowEngine)
  - 노드별 timeout, retry, compensate 옵션 처리
  - Planner/Executor에서 로컬 LLM 호출 제거
- Gates
  - 워크플로우 전부 Edge 경유로 통과, 회귀테스트 OK

## Batch 4 (M4)
- Deliverables
  - Realtime 채널: `trace:{trace_id}`/`task:{task_id}` 설계 반영
  - Orchestrator 구독/이벤트 기반 상태전이(FSM 반영)
  - `/api/metrics/trace/{trace_id}` 집계 추가
- Gates
  - 장시간 10분/50rps 무손실, p95<3.5s

## Batch 5 (M5)
- Deliverables
  - Legacy LLM 클라이언트 제거(플래그 유지 가능)
  - 문서/런북/다이어그램 반영, 버전 태깅 `edge-first-1.0`
- Gates
  - QA 문서 점검, 운영 체크리스트 완료

## Dependencies & Risks
- 모델/키: Edge secrets 일원화, 프로젝트별 리밋 정책
- 콜드스타트: Functions pre-warm 시나리오, 작은 번들 유지
- 백프레셔: 큐/서킷브레이커/재시도 스케줄러 사용

## Rollout
- Canary(프로젝트/에이전트 shard별), 급증 시 점진 확장
- 롤백: Edge route version으로 즉시 전환
