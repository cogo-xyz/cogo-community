## Cogo0 Self‑Evolution – Phase 1 Plan

### 1) Goal (Phase 1)
- PM2 기반 단일 노드 운영에서 “하이브리드 RAG+KG → 제안 → 소규모 변경 → 평가 → 카나리 관찰” 루프를 정착
- Orchestrator 기반 업그레이드 오케스트레이션(초기 범위 한정)을 도입하되, 배포/승급은 수동 또는 제한 자동화로 운영 안정성 우선

### 2) In/Out of Scope
- In Scope
  - RAG+KG 하이브리드 질의(E2E): `runAskHybrid.ts` 활용, KG는 import-그래프 제약(Neo4j optional)
  - 품질/안정성 지표 수집: 성공률, 지연 p50/p95, heapUsed/rss, Realtime CLOSED, runtime lock 유지율
  - 카나리 관찰: PM2 `rag-canary`(10분 주기)로 핵심 경로 질의 감시
  - 야간 재임베딩 정착: 테스트/생성물 제외 필터 반영, 03:00 배치
- 업그레이드 오케스트레이션 잡 초안: `upgrade.proposal / upgrade.patch / upgrade.evaluate / upgrade.promote` (Supabase jobs)
- Out of Scope
  - Kubernetes/Argo Rollouts 전환(Phase 2)
  - Neo4j 정식 운영(Phase 2): 현재는 import-그래프 기반 KG 제약으로 충분

### 3) Deliverables
- 코드/스크립트
  - `src/scripts/rag/runAskHybrid.ts`: KG 제약 + askRag E2E
  - `src/scripts/ci/smokeRagQuery.ts`: RAG 검색 스모크(제약/무제약)
  - `ecosystem.config.js`: `rag-canary`(*/10) + `reembed-nightly`(03:00)
  - `src/knowledge/SupabaseVectorStore.ts`: `uris` 허용목록, RPC 기반 검색, direct fetch 경로
  - `src/scripts/kg/*`: import-그래프 기반 KG 구성/URIs 추출(Neo4j optional)
  - `supabase/sql/*`: `match_agent_knowledge_vectors`, `runtime_locks`
- 문서/운영
  - 운영 메트릭/게이트: heapUsed>320MB(3m), 오류율>1%, CLOSED 3회 연속, lock 갱신 실패 2회 → 경고/중단
  - Phase 1 운용 플레이북 및 명령 스니펫(아래 6) 참조)

### 4) Metrics & Gates (Phase 1)
- 정확도: 검색 적중률@k, 근거 인용률, 실패율
- 성능: 지연 p50/p95, 처리량
- 안정성: heapUsed/rss 추이, Realtime CLOSED 빈도, runtime lock 유지율
- 비용: 모델/토큰/시간
- 게이트 예시
  - 승급 후보 기준: 성공률 +3%p↑, 오류율 <0.5%, p95 -5% 또는 메모리 ±5% 이내, 비용 동등 이하
  - 롤백: 오류율 >1% 또는 가드 트립 발생

### 5) Upgrade Orchestration(Orchestrator) – Phase 1 운영 방식
- 잡 타입(초안, 수동 트리거)
  - `upgrade.proposal`: KG 제약 + RAG로 변경안/근거/리스크/테스트 제안 생성
  - `upgrade.patch`: 브랜치/커밋/PR 생성(초기엔 수동 적용)
  - `upgrade.evaluate`: 스모크/벤치 실행, 메트릭 리포트 산출
  - `upgrade.promote`: 기준 충족 시 수동 승급(Phase 2에서 자동화 고려)
- 저장
  - Supabase `jobs`/`job_events`로 결과 기록, 라우팅 비율/플래그 테이블 분리(관제용)

### 6) Ops Cheat‑Sheet (Phase 1)
- 하이브리드 질의(파일군 제한)
```bash
KG_SEED=SupabaseVectorStore.ts KG_RADIUS=1 \
ENABLE_SUPABASE=true SUPABASE_URL=$SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY=$SRK \
npx ts-node src/scripts/rag/runAskHybrid.ts "Where is searchSimilar implemented?"
```
- KG_URIS 강제 검색 스모크
```bash
KG_URIS=src/knowledge/SupabaseVectorStore.ts \
DOMAINS=cogo,cogo.xyz TYPES=code,document ENABLE_SUPABASE=true \
SUPABASE_URL=$SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY=$SRK \
npx ts-node src/scripts/ci/smokeRagQuery.ts "Where is searchSimilar implemented?"
```
- PM2 카나리/재임베딩
```bash
npx pm2 restart rag-canary
npx pm2 restart reembed-nightly
```

### 7) Timeline (예시)
- W1: 카나리/야간 재임베딩 안정화, 스모크 세트 확장, 게이트 임계치 조정
- W2: 사이드킥 잡 프로토타입(수동 트리거) → 평가 리포트/대시보드 초안
- W3: 소규모 변경(1~2개) 루프 운영, 승급/롤백 플레이북 검증

### 8) Risks & Mitigations
- RAG 노이즈 증가 → 도메인/타입 필터 + KG 제약 + direct fetch 보강
- 메모리/채널 누수 → processedCache TTL, Realtime 재구독 로직, runtime locks 유지
- 장기 drift → nightly re-embed + canary 질의 감시

### 9) Next (Phase 2 Preview)
- K8s/Argo Rollouts 도입(자동 카나리/승급/롤백)
- Neo4j 정식 운영(KG 기반 라우팅/부스팅 정밀화)
- 멀티암 밴딧으로 다중 후보 자동 탐색 및 비율 튜닝


