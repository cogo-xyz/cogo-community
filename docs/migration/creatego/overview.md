## CreateGo-Agent → cogo-agent 통합 개요(안전 이행 계획)

본 문서는 Python 기반 CreateGo-Agent를 cogo-agent 표준으로 안전하게 흡수·통합하기 위한 전체 전략을 정의합니다. 대규모 TS 일괄 전환 리스크를 회피하고, Supabase 스키마/Neo4j 모델/Realtime 프로토콜의 호환을 확보한 뒤 단계적으로 기능을 대체합니다.

### 목표와 원칙
- 최종 목표: CreateGo 기능을 cogo 표준(메시지/아티팩트/메트릭/게이트/보안/실시간)로 완전 통합
- 원칙
  - 최소 변경-최대 호환: 초기에는 Python 경로를 사이드카/브릿지로 연결, 점진 TS 리라이팅
  - 데이터 우선: Supabase/Neo4j/Realtime 계약을 먼저 인벤토리·매핑·이행
  - 표준화: trace_id / idempotency / retry / circuit / metrics / artifacts / policy
  - MCP 일원화: Figma/Browser 접근은 MCP Gateway 경유(WebSocket)

### 대상 기능
- Figma JSON → UI JSON 변환(cogo UI DSL)
- UI JSON + uiState + appData + tempData + UI Events → BDD 시나리오 생성
- BDD → action JSON, actionFlow JSON 합성
- 저장소: Supabase(Postgres), Neo4j(Graph), pgvector(문맥 검색)

### 최종 아키텍처(요약)
- 서비스 계층: `src/services/ui/*` (변환/BDD/Action/타입/인덱싱)
- 워커: `UiConversionWorker`, `UiBddWorker`, `UiActionWorker`
- 호환 브릿지: `CreateGoBridgeWorker` + `ProtocolAdapter` (Python ↔ cogo 버스 변환)
- 게이트웨이: MCPGateway(WebSocket)로 Figma/Browser 호출 통일
- 관측: `cogo_ui_*`, `cogo_mcp_*`, `cogo_bridge_*` 메트릭, 아티팩트 표준 저장

### 단계별 전략
1) 인벤토리: Supabase 스키마, Neo4j 모델, Realtime 이벤트 카탈로그화
2) 데이터 계약 정의: CreateGo ↔ cogo 매핑표, 손실/확장 필드 명시, `schema_version` 부여
3) 프로토콜 브릿지: CreateGo 이벤트 → cogo 표준 버스 포맷으로 변환, DLQ/아이템포턴시 지원
4) DB 마이그레이션: idempotent SQL, Shadow Write/검증 쿼리 세트, 점진 백필
5) Neo4j 마이그레이션: 라벨/관계/프로퍼티 매핑, 인덱스/제약, 검증 질의 Diff
6) 런타임 통합: Python 사이드카 운영, Supabase 버스 ↔ 브릿지 ↔ Python ↔ 결과 버스
7) 기능 대체: 기능 단위 TS 리라이팅 후 A/B 검증→플래그 전환→Python 제거
8) CI/Gate: MCP 핑, 변환→BDD→Action E2E, 스키마 검증, 회로/리트라이 시나리오

### 산출물(이 문서 세트)
- `supabase_schema_inventory.md`: 테이블/뷰/인덱스/RLS/함수/트리거 정의서
- `neo4j_model_mapping.md`: 노드/관계/프로퍼티 매핑 및 마이그레이션 가이드
- `realtime_protocol_catalog.md`: 채널/이벤트/페이로드/순서·ACK 규약
- `migration_plan.md`: 실행 순서·체크리스트·롤백/스위치오버 전략

### 착수 우선순위(실행)
- 문서 3종 인벤토리 골격 작성 → 브릿지 워커/어댑터 스켈레톤 생성
- Supabase/Neo4j 검증 스크립트 초안 → 샘플 데이터 E2E 파이프 스모크


