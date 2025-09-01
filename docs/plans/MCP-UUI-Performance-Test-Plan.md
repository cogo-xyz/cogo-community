## MCP/UUI Performance Test Plan

### 1) 목적
- 기능 개발 완료 후, 분산 MCP(UUI) 경로의 처리량/지연/안정성을 검증한다.
- Figma Plugin 제약(HTTP fetch만, SDK 없음)과 Supabase Realtime/Edge 제약 하에서의 현실적 성능 기준 수립.

### 2) 범위
- Edge Functions 경유 UUI 5종 툴: variables_derive, symbols_map, bdd_generate, bdd_refine, actionflow_refine
- 메시지 버스(agent_messages/bus_events), 실시간 브로드캐스트(session, project 동시), 결과 오프로딩
- 메트릭·요약 API, 타임라인 일관성

### 3) 비범위(현재 단계)
- Dev 서버에서의 고부하 실행(스테이징/성능 전용 환경에서 수행)
- 실제 외부 MCP 서버 연동(현재는 워크플로우/모의 경로)

### 4) 환경/전제
- 환경: Staging(Edge/DB/Realtime 동일 리전)
- 필수 키: SUPABASE_URL/ANON_KEY/SERVICE_ROLE_KEY, SUPABASE_EDGE(https://<project>.functions.supabase.co)
- 식별자: projectId(uuid, 필수), cogoProjectId(uuid, 선택/독립 스코프)
- 오프로딩: RESULT_INLINE_MAX 조정 가능(기본 200KB)

### 5) 성능 지표(수집/판정)
- 처리량: 분당 완료 건수(툴셋별)
- 지연: p50/p95(성공/오류 별도)
- 성공률: mcp_call_succeeded / (succeeded+failed)
- 큐 상태: agent_messages(queued), bus_events 증가량
- 실시간 손실: SSE/Realtime 이벤트 누락 지표(샘플 구독)

### 6) 수집 경로/도구
- 요약: GET `/api/mcp/summary/project?projectId=...&sinceMs=...&cogoProjectId=...`
- 프로젝트 메트릭: GET `/api/metrics/mcp/project?projectId=...&sinceMs=...&cogoProjectId=...`
- 타임라인: GET `/api/mcp/timeline?messageId=...&projectId=...`
- SSE 브리지: GET `/api/mcp/feed/project?projectId=...&cogoProjectId=...&toolset=uui`
- 부하 스모크: `npm run -s mcp:smoke:uui:edge:load` (LOAD_N, LOAD_CONC, POLL_TIMEOUT_MS)

### 7) 테스트 매트릭스(예시)
- 소부하: N=50, CONC=5, POLL_TIMEOUT_MS=60000 → 기준선
- 중부하: N=200, CONC=20 → 확장성 확인
- 고부하: N=500, CONC=50 → 한계점/백프레셔 동작 확인
- 대용량 결과: RESULT_INLINE_MAX=50KB로 하향 후 대용량 응답 툴에서 오프로딩 기능 확인

### 8) 백프레셔/제한 설정
- Edge: `ENQUEUE_MAX_QUEUE` (예: 1000)
- 토큰 버킷(필요 시): 초당 최대 enqueue 제한(추가 예정)
- 워커: BUS_POLL_MS, 재시도 정책(configs/retry_policy.json), 서킷(configs/circuit_breaker.json)

### 9) 합격 기준(초안)
- 소부하: 성공률 ≥ 99%, p95 지연 ≤ 1.5s, 큐 잔여 0~미미
- 중부하: 성공률 ≥ 95%, p95 지연 ≤ 3s, 큐 안정화(테스트 종료 후 일정 시간 내 0)
- 고부하: 백프레셔 작동(429/overloaded 비율 보고), 시스템 안정성 유지(에러 로그 무증가, 워커/서버 크래시 없음)

### 10) 실행 순서(스테이징)
1. 변수 설정: PROJECT_ID, (선택) COGO_PROJECT_ID, SUPABASE_EDGE, 키들
2. 워커/서버 기동(스테이징): MCP 게이트웨이, Bus Events 브로드캐스터
3. 소부하 → 중부하 → 고부하 순으로 단계적 실행(각 단계 사이 메트릭 스냅샷 저장)
4. SSE 60초 구독으로 이벤트율 관찰(진행/완료/오류)
5. 로그/요약/타임라인 샘플 수집 후 보고서 생성

### 11) 위험/대응
- Realtime 손실: SSE 브리지/폴링 폴백 유지
- Edge 한도: `ENQUEUE_MAX_QUEUE`/토큰 버킷으로 급증 트래픽 제어
- 장시간 폴링: POLL_TIMEOUT_MS 상향, 배치 간 간격 조절

### 12) 산출물
- 성능 보고서(JSON/MD): 처리량/지연(p50/p95)/성공률/큐 변화 추이, 한계점 및 권장 설정값
- 재현 스크립트/명령 모음

### 13) 일정/게이트
- 기능 동결 후 1~2일 내 성능 테스트(스테이징)
- 게이트 통과 시 운영 배포 승인

### 14) 부록: 명령 예시
```
# 소부하
SUPABASE_EDGE=... PROJECT_ID=... SUPABASE_ANON_KEY=... \
LOAD_N=50 LOAD_CONC=5 POLL_TIMEOUT_MS=60000 \
npm run -s mcp:smoke:uui:edge:load

# 중부하(백프레셔 상향 예)
ENQUEUE_MAX_QUEUE=1000 \
SUPABASE_EDGE=... PROJECT_ID=... SUPABASE_ANON_KEY=... \
LOAD_N=200 LOAD_CONC=20 POLL_TIMEOUT_MS=120000 \
npm run -s mcp:smoke:uui:edge:load

# SSE 샘플 구독(60초)
curl -sN --max-time 60 \
  "http://localhost:3002/api/mcp/feed/project?projectId=$PROJECT_ID&toolset=uui"
```


