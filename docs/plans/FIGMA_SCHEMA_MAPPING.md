## Figma Node-ID ↔ COGO Pages/Components – Mapping Plan (Edge-Only)

### Goals
- Maintain existing `public.pages` and `public.components` for user project data
- Manage Figma node-id to page relationships and agent metadata under `cogo` schema
- Keep Edge-only execution for context extraction and generation; no distributed agent dependency

### Current Inventory (remote)
- `public.pages`: id, name, description, width, height, image_url, path, drawer_id, header_id, footer_id, version, on_load, parent_page_id, cogo_agents, folder_id, is_folder, timestamps
- `public.components`: id, name, type, dx, dy, width, height, version, options, page_id(FK pages.id), group_id, is_lib_comp, index_in_page, parent_page_id, intents, timestamps
- `public.fig2cg_ai_res`: id, created_at, json (legacy transform result)
- Missing: `public.figma_nodes` (not present)

### Design Principles
- `public` owns user-facing project entities; `cogo` owns meta/agent/runtime artifacts
- Figma node-id is many-to-many with COGO pages; one node may map to multiple pages (variants or grouping), and a page may derive from multiple nodes
- Creation path is idempotent; if no `page_id` exists, do not upsert `components`—store artifacts and links only

### Proposed Tables (cogo schema)
1) `cogo.node_page_link_meta`
   - `id` bigint PK
   - `figma_file_key` text NOT NULL
   - `node_id` text NOT NULL  // normalized (`9:5240`)
   - `page_id` bigint REFERENCES public.pages(id) ON DELETE CASCADE
   - `role` text CHECK(role IN ('primary','variant','fragment','asset')) DEFAULT 'primary'
   - `weight` numeric DEFAULT 1.0
   - `labels` text[] DEFAULT '{}'
   - `created_at` timestamptz DEFAULT now()
   - Unique(figma_file_key,node_id,page_id,role)

2) `cogo.page_classification_log`
   - `id` bigint PK
   - `trace_id` uuid
   - `figma_file_key` text
   - `node_id` text
   - `page_id` bigint
   - `classifier` text  // rule/LLM/version
   - `reason` text
   - `score` numeric
   - `created_at` timestamptz DEFAULT now()

3) `cogo.ast_cache`
   - `id` bigint PK
   - `page_id` bigint REFERENCES public.pages(id) ON DELETE CASCADE
   - `ast_kind` text CHECK(ast_kind IN ('uui','aflow','layout','code'))
   - `hash` text
   - `payload` jsonb
   - `created_at` timestamptz DEFAULT now()
   - Unique(page_id, ast_kind, hash)

4) `cogo.rag_documents`
   - `id` bigint PK
   - `page_id` bigint NULL
   - `source` text  // figma, doc, ui
   - `content` text
   - `embedding` vector  // via pgvector dim from env
   - `meta` jsonb
   - `created_at` timestamptz DEFAULT now()

5) `cogo.prompt_templates` / `cogo.prompt_logs`
   - templates: `{ name, version, body, meta, created_at }`
   - logs: `{ trace_id, name, model, body, variables, output, created_at }`

### Edge Function Interfaces
- `figma-context`
  - `/start` with `file_key`, `node_id` set → stream chunks
  - `/apply` enqueues generation or direct upsert when `page_id` known

- `figma-compat`
  - `/uui/symbols/map` requires `page_id` to upsert `components`
  - If `page_id` missing: upload artifact only and emit link candidate to `cogo.node_page_link_meta` (page_id NULL) for later manual/auto binding

- `design-generate`
  - Orchestrates Chat→RAG→LLM→UI JSON and returns SSE progress
  - Emits artifact and (optional) creates page then upserts `components`
  - Records mapping into `cogo.node_page_link_meta`

### Node-ID Normalization
- Use helper `extractNodeIdFromUrl` ensuring `9-5240` → `9:5240`
- Store normalized `node_id` only; original form kept in `meta` when needed

### Migration Order (for operator)
1) Create `cogo` schema if missing
2) Create 1)~5) tables with grants: `USAGE` on schema to anon/authenticated as needed, `SELECT` to anon for read-only analytics, `INSERT/UPDATE` via edge functions with service role
3) Optionally add public alternatives `public.figma_files`, `public.figma_nodes` if product requires user-visible listing

### Data Flow
1) Figma plugin/URL → `figma-context/start` → chunks
2) User chooses `/apply` or `/design-generate` → UI JSON
3) If `page_id` present: `components` upsert; else artifact only
4) Link node-id ↔ page via `cogo.node_page_link_meta` (one or many)
5) Ingest to `cogo.rag_documents`; embeddings via shared embed function

### Validation & Introspection
- Use `schema-introspect?tables=pages,components,fig2cg_ai_res` for remote check
- Prefer DB function `public.get_columns(text[])` (SECURITY DEFINER) for authoritative metadata

### Security
- Secrets in Key-Vault/.env only (no commit/paste)
- Dev: disable JWT/HMAC as configured; Prod: enable JWT/HMAC and rate-limit & idempotency

### Open Questions
- Should public expose `figma_nodes` as user-visible assets? Or keep all node-linking meta in `cogo`?
- Embedding dimension and model alignment with existing pgvector config

