### Scope
- Figma MCP JSON → UUI JSON → Cogo UI JSON end-to-end
- Edge(compat) 강화, 대용량 ingest 파이프라인, AST 기반 변환, 검증/게이트/메트릭스/리포트/야간 배치
- 공개 플러그인 배포(cogo-open) 및 릴리즈(v0.1.1)

### Completed
- Figma Plugin (packages/figma-plugin in `cogo-open`)
  - Convert Selection → UUI/Cogo 동시 변환(`uui_json`, `cogo_ui_json`)
  - Ingest(대용량): presign → signed PUT → ingest → result 폴링 → artifact signedUrl/키/trace 표시
  - 결과 액션: Open/Copy URL, Copy Key, Copy trace, Copy UUI/Cogo JSON
  - 설정 저장/복원(LocalStorage), 선택/입력 가드, 네트워크 재시도(backoff)
  - 빌드/패키징 스크립트(`build`, `pack`) 정비 및 `dist/ui.html` 포함
  - 공개 레포 생성/구성/PR/릴리즈: `cogo-xyz/cogo-open` (PR/릴리즈 v0.1.1)

- Edge/변환/검증
  - Edge `figma-compat` 응답에 `uui_json` 동시 반환
  - UUI 스키마 추가: `docs/schemas/uui/ui.schema.json`
  - 검증 스크립트 확장: UUI/Cogo 동시 검증, 스키마 경로 자동 탐색, UUI 스키마 검증 로그

- Ingest 파이프라인/테스트
  - 단건 E2E + 검증 + 스냅샷 + 트레이스 리포트 성공
  - 배치 ingest + 검증 + 스냅샷 성공(ok=6, fail=0)
  - UiIngestWorker/버스 이벤트 경로 동작 확인(artifact 저장 및 `uui_ingest_succeeded`)

- 메트릭스/게이트/리포트
  - 메트릭 서버(요약/트레이스/대시보드/스냅샷 등) 구현 및 하드닝
  - 게이트 번들(UUI/Chat) 실행 및 통과, 스냅샷/요약 아티팩트 생성 확인
  - smoke 리포터 크론 등록(매시 정각), 수동 1회 리포트 성공
  - 야간 회귀(03:00): `nightlyRegression` PM2 크론 등록(배치 ingest → 게이트)

- 운영 복구/정리
  - PM2 설정 정리: ts-node 직접 실행, HOST=3100 적용
  - metrics-server PM2/수동 기동 모두 가능 상태 확인

### Public repo and Release
- Repo: [cogo-xyz/cogo-open](https://github.com/cogo-xyz/cogo-open)
- Release: `v0.1.1` (zip artifact 포함)

### How to run quick checks
- 단건 E2E+검증+트레이스: `npm run -s smoke:ingest:full:report+trace`
- 배치+검증: `npm run -s smoke:ingest:batch:report`
- 게이트 번들: `HOST=http://localhost:3100 npm run -s metrics:gate:bundle`
- 메트릭 요약: `curl -s http://localhost:3100/api/metrics/summary`

### Remaining / To verify
- Webhook/Alerting 운영화
  - QUALITY_WEBHOOK_URLS, QUALITY_WEBHOOK_SECRET 설정 및 알림 템플릿 확정(HMAC/재시도/회로차단)
  - 임계치 테이블에 UNIQUE 제약 추가 후 업서트 단순화(현 safe-mode read→upsert는 동작 중)

- Dashboard 강화(지표 가시화)
  - p50/p95/에러율 스파크라인 및 Top-N 실패/최근 트레이스 링크
  - 프로젝트 입력 저장/복원, 캐시/TTL 최적화

- Release/CI
  - GitHub Actions release 권한/트리거 정식화(permissions: contents: write, workflow_dispatch)
  - PR 빌드 아티팩트(zip) 업로드 안정화, README 최신 릴리즈/다운로드 링크 자동 갱신

- Plugin 품질/배포
  - presign/업로드 실패 재시도 UX 개선, 타임아웃/에러 메시지 정교화
  - Figma Community 메타(아이콘/커버/설명/권한) 정리

- Storage/보안
  - artifacts 보존 정책/버킷 분리/만료 관리, presigned 업로드 범위 제한
  - CORS/Helmet/레이트리밋 정책 점검 및 운영 문서화

- 문서화
  - Edge OpenAPI 최신화(ingest result 포함), 플러그인 README/사용 가이드 확장
  - 운영/배치/알림 Runbook 보강


