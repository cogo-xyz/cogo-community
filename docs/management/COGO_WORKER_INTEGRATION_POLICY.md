# COGO Worker Integration Policy (Authoritative Reference)

본 문서는 Python 기반 `cogo-worker`(테스트가 충분히 이뤄진 코드)를 본 레포의 파이프라인과 통합할 때 반드시 준수해야 할 기준을 규정합니다. `cogo-worker`는 실행/빌드/테스트/샌드박스 관리를 담당하는 권위(reference) 구현이며, 프로덕션/스테이징에서는 Mock 경로보다 `cogo-worker` 연동이 우선되어야 합니다.

## 원칙
- 반드시 참조: `cogo-worker`는 이미 테스트가 다수 수행된 코드로, 실행·빌드·테스트 단계의 기준 구현입니다.
- 로컬/개발 편의와 분리: 로컬 개발에서는 Mock를 허용하되, 스테이징/프로덕션/CI 게이트는 `cogo-worker` 경로를 필수화합니다.
- 추적가능성: 모든 연동 이벤트는 `trace_id`와 `bus_events`에 기록되어야 하며, `/api/metrics/trace/{traceId}`로 상관관계 조회가 가능해야 합니다.

## 적용 범위
- Build/Test 파이프라인: `cogo-worker`가 실제 빌드·테스트를 수행하고 결과를 반환
- 샌드박스 실행(격리 실행): 코드 실행/런타임 제어, 로그/리소스 제한 적용
- 선택적 코드생성 위임: 필요 시 코드 생성 단계도 `cogo-worker` 래퍼로 위임 가능

## 연동 모드
1) REST 모드(권장 단순화)
- `BuildTestBusWorker` → `POST http://<cogo-worker-host>/run/build-test`
- Request: `{ task_id, repo/ref(optional), edits_url(optional), trace_id }`
- Response: `{ passed, tests, failures, duration_ms, report_url }`
- 실패/타임아웃: 지수 백오프 재시도(`execute_retry`), 최종 실패 시 `execute_failed`/`buildtest_failed`

2) Realtime 모드(에이전트 버스)
- `cogo-worker`가 `public.agent_messages` 구독(`service=code, role=build-test, shard=N`)
- 결과 write-back: 동일 테이블 `status/result_*` 및 `bus_events` 기록
- 장점: 단일 버스 표준, 단점: 워커 배포/구독 관리 필요

## 환경 변수/구성
- `ENABLE_COGO_WORKER=true` → `cogo-worker` 연동 활성화(기본: false)
- `COGO_WORKER_URL=http://cogo-worker:8080` → REST 엔드포인트
- `COGO_WORKER_TIMEOUT_MS=60000` → REST 호출 타임아웃
- 공통: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`(이벤트/상태 기록)

## 코드 접점(반드시 참조)
- `src/workers/BuildTestBusWorker.ts`
  - 현재: Mock 보고서 작성 및 `result_url/result_snippet` 업데이트
  - 변경: `ENABLE_COGO_WORKER=true` 시 `COGO_WORKER_URL`에 REST 호출로 대체
- `src/workers/CodegenBusWorker.ts`
  - 현재: Mock `edits.json` 생성
  - 선택: 필요 시 `cogo-worker` 코드생성 래퍼로 위임(단계적 적용)

## 관측/기록
- 모든 호출/결과에 `trace_id` 포함 → `/api/metrics/bus/events?trace=...`와 `/api/metrics/trace/{traceId}`로 확인
- 감사 이벤트: `execute_enqueued/execute_retry/execute_failed/execute_done`, `buildtest_done/buildtest_failed`를 사용

## 수용 기준(게이트)
- 스테이징/프로덕션/CI에서는 `ENABLE_COGO_WORKER=true` 상태에서 파이프라인 PASS
- 게이트 정책: 실패율 ≤ 5%, 대기 p90 ≤ 5s, 결정 품질 ≥ 85%, `buildtest_done` 존재

## 롤아웃 권고
1) 개발: Mock 유지 + 플래그 온/오프로 양 경로 점검
2) 스테이징: `ENABLE_COGO_WORKER=true` 기본화, 장애 시 Mock 폴백 허용
3) 프로덕션: `ENABLE_COGO_WORKER=true` 고정, 폴백은 운영 승인 필요

## 체크리스트
- [ ] `ENABLE_COGO_WORKER=true` 환경에서 E2E 스모크 통과
- [ ] `trace_id`가 전 구간 이벤트에 포함됨 확인
- [ ] `bus_events`에 재시도/성공/실패 이벤트가 기록됨 확인
- [ ] 게이트/메트릭 API에서 품질/대기/실패율 기준 충족
