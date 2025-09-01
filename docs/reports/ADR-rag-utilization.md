### ADR: RAG Utilization in Chatting Tasks

Status: Proposed

Context
- design-generate 등 채팅 태스크에서 지식 검색이 유용함.
- 토큰/지연/가용성 비용과 품질 이득 사이 트레이드오프 존재.

Decision
- 기본값: RAG 사용(ENABLE_RAG=true). 실패 시 graceful fallback로 LLM 단독 계획 생성.
- 토글: Edge 함수 환경변수 `ENABLE_RAG=true|false`.
- 응답 규격: `response`는 요약, `artifacts`에 검색 스니펫/링크를 선택적으로 포함.

Consequences
- 품질 향상 기대. 비용/지연 증가 가능. 모니터링 필요.
- `trace_id` 기반으로 RAG on/off 결과 비교 가능하게 로그/메트릭 추가.

Rollout
- Canary → 전면. 실패율/지연 임계 초과 시 자동 fallback.


