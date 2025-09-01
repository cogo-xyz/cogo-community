## COGO Edge Functions – Development Plan (LLM/RAG 분리)

### 목표
- IDE 최소 계약(task_type, trace_id, intent.keywords, artifacts)을 준수하면서, 생성/변환/도출/스캔 흐름을 안정화.
- LLM과 RAG의 책임을 명확히 분리하고, RAG 비활성 환경에서도 동작 보장.

### 범위
- 신규: `intent-resolve` (텍스트 → intent.keywords 추출·검증)
- 보강: `design-generate`, `figma-context`, `figma-compat`, BDD/ActionFlow/DataAction 계열
- 공통: SSE 하드닝, artifacts 일원화, 멱등성, 메트릭/트레이스

### LLM vs RAG 책임 분리 (task_type 기준)
- design_generate: LLM 필수(플래닝/초안), RAG 선택(패턴/레시피). 실패 시 LLM-only fallback.
- figma_context_scan/apply: 결정론(LLM/RAG 불필요).
- symbols_identify/variables_derive: 결정론 우선 + (옵션) LLM 보정 제안만 artifacts.suggestions에 포함.
- bdd_generate/refine: LLM 필수, (옵션) RAG로 도메인 가이드/스타일 컨텍스트.
- actionflow_generate/refine: LLM 필수, (옵션) RAG로 레시피/안티패턴.
- data_action_generate(bind): LLM 필수, (옵션) RAG로 API 스키마/화이트리스트 보강.

### 작업 항목
1) Intent
   - `intent-resolve` Edge: POST /intent/resolve { text, language? } → { keywords[], confidence, registry_version, unknown[] }
   - 레지스트리 검증: `cogo.intent_keyword` 조회로 unknown 필터링.
   - 규칙 기반 추출(초기), (옵션) LLM 보조 추출은 후속.

2) Design Generate
   - LLM 프롬프트 정리 + zod 검증
   - RAG 토글 `ENABLE_RAG=true|false` 및 실패 시 fallback
   - SSE 프레임 표준화: rag.item → rag.done → llm.done → ui.generate → done

3) Figma Context
   - stream: idle/max 타임아웃, 청크 크기/주기 상수화
   - apply: page_id/외래키 검증 + 결과 메타 기록

4) 변환/도출
   - figma-compat: mapType/geometry/옵션 강화, generate/llm는 별도 LLM 모듈 호출
   - symbols/variables: 결정론 규칙 확장, LLM 보정은 artifacts.suggestions로만

5) BDD/ActionFlow/Data Action
   - LLM 템플릿 확정, 결과 스키마 검증, diff/미결 단계 표기

6) 공통 인프라
   - SSE 하드닝(Idle/Max/Conn cap)
   - artifacts 업로드/서명/기록 공통화
   - 멱등성 키 + 중복 방지 캐시
   - /api-router/metrics/trace/{trace} 아티팩트 서명 링크 포함

### 마일스톤/일정
- M1(주차 1): intent-resolve, SSE/Artifacts/Idempotency 표준화
- M2(주차 2): design-generate LLM-only 안정화 + RAG 토글
- M3(주차 3): symbols/variables 결정론 고도화 + LLM 보정 제안
- M4(주차 4): BDD/ActionFlow/DataAction LLM 템플릿·검증 확정
- M5(지속): e2e 스크립트, 메트릭 기준 수립(p50/p95, 성공률)

### 수용 기준
- 모든 응답에 trace_id, intent.keywords(검증 통과), artifacts 존재
- ENABLE_RAG=false에서 design-generate 100% 성공
- /metrics/trace/{id}에서 아티팩트 조회/다운로드 성공률 ≥ 99%


