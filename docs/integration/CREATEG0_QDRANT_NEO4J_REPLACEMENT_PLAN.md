### CreateGo-Agent Replacement: Qdrant & Neo4j → COGO

#### Scope
- Replace CreateGo-Agent vector/Qdrant search with pgvector (BGE-M3 1024) + hybrid keyword
- Replace CreateGo-Agent Neo4j KG with COGO Neo4j schema/adapters

#### Qdrant → pgvector
- Importer: read Qdrant dumps (collections, points, payloads)
- Map to `cogo.vector_documents(title, content, embedding, text_tsv)`
- Embeddings: if 1536 → convert/truncate/pad to 1024, else accept 1024 as-is
- Hybrid index: HNSW + GIN(tsvector)

#### Neo4j KG
- Importer: read CreateGo KG CSV/JSON/Cypher dumps
- Map nodes to COGO labels (Concept/Technology/Pattern/Document/Code)
- Preserve relationships; attach embeddings when present

#### Adapters
- Qdrant-like API → `public.hybrid_search_vector_documents` + `match_code_vectors`
- KG queries → COGO Neo4j adapter with compatible DTOs

#### Verification
- Collection parity: top-k search consistency over sample queries
- KG parity: node/edge counts, label distribution, spot-check shortest paths


