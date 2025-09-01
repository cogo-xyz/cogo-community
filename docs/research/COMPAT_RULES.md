# CreateGo → COGO ActionFlow Compatibility Rules (Minimal)

- Mapping
  - basic.navigate → navigate { path }
  - basic.showPopup → emit { event: "ui.popup", payload: { title, message } }
  - expression → expression { execute, params }
  - conditional { execute, isTrue[], isFalse[] } → if { guards:[{expr}], steps, elseSteps }
  - callback.restApi → api_call { baseUrl, path, method, body, headers, authJwt, saveTo } + onSuccess/onError chains
  - callFlow → call_flow { flowId } (headless event placeholder)

- Symbols / Context
  - `#var` read/write supported, priority: actionParams > flowContext > globals
  - saveTo: string `"#var"` → store into `#var`

- Expression (Lite)
  - Operators: arithmetic/comparison/logical, `#var` is safely transformed
  - Built-ins: toString, parseInt, parseFloat, now, len, includes
  - Timeout: default 25ms

- API Call (optional real HTTP)
  - env COMPAT_REAL_HTTP=1 → real fetch with timeout/retries
  - authJwt → Authorization: Bearer {token}
  - Retries: params.retries (default 0), Backoff: exponential (MiniRunner)
  - Timeout: params.timeoutMs respected per request

- Events
  - UI-only actions mapped to emit events (handled by UUI/IDE)

- Limits
  - Complex Dart grammar/custom functions not supported yet (planned)
  - File IO, network side-effects outside api_call are blocked
  - Large body payloads (>1MB) may be truncated by gateways
