# 권장 개발 계획서 (2025-08-09)

## 0. 요약
- 목표: Collab API + Supabase 기반 큐/실시간/집계 구조 완성, 메인 엔트리 분리, 운영 문서/테스트 정비
- 원칙: Edge Functions로 읽기/집계 이관, 트랜잭션 일관 이벤트는 DB 트리거 → 테이블 스트림, 실시간 표시/알림은 Realtime 채널

현재 완료(동기화)
- 분산 스모크/모니터/품질 라이트/PR‑Lite 체인 로컬·CI 동작(린트 OK)
- 메트릭 Phase A 1차 구현: Scheduler/Lease/Retry/DLQ/Phase Latency, `/metrics`, `/api/metrics/summary`
- 라우팅 가시성: `/api/metrics/routing`, `RouterSelectClient` + 스냅샷 기록
- LLM 라우팅·키 연동: `AIClients.queryRouted`, Key‑Vault 우선 초기화
- 스펙 문서: 상태기계/사가·보상/메시지/메트릭/라우터/키볼트/인덱싱/품질 계획 추가

## 1. 즉시(Phase A)
1) 메인 엔트리 분리/컴파일 통과
- `src/index.ts` 조건부 로드 or 스텁 모듈 도입
- `src/dev/*` 경량 서버 확장 (collab, metrics mock)

2) Collab API 정식화
- OpenAPI 스펙 작성(`docs/openapi/collab.yaml`)
- 입력 검증(zod), 에러코드 표준, 레이트리밋
- 조회 API: 페이지네이션/필터(상태/타입/기간/실행자)

3) DB/스키마
- `jobs`, `artifacts` 인덱스 최적화(`status`, `executor_id`, `created_at`, `idempotency_key UNIQUE`)
- `job_events` 테이블/트리거/인덱스 추가(트랜잭션 일관 Realtime)

4) 메트릭 Phase A 검증(추가됨)
- 원샷 실행 후 `/metrics`, `/api/metrics/summary`에서 claims/conflicts/lease/retry/dlq/latency 확인
- 라우팅 스냅샷 `/api/metrics/routing?service=chat` 점검, 랭크/비용/지연 확인
- 게이트: PR‑Lite green(라이트≥2)

## 2. 단기(Phase B)
4) Edge Functions
- `metrics-overview`, `jobs-recent`, `artifacts-list`, `sign-artifact`
- 키/권한/RLS 정책 분리, 캐시/쿼터 대응

5) DB 마이그레이션 적용(추가됨)
- `job_events` 테이블/트리거/인덱스 생성 (commit-backed realtime)
- `jobs.idempotency_key` UNIQUE 인덱스 보장

5) Realtime 채널/워커
- Presence Heartbeat(5–10s), Broadcast 이벤트 발행
- 워커 클레임/락/재시도/하트비트, DLQ 정책

6) 라우팅/키(추가됨)
- `RouterSelectClient.rank` 실제 호출 경로 적용(LLM 호출 전 단계)
- 키볼트 감사·체크섬·만료 검사 반영(프로덕션 모드)

6) 관측/운영
- 구조화 로깅, 에러 맵, `/metrics`(선택)
- 런북/운영 체크리스트 갱신

## 3. 테스트(Phase C)
- 단위: 라우트/스키마/서비스
- 통합: Supabase 실환경 기반(멱등/재시도/동시성)
- E2E: 워커 병렬/타임아웃/DLQ/실시간 구독
- 성능: 큐 적재/소비 TPS, 스토리지/아티팩트 부하

추가: 검색/인덱싱 평가 하니스
- `reports/search/*` JSON 생성, hit@3 임계치(문서 0.75, 코드 0.70)

## 4. 산출물
- 문서: `DISTRIBUTED_AGENT_ARCHITECTURE_UPDATE.md`(갱신), `REALTIME_CHANNELS_AND_USAGE.md`(갱신), OpenAPI 초안, 운영 Runbook 업데이트
- 코드: `src/dev/*` 엔트리, Edge Functions 스켈레톤, 워커 Heartbeat 유틸
 - 메트릭/라우팅/키: `/api/metrics/summary`, `/api/metrics/routing`, `RouterSelectClient`, `KeyVaultClient`

## 5. 완료 기준(DoD)
- Collab API/OpenAPI/테스트 합격
- `job_events` 트리거 작동 및 구독 데모
- EF 조회/집계 제공, 대시보드 실시간 반영
- 메인 엔트리 분리로 빌드/런 성공
 - 메트릭 Phase A 지표 노출 및 리그레션 통과, 라우팅 스냅샷/Key‑Vault 연동 확인

