# Login Scenario – Technical Notes

- Flow: Figma(UI) → Symbols(JSON) → BDD → ActionFlow(JSON) → Compile/Run(SSE) → Assert
- Symbols: see `2_symbols.json` (`#loginAPI`, `#statusMessage`)
- ActionFlow: `4_actionflow.json` uses `api_call` then `setProperty` to `appData.statusMessage`.
- Compile/Run API: `actionflow-compat/compat/actionflow/(compile|run)`
- Assertion: `actionflow_runs.result.state.appData.statusMessage === "Login successful"`

## Commands
```bash
# E2E
SUPABASE_URL=... SUPABASE_ANON_KEY=... SUPABASE_SERVICE_ROLE_KEY=... \
  npx ts-node src/scripts/ci/scenarioLoginE2E.ts
```
