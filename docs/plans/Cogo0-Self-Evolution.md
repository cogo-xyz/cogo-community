## Cogo0 Self‑Evolving Distributed Agent Roadmap

### 1) Objective
- cogo-agent-core(cogo0)를 분산 에이전트 구조로 전환하여 “스스로 업그레이드” 가능한 플랫폼 구축
- 새 버전 에이전트를 격리 배포·평가·승급하고, 기존 에이전트는 안전 교체(무중단/가드)
- 운영 중 RAG+KG 기반 탐색/정확도 향상, Orchestrator가 트래픽·승급 정책 제어

### 2) Architecture (High level)
- **Agents**
  - Orchestrator: 라우팅/정책, 카나리 비율 조정, 승급 트리거(업그레이드 오케스트레이션의 중심)
  - Deployer: Docker 이미지 빌드/푸시, Helm/Argo Rollouts 배포/롤백
  - Evaluator: 스모크/벤치/리그 과제 수행 → 성공률/지연/메모리/비용 점수화
  - Registry: 활성 에이전트 세트 관리(승급 시 멤버십 갱신, 구버전 해제)
  - Governor: 런타임 임계치 가드(오류율/메모리/Ready), 자동 차단/롤백
- **Data/Control Plane**
  - Supabase(DB/Realtime/Jobs + PGVector), RAG RPC(`match_agent_knowledge_vectors`) 및 Runtime Locks
  - KG: import-그래프(로컬) → Neo4j(선택)로 확장 가능
  - K8s/Argo(rollouts, HPA, PDB), Docker/Registry(서명/SBOM)

### 3) Operations Flow
1. 버전 정의: `registry/cogo-agent-core:cogoN` 이미지 + Helm/Argo values(version/track)
2. 카나리 실험: Orchestrator가 p% 트래픽을 canary로 라우팅(샘플/실업무 혼합)
3. 평가/게이팅: Evaluator가 A/B 수행 → 성공률/지연/메모리/비용 비교, 게이트 통과 판단
4. 승급/교체: 기준 충족 시 canary → stable 승급, 구버전 스케일다운/등록 해제
5. 실패/롤백: 임계치 초과/악화 시 즉시 stable 100% 복귀 및 canary 제거

### 4) Required Components (MVP)
- Containerization: Dockerfile(BuildKit), 이미지 서명(cosign), SBOM(syft)
- K8s Deployment: Helm Chart(Deployment/Service/HPA/PDB/Config/Secret), Argo Rollouts
- GitOps/CI: GH Actions build/push/scan/test → Helm values 업데이트 → Argo Sync
- Evaluation Suite: 스모크/벤치 + 회귀 비교(성공률·지연·메모리·비용)
- Runtime Guards: heapUsed>320MB 3분, 오류율>1%, Ready<1 등 가드/알림

### 5) RAG + KG Usage (현재 구성)
- 전량 색인 + 기본 필터(`RAG_DOMAINS=cogo,cogo.xyz`, `RAG_TYPES=code,document`)
- KG 제약: import-그래프 기반 URIs로 후보 제한(Neo4j 미가동 시에도 동작)
- 스크립트
  - `src/scripts/rag/runAskHybrid.ts`: KG 제약 + askRag E2E
  - `src/scripts/ci/smokeRagQuery.ts`: KG_URIS/DOMAINS/TYPES 기반 검색 스모크
  - PM2 canary: `rag-canary`(10분 주기 하이브리드 질의)

### 6) Control (Docker/K8s)
- Docker: buildx, registry push, cosign 서명, syft SBOM
- K8s: Argo Rollouts로 Canary/Blue-Green, HPA/PodDisruptionBudget, RBAC(Deployer Agent)
- Orchestrator: Supabase의 라우팅 비율/플래그를 API/테이블로 외부화하여 UI/CLI 제어

### 7) Immediate Commands (Ops Cheat‑Sheet)
- 하이브리드 질의(파일군 제한):
```bash
KG_SEED=SupabaseVectorStore.ts KG_RADIUS=1 \
ENABLE_SUPABASE=true SUPABASE_URL=$SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY=$SRK \
npx ts-node src/scripts/rag/runAskHybrid.ts "Where is searchSimilar implemented?"
```
- KG_URIS 강제 검색 스모크:
```bash
KG_URIS=src/knowledge/SupabaseVectorStore.ts \
DOMAINS=cogo,cogo.xyz TYPES=code,document ENABLE_SUPABASE=true \
SUPABASE_URL=$SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY=$SRK \
npx ts-node src/scripts/ci/smokeRagQuery.ts "Where is searchSimilar implemented?"
```
- PM2 canary/재임베딩:
```bash
npx pm2 restart rag-canary
npx pm2 restart reembed-nightly
```

### 8) Promotion & Rollback Criteria (예시)
- 승급: 성공률 +3%p 이상, 오류율 <0.5%, 지연 p95 -5% 이상 또는 메모리 ±5% 이내, 비용 동등 이하
- 롤백: 오류율 >1% 또는 가드 트립, 라우팅 비율 즉시 stable 100%

### 9) Roadmap
- Phase A (현 단계)
  - PM2 단일 인스턴스 + nightly re-embed + canary 하이브리드 질의(운영 관찰)
  - RAG RPC/필터/제약 정교화, 승급 기준/메트릭 대시보드 마련
- Phase B (K8s 전환)
  - Dockerize + Helm/Argo Rollouts, Deployer/Evaluator/Governor Agent 활성화
  - GitOps 파이프라인 통합, 카나리 A/B → 자동 승급/중단
- Phase C (Neo4j/멀티암)
  - Neo4j KG 활성화, KG 기반 라우팅/부스팅 정밀화, 멀티암 밴딧으로 비율 자동 튜닝

### 10) References (Source)
- `src/knowledge/SupabaseVectorStore.ts` (searchSimilar, RPC/필터/제약)
- `src/scripts/rag/askCore.ts` (RAG Core)
- `src/scripts/rag/runAskHybrid.ts` (E2E 하이브리드)
- `ecosystem.config.js` (PM2 apps: chat-gateway-worker, reembed-nightly, rag-canary)


