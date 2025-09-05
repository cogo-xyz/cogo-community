## Prompt Policy (draft)

- Use English-only templates; deterministic keys; include trace_id.
- Include system guidance on schema IDs, required fields, and don’t fabricate.
- Backoff: retry up to 2 times on invalid JSON; increase temperature slightly on retry.
- Log `prompt_id`, `prompt_version`, model, temperature, top_p into bus_events.


