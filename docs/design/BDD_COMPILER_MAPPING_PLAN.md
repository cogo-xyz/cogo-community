## BDD Compiler Mapping Plan (Source-first)

This plan extends the BDD compiler (`src/services/bdd/compiler.ts`) and runner to align with action docs under `docs/research/actions`.

### Scope
- Navigation: `navigationAction.md`, `goToLinkAction.md`
- UI Popups/Dialogs/Sheets/Calendar: `showPopupAction.md`, `showErrorPopupAction.md`, `showLoadingDialogAction.md`, `open/close Drawer/BottomSheet/Calendar`, `showWebInPopupAction.md`
- REST: `restApiAction.md`
- Conditionals/Expressions: `conditionalActions.md`, `expressionActions.md`
- Flow: `callFlowAction.md`, `stopFlowAction.md`
- Misc: `setLanguageAction.md`, `selectLanguageAction.md`, `scrollToPositionAction.md`

### Design
- Map to COGO ActionFlow DSL types: `navigate`, `emit`, `api_call`, `if`, `switch`, `expression`, `call_flow`, `loop`, `break`, `stop_flow`(new semantic)
- Emit events namespace: `ui.*`, `nav.*`, `flow.*`
- Preserve unknown/extra fields to `params.extra`

### Mappings
- navigationAction → `{ type: 'navigate', params: { path|route|target, animated? } }`
- goToLinkAction → `{ type: 'emit', params: { event: 'ui.open_link', payload: { url, target? } } }`
- showPopupAction → `{ type: 'emit', params: { event: 'ui.popup', payload: { title, message, buttons? } } }`
- showErrorPopupAction → `{ type: 'emit', params: { event: 'ui.error', payload: { title, message, buttonText? } } }`
- showLoadingDialogAction → `{ type: 'emit', params: { event: 'ui.loading', payload: { visible: true, text? } } }`
- openDrawerAction/closeDrawerAction → `emit(ui.drawer.open/ui.drawer.close)`
- openBottomSheetAction/closeBottomSheetAction → `emit(ui.bottom_sheet.open/ui.bottom_sheet.close)`
- openCalendarAction → `emit(ui.calendar.open)`
- showWebInPopupAction → `emit(ui.web.popup)` with `{ url, title? }`
- restApiAction → `api_call` with `{ baseUrl, path, method, headers, body, authJwt, retries?, timeoutMs?, saveTo? }`
- conditionalActions → `if` / `switch`
- expressionActions → `expression` with `execute="<lhs>=<rhs>" | eval(...)`
- callFlowAction → `call_flow` with `{ flowId, args? }`
- stopFlowAction → `stop_flow`
- setLanguageAction/selectLanguageAction → `emit(ui.language.set/select)`
- scrollToPositionAction → `emit(ui.scroll.to)` with `{ x?, y?, animated? }`

### Compiler changes
- Extend `compileAction` switch to cover the above keys, reading documented parameter names; normalize to standard `params`.
- Add `params.extra` bucket for unsupported fields.

### Runner changes
- Add `stop_flow` to `MiniRunner` resulting in early termination and event `flow.stop`.
- Include common payload fields in `navigate` and `emit` for observability.

### Gate enhancements
- Add env thresholds: `KG_MIN_EDGES` (default 1), `STEP_MIN_COUNTS` (JSON: `{ "api_call": 1, "navigate": 1 }`).
- Gate fails with explicit reason in `summary/junit.xml` and `summary.md`.

### Tests
- Update bddCompileSmoke with new actions.
- Add runner E2E for stop_flow, language, scroll and drawer/sheet open/close.


