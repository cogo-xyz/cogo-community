## COGO Agent: 지능(Intelligent) + 자율(Autonomous) + 분산(Distributed)

이 문서는 COGO Agent의 목적과 철학, 전체 기술 아키텍처, 핵심 컴포넌트, 표준(메시지/아티팩트/메트릭/게이트), 배포/운영, 그리고 End-to-End 동작 흐름까지 한 문서로 모두 파악할 수 있도록 정리합니다.

---

### 1) 목적(Purpose)과 철학(Principles)
- 엔터프라이즈급 에이전트 플랫폼: 스스로 추론하고 실행하며 학습적으로 개선합니다.
- 지능(Intelligent): 지식 RAG(문서 pgvector + 관계 Neo4j)와 LLM을 결합해 맥락 기반의 의사결정을 수행합니다.
- 자율(Autonomous): 이벤트 기반 오케스트레이션, 재시도/회로차단을 통한 자가 치유(Self-healing) 능력.
- 분산(Distributed): 멀티 프로세스/컨테이너 워커, 실시간 버스(Supabase)로 느슨하게 결합.
- 관측·표준화(Observable & Standardized): 메시지·아티팩트·메트릭·게이트를 표준화해 안전한 반복 개선.

---

### 2) 전체 아키텍처 개요(High-level Architecture)
- 오케스트레이터(Orchestrator)
  - 단순 라우터가 아님: 지식 RAG(pgvector+Neo4j) + LLM을 활용해 목표 분해, 도구 선택, 정책 기반 실행계획을 스스로 수립합니다.
  - 의사결정 표준: trace_id 전파, idempotency_key, 정책/도구 성능(메트릭) 피드백 루프.

- 워커(Workers)
  - Execution/Research/Indexing/GraphRAG/Codegen/MCP Gateway 등 전문화된 역할의 분산 유닛.
  - 예) GraphRAG: 문서(pgvector) + 지식 그래프(Neo4j)를 결합해 관계/경로 기반 증거를 생성.
  - 예) MCP Gateway: 외부 MCP(Figma/Browser)를 COGO 분산망에 표준으로 연결.

- 메시지 버스(Bus)
  - Supabase Realtime + Postgres 테이블(`agent_messages`, `bus_events`) 기반의 느슨 결합.
  - 이벤트 소싱: `*_scheduled/succeeded/failed` 이벤트 기록으로 재현성/디버깅 확보.
  - 고정 IP 불필요: 외부 노출 없이 개별 PC/사내망에서 Supabase에 “구독(Subscribe)”만으로 참여합니다.
  - NAT/방화벽 친화: 아웃바운드만 열려도 에이전트는 온라인/하트비트/오프라인 이벤트로 플랫폼에 존재를 알립니다.

- 데이터 계층(Data)
  - Supabase(Postgres + pgvector): 문서/임베딩/메타 저장 및 하이브리드 검색.
  - Neo4j: 개체·관계 기반 지식 그래프, GraphRAG 탐색/추론 지원.

- 관측/운영(Observability/Operations)
  - Prometheus 메트릭과 표준 요약 API(`/api/metrics/summary`), MCP 요약(`/api/metrics/mcp/summary`).
  - 표준 아티팩트 저장규약(실패/성공 요약, 요청/응답 캡처)으로 회귀분석·리뷰 용이.

---

### 3) 지능형 오케스트레이터(특징 강조)
- 목표 분해(Planning) → 도구 선택(Tool Selection) → 실행(Execution) → 평가(Evaluation) → 재계획(Adaptation)
- 지식 RAG 결합
  - 문서 RAG: pgvector 임베딩 기반 유사도/하이브리드 검색
  - GraphRAG: Neo4j 탐색(경로/이웃/메타패턴)으로 관계 증거 확보
- LLM 정책/프롬프트 표준
  - 의사결정 근거를 아티팩트/메트릭에 기록해 학습적 개선 가능
- 분산 실행 제어
  - 재시도 정책(`configs/retry_policy.json`)과 회로차단(`configs/circuit_breaker.json`)으로 불안정 도구를 자동 보호
  - Half-open 전이/최소 요청 수(min_requests) 등 실전 운영 파라미터 지원

---

### 4) MCP 통합 (Figma/Browser)
- 원본 MCP 서버 스펙 보존(인터페이스/툴 자산 재활용)
- COGO 접점: `MCPGatewayBusWorker`가 Supabase 버스 메시지 ↔ MCP WebSocket 호출을 브릿지
- 로컬 포트 표준: `configs/mcp.json`에서 Figma `ws://localhost:3007`, Browser `ws://localhost:3004`
- 헬스 라우트: `GET /api/mcp/health` (두 MCP를 병렬 핑)
- CI:
  - MCP 핑(Figma/Browser) 기본 포함
  - 선택적 E2E(`mcp:verify:e2e`)는 Supabase 시크릿 설정 시 자동 수행
  - 통합 게이트(`gate:unified`) 전 MCP 헬스 보장

---

### 5) 표준(Standards)
- 메시지 표준
  - 공통: `id`, `service/role/shard`, `tenant`, `intent`, `trace_id`, `idempotency_key`, `attempts`
  - MCP 호출: `toolset`, `tool`, `params`
