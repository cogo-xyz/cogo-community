# CI Gate Playbook

## Commands

- Local scenario: `npm run -s scenario:full`
- Docker scenario: `npm run -s scenario:docker`
- Unified gate: `npm run -s gate:unified`

## Env thresholds

- `CIRCUITS_MAX` (default 2)
- `MIN_FAIL_RATE` (default 0.2)
- Optional Supabase on-mode:
  - `SUPABASE_URL`
  - `SUPABASE_SERVICE_ROLE_KEY`

## Behavior

- Unified gate runs local and docker scenarios. Any failure sets exit code 1.
- In Supabase on-mode, orchestrator events must be present (>0).
- Artifacts stored under `artifacts/` by each scenario.


