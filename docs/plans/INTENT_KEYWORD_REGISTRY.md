## COGO Intent Keyword Registry (Proposal)

### Purpose
- 프로그램이 해석 가능한 의도 키워드 집합을 표준화하여 IDE/CLI/에이전트가 일관되게 자동화하도록 함.

### Naming
- 형식: `namespace.action` (소문자, 점 분리)
- 예: `ui.generate`, `symbols.identify`, `variables.derive`, `actionflow.generate`, `actionflow.refine`, `data_action.bind`, `figma.context_scan`, `figma.apply`.

### Suggested DDL (cogo schema)
```sql
-- 의도 키워드 테이블
create table if not exists cogo.intent_keyword (
  keyword text primary key,
  version text not null default '1.0.0',
  description text,
  requires jsonb default '{}'::jsonb, -- 필요한 파라미터 스키마(zod 유사 명세)
  deprecated boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 키워드-액션 매핑(선택): 특정 키워드가 호출할 Edge/CLI 템플릿
create table if not exists cogo.intent_action_template (
  id bigserial primary key,
  keyword text references cogo.intent_keyword(keyword) on delete cascade,
  kind text check (kind in ('edge','cli','agent')) not null,
  template jsonb not null, -- { endpoint|command, args, input_ref, apply_strategy, conflict_strategy }
  enabled boolean not null default true,
  created_at timestamptz not null default now()
);

-- 트리거: updated_at 갱신
create or replace function cogo.tg_update_timestamp()
returns trigger as $$ begin new.updated_at = now(); return new; end $$ language plpgsql;
drop trigger if exists tg_u on cogo.intent_keyword;
create trigger tg_u before update on cogo.intent_keyword for each row execute function cogo.tg_update_timestamp();
```

### Governance
- 변경은 PR+승인 프로세스 필요. deprecated → grace period 후 제거.
- `requires` 스키마에 따라 런타임 검증 수행(부족 시 거절/보정).

### Runtime Validation (개요)
- `intent.keywords[*]`가 테이블에 존재하는지 체크.
- `requires`에 선언된 필수 타깃/파라미터(`project_uuid`, `page_id` 등) 만족 여부 검사.
- 매핑 템플릿(`intent_action_template`) 기반으로 `cli_actions`/`agent.requests` 자동 생성 가능.

### Examples
```json
{
  "intent": {
    "keywords": ["ui.generate", "variables.derive"],
    "parsed": {"target": {"project_uuid": "...", "page_id": 101}}
  }
}
```

### Baseline Keywords (v1)
- ui.generate
  - requires: { target.project_uuid: string }

- figma.context_scan
  - requires: { target.project_uuid: string, payload.figma_url?: string }

- figma.apply
  - requires: { target.project_uuid: string, target.page_id: number, payload.job_id: string }

- symbols.identify
  - requires: { payload.ui_json_ref?: string | payload.ui_json?: object }

- variables.derive
  - requires: { target.project_uuid: string, target.page_id?: number, payload.symbols?: string[] }

- bdd.generate
  - requires: { payload.event_id?: string, payload.context?: object }

- bdd.refine
  - requires: { payload.bdd_text?: string | payload.bdd_struct?: object }

- actionflow.generate
  - requires: { payload.bdd_text?: string | payload.bdd_struct?: object }

- actionflow.refine
  - requires: { payload.actionflow?: object }

- data_action.bind
  - requires: { payload.api?: { path: string, method: string }, target.project_uuid: string }

Note: `requires`는 zod 유사 스키마로 구현 가능하며, 서버 검증 시 미충족 항목은 400 또는 보정 경고로 처리합니다.


