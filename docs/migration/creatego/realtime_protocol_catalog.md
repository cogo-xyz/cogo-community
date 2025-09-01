## Realtime 프로토콜 카탈로그(초안)

CreateGo에서 사용하는 Supabase Realtime 채널/이벤트/페이로드 스키마를 수집합니다. cogo 표준 버스(`agent_messages`, `bus_events`)와의 매핑을 병기합니다.

### 수집 항목
- 채널명, 구독 패턴, 인증/권한, 보존 기간
- 이벤트 타입: `job_scheduled`, `job_started`, `job_succeeded`, `job_failed`, `heartbeat` 등
- 페이로드 예: `{ id, service, role, shard, trace_id, idempotency_key, attempts, payload }`

### 매핑 방향(예시)
- CreateGo 이벤트 → cogo `bus_events`
  - `job_*` → `ui_*` 또는 `mcp_*`로 네이밍 표준화
  - 알 수 없는 이벤트: DLQ 보관 + 경고 이벤트 발행

### 브릿지 정책
- 순서 보존 태깅: `trace_id`, `seq`
- 재시도/회로 적용: `retry_policy.json`, `circuit_breaker.json` 키 체계 준수
- 아이템포턴시 보장: `idempotency_key` 강제




### Recent Realtime Event Types (24h)

No events in window

<details><summary>Raw (truncated)</summary>

```json
{
  "ts": "2025-08-17T10:21:10.133Z",
  "sinceIso": "2025-08-16T10:21:10.102Z",
  "byType": {}
}
```

</details>
