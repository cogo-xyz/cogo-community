## COGO Agent – Chat Response Spec (User-Facing)

이 문서는 채팅으로 사용자에게 전달되는 응답 메시지 형식을 정의합니다. 내부 유틸 호출(rag/llm/graph/schema-introspect 등)은 제외하고, 사용자 시나리오에 노출되는 task_type만 포함합니다.

### Required Fields (공통)
- task_type: 아래 정의된 응답 유형 중 하나
- title: 사용자 관점에서 이해 가능한 간단한 제목
- response: 최종 산출(또는 요약) 텍스트 본문
- trace_id: 추적 ID (SSE/로그/아티팩트와 연결)

표 형태 요약:

| Field     | Type   | Description                | Example                                                   |
|-----------|--------|----------------------------|-----------------------------------------------------------|
| task_type | String | 응답 유형                   | "design_generate"                                        |
| title     | String | 응답 제목                   | "Design Generation - Login Page"                         |
| response  | String | 최종 결과(또는 요약) 본문    | "UI generated. See JSON below …"                         |
| trace_id  | String | 추적 ID                     | "9a5558e6-726b-41bc-8e75-6577467900d1"                  |

공통 Optional Fields (필요 시):
- meta: { model, page, project_id, job_id, … }
- artifacts: 결과 JSON/링크/간략 미리보기 등 (크면 링크 권장)

#### Artifacts 필드 (목적 및 설명)
- 목적: 대용량/구조화 산출물을 채팅 본문과 분리해 안전하게 전달하고, 아티팩트 저장소/trace와 연계하기 위함
- 이유:
  - 채팅 message의 `response`는 사람이 읽는 요약에 집중
  - 원본 JSON/파일은 포맷 보존·버전링·다운로드가 필요한 경우가 많음
  - 보안/거버넌스 상, 대용량/민감 데이터를 링크/ID로 전달하는 것이 적합
- 권장 사용:
  - 소형: 미리보기 일부(JSON snippet)를 artifacts에 포함
  - 대형: 아티팩트 ID/URL만 포함(예: `artifact_id`, `url`)
- 예시 구조:
```json
{
  "artifacts": {
    "cogo_ui_json_preview": { "version": "1.0", "page": {"name": "..."}, "tree": [/* truncated */] },
    "actionflow": { "id": "...", "actionType": "flow", "steps": [/* ... */] },
    "links": [{ "name": "full_ui_json", "url": "https://.../artifacts/ui/login.json" }]
  }
}
```
- frames: SSE 프레임 요약 리스트(필요 시)

---

## task_type 정의 및 예제

아래 예제는 실제 구현(Edge Functions: design-generate, figma-context, figma-compat 계열)과 문서를 근거로 한 사용자 응답 예시입니다.

### 1) design_generate
- 설명: 사용자가 “이런 화면 만들어줘” 요청 → LLM+RAG 계획 수립 → COGO UI JSON 생성(진행은 SSE)
- 입력(예): prompt, (선택) model
- 출력: 계획 요약, 최종 UI JSON 미리보기(요약/링크)

예시 응답:
```json
{
  "task_type": "design_generate",
  "title": "Design Generation - Login Page",
  "response": "Generated UI plan (header/main/footer) and initial COGO UI JSON.",
  "trace_id": "9a5558e6-726b-41bc-8e75-6577467900d1",
  "artifacts": {
    "cogo_ui_json_preview": {
      "version": "1.0",
      "page": {"name": "loginPage"},
      "tree": [{"id": "root", "type": "container"}]
    }
  },
  "meta": {"model": "auto", "sse": true}
}
```

### 2) figma_context_scan
- 설명: Figma 페이지/노드 구조를 스캔하여 컴포넌트/청크를 SSE로 전송
- 입력(예): figma_url (및 선택 node-id)
- 출력: 수집 요약(총 청크/대표 컴포넌트 등)

예시 응답:
```json
{
  "task_type": "figma_context_scan",
  "title": "Figma Context Scan - Page",
  "response": "Scanned page successfully. 1 chunk emitted, includes header/footer placeholders.",
  "trace_id": "47423a2f-7707-4556-8abe-fb324af39975",
  "meta": {"job_id": "2a6d74b5-6490-4ded-aa08-6451c2505f63", "chunks": 1}
}
```

### 3) figma_apply
- 설명: 스캔 결과를 프로젝트 페이지/컴포넌트에 적용
- 입력(예): job_id, page_id
- 출력: 적용 결과 및 trace_id

예시 응답:
```json
{
  "task_type": "figma_apply",
  "title": "Apply to Page",
  "response": "Apply queued successfully.",
  "trace_id": "d0b1f9ab-2c8a-4851-8a90-3d34c3d3e6f0",
  "meta": {"job_id": "2a6d74b5-6490-4ded-aa08-6451c2505f63", "page_id": 101}
}
```

