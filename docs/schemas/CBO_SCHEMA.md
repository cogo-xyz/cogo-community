# Code Blueprint Object (CBO) Schema (TS + PY, v3)

Single Source of Truth: source code → parsed → CBO → stored (Supabase/Neo4j) → projected to RAG (vector_documents/code_vectors).

## Supabase (Postgres) tables

- cbo_objects
  - id (text, pk)                    // stable id: sha1(language|kind|name|file_path) with 'cbo_'+prefix
  - kind (text)                      // module | class | function | method | interface | type | schema.*
  - name (text)
  - file_path (text)
  - signature (text)
  - doc (text)
  - exports (jsonb)
  - imports (jsonb)
  - metadata (jsonb)                 // language('ts'|'py'), start_line/end_line, params_json, returns_json, fields_json, module/package, reachable(bool)
  - created_at/updated_at (timestamptz)

- cbo_relations
  - id (bigint identity, pk)
  - src_id (text, fk → cbo_objects.id)
  - dst_id (text, fk → cbo_objects.id)
  - rel (text)                         // contains | imports | extends | implements | calls | uses_type | returns_type | implements_schema | uses_schema
  - metadata (jsonb)                   // weight, evidence, hop
  - created_at (timestamptz)

Indexes
- GIN on cbo_objects.metadata
- btree (src_id), (dst_id), (type)

## Neo4j (labels/relationships)
- Nodes: `:CBOObject` + language label (`:TS`|`:PY`)
  - props: id, kind, name, file_path, signature, start_line, end_line
- Rels: `:REL { rel, weight }` where rel ∈ { contains, imports, extends, implements, calls, uses_type, returns_type, implements_schema, uses_schema }

## RAG Projection
- vector_documents: title=CBO name, content=doc+signature+params/returns/fields summary, metadata: { domain:['cbo', language] }
- code_vectors (optional): code chunks with metadata.tags=[kind, language]

## Ingestion Pipeline (v3)
1) TypeScript: ts-morph + tree-sitter로 params/returns/fields/라인/contains/imports/calls(유일해석) 추출
2) Python: tree-sitter-python 1차 + LibCST/ast 2차로 params/returns(type hints)/calls/docstring 추출
3) App JSON Schema ingest: schema.ui/variables/actions/actionFlow/bdd/ddd → CBO nodes + implements/uses_schema 관계
4) Upsert to Supabase (stable id onConflict)
5) Project to Neo4j with language labels and weighted rels
6) Project to RAG (schema→contains→local_file 가중)

## Notes
- Execution-first scope only (no random repo-wide parsing). Reachable marking will be applied from server entrypoints.
- Calls are conservative: generated only when callee resolves uniquely to an internal symbol.
