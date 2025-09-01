### Distributed Agents – Batch Development Plan (v1)

목적: 분산 에이전트 체계를 한 번에 크게 개선하되, 배치별 위험을 통제하고 검증 루틴을 표준화합니다.

#### 공통 검증 커맨드
- 게이트(필수): `CODE_BUILD_CMD='npm run -s build' npm run -s gate:local`
- 분산 스모크: `npm run -s smoke:distributed:buildtest`
- 메트릭 요약: `curl -s http://localhost:3001/api/metrics/summary`
- 아티팩트 인덱스: `curl -s http://localhost:3001/api/artifacts/index`

---

### Batch A. 공통 기반(필수)
- 목표: 전 에이전트 공통 규약 통일(idempotency, trace/metrics, 구성 외부화, DLQ)
- 작업
  - Idempotency 표준: `idempotency_key`, `source_hash` 생성/검증 유틸 `src/common/idempotency.ts`
  - Trace/metrics 표준: `trace_id`, `span` 전파 유틸 `src/common/trace.ts`; Prometheus 레이블 통일
  - 구성 로더: `src/common/config.ts`를 통해 `configs/*.json` 핫 리로드 대응
  - DLQ/리플레이: 실패 메시지 표준 스키마 및 재처리 스크립트 보강
- 수용 기준
  - 모든 메시지에 `trace_id` 존재, 중복 처리 시 idempotency 차단 확인
  - DLQ 이동/리플레이 정상 동작

### Batch B. BuildTest/Codegen 아티팩트 표준화
- 목표: 결과 구조/로그 일원화 및 인덱스 노출
- 작업
  - 표준 파일: `build-test/{report.json, report.json.meta.json, build.log, test.log, summary.json}`
  - Codegen 결과: `codegen/{diff.patch, summary.md, metrics.json}`
  - 공용 스키마: `configs/schemas/artifact.*.schema.json`, 타입 `src/types/artifacts.ts`
- 수용 기준
  - `/api/artifacts/index`에 신규 구조 노출, 최신 task 리포트 조회 가능

### Batch C. 재시도/서킷브레이커/백오프
- 목표: 안정성/회복력 강화
- 작업: 지수 백오프/최대 시도/감쇠 정책을 `configs/retry_policy.json`으로 통일, 서킷브레이커 추가
- 수용 기준: 실패율 증가 시 자동 감쇠, 차단 해제 로깅/메트릭 확인

### Batch D. Gateway/Orchestrator 정책/보안
- 목표: 입력·흐름 방어 및 정책 외부화
- 작업: API 인증/레이트리밋, `configs/route_policies.json` 핫 리로드
- 수용 기준: 비인증 요청 차단, 정책 변경 즉시 반영(Log)

### Batch E. Indexing/GraphRAG 정합성
- 목표: 데이터 품질과 일관성
- 작업: 벡터 차원/토크나이저 런타임 검증, Neo4j 인덱스/제약 스크립트 정리
- 수용 기준: 스키마 검사/인덱스 적용 로그 확인

### Batch F. Sandbox Worker 격리/제한
- 목표: 안전 실행 보장
- 작업: 제한 프로파일(`configs/sandbox_limits.json`) 적용, 파일시스템 허용 목록
- 수용 기준: 제한 초과 시 일관 에러코드/로그

### Batch G. Observability/알림
- 목표: 가시성/운영 반응성 강화
- 작업: Prometheus 레이블 표준(`service`,`role`,`shard`,`tenant`), 임계 초과 시 Google Chat 알림
- 수용 기준: 임계 초과 시 자동 알림, 요약에 레이블 반영

### Batch H. 문서/DevOps
- 목표: 운영 핸드오프 완결
- 작업: `docs/` 업데이트(환경변수 표, 정책, 스키마 레퍼런스), DOCKER_LOCAL_PLAYBOOK 최신화
- 수용 기준: 개발→운영 절차 누락 없음

---

### 일정/적용 순서(권장)
- Day 1: Batch A,B 병행 → 게이트/스모크/아티팩트 검증
- Day 2: Batch C,D → 실패/정책 스모크
- Day 3: Batch E,F → 데이터/격리 검증
- Day 4: Batch G,H → 알림/문서 점검, 전체 리그레션 스모크

### 산출물 체크리스트(요약)
- 공통 유틸: `src/common/{idempotency,trace,config}.ts`
- 정책/스키마: `configs/{retry_policy.json, route_policies.json, sandbox_limits.json}`, `configs/schemas/artifact.*.schema.json`
- 타입: `src/types/artifacts.ts`
- 문서: 본 문서 + DOCKER_LOCAL_PLAYBOOK.md 보완


