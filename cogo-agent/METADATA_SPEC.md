### COGO Metadata Spec

Artifacts (variables/symbols/actionFlow/BDD) meta:
- meta.schema_id: string (e.g., action.flow@1)
- meta.version: string
- meta.generator_version: string
- meta.prompt_id: string
- meta.rag: { project_id: string, retrieval_strategy: string, top_k: number, context_hashes: string[] }
- meta.kg: { node_ids: string[], relation_ids: string[] }
- meta.ast: { parser_version: string, parse_ms: number, coverage: number }

bus_events.payload enrichment fields:
- prompt_id, prompt_version, model, temperature, top_p
- used_rag: boolean, retrieval_ms: number, contexts: number, retrieval_strategy: string
- used_kg: boolean, kg_nodes: number, kg_edges: number
- validate_pass: boolean, doc_parity_score: number

Conventions:
- Timestamps as ISO 8601; numeric durations in ms
- Versions as semver strings


