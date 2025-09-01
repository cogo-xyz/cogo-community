### COGO ActionFlow Methodology (UUI → COGO JSON → BDD → ActionFlow)

This document captures the methodology alignment between CreateGo and COGO Agent for dynamic UI behavior using variables, `#symbol` abstraction, BDD scenarios, and ActionFlow execution.

### Core Concepts

- **UUI → COGO UI JSON**: UI is represented in JSON. Any value that changes at runtime is modeled as a variable.
- **`#symbol` abstraction**: A symbolic reference that abstracts dynamic bind targets (UI properties, variables, APIs, flows, entities). Symbols decouple authoring from concrete implementation and enable late binding.
- **Events**: UI/user/system triggers (e.g., onTap, onLoad). Events initiate behavior transitions.
- **BDD scenarios (Given–When–Then)**: High-level behavior specifications that describe state transitions in natural language. BDD drives ActionFlow generation/refinement.
- **ActionFlow**: Executable JSON plan compiled from BDD and bound `#symbol`s. Execution mutates variables/state and emits events/metrics.
- **CQRS + Projection**: Writes occur in `cogo` schema; read models are materialized via Projection Worker and public views for IDE consumption.

### End-to-End Pipeline

1) Design → UUI/COGO JSON (static structure + dynamic bindings via `#symbol`)
2) Author BDD scenarios (Given–When–Then) tied to events
3) Compile: BDD → ActionFlow (resolve `#symbol` → concrete steps)
4) Validate: lint preconditions, check bindings, infer missing steps
5) Run: execute ActionFlow, update variables/`#symbol`, emit events/metrics (SSE/Bus)
6) Project: Projection Worker updates read models and public views

### `#symbol` Types (examples)

- UI component property: `#statusMessage`, `#theme.color.primary`
- Variables/state: `appData.*`, `uiState.*`
- API endpoint: `#loginAPI`
- Flow reference: `#loginFlow`
- Entity/schema: `#user_table`

### ActionFlow DSL (minimal schema)

- `id`: string (flow id)
- `version`: string (semver)
- `steps`: array of actions
  - `actionType`: one of `api_call | setProperty | navigate | emit | compute`
  - `target`: `#symbol` or concrete identifier
  - `params`: free-form JSON (with `#symbol` bindings)

Example:

```json
{
  "id": "loginFlow",
  "version": "1.0.0",
  "steps": [
    {
      "actionType": "api_call",
      "target": "#loginAPI",
      "params": { "body": { "email": "appData.loginEmail", "password": "appData.loginPassword" } }
    },
    {
      "actionType": "setProperty",
      "target": "appData.statusMessage",
      "params": { "value": "Login successful" }
    }
  ]
}
```

### Edge Endpoints (compatibility layer)

- `POST /compat/actionflow/compile`
  - In: `{ uui_json, bdd, symbols?, context? }`
  - Out: `{ flow, diagnostics }`

- `POST /compat/actionflow/validate`
  - In: `{ flow }`
  - Out: `{ ok, issues[] }`

- `POST /compat/actionflow/run` (SSE)
  - In: `{ flow, variables?, session_id?, trace_id? }`
  - SSE events: `aflow.start`, `aflow.step`, `aflow.warn`, `aflow.error`, `aflow.done`

- Existing: `/figma-compat/uui/actionflow/refine` (refine existing flows)

### CQRS and Storage

- **Writes**: `cogo` schema only (ActionFlow definitions, runs, symbols, histories)
- **Reads**: `public` views (IDE/compat), Projection Worker publishes `bus_events`
- **Symbols registry**: `cogo.symbols` (type, key, binding, metadata), exposed via `public.symbols`

### Observability & Reliability

- `trace_id` propagation across compile/validate/run
- SSE streams for live status; `bus_events` for durable audit
- Retries with exponential backoff, circuit breaker; DLQ with replay
- Metrics: step latency, error rate, success ratio, fan-out counts

### Security

- JWT/HMAC verification (disabled in dev if configured), CORS, IP/user/project rate limits
- Idempotency via `idempotency-key`

### Parity & Tests (CreateGo → COGO)

- Parity scenarios: compile/validate/run/refine with UUI samples
- IDE adapter: public APIs map to `compat` endpoints
- Automated smoke: ActionFlow SSE end-to-end

### Status

- Figma pipeline replacement: completed (UUI/COGO JSON generation and refine flow)
- ActionFlow replacement: refine endpoint available; compile/validate/run endpoints and runner orchestration are the next implementation items.


