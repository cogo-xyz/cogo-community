### Docker Local Build/Run Playbook (Cogo Agent Core)

- 목적: 로컬 개발에서 도커 빌드/기동 실수를 줄이고, 일관된 검증 루틴을 제공합니다.

### 1) 필수 전제
- Node 20.x, Docker Desktop 최신, 충분한 디스크 여유(>10GB)
- 환경 변수: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`(선택), `GOOGLE_CHAT_WEBHOOK_URL`(선택)

### 2) 품질 게이트(로컬)
```bash
npm run -s gate:local
# 실패 시 tsc로 강제:
CODE_BUILD_CMD='npm run -s build' npm run -s gate:local
# 구글챗 알림 포함:
GOOGLE_CHAT_WEBHOOK_URL=<url> npm run -s gate:notify
```

### 3) 도커 이미지 빌드/기동/종료
```bash
# 이미지 빌드
npm run -s docker:build:dev

# 기동 (api:3001, 최소 구성)
npm run -s docker:up:local

# 종료
npm run -s docker:down:local
```

검증
```bash
# API 헬스
curl -s http://localhost:3001/api/integration/status
# 메트릭 요약
curl -s http://localhost:3001/api/metrics/summary
```

### 4) 분산 파이프라인 스모크
```bash
npm run -s smoke:distributed:buildtest
# 생성된 리포트(예)
curl -s http://localhost:3001/artifacts/<task>/build-test/report.json
```

Artifacts
- 정적 경로: `/artifacts` (컨테이너 내부 기본: `/app/artifacts`)
- 인덱스(옵션): `/api/artifacts/index` (파일 목록 제공)

### Configs
- 표준 구성 경로: `configs/` 유지 (예: `quality_thresholds.json`, `kg_scope.v1.json`)
- 레거시 `config/` 내용은 `backups/_archive_<ts>/config/`로 이동하여 보존

### 5) 자주 발생하는 문제 & 해결
- 빌드 캐시/디스크 문제
  - 증상: `no space left on device`
  - 조치: `docker system prune -a`
- 포트 충돌(EADDRINUSE)
  - 증상: `listen EADDRINUSE: :::3000`
  - 조치: `lsof -ti:3000 | xargs kill -9`
- esbuild 모듈 해상도 오류
  - 증상: `Could not resolve "./lib/axios.js"`
  - 조치: 게이트 빌드를 tsc로 강제: `CODE_BUILD_CMD='npm run -s build' npm run -s gate:local`
- Jest 커버리지 리포트 모듈 누락
  - 증상: `Cannot find module 'istanbul-reports'`
  - 조치: devDependencies 설치 유지(이미지 빌드 시 포함). 필요시 `npm i -D istanbul-reports @jest/reporters`

### 6) Dockerfile.dev 빌드 품질 체크리스트
- package*.json → npm ci --include=dev → 소스 COPY 순서를 유지
- 런타임에 `npm install` 금지(이미지 빌드 단계에서 종속성 설치)
- HEALTHCHECK 설정: `/api/integration/status`
- Node 옵션/메모리 한도 과도 설정 지양(필요시만 사용)

### 7) Compose(local) 체크리스트
- 포트 매핑: `3001:3000`
- 환경값: `ARTIFACTS_BASE=/app/artifacts` 통일
- 최소 서비스만 실행(과부하 시 worker 축소)

### 8) 안전 배포 가이드(요약)
- 금지: 홈 디렉토리 대상 `rsync --delete`
- 권장: 릴리즈 디렉토리 + 심볼릭 링크 스위칭
  1) 로컬에서 tar.gz 생성(노드 모듈/산출물 제외)
  2) 서버 업로드(scp)
  3) 서버: `~/deploy/<app>/releases/<ts>`에 압축 해제
  4) `ln -sfn releases/<ts> current` → current에서 compose 실행

### 9) 시크릿/키 관리
- 키/토큰을 코드에 커밋/출력 금지
- Supabase 키 노출 시 즉시 대시보드에서 로테이션, `.env`/CI 비밀 갱신

### 10) 표준 운영 루틴
```bash
# 1) 게이트 통과
CODE_BUILD_CMD='npm run -s build' npm run -s gate:local

# 2) 빌드/기동
npm run -s docker:build:dev && npm run -s docker:up:local

# 3) 헬스/스모크
curl -s http://localhost:3001/api/integration/status
npm run -s smoke:distributed:buildtest

# 4) 결과 확인
curl -s http://localhost:3001/api/metrics/summary
curl -s http://localhost:3001/artifacts/<task>/build-test/report.json
```

### 11) 로그/디버깅
```bash
docker ps --format '{{.Names}}\t{{.Status}}'
docker logs -n 200 cogo-agent-core-api-1
```

### 12) 참조
- 내부 스크립트: `package.json`의 `docker:*`, `gate:*`, `smoke:*`
- 서버 엔드포인트: `/api/integration/status`, `/api/metrics/summary`, `/artifacts/**`


