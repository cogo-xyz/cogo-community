## Batch Rollout Plan – COGO Edge Changes

### 목적
- 대규모 기능을 안전하게 배치하여 IDE/사용자에게 중단 없는 경험 제공

### 배치 전략
1) Canary Tenant → 점진 확대(GA)
2) Feature toggles: `ENABLE_RAG`, `REQUIRE_IDEMPOTENCY`, `EDGE_AUTH_OPTIONAL`
3) Backward compatibility: 새 필드 무시해도 기존 클라이언트가 동작하도록 스펙 유지

### 배치 묶음 (Batch)
- Batch A (Infra/안정화)
  - intent-resolve 배포
  - SSE 하드닝(표준 타임아웃/커넥션 상한)
  - artifacts 일원화/서명 TTL 적용

- Batch B (design-generate)
  - LLM-only 경로 안정화
  - RAG 토글 켜기 → Canary → 확대

- Batch C (figma-context/compat)
  - 스캔/적용 검증 강화
  - 변환 규칙 고도화

- Batch D (symbols/variables)
  - 결정론 규칙 확장 + LLM 보정(옵션)

- Batch E (BDD/ActionFlow/DataAction)
  - LLM 템플릿/검증 확정 → Canary → GA

### 롤백
- Toggle 기반 즉시 비활성화
- 이전 릴리즈 아티팩트 유지
- /health, /self-check, /metrics-overview 기반 자동 게이트

### SLO/지표
- SSE completion rate ≥ 99%
- design-generate 성공률(RAG off) ≥ 99%
- 아티팩트 업로드/조회 성공률 ≥ 99%
- p50/p95 지연 목표: design-generate 1.5s/5s(LLM-only), context stream 초기 500ms


