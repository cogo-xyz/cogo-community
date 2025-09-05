## Requirements Matrix (Doc → Output)

Schemas and required fields the generator/edges must satisfy.

- variables@1
  - items[]: idx, id, key, type, scope, created_at, project_id, is_list, dataType, boundVariables
  - meta: schema_id, version, generator_version, prompt_id

- symbols@1
  - items[]: idx, id, type, name, tracking_no, data, project_id, created_at
  - meta: schema_id, version, generator_version, prompt_id

- action.flow@1
  - root: id, steps[]
  - steps include types: basic, expression, conditional, callback
  - callback step has onSuccess[], onError[]
  - meta: schema_id, prompt_id, event_links.items[]

- bdd@1
  - root: name, gherkin_text, meta.schema_id

- JSON CRUD endpoints
  - set/merge/remove: Idempotency-Key headers; support If-Match/If-None-Match; emit ETag; emit json.ingest_request
  - get: HEAD + If-None-Match 304; ETag on 200
  - list: { limit, offset, next_offset, count }


