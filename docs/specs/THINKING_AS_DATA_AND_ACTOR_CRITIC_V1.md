## Thinking as Data & Actor–Critic Loop (V1)

Goal: Standardize LLM I/O as strict JSON so that the agent's reasoning (thinking), tool execution, automatic critique, and gate decisions are fully machine-evaluable, auditable, and optimizable in a distributed environment.

### Message Envelope (Common)
```json
{
  "version": "v1",
  "id": "msg_123",
  "correlation_id": "corr_abc",
  "trace_id": "trace_xyz",
  "role": "actor|critic|tool|system",
  "type": "plan_step|tool_call|tool_result|critique|control",
  "timestamp": "2025-08-10T05:55:00Z",
  "payload": {}
}
```

### Actor Output (Thinking as Data)
```json
{
  "version": "v1",
  "role": "actor",
  "type": "plan_step",
  "payload": {
    "step_id": "step_12",
    "intent": "Implement embedding API call",
    "hypothesis": "OpenAI embeddings 3072D will improve retrieval",
    "expected_outcome": "Return 10 similar docs under 200ms",
    "assertions": ["latency_ms <= 200", "dim == 3072", "no PII in logs"],
    "tool_plan": [
      {
        "id": "tp_1",
        "tool": "http.request",
        "args": {
          "method": "POST",
          "url": "https://api.openai.com/v1/embeddings",
          "headers": { "authorization": "Bearer {{KEY}}", "content-type": "application/json" },
          "body": { "model": "text-embedding-3-large", "input": ["hello"] }
        },
        "success_criteria": ["status==200", "body.data[0].embedding.length==3072"]
      }
    ],
    "rollback_plan": "Revert to cached embeddings for 24h",
    "confidence": 0.68,
    "budget": { "max_tokens": 5000, "max_cost_usd": 0.05 }
  }
}
```

### Tool Result
```json
{
  "version": "v1",
  "role": "tool",
  "type": "tool_result",
  "payload": {
    "step_id": "step_12",
    "tool_run_id": "run_9001",
    "tool": "http.request",
    "args_hash": "sha256:...",
    "result": {
      "status": 200,
      "latency_ms": 142,
      "body": { "data": [{ "embedding": [0.1, 0.2], "index": 0 }], "model": "text-embedding-3-large" }
    },
    "metrics": { "input_tokens": 26, "output_tokens": 0, "cost_usd": 0.0008 }
  }
}
```

### Critic Verdict
```json
{
  "version": "v1",
  "role": "critic",
  "type": "critique",
  "payload": {
    "step_id": "step_12",
    "critic": "embedding_contract_check",
    "verdict": "pass",
    "score": 0.94,
    "checked": ["status==200", "dim==3072", "latency_ms<=200"],
    "evidence": [{ "ref": "tool_run:run_9001", "field": "result.body.data[0].embedding.length", "value": 3072 }],
    "fixes": [],
    "cost": { "cpu_ms": 2, "usd": 0 }
  }
}
```

### Gate Decision (System)
```json
{
  "version": "v1",
  "role": "system",
  "type": "control",
  "payload": {
    "step_id": "step_12",
    "gate_policy": "all_required_critics_pass",
    "decision": "commit",
    "next_action": { "type": "proceed", "to_step": "step_13" }
  }
}
```

### Orchestrator Loop (Actor–Critic)
- Actor emits plan_step (thinking as data)
- Execute tool_plan → produce tool_result events
- Run critics → produce critique events
- Gate applies policy → commit/retry/branch
- Record all events to Supabase; link artifacts and knowledge

### Supabase Mapping (Tables)
- plans, plan_steps, tool_runs, critic_verdicts, branch_tree, agent_subagents, agent_tools, file_snapshots
- See `docs/supabase/sql/DEEP_AGENTS_SCHEMA.sql` for DDL

### Neo4j Mapping (Concept Graph)
- Nodes: Plan, Step, Thought, Critique, Tool, Run, Artifact, Knowledge, InductiveBias
- Relationships: (Plan)-[:HAS_STEP]->(Step), (Step)-[:EMITS]->(Thought), (Critique)-[:EVALUATES]->(Step), (Step)-[:CALLS]->(Tool), (Step)-[:PRODUCES]->(Artifact), (Step)-[:REFERENCES]->(Knowledge), (Step)-[:NEXT]->(Step), (InductiveBias)-[:APPLIES_TO]->(Step)

### Policies & Gates
- Gate policies: all_required_critics_pass | weighted_threshold | domain_specific
- Budget guards: max tokens/cost/time per step/plan
- Safety: redact PII, allow-list tools, domain constraints as Inductive Bias


