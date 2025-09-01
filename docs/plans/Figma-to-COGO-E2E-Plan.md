## Figma → COGO E2E 개발·테스트 계획 (Plugin → MCP → 변환 단위/통합)

### 0) 개요
- 목적: Figma Plugin에서 생산한 JSON을 Supabase 기반 분산 에이전트 아키텍처를 통해 COGO(UUI) JSON으로 변환하고, 단위/통합 테스트까지 일관되게 검증한다.
- 범위: Figma Plugin 개발 → Figma MCP 연동 → 변환 단위 테스트 → Chatting 인터페이스 경유 통합 테스트.
- 제약: Edge Functions/Realtime 기반 통신, 외부 npm 설치 금지(Plugin), 무인 테스트 우선(No-Auth 모드 지원).

### 1) 사전 준비
- 환경 변수
  - SUPABASE_EDGE, SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY
  - PROJECT_ID: 738a1fc6-3d88-42e0-8afa-eacb0d4ead61
  - COGO_PROJECT_ID: 3f50a6d4-7990-435e-a6a6-97c95358adea
- 배포/서비스 상태
  - Edge: figma-plugin(기존), chatting(완료) 배포 및 헬스 체크
  - Worker: MCPGatewayBusWorker, ChatGatewayWorker 기동
  - Realtime/Publication/RLS 확인(사전 스키마 구성 완료 기준)
- 문서/스키마
  - 분산 프로토콜: docs/integration/Supabase-Realtime-Distributed-Protocol.md
  - 채팅 프로토콜: docs/integration/Chatting-Protocol.md
  - UUI/COGO 스키마: docs/schemas/cogo_ui/*.json

### 2) Figma Plugin 개발 단계
- 목표: 외부 의존성 없이(fetch/WS만 사용) Edge Functions와 통신하는 최소 클라이언트 구현
- 기능
  - Session/Project 메타 삽입: sessionId, projectId, cogoProjectId
  - Enqueue/Result Poll (HTTP), 선택 시 Realtime 구독
  - 서비스 카탈로그 조회: GET ${SUPABASE_EDGE}/chatting/services
- 산출물
  - 샘플 코드: docs/examples/figmaPluginClient.ts (이미 제공)
  - 실행 가이드: README 조각 추가
- DoD
  - Plugin에서 Enqueue → Result Poll 성공(HTTP 200, status=ok)

### 3) Figma MCP 연동 단계
- 목표: Plugin→MCP 호출 경로를 Supabase 메시지 버스로 브릿징
- 요구 사항
  - 분산 버스(public.agent_messages, public.bus_events) 사용
  - Realtime Broadcaster를 통한 plugin:<sessionId>/project:<projectId> 브로드캐스트
  - Envelope 메타(trace_id, project_id, cogo_project_id) 강제 옵션 검토(BROADCAST_ENFORCE_META)
- 검증
  - 스모크: npm run -s mcp:smoke:plugin:ws (참고), npm run -s mcp:smoke:uui:edge

### 4) Figma JSON → COGO JSON 변환 단위 테스트 단계
- 목표: 변환 API를 통한 결과를 COGO 스키마로 정합성 검증
- 절차
  1) 변환 호출(Edge UUI compat):
     - POST ${SUPABASE_EDGE}/figma-plugin/compat/uui/symbols/map
  2) 결과를 UUI/COGO 스키마로 Ajv 검증
- 스크립트
  - npm run -s uui:validate:figma2cogo
    - 입력: IN=<figmaLike.json>(옵션, 미지정 시 샘플)
    - 출력: { ok: true, message: 'cogo JSON validated' } 기대
- DoD
  - 샘플/실제 JSON 모두 스키마 검증 통과

### 5) Chatting 인터페이스 통합 테스트 단계
- 목표: 사용자 대화(챗 인터페이스)로 변환을 트리거/모니터링/응답
- 엔드포인트
  - Enqueue: POST ${SUPABASE_EDGE}/chatting/enqueue
  - Result: GET  ${SUPABASE_EDGE}/chatting/talking/result?id=...
  - Respond: POST ${SUPABASE_EDGE}/chatting/respond (HITL)
  - SSE: GET  http://localhost:3002/api/chat/feed?projectId=...&cogoProjectId=...
- 스크립트/예시
  - Respond 스모크: npm run -s chat:smoke:respond
  - SSE 스모크: npm run -s chat:smoke:sse
  - 부하 스모크: npm run -s chat:smoke:edge:load (파라미터: LOAD_N, LOAD_CONC)
  - 실제 예제: docs/examples/chatting-example.md (서비스 카탈로그/응답 포함)
- DoD
  - Enqueue→Progress/Done(Realtime/SSE) 확인, Result Poll status=ok
  - chat_* 메트릭 노출: /api/metrics/chat/project

### 6) 관측/메트릭/대시보드
- 메트릭 API
  - /api/metrics/chat/project: counts, p50, p95, successRate
  - /api/mcp/summary/project: chat 집계 포함
  - /api/mcp/dashboard/project: chat 집계 포함
- Alert 프리뷰
  - /api/mcp/alerts/preview?projectId=...&sinceMs=... (참고) + chat 지표 로그 추가됨

### 7) 성능/안정성 기준
- Backpressure: ENQUEUE_MAX_QUEUE 적용
- Idempotency: idempotencyKey 재사용 확인
- 브로드캐스트 메타 강제: 필요 시 BROADCAST_ENFORCE_META=1
- 인덱스: public.bus_events 프로젝트/타입 보조 인덱스 적용

### 8) 위험/완화
- Edge 권한/키 누락 → .env/Supabase Secrets 관리, No-Auth에서 Authorization: Bearer <ANON_KEY> 강제
- 대량 큐 적체 → Backpressure 429 응답, 재시도 정책 문서화
- 스키마 검증 실패 → 변환 스키마/샘플 보정 및 단위 테스트 강화

### 9) 일정(권장)
- D1: Plugin 최소 기능/카탈로그 Ready, Edge/Worker 기동
- D2: MCP 브릿지 스모크, 변환 단위 스모크 통과
- D3: Chatting 통합(E2E) 스모크 및 부하 스모크 통과, 문서/대시보드 갱신

### 10) DoD 총정리
- Plugin→MCP→변환 단위→Chatting 통합 모든 단계의 스모크가 그린
- 메트릭/대시보드/문서 최신화(본 계획 포함)
- 성능 베이스라인 측정 및 인덱스 반영

### 참고 명령어 모음
- 카탈로그 조회: GET ${SUPABASE_EDGE}/chatting/services
- 변환 유닛 검증: npm run -s uui:validate:figma2cogo
- 챗 Respond 스모크: npm run -s chat:smoke:respond
- 챗 SSE 스모크: npm run -s chat:smoke:sse
- 챗 부하 스모크: npm run -s chat:smoke:edge:load


