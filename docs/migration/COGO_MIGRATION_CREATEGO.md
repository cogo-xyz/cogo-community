## CreateGo → cogo 통합 계획서(최신)

본 계획서는 Python 기반 CreateGo-Agent를 cogo-agent 표준으로 안정적으로 통합하기 위한 실행지침입니다. 대규모 TS 일괄 전환 리스크를 회피하고 데이터/프로토콜 호환을 선행 확보합니다.

### 핵심 전략
- 사이드카/브릿지 우선: Python CreateGo를 브릿지로 연결, 점진 TS 대체
- 데이터 계약 우선: Supabase/Neo4j/Realtime 인벤토리→매핑→이행
- MCP 일원화: Figma/Browser 접근은 MCP Gateway(WebSocket) 경유
- 표준 준수: trace/idempotency/retry/circuit/metrics/artifacts/policy/agent presence

### 산출물
- docs/migration/creatego/* 4종(overview, supabase, neo4j, realtime, plan)
- src/services/legacy/creatego/ProtocolAdapter.ts (프로토콜 변환)
- src/workers/CreateGoBridgeWorker.ts (브릿지 워커)
- src/services/ui/* (Figma→UI 변환, BDD 생성, Action 합성 타입/서비스)
- src/workers/Ui*Worker.ts 3종 + src/routes/uiRoutes.ts (API)

### 단계별 수행
1) 인벤토리 문서: Supabase, Neo4j, Realtime 카탈로그
2) 브릿지 가동: CreateGo 이벤트→cogo 버스로 변환(샘플 이벤트부터)
3) 데이터 이행: idempotent SQL/Cypher + 검증 스크립트
4) E2E 스모크: 변환→BDD→Action 파이프 최소 경로
5) 기능 전환: A/B 검증 후 Feature Flag 스위치

### 품질 게이트
- MCP 핑/헬스, 변환→BDD→Action 스모크, 스키마 검증, 회로/리트라이 시뮬레이션


