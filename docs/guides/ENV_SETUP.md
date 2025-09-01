## Environment Setup (Routing & Key Vault)

Required environment variables for local scripts:

- SUPABASE_URL: `https://<project-ref>.supabase.co`
- SUPABASE_SERVICE_ROLE_KEY: service role (server-side only)
- SUPABASE_ANON_KEY: anon/public key (for Function auth headers)
- ROUTER_SELECT_URL: `https://<project-ref>.functions.supabase.co/router-select`
- KEY_VAULT_URL: `https://<project-ref>.functions.supabase.co/key-vault`
- KEY_ENV: `dev` (default)

Neo4j (Indexing & Graph):

- NEO4J_URI: e.g. `neo4j+s://<your-instance>.databases.neo4j.io`
- NEO4J_USERNAME: e.g. `neo4j`
- NEO4J_PASSWORD: password for the above user
- Optional (Aura): `AURA_INSTANCEID`, `AURA_INSTANCENAME`

Recommended command examples:

```
# List keys
SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... npm run keys:list -- dev

# Upsert keys directly (dev plaintext)
SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... npm run keys:upsert:db -- anthropic chat anthropic/claude-3.5-sonnet <ANTHROPIC_API_KEY> dev false
SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... npm run keys:upsert:db -- openai embeddings openai/text-embedding-3-large <OPENAI_API_KEY> dev false

# Router smoke (Option A: keep JWT verification)
SUPABASE_ANON_KEY=... ROUTER_SELECT_URL=... npm run router:smoke -- chat
SUPABASE_ANON_KEY=... ROUTER_SELECT_URL=... npm run router:smoke -- embeddings

# LLM request dry-run (routing+keys with DB fallback)
ROUTER_SELECT_URL=... KEY_VAULT_URL=... SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... npm run llm:chat:smoke -- anthropic/claude-3.5-sonnet
ROUTER_SELECT_URL=... KEY_VAULT_URL=... SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... npm run llm:embed:smoke -- openai/text-embedding-3-large
```

One-shot local PR-Lite validation (smoke + monitoring + quality-light):

```
export SUPABASE_URL=https://<project-ref>.supabase.co
export SUPABASE_ANON_KEY=<anon-jwt>
export SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
export SUPABASE_SECRET_KEY=sb_secret_...
export KEY_VAULT_URL=$SUPABASE_URL/functions/v1/key-vault
export ROUTER_SELECT_URL=$SUPABASE_URL/functions/v1/router-select
export NEO4J_URI=neo4j+s://<your-instance>.databases.neo4j.io
export NEO4J_USERNAME=neo4j
export NEO4J_PASSWORD=<password>

npm run -s ci:run:prlite:local | cat
```

Notes:
- Keep secrets out of client/UI. Use service role only on server or local scripts.
- For development convenience, scripts include DB fallbacks if Functions require auth.
- For production, use encrypted storage (`is_encrypted=true`) and KMS-backed Edge decryption.

Troubleshooting:
- `TypeError: "Bolt URL" expected to be string` → ensure `NEO4J_URI/USERNAME/PASSWORD` are present for the Indexing worker.
- `Invalid JWT` when calling Functions → send `Authorization: Bearer $SUPABASE_ANON_KEY` and set `apikey` to publishable/secret/anon per the new keys policy.
- Metrics server default port is `${METRICS_PORT:-3101}`; override with `METRICS_PORT=...` if needed.


