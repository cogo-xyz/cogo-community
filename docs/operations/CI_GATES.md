### CI Gates: ActionFlow

Gate command
- `npm run -s ci:aflow`

What it runs
- `smoke:aflow:compat` (compile/validate/run SSE)
- `smoke:aflow:api` (symbol-bound API call)
- `smoke:aflow:result` (resultPath/assign mapping)
- `smoke:aflow:sse` (emit/navigate/done events)
- `smoke:aflow:metrics:direct` (metrics snapshot)

Pass criteria
- All smokes exit 0
- Metrics snapshot `error = 0`, `done > 0`

Notes
- Ensure Supabase env (URL/keys) are set in CI secrets
- For production runs, enable Edge security toggles


