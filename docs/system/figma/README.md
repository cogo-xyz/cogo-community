# Figma CTA Scenario (User → Agent → ActionFlow)

1) User intent: `1_user_intent.md`
2) Symbols(JSON): `2_symbols.json`
3) BDD feature: `3_bdd.feature`
4) ActionFlow(JSON): `4_actionflow.json`

E2E test:
```bash
SUPABASE_URL=... SUPABASE_ANON_KEY=... SUPABASE_SERVICE_ROLE_KEY=... \
  npx ts-node src/scripts/ci/scenarioFigmaE2E.ts
```
