# COGO Agent – User Scenarios (End-to-End)

This document describes practical, end-to-end scenarios for using the COGO Agent to go from design (Figma/UUI) to variables, BDD, actions, and ActionFlow execution. It aligns with the designer-oriented guide “CreateGo Designer Development Process – Step-by-Step Guide” and reflects the agent-driven, distributed architecture.

## Personas and Scope

- Designer: Creates/edits UI and confirms dynamic behavior with the Agent
- Developer: Connects data/API, refines BDD → ActionFlow, validates execution
- Operator: Observes metrics, profiles, and enforces security gates

Notes:
- Edge Functions (e.g., `figma-compat`) are short-lived gateways for ingestion/conversion/triggers.
- Heavy tasks (compile, run, orchestration, long statistics) are handled by the Agent services.

## Prerequisites

- A project created in the platform
- Access to COGO Agent services and Metrics server
- Fig/UUI conversion reachable via `figma-compat` Edge Function
- Required environment variables provided centrally (no secrets inside source/docs)

## Scenario 1 — From Design to Dynamic Symbols

Goal: Start from a Figma-like (or UUI JSON) layout and identify dynamic fields and events with the Agent.

Steps:
1. Designer lays out components (text, image, button, list, etc.).
2. Agent suggests interactive events (e.g., onClick, onChange, onPageLoad). Designer confirms/edits.
3. Designer marks content/style that should be dynamic; Agent proposes `#symbol` names per field.
4. Agent registers symbols for later mapping to variables.

Outcome:
- UI JSON with clearly identified dynamic points and `#symbols` (returned with `trace_id`)
- Artifacts: `cogo_ui_json_preview` + optional signed links when large

## Scenario 2 — Variable Definition and Mapping

Goal: Convert the identified `#symbols` into variables and map them back to the UI.

Steps:
1. Agent inspects UI JSON and creates variables by domain:
   - Content-type → `appData.PageName.*`
   - Style/state-type → `uiState.PageName.*`
2. Agent infers types (string, boolean, list, etc.).
3. Agent assigns initial/default values from current UI JSON (if present).
4. Agent links each `#symbol` to a concrete variable path.

Outcome:
- Deterministic symbol-to-variable references (preview + links in `artifacts`)

## Scenario 3 — Event-based BDD Definition

Goal: For an event (e.g., `#onLoginClicked`), describe expected logic with BDD.

Steps:
1. Designer writes Given-When-Then using existing `#symbols`.
2. Agent drafts candidate scenarios using UI structure, variables, and known actions.
3. Designer confirms or refines the scenario.

Outcome:
- BDD artifact(s) with `trace_id`; large text as artifact link if needed

## Scenario 4 — ActionFlow Generation from BDD

Goal: Turn the confirmed BDD into a structured ActionFlow JSON.

Steps:
1. Agent compiles BDD to ActionFlow JSON.
2. Undecided actions are marked with `actionType: "none"`.

Outcome:
- ActionFlow artifact available (preview + signed link)

## Scenario 5 — Data Actions and API Calls

Goal: Bind API/data actions while enforcing security and reliability.

Steps:
1. Define `api_call`/data actions with parameter binding from variables.
2. Enforce REST allowed hosts (whitelist) and optional idempotency.
3. Configure retries, timeouts, and onSuccess/onError branches.
4. Map responses back to variables (`saveTo`) with validated paths.

Outcome:
- Secure, observable data actions integrated (artifacts for logs/reports when large)

## Scenario 6 — Execution, Metrics, and Profiling

Goal: Execute ActionFlow, record metrics/timings, and inspect results.

Steps:
1. Run the flow via Agent Runner.
2. Inspect execution log and timings.
3. Review `/api-router/metrics/trace/{traceId}` for aggregated events + signed artifact links.

Outcome:
- Trace-bound observability with artifacts

## Scenario 7 — Iteration and Refinement

Goal: Evolve design and logic iteratively with minimal friction.

Steps:
1. Update UI JSON and re-run symbol/variable mapping.
2. Update BDD per event; recompile to ActionFlow.
3. Re-validate metrics/gates before promotion.

Outcome:
- Continuous improvement with guardrails

## Quick Commands

