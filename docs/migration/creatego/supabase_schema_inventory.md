## Supabase 스키마 인벤토리(초안)

이 문서는 CreateGo 현행 Supabase(Postgres) 스키마를 수집·정리하고, cogo 표준과의 매핑을 위한 기초 자료를 제공합니다. 실제 정의는 SQL 덤프/정보 스키마 쿼리로 채워 넣습니다.

### 수집 대상
- 스키마/테이블/뷰 목록, 컬럼/타입/제약/기본값
- 인덱스/파티션/시퀀스
- RLS 정책, Row Level Security 활성화 여부
- 함수/트리거/확장(extensions)

### 산출 예(템플릿)
- 테이블: `public.agent_messages`
  - 컬럼: `id uuid pk`, `service text`, `role text`, `payload jsonb`, `trace_id text`, `created_at timestamptz default now()`
  - 인덱스: `idx_agent_messages_trace_id (trace_id)`
  - RLS: `enable row level security`, 정책 N건
- 테이블: `public.bus_events`
  - 컬럼: `id uuid pk`, `event text`, `payload jsonb`, `created_at timestamptz default now()`
  - 인덱스: `idx_bus_events_event (event)`

### 매핑 메모(초안)
- CreateGo의 이벤트/잡 테이블 → cogo `agent_messages`, `bus_events` 표준으로 매핑 검토
- 키 관리/비밀: cogo 키 보관 규칙(RemoteEnv/KeyVault)로 통일

### 다음 단계
- SQL 덤프 취득 → diff 정리 → idempotent 마이그레이션 스크립트 작성(`supabase/migrations/creatego_compat/*.sql`)
- 검증 쿼리 목록화(카운트, 무결성, 샘플 행 비교)




### Collected Inventory Snapshot

- Tables: n/a
- Policies: n/a
- Functions: n/a
- Indexes: n/a

<details><summary>Raw (truncated)</summary>



```json
{
  "ts": "2025-08-17T10:21:08.806Z",
  "url": "https://sqxoqetfctukfcjuyrcf.supabase.co",
  "tables": null,
  "policies": null,
  "functions": null,
  "indexes": null
}
```

</details>
