# COGO Edge-first × 분산 에이전트 구현 계획서 (분석·설계·개발 계획)

## 1) 목적과 범위
- 목적: 현재 코드베이스의 Edge Functions(chat/embed/rag/role-select/graph)와 분산 에이전트(Orchestrator/Indexing/Research/Executor/GraphRAG)를 “제어면(Control-plane)=Edge/Realtime, 데이터·실행면(Data-plane)=워커” 원칙으로 정렬하고, 성능/안정성/가치 지표를 만족하는 구조로 고도화.
- 범위: 설계 원칙, 현행 분석, 컴포넌트별 설계/변경, API·계약, 개발 태스크, 게이트/운영.

## 2) 현행 분석(파일/구성 요소)
- Edge Functions
  - 위치: `supabase/functions/{chat,embed,rag,role-select,graph}/index.ts`
  - 특징: SSE 이벤트(meta/llm.delta/llm.done, embed.chunk/done, rag.item/done), 멱등성(Deno KV or in-mem), 에러 포맷 `{ok,error,code,via}`, 옵저버빌리티(bus_events 선택)
- Edge 클라이언트
  - 위치: `src/services/edge/*` (EdgeChat/Embed/Rag/Graph/RoleSelectClient, `edgeBase.ts`)
- 오케스트레이터
  - 위치: `src/workflow/LangGraphWorkflowEngine.ts`, `src/roles/RolePackageSchema.ts`
  - 상태: `edge_call`/`route`/근거 주입/백오프/타임아웃 구현
- 분산 에이전트·인프라
  - Indexing/Research/Executor/GraphRAG(여러 경로): `src/agents/*`, `src/workers/*`, `src/services/realtime/*`, `src/workflows/*`
  - Jobs/Realtime: `src/services/realtime/WorkerLink.ts`, `src/services/realtime/SupabaseRealtimeBus.ts`, `src/workers/ExecutorDispatcher.ts`
- RAG 저장소/지식
  - 벡터(pgvector): `src/knowledge/SupabaseVectorStore.ts`, `src/scripts/ci/seedVectorDocuments.ts` 외
  - 그래프(Neo4j): `supabase/functions/graph/index.ts`, `src/services/edge/EdgeGraphClient.ts`
- Figma MCP/인제스트: `mcp-servers/figma-context/*`, `src/workers/FigmaRagIngestWorker.ts`
- CBO/블루프린트: `src/core/CodeBlueprintObject.ts`

## 3) 설계 원칙(확정)
- 제어면(Control-plane)=Edge/Realtime: 수락·분배·상태조회·SSE 중계·경량 검증/필터.
- 데이터·실행면(Data-plane)=워커: 장시간·고부하·네트워크/IO/GPU 집약(Research/Indexing/Build/Execute).
- Jobs 계약 표준화: enqueue → lease/claim → execute → progress/result → artifacts, idempotency-key, trace_id.
- 옵저버빌리티: 표준 에러/멱등성/trace 전파, bus_events → metrics 집계, 대시보드.
- 보안·한계: Edge 실행 ≤ 수 초, 장시간 작업은 워커 전담. 레이트리밋/권한/감사 적용.

## 4) 컴포넌트별 설계/변경 사항
### 4.1 Research Agent
- 변경: 외부 데이터 조회/웹 크롤/도메인 API 호출은 워커 전담. Edge는 접수/라우팅/스로틀/권한.
- 이벤트: `research.progress`, `research.partial`, `research.done`(Realtime + bus_events).
- 실패 처리: 재시도 정책(지수 백오프), DLQ 목록화, 멱등 키 재실행 보호.

### 4.2 Indexing Agent
- 변경: 파일 스캔/청킹/임베딩/그래프 작성 워커 전담. 증분 인덱싱(해시/mtime)·resume 지원.
- 아티팩트: 로그/리포트/스냅샷 Storage 업로드 + `artifacts` 테이블 링크.
- 이벤트: `indexing.progress`, `indexing.done`.

### 4.3 Build/Compile Sandbox Worker
- 변경: 빌드/테스트/패키징 전용 워커. 리소스 한도/타임아웃/격리. 결과물 업로드.
- 이벤트: `build.progress`, `build.done`.

### 4.4 Execute Agent
- 역할: Edge=경량 오케스트레이션(SSE 중계/검증), 워커=실제 실행. 액션 실행/플로우 관리.
- 계약: 액션 단위 idempotency, 권한/레이트리밋, 롤백/보상 플로우.