- 이벤트 표준(`bus_events`)
  - `*_scheduled`, `*_succeeded`, `*_failed`, `*_retry_scheduled`, `*_requeued`
- 아티팩트 표준
  - MCP: `artifacts/mcp/<toolset>/<ts>/{request.json,response.json,summary.json,error.json}`
  - 게이트/시나리오: `artifacts/gate-run`, `artifacts/full-scenario`, `artifacts/docker-scenario`
- 메트릭 표준
  - MCP: `cogo_mcp_calls_total`, `cogo_mcp_fail_total`, `cogo_mcp_latency_ms`
  - 회로: `cogo_circuit_open_current`, `cogo_circuit_open_total`, `cogo_circuit_close_total`
  - 요약 API: `/api/metrics/summary` 내 `summary.mcp`(calls/fails/p50/p95/detail)
- 게이트 표준
  - `gate:unified` = MCP 핑 → 로컬 시나리오 → 도커 시나리오(옵션 스킵)
  - CI `ci-gate.yml`: MCP 핑(양쪽), (옵션) MCP E2E, (옵션) minimal health, 최종 게이트 실행

---

### 6) 회복력(Resilience)
- 재시도 정책(`configs/retry_policy.json`)
  - 예: `mcp.call.figma.get_document_info`, `mcp.call.browser.navigation|screenshot|scraping` 등 per-tool 키
- 회로차단 정책(`configs/circuit_breaker.json`)
  - per-key 전개(예: `mcp.call.browser.get_title.0`), half-open/close 상태 반영
- DLQ/재큐잉
  - 최대 시도 초과 시 `DLQ`로 이동, 운영자가 분석/재처리 가능

---

### 7) 보안·정책(Security/Policy)
- 라우트 정책 `configs/route_policies.json` (deny-by-default + allowlist)
- 운영 보호: `REQUIRE_ADMIN_FOR_NON_GET=true` + `x-admin-token`
- 헬멧(helmet), rate limit, 최소 권한 원칙
- 비밀/키 중앙관리: Supabase 테이블(원격 환경 병합 `RemoteEnv`) → 프로세스 환경에 주입

---

### 8) 배포/실행(DevOps)
- 로컬/CI 도커 컴포즈: `docker-compose.local.yml`, `docker-compose.ci.yml`
- MCP 스택: `cogo-figma-mcp`(HTTP 3001/WS 3007), `cogo-browser-mcp-ws`(WS 3004), `redis`
- Minimal 서버(초경량) vs 분산 서버(실전): 최소 라우트로 관측/헬스/아티팩트 서빙
- 이미지 기반 롤아웃 권장(원자성), 포트 충돌 방지(오토프리 옵션)

---

### 9) API 개요(API Surface)
- MCP 프록시/헬스
  - `POST /api/mcp/:toolset/:tool` (관리자 토큰 가드)
  - `GET /api/mcp/ping/:toolset/:tool`
  - `POST /api/mcp/enqueue` (버스 메시지 직접 주입)
  - `GET /api/mcp/config`
  - `GET /api/mcp/health` (Figma/Browser 병렬 핑)
- 메트릭/아티팩트/이벤트
  - `GET /api/metrics/summary`
  - `GET /api/metrics/mcp/summary`
  - `GET /api/metrics/mcp/events`
  - `GET /api/metrics/mcp/artifacts/summary`
  - `POST /api/metrics/snapshot`

---

### 10) 개발 흐름(Development Workflow)
1. MCP/워커/오케스트레이터를 메시지 표준에 맞춰 연결
2. 리트라이/회로/정책/보안 적용 → 메트릭/아티팩트 기록
3. 로컬 E2E (`mcp:ping`, `gate:unified`)로 기준선 확보→ 그린
4. CI(`ci-gate.yml`)에서 MCP 핑/옵션 E2E/게이트 실행, 실패 시 알림
5. 대시보드에서 MCP detail/지연/회로 상태 모니터링

---

### 11) E2E 시나리오 예시(버스↔MCP)
1) 메시지 enqueue: `service=mcp, role=gateway, payload={ toolset, tool, params }` → `agent_messages`
2) `MCPGatewayBusWorker`가 메시지 claim → 회로/리트라이 확인 → MCP WS 호출
3) 결과 저장: 아티팩트 생성, 메트릭 관측, `mcp_call_succeeded|failed` 이벤트 발행(`bus_events`)
4) 요약 조회: `/api/metrics/mcp/summary` 또는 `/api/metrics/summary`

---

### 12) 디렉터리 & 구성(참고)
- `mcp-servers/figma-context` / `mcp-servers/browser-use`: 외부 MCP 서버
- `src/workers/MCPGatewayBusWorker.ts`: 버스↔MCP 브릿지
- `src/services/mcp/McpClient.ts`: MCP WebSocket 클라이언트
- `configs/*.json`: 재시도/회로/정책/MCP 엔드포인트 등 구성 파일
- `docs/*`: 아키텍처/엔드포인트/환경 표준 문서

---

### 13) 왜 COGO인가(총평)
- 지식 RAG(pgvector + Neo4j) + LLM 결합으로 “지능적” 오케스트레이션을 실현
- 분산·관측·표준을 전제로 한 운영 친화적 설계
- 기존 자산(MCP 등)을 보존하면서 내구성과 자율성을 확보
