## Supabase Schema – Overview (Tables, Views, Functions)

This document summarizes the current Supabase schema from the migrations present in this repository. It is intended for quick orientation before making workflow or agent changes.

### Tables (selected, grouped by domain)

#### Job/Workflow & Workers
- public.jobs
- public.job_events
- public.artifacts
- public.worker_devices
- public.worker_heartbeats
- public.job_queue_summary

#### Distributed Communication & Presence
- public.distributed_agents
- public.communication_channels
- public.distributed_messages
- public.channel_subscriptions
- public.distributed_locks
- public.communication_metrics
- public.agent_presence

#### Conversations & Tasks (client/agent)
- public.chat_sessions
- public.chat_messages
- public.agent_events
- public.conversation_sessions
- public.conversation_messages
- public.agent_tasks
- public.task_steps

#### Vector/RAG & Code
- public.vector_documents
- public.code_vectors
- public.agent_knowledge_vectors
- public.conversation_embeddings
- public.task_embeddings
- public.hybrid_parsing_results
- public.ast_nodes
- public.code_relationships
- public.rag_workflow_executions

#### Knowledge & Analytics
- public.cogo_events
- public.cogo_knowledge_documents
- public.cogo_knowledge_nodes
- public.cogo_workflow_history
- public.cogo_agent_activities
- public.cogo_knowledge_quality
- public.system_metrics
- public.performance_logs
- public.search_logs

#### Users & Roles
- public.user_roles
- public.role_permissions
- public.user_sessions

#### Realtime (scoped public.* from realtime-schema)
- public.agents
- public.tasks
- public.agent_events (realtime)
- public.performance_metrics
- public.chat_messages (realtime)
- public.notifications
- public.development_progress
- public.workflow_status
- public.system_health
- public.realtime_sessions

### Views
- conversation_summary
- agent_task_summary
- task_progress
- integrated_conversation_view
- integrated_task_view
- unified_vector_search_view
- unified_search_view
- chat_session_summary
- agent_events_summary
- flutter_projects_summary
- job_queue_summary
- agent_workload
- system_health
- task_summary
- agent_performance
- knowledge_source_health

### Functions (high-level inventory)

#### Queue & Workflow
- claim_one_job, claim_one_job_v2
- fn_job_events_on_jobs
- update_job_queue_summary

#### Worker/Leases & Edge Helpers
- workers-active (Edge Function)
- leases-release (Edge Function)

#### Metrics & Logging
- record_metric, record_performance, record_search
- collect_database_stats

#### Search & Vectors
- unified_vector_search, hybrid_search, context_aware_search
- search_documents, search_hybrid_documents, search_hybrid_agent_knowledge, search_hybrid_code
- search_similar_documents, search_agent_knowledge, search_similar_code, find_related_concepts
- generate_embedding, create_conversation_embedding, create_task_embedding, batch_create_embeddings
- match_code_vectors

#### RAG/Code Utilities
- get_parsing_results_by_language
- get_ast_nodes_by_type
- get_code_relationships_by_type
- get_workflow_execution_stats

#### Triggers & Maintenance
- update_updated_at_column
- update_code_vectors_timestamps
- update_embedding_timestamps

#### Chat/Sessions
- get_or_create_chat_session
- create_chat_session, add_chat_message, add_agent_event, search_chat_messages
- insert_cogo_client_test_data
- update_chat_session_activity

#### Permissions
- assign_user_role
- get_user_permissions
- check_user_permission
- assign_default_role_to_new_user

#### Communication
- update_agent_last_seen
- cleanup_expired_messages
- cleanup_expired_locks
- get_network_topology
- record_communication_metrics

Notes:
- Vector dimensions are standardized to 1024 based on recent migrations.
- Job claiming and events have hardened variants (multiple claim_one_job versions, job_events standardization, DLQ support).


