### Ops Quickstart

#### Endpoints
- Metrics summary: `GET http://localhost:3100/api/metrics/summary`
- Trace lookup: `GET http://localhost:3100/api/metrics/trace/:traceId`

#### Common Tasks
- 단건 ingest+검증+트레이스: `npm run -s smoke:ingest:full:report+trace`
- 배치 ingest+검증: `npm run -s smoke:ingest:batch:report`
- 서비스 게이트 번들: `HOST=http://localhost:3100 npm run -s metrics:gate:bundle`

#### Webhook Alerts
- 환경변수: `QUALITY_WEBHOOK_URLS`(comma-separated), `QUALITY_WEBHOOK_SECRET`(optional HMAC)
- UUI gate 알림 테스트(성공시 알림 없음):
  - `HOST=http://localhost:3100 SEND_ALERT=1 npm run -s metrics:service:uui:gate`
- 실패 유도 테스트(알림 기대):
  - `HOST=http://localhost:3100 SEND_ALERT=1 UUI_P95_MAX_MS=100 npm run -s metrics:service:uui:gate`

#### Nightly Regression
- PM2 등록(매일 03:00): `scripts/pm2/nightly-regression.config.js`
- 구성: 배치 ingest → 검증/스냅샷 → 게이트

#### Processes (PM2)
- 상태: `npx pm2 ls`
- 메트릭 서버 재시작: `npx pm2 restart scripts/pm2/metrics-server.config.js`
- 스모크 리포터(매시 정각): `npx pm2 restart scripts/pm2/smoke-reporter.config.js`
- 야간 배치 확인: `npx pm2 describe nightly-regression | cat`

#### Emergency
- 메트릭 서버 수동 기동: `nohup ts-node src/servers/metrics/index.ts > /tmp/metrics-server.manual.log 2>&1 &`
- 요약 확인: `curl -s http://localhost:3100/api/metrics/summary | jq .`


