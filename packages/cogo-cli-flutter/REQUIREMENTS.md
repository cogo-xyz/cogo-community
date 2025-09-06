## cogo-cli-flutter: 요구사항(웹/모바일/데스크톱 공통)

### 1) 지원 플랫폼 및 가드
- 지원: Web, Mobile(Android/iOS), Desktop(macOS/Windows/Linux)
- 런타임 가드(필수)
  - `runner_type`: `native` | `web`
  - Web:
    - 금지: 로컬 파일 쓰기·읽기(사용자 제스처 없는 임의 경로), 로컬 프로세스 실행(Process.run), stdin 직접 블로킹 입력
    - 허용: HTTP(S)/SSE, 브라우저 제공 다운로드(사용자 제스처 기반), in-memory 로깅
  - Native(모바일/데스크톱):
    - 파일 I/O는 앱 샌드박스/권한 정책 준수
    - 프로세스 실행은 기본 금지(옵션): allowlist로만 허용

### 2) 구성/환경 변수
- SUPABASE_EDGE 또는 SUPABASE_PROJECT_ID + SUPABASE_ANON_KEY
- .cogo/runner.config.json (옵션)
  - allowlist/denylist/env_allow/env_deny/auto_cli_allow
  - default_cli_retries/default_cli_retry_backoff_ms/default_cli_timeout_seconds
  - default_cli_on_fail: stop|continue
  - runner_type: native|web (플랫폼에 맞게 기본값 설정)

### 3) 명령/기능 범위
- Chat Gateway: chat-send, chat-stream(SSE), chat-loop(폴링/next_actions 실행)
- Trace: status/logs/open
- Attachments: presign/ingest/result/download(+batch/list/rm: 로컬동작은 runner_type에 맞춰 가드)
- JSON Ops: json-set/merge/remove/get/list
  - remote 모드(Edge) 필수 지원, local 파일 모드는 runner_type='native'에서만 허용
- Apply Edits: 원격에서 전달된 edits 적용
  - web: 금지(미적용); native: allowlist로 opt-in 허용

### 4) 안전/보안
- 비밀정보 마스킹 출력(_maskSecrets): token/password/apiKey/JWT 등
- allow/deny 리스트 기반 실행 가드, env 전달 필터링
- 재시도/백오프/타임아웃 기본값 제공 및 옵션화
- 로그 저장:
  - web: 메모리/콘솔/서버 업로드(옵션)
  - native: 파일 로그 허용(디렉터리 지정 시)

### 5) API/호출 규약
- 모든 커맨드는 JSON 응답 출력(표준 키: ok/domain/action/status 등)
- --out-json/--out-trace/--out-actions 등 파일 출력 옵션은 runner_type='web'에서 no-op 처리
- SSE: 이벤트/델타 수신 시 진행 상황 점 표기 또는 JSON 프레임 누적 요약 옵션

### 6) IDE/Agent 연동 가이드(권장)
- next_actions 스키마에 `ide_command` 타입 권장: IDE가 파싱·실행
- 또는 `cli` → `cogo_cli_flutter ide-exec --body-file ...` 등으로 IDE 인터페이스 호출(웹에선 네트워크 브릿지 필요)
- 결과/상태는 JSON으로 stdout 혹은 콜백/업로드로 반환

### 7) 추가 기능 제안(확장)
- ide-exec: 표준 입력/파일/인자에서 IdeCommand JSON을 받아 IDE 엔드포인트로 전달
- auth relay: Supabase 세션 토큰 전달 유틸(웹/네이티브 상이함)
- session-summary 고도화: step/action 로그를 한 파일(JSON Lines)로 집계
- json-remote 확장: optimistic concurrency, idempotency-key 표준화(이미 옵션 존재)

### 8) 테스트/품질
- 단위 테스트: http 모킹, 파서/실행기/재시도/백오프 검증
- e2e 샘플: examples/* 유지(웹 환경용 대체 샘플 추가)
- 린트: Dart 3.x, lints ^5 적용