### 4) symbols_identify
- 설명: UI JSON에서 동적 포인트/이벤트 후보 `#symbols` 식별
- 입력(예): ui_json(또는 참조 링크)
- 출력: `#symbols` 목록 및 간단한 근거

예시 응답:
```json
{
  "task_type": "symbols_identify",
  "title": "Symbols Identified - loginPage",
  "response": "Found 4 symbols and 2 events.",
  "trace_id": "1f2a7b61-3a5b-4e7b-8cf2-3a1a8c02bb7a",
  "artifacts": {
    "symbols": ["#userName", "#password", "#errorMessage", "#rememberMe"],
    "events": ["#onLoginClicked", "#onRememberToggle"]
  }
}
```

### 5) variables_derive
- 설명: `#symbols`를 변수(appData/uiState)로 유도/매핑
- 입력(예): page, symbols[], 정책(네이밍/타입)
- 출력: 매핑표 및 타입 정보

예시 응답:
```json
{
  "task_type": "variables_derive",
  "title": "Variables Mapping - loginPage",
  "response": "Mapped symbols to appData/uiState.",
  "trace_id": "a4d5e4b2-3b94-4b12-9f3e-9b0f2c10a2ce",
  "artifacts": {
    "mapping": {
      "#userName": "#_appData.loginPage.userName",
      "#isLoading": "#_uiState.loginPage.isLoading"
    },
    "types": {"#_appData.loginPage.userName": "string", "#_uiState.loginPage.isLoading": "boolean"}
  }
}
```

### 6) bdd_generate
- 설명: 특정 이벤트에 대한 BDD 초안 생성
- 입력(예): event_id, symbols/variables
- 출력: Given-When-Then 텍스트

예시 응답:
```json
{
  "task_type": "bdd_generate",
  "title": "BDD Draft - #onLoginClicked",
  "response": "Given #userName and #password … Then call #restAPI:Login and set #errorMessage",
  "trace_id": "3a2b1c90-2c1e-4aa9-9b5b-0726a9d74f46"
}
```

### 7) bdd_refine
- 설명: 기존 BDD를 보강/정제(분기/유효성 등)

예시 응답:
```json
{
  "task_type": "bdd_refine",
  "title": "BDD Refined - #onLoginClicked",
  "response": "Added empty-field validation and error branch for #errorMessage.",
  "trace_id": "7c73fa9e-2a8b-4c27-814f-ef842d4d1a63"
}
```

### 8) actionflow_generate
- 설명: 확정된 BDD → ActionFlow JSON 생성(미결단계는 actionType:"none")

예시 응답:
```json
{
  "task_type": "actionflow_generate",
  "title": "ActionFlow Generated - loginProcessFlow",
  "response": "Compiled BDD to ActionFlow with 3 steps (setProperty → restApi → setProperty).",
  "trace_id": "c8b8d7f3-2f1e-4579-8b52-2b8a7db5a1b0",
  "artifacts": {
    "actionflow": {
      "id": "loginProcessFlow",
      "actionType": "flow",
      "steps": [
        {"actionType": "basic", "actionId": "setProperty", "params": {"target": "#isLoading", "value": true}},
        {"actionType": "callback", "actionId": "restApi", "params": {"path": "/login", "method": "POST"}},
        {"actionType": "basic", "actionId": "setProperty", "params": {"target": "#isLoading", "value": false}}
      ]
    }
  }
}
```

### 9) actionflow_refine
- 설명: ActionFlow 보강(가드/분기/API 바인딩 등)

예시 응답:
```json
{
  "task_type": "actionflow_refine",
  "title": "ActionFlow Refined - loginProcessFlow",
  "response": "Added guard and error branch; bound Login API with saveTo mapping.",
  "trace_id": "f1c9c220-2eb6-4e56-9ad1-216c8342d4e8"
}
```

### 10) data_action_generate
- 설명: 데이터/REST 액션 정의 및 바인딩(화이트리스트, saveTo 포함)

예시 응답:
```json
{
  "task_type": "data_action_generate",
  "title": "Data Action - Login API Binding",
  "response": "Added restApi action with host whitelist and saveTo mapping.",
  "trace_id": "a8d531d1-8d3c-43e6-8f96-a6a21f2b7c2c",
  "artifacts": {
    "action": {
      "actionType": "callback",
      "actionId": "restApi",
      "params": {
        "baseUrl": "#_appData.api.base",
        "path": "/login",
        "method": "POST",
        "body": {"u": "#userName", "p": "#password"},
        "saveTo": "#_appData.session.auth"
      }
    }
  }
}
```

---

### 참고 (SSE 사용 시 권장 클라이언트 처리)
- `Accept: text/event-stream`로 요청하면, 진행 단계를 frame 단위로 화면에 표시한 뒤, 마지막에 본 스펙의 "응답 메시지"를 합성해 사용자에게 전달하는 것을 권장합니다.
- 대용량 JSON은 링크/아티팩트 ID로 제공하고, `response`에는 요약을 싣습니다.