### 4.5 Orchestrator + 모델 라우팅
- 정책: gpt-5-nano(의도/분류·저지연), gpt-5-mini(중간 업무/태스크 분해), gpt-5(기획/설계/정밀)
- 기준: 위험도/정확성 요구, 토큰/맥락 깊이, 산출물 유형(설계/정책/아키텍처=5), 불확실성 스코어, 지연/비용 SLO.
- 구현: LangGraph `route` 노드에 스코어러(uncertainty/risk/length/type) 반영. 실패/불충분 근거 시 상향 재호출(최대 N회, 백오프).

### 4.6 Realtime & Jobs 계약 정리
- 채널: `agents:{id}`, `jobs:{id}`, `system:events` 고정, Presence/Broadcast 명세 확정.
- Jobs: 컬럼(id, type, payload, executor_id, status, attempts, lease_until, idempotency_key, artifacts, created_at...).
- API: Edge에서 `POST /enqueue` 수락(202 + jobId), `GET /jobs/{id}` 상태, `GET /jobs/{id}/events` SSE.

## 5) API/계약(요약)
- Edge 라이트 엔드포인트
  - `POST /research/enqueue`: trace/idempotency/권한 검사→queue, 202 + jobId
  - `POST /indexing/enqueue`, `POST /build/enqueue`, `POST /execute/enqueue` 유사 구조
  - `GET /jobs/{id}/events`: meta/progress/partial/done SSE
- 워커 처리
  - lease/claim(원자성), progress 이벤트 주기, artifacts 업로드, result 기록

## 6) 개발 태스크(구체)
- 공통(표준화)
  1. Jobs 스키마/인덱스 보강(lease_until, idempotency_key, artifacts) 및 리포트 뷰 생성
  2. Realtime taxonomy/Presence 계약 정리(+ 문서)
  3. bus_events 타입 추가: research/indexing/build/execute progress/done 에러 코드 표준
  4. Edge 엔드포인트 4종(enqueue + status + events) 생성/문서화(OpenAPI)
- Research
  5. ResearchWorker: 외부 소스 클라이언트 어댑터(웹/API/도메인) 인터페이스·키/레이트리밋·리트라이 정책
  6. partial evidence 축적/머징 로직 + 최종 evidence 정규화
- Indexing
  7. 증분 인덱싱: 파일 해시/mtime 기반 변경 감지, resume 체크포인트
  8. 임베딩 파이프라인(BGE-M3) 큐 처리량/동시성 제어, 에러 샘플링 보고
- Build/Sandbox
  9. 격리/자원 한도/타임아웃 공통 미들웨어, 로그 스트리밍, 아티팩트 표준화
- Execute
  10. 액션 실행기(Action Runner) 권한/레이트리밋/보상 플로우 구현, 멱등 키 처리
- Orchestrator
  11. 라우팅 스코어러(uncertainty/risk/length/type) 유틸 + `route` 노드 통합
  12. 실패 시 상향 재호출(backoff) 및 최대 횟수 설정
- 문서/도구
  13. OpenAPI 스펙 업데이트, 운영 런북(장시간 잡/복구/관측), 대시보드 카드 추가

## 7) 수용 기준/게이트(수치)
- 분산 각 영역 E2E 성공률 ≥ 95%, P95 ≤ 5s, 에러율 < 1%
- Research/Indexing/Build: 중복 실행률 0(멱등), TTR < 10s(장애 시 복구까지 제어면 시그널)
- 라우팅: nano→mini→5 상향 정확도 개선, 비용/지연 절감률 보고(주간)
- 합성 영향: render/액션 성공률 저하 없을 것, 근거 불일치 ≤ 5%

## 8) 일정(제안)
- 주차 1: 공통 표준화(1~4) + Research(5)
- 주차 2: Research(6) + Indexing(7)
- 주차 3: Indexing(8) + Build(9)
- 주차 4: Execute(10) + Orchestrator 라우팅(11~12)
- 주차 5: 문서/게이트(13) + 번들 스모크/대시보드 확정

## 9) 리스크/완화
- 외부 API 속도·제한 → 레이트리밋/캐시/리트라이, 오프로딩
- 긴 잡 실패/중단 → 체크포인트/resume, DLQ/재큐잉, 알림
- 모델 라우팅 오판 → 상향 재호출, 품질 모니터링, 휴리스틱+데이터 기반 개선

## 10) 코드 기준 참조(대표)
- Edge: `supabase/functions/*`
- Clients: `src/services/edge/*`
- Orchestrator: `src/workflow/LangGraphWorkflowEngine.ts`
- Jobs/Realtime: `src/services/realtime/WorkerLink.ts`, `src/workers/ExecutorDispatcher.ts`
- RAG: `src/knowledge/*`, `src/services/edge/EdgeRagClient.ts`, `supabase/functions/rag`
- Graph: `supabase/functions/graph`, `src/services/edge/EdgeGraphClient.ts`
- Figma MCP: `mcp-servers/figma-context/*`, `src/workers/FigmaRagIngestWorker.ts`
