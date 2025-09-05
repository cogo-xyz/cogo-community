## Prompt Templates and Policy (skeleton)

Purpose: centralize LLM prompt templates and policy used by the agent/generators.

Files:
- POLICY.md — guidance on style, constraints, retries/backoff, and safety.
- templates/chat.prompt.md — default chat generation template (versioned).
 - templates/ui_to_vars.prompt.md — derive variables.
 - templates/vars_to_symbols.prompt.md — define symbols from variables/events.
 - templates/symbols_to_bdd.prompt.md — draft BDD scenarios.
 - templates/bdd_to_actionflow.prompt.md — generate actionFlow.

Versioning:
- Reference prompts by `prompt_id` and `prompt_version` in artifact `meta` and `bus_events.payload`.

Note: This is a placeholder to be expanded in the next bundle.


