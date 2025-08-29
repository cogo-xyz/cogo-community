## COGO Agent – Chat Response Spec (User-Facing)

This document defines the format of response messages delivered to users through chat. It excludes internal utility calls (rag/llm/graph/schema-introspect, etc.) and only includes task_types exposed to user scenarios.

### Required Fields (Common)
- task_type: One of the response types defined below
- title: Simple title understandable from user's perspective
- response: Final output (or summary) text body
- trace_id: Trace ID (connected to SSE/logs/artifacts)

Table summary:

| Field     | Type   | Description                | Example                                                   |
|-----------|--------|----------------------------|-----------------------------------------------------------|
| task_type | String | Response type              | "design_generate"                                        |
| title     | String | Response title             | "Design Generation - Login Page"                         |
| response  | String | Final result (or summary) body | "UI generated. See JSON below …"                      |
| trace_id  | String | Trace ID                   | "9a5558e6-726b-41bc-8e75-6577467900d1"                  |

Common Optional Fields (when needed):
- meta: { model, page, project_id, job_id, … }
- artifacts: Result JSON/links/brief previews, etc. (prefer links for large content)

#### Artifacts Field (Purpose and Description)
- Purpose: To safely deliver large/structured outputs separately from chat body and connect to artifact storage/trace
- Reason:
  - Chat message `response` focuses on human-readable summaries
  - Original JSON/files often need format preservation, versioning, and downloads
  - Security/governance prefers delivering large/sensitive data via links/IDs
- Recommended Usage:
  - Small: Include preview portion (JSON snippet) in artifacts
  - Large: Include only artifact ID/URL (e.g., `artifact_id`, `url`)
- Example structure:
```json
{
  "artifacts": {
    "cogo_ui_json_preview": { "version": "1.0", "page": {"name": "..."}, "tree": [/* truncated */] },
    "actionflow": { "id": "...", "actionType": "flow", "steps": [/* ... */] },
    "links": [{ "name": "full_ui_json", "url": "https://.../artifacts/ui/login.json" }]
  }
}
```
- frames: SSE frame summary list (when needed)

---

## task_type Definitions and Examples

The examples below are based on actual implementations (Edge Functions: design-generate, figma-context, figma-compat series) and documented user response examples.

### 1) design_generate
- Description: User requests "Create this screen" → LLM+RAG planning → COGO UI JSON generation (progress via SSE)
- Input (example): prompt, (optional) model
- Output: Plan summary, final UI JSON preview (summary/links)

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
- Description: Scan Figma page/node structure and send components/chunks via SSE
- Input (example): figma_url (and optional node-id)
- Output: Collection summary (total chunks/representative components, etc.)

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
- Description: Apply scan results to project pages/components
- Input (example): job_id, page_id
- Output: Application results and trace_id

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
- Description: Identify dynamic points/event candidates `#symbols` from UI JSON
- Input (example): ui_json (or reference link)
- Output: `#symbols` list and brief reasoning

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
- Description: Derive/map `#symbols` to variables (appData/uiState)
- Input (example): page, symbols[], policy (naming/types)
- Output: Mapping table and type information

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
- Description: Generate BDD draft for specific event
- Input (example): event_id, symbols/variables
- Output: Given-When-Then text

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
- Description: Enhance/refine existing BDD (branches/validation, etc.)

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
- Description: Generate ActionFlow JSON from confirmed BDD (undecided steps use actionType:"none")

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
- Description: Enhance ActionFlow (guards/branches/API binding, etc.)

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
- Description: Define and bind data/REST actions (whitelist, saveTo included)

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

### Notes (Recommended Client Handling for SSE)
- When requesting with `Accept: text/event-stream`, it is recommended to display progress steps frame by frame on screen, then synthesize the "response message" from this spec at the end for delivery to the user.
- Large JSON should be provided via links/artifact IDs, with summaries included in `response`.


