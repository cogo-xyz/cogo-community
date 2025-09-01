# Login Scenario – User Manual

## What you do (Designer/User)
- Design a login screen (Figma): button `loginButton`, label `statusText`.
- Specify dynamics/events:
  - `#statusMessage` changes after login
  - Tap `loginButton` triggers login

## What the agent does
- Declare symbols(JSON): `#loginAPI`, `#statusMessage`
- Write BDD (Given/When/Then)
- Generate ActionFlow(JSON) and run

## How to test
```bash
# Set env
export SUPABASE_URL=...
export SUPABASE_ANON_KEY=...
export SUPABASE_SERVICE_ROLE_KEY=...

# Run E2E
npx ts-node src/scripts/ci/scenarioLoginE2E.ts
```

Expected: `statusMessage = "Login successful"` in the result state.
