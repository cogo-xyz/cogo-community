### CreateGo-Agent → COGO Cutover Checklist

- [ ] Edge endpoints parity validated (`/figma-compat/uui/*`, `/chat`/`/chat-gateway`)
- [ ] OpenAPI updated and types generated
- [ ] Figma plugin updated (generate/LLM, ingest, SSE, x-agent-id)
- [ ] `cogo.project_updates` outbox events flowing; worker marks done
- [ ] IDE writes/upserts only to `public.*`; agent writes only to `cogo.*`
- [ ] Observability: `bus_events` present; traces queryable
- [ ] Security toggles set for environment (JWT/HMAC in prod)
- [ ] Rollback plan prepared (re-enable legacy endpoints)
- [ ] Docs updated in community repo
