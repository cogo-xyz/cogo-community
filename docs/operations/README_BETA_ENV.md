## Beta Environment Templates

서버(.env 예시):
```
SUPABASE_URL=https://cjvgmyotqxfpxpvmwxfv.supabase.co
SUPABASE_ANON_KEY=
SUPABASE_PUBLISHABLE_KEY=
SUPABASE_SERVICE_ROLE_KEY=

ROUTER_SELECT_URL=${SUPABASE_URL}/functions/v1/router-select
KEY_VAULT_URL=${SUPABASE_URL}/functions/v1/key-vault

METRICS_PORT=3100
QUALITY_NOTIFY_ADMIN_TOKEN=
RAG_INTENDED_MODEL=google/gemini-2.5-pro
```

로컬(.env.local 예시):
```
SUPABASE_URL=https://cjvgmyotqxfpxpvmwxfv.supabase.co
SUPABASE_ANON_KEY=
SUPABASE_PUBLISHABLE_KEY=
METRICS_PORT=3100
```


