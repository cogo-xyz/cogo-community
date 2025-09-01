## COGO Agent Core – Architecture Index

This repository index provides a single place to navigate the most important technical documentation needed to understand the current system state before prioritizing further development of the distributed agent (cogo0).

All documentation is written in English. Source code comments and log messages are also English-only, aligned with project preferences.

### Contents
- Supabase schema overview (tables, views, functions)
  - Markdown: ./schemas/SUPABASE_SCHEMA.md
  - CSV (machine-readable): ./schemas/supabase_objects.csv
- Neo4j ontology overview and core relationships
  - Markdown with Mermaid: ./schemas/NEO4J_ONTOLOGY.md
- Distributed Agents public API signatures
  - Markdown: ./agents/AGENTS_API_INDEX.md
  
### Plans
- Development plan and milestones
  - Markdown: ../DEVELOPMENT_PLAN.md

### Summary
- The data plane is primarily Supabase (Postgres + Realtime + Edge Functions) hosting:
  - Job queue and workflow hardening (jobs, job_events, leases, DLQ, artifacts, worker heartbeats, RPC claim_one_job family)
  - Conversation and agent-task extensions, vector search tables, hybrid search functions
  - Admin/roles, distributed communication registry, and analytics logs/metrics
- The knowledge plane is Neo4j, modeled as a core ontology for Agents, Tasks, Documents/Chunks, Code Symbols, Research Insights/Recommendations, and Events/Workflows.
- The compute plane implements a Parent Orchestrator and multiple Child Agents:
  - DistributedOrchestratorAgent (parent)
  - DistributedIndexingAgent, DistributedResearchAgent, DistributedGraphRAGAgent, DistributedExecutorAgent (children)

### How to Use
1) Start from SUPABASE_SCHEMA.md to understand persisted entities and RPCs that drive distributed operations.
2) Review NEO4J_ONTOLOGY.md to understand how knowledge and code entities are represented in the graph.
3) Inspect AGENTS_API_INDEX.md to see how agents interact, what they expose, and how orchestration is performed.

### Next Steps (Planning Stub)
Once the current state is validated via the documents above, we will produce a development plan prioritized by the cogo0 distributed agent objectives:
- Objectives (draft):
  - Robust job claiming/lease safety, transparent events, and metrics
  - End-to-end research→indexing→GraphRAG workflows
  - Real-time health monitoring, backpressure handling, and graceful recovery
- Priority areas (draft):
  - Job workflow hardening and DLQ tooling
  - Vector and hybrid search consistency (dimensions, views, RPCs)
  - Graph integration flows (research/indexing → Neo4j) and reasoning

Refer to the linked documents for the full details.


