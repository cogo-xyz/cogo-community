### IDE Parity Matrix (CreateGo → COGO)

| Area | Input (min) | Endpoint | Expected Output (key fields) |
|---|---|---|---|
| Variables | `{ page_id, cogo_ui_json }` | `POST /figma-compat/uui/variables/derive` | `variables`, `uui_json`, `cogo_ui_json` |
| Symbols | `{ page_id, variables, cogo_ui_json }` | `POST /figma-compat/uui/symbols/map` | `symbols`, `uui_json`, `cogo_ui_json` |
| BDD Generate | `{ cogo_ui_json }` | `POST /figma-compat/uui/bdd/generate` | `scenarios`, `uui_json`, `cogo_ui_json` |
| BDD Refine | `{ current_bdd, refinement_queries[] }` | `POST /figma-compat/uui/bdd/refine` | `refined`, `uui_json`, `cogo_ui_json` |
| ActionFlow Refine | `{ flow_id, current_flow, refinement_queries[] }` | `POST /figma-compat/uui/actionflow/refine` | `flow_json` or parity `uui_json`, `cogo_ui_json` |

Notes
- All dev calls accept Anon; production requires JWT/HMAC.
- `x-agent-id` propagates and appears in `bus_events` when relevant.
- For parity checks, we focus on schema presence and type stability; minor field value differences are tolerated unless specified.