```bash
# Design generate
curl -sS -X POST "$BASE/design-generate" -H 'content-type: application/json' \
  -H "apikey: $ANON" -H "Authorization: Bearer $ANON" \
  --data '{"prompt":"Create a simple login page"}' | jq '{trace_id, artifacts}'

# Figma context (start → synthetic stream → status)
JOB=$(curl -sS -X POST "$BASE/figma-context/start" -H 'content-type: application/json' \
  -H "apikey: $ANON" -H "Authorization: Bearer $ANON" --data '{"figma_url":"<URL>"}' | jq -r '.job_id')

curl -sS -N -X POST "$BASE/figma-context/stream" -H 'content-type: application/json' -H 'accept: text/event-stream' \
  -H "apikey: $ANON" -H "Authorization: Bearer $ANON" --data "{\"job_id\":\"$JOB\",\"dev_enable_synthetic\":true,\"dev_total_nodes\":20}"

curl -sS "$BASE/figma-context/status?job_id=$JOB" -H "apikey: $ANON" -H "Authorization: Bearer $ANON" | jq '{ok, status, artifacts: .artifacts}'

# Trace artifacts
curl -sS "$BASE/api-router/metrics/trace/<TRACE_ID>" | jq '.artifacts'
```

## Acceptance Checklist

- [ ] Symbols are named and mapped (no orphan placeholders)
- [ ] Variables typed and initialized where needed
- [ ] BDD confirmed per interactive event
- [ ] ActionFlow compiled and passes security gates (host whitelist, idempotency if required)
- [ ] Execution succeeds; metrics/profile within thresholds
- [ ] Documentation updated (UI, BDD, flow, variable map)

## Protocol References (Edge / SSE / Realtime)

- Edge Function: All endpoints under `/figma-compat/*` are Edge (short-lived HTTP JSON). Label requests as Edge in docs.
- SSE: When using Chat via gateway, set `Accept: text/event-stream` or `{"stream": true}` to receive SSE frames.
- Realtime: Subscribe to `trace:<trace_id>` or `cogo:agent:<agent_id>` for async events if enabled.

## Figma via Plugin vs Chat

- Plugin (recommended): Configure Figma Access Token in plugin settings → select page/component → Send to Agent → receive `trace_id`/`ingestId` → proceed to BDD/ActionFlow.
- Chat-only: Provide Figma public URL; if private, do not paste token. Use Edge presign/ingest (`/figma-compat/uui/presign` → upload → `/figma-compat/uui/ingest`).

## Quick Reference – Edge vs Agent Responsibilities

- Edge (`figma-compat`): short-lived conversion/ingestion/triggers under `/figma-compat/uui/*`
- Agent: compile, run, RAG/KG, orchestration, profiling, metrics, long-running operations

---

## Appendix A — Designer Chat-driven Path (Quick Start)

When using COGO-Agent Chatting (designer/end-user flow), the steps mirror Scenarios 1–4:

1) Identify dynamics
```
User: "Scan this screen and propose #symbols and events."
Agent: lists candidate events (onClick/Load) and `#symbols` with suggested names.
```

2) Variables mapping
```
User: "Map symbols to variables for login page."
Agent: returns mapping (e.g., `#userName → #_appData.loginPage.userName`).
```

3) BDD draft & refine
```
User: "Write BDD for #onLoginClicked using #userName/#password."
Agent: outputs Given-When-Then; user refines branches/side-effects.
```

4) Generate ActionFlow
```
User: "Compile the confirmed BDD to ActionFlow."
Agent: returns ActionFlow JSON and highlights undecided steps.
```

See also: `docs/manuals/Designer_Chatting_Guide.md` for full prompts and examples.

## Appendix B — Minimal Sample Artifacts

Example BDD:
```
Given #userName and #password are provided
When #onLoginClicked occurs
Then call #restAPI:Login and set #errorMessage or navigate Home
```

Example ActionFlow (excerpt):
```json
{
  "id": "loginProcessFlow",
  "actionType": "flow",
  "steps": [
    { "actionType": "basic", "actionId": "setProperty", "params": { "target": "#isLoading", "value": true }},
    { "actionType": "callback", "actionId": "restApi", "params": { "baseUrl": "#_appData.api.base", "path": "/login", "method": "POST", "body": { "u": "#userName", "p": "#password" }, "saveTo": "#_appData.session.auth" }},
    { "actionType": "basic", "actionId": "setProperty", "params": { "target": "#isLoading", "value": false }}
  ]
}
```

## Appendix C — Useful Links

- Designer guide: `docs/methodology/172.CreateGo Designer Development Process Summary_Eng(20250326).docx.md`
- Developer manual: `docs/manuals/Developer_Manual.md`
- Designer chatting guide: `docs/manuals/Designer_Chatting_Guide.md`


