# 현재 데이터베이스 스키마 분석

## 📊 분석 개요

이 문서는 현재 COGO Agent Core 시스템에서 사용 중인 실제 데이터베이스 스키마를 분석한 결과입니다.

- **분석 일시**: 2025-07-29
- **Supabase 프로젝트**: cjvgmyotqxfpxpvmwxfv
- **연결 상태**: ✅ 실제 연결 확인됨
- **Mock 모드**: ❌ 비활성화됨

---

## 🗄️ Supabase PostgreSQL 스키마

### 📋 현재 테이블 목록

실제 Supabase API를 통해 확인한 테이블들:

#### 1. **code_vectors** - 코드 벡터 저장
```sql
CREATE TABLE code_vectors (
  id SERIAL PRIMARY KEY,
  file_path TEXT,
  function_name TEXT,
  code_content TEXT NOT NULL,
  code_vector vector(1536),
  language TEXT NOT NULL,
  complexity_score DOUBLE PRECISION,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

#### 2. **concept_relationships** - 개념 관계 저장
```sql
CREATE TABLE concept_relationships (
  id SERIAL PRIMARY KEY,
  concept_a TEXT NOT NULL,
  concept_b TEXT NOT NULL,
  relationship_type TEXT NOT NULL,
  relationship_vector vector(1536),
  strength DOUBLE PRECISION NOT NULL,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

#### 3. **context7_queries** - Context7 쿼리 저장
```sql
CREATE TABLE context7_queries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  query_text TEXT NOT NULL,
  query_type VARCHAR(100) NOT NULL,
  agent_id VARCHAR(255),
  status VARCHAR(50) DEFAULT 'pending',
  result JSONB,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

#### 4. **tasks** - 작업 관리
```sql
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255),
  description TEXT,
  type VARCHAR(100) NOT NULL,
  priority INTEGER DEFAULT 3,
  status VARCHAR(50) DEFAULT 'pending',
  assigned_to VARCHAR(255),
  created_by VARCHAR(255),
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

#### 5. **agent_metadata** - 에이전트 메타데이터
```sql
CREATE TABLE agent_metadata (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id VARCHAR(255) NOT NULL,
  agent_name VARCHAR(255) NOT NULL,
  agent_type VARCHAR(100) NOT NULL,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(100) NOT NULL,
  status VARCHAR(50) DEFAULT 'idle',
  current_task TEXT,
  last_activity TIMESTAMPTZ DEFAULT now(),
  tasks_completed INTEGER DEFAULT 0,
  average_time INTEGER DEFAULT 0,
  success_rate NUMERIC DEFAULT 0.0,
  capabilities JSONB,
  metadata JSONB,
  performance JSONB,
  ai_stats JSONB,
  performance_metrics JSONB,
  workload_stats JSONB,
  configuration JSONB,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

#### 6. **workflow_executions** - 워크플로우 실행
```sql
CREATE TABLE workflow_executions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  execution_id VARCHAR(255) NOT NULL,
  workflow_id VARCHAR(255) NOT NULL,
  status VARCHAR(50) DEFAULT 'pending',
  current_node VARCHAR(255),
  completed_nodes JSONB,
  failed_nodes JSONB,
  data JSONB,
  start_time TIMESTAMPTZ DEFAULT now(),
  end_time TIMESTAMPTZ,
  error TEXT,
  metadata JSONB
);
```

#### 7. **agent_knowledge_vectors** - 에이전트 지식 벡터
```sql
CREATE TABLE agent_knowledge_vectors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id VARCHAR(255) NOT NULL,
  knowledge_id VARCHAR(255) NOT NULL,
  title VARCHAR(500) NOT NULL,
  content TEXT NOT NULL,
  knowledge_type VARCHAR(100) DEFAULT 'capability',
  context JSONB,
  embedding vector(1536),
  embedding_model VARCHAR(100) DEFAULT 'text-embedding-ada-002',
  confidence_score NUMERIC DEFAULT 1.0,
  usage_count INTEGER DEFAULT 0,
  last_used TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

#### 8. **job_queue** - 작업 큐
```sql
CREATE TABLE job_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id VARCHAR(255) NOT NULL,
  title VARCHAR(255),
  description TEXT,
  priority INTEGER DEFAULT 3,
  assigned_to VARCHAR(255),
  status VARCHAR(50) DEFAULT 'pending',
  result_json JSONB,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  metadata JSONB
);
```

#### 9. **cluster_info** - 클러스터 정보
```sql
CREATE TABLE cluster_info (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  node_id VARCHAR(255) NOT NULL,
  node_name VARCHAR(255) NOT NULL,
  node_type VARCHAR(100) NOT NULL,
  status VARCHAR(50) DEFAULT 'active',
  load_balancing_info JSONB,
  coordination_data JSONB,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

#### 10. **workflow_definitions** - 워크플로우 정의
```sql
CREATE TABLE workflow_definitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow_id VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  version VARCHAR(50) DEFAULT '1.0.0',
  definition JSONB NOT NULL,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

#### 11. **vector_documents** - 벡터 문서
```sql
CREATE TABLE vector_documents (
  id SERIAL PRIMARY KEY,
  title TEXT,
  content TEXT NOT NULL,
  content_vector vector(1536),
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

#### 12. **langgraph_executions** - LangGraph 실행
```sql
CREATE TABLE langgraph_executions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  execution_id VARCHAR(255) NOT NULL,
  workflow_name VARCHAR(255) NOT NULL,
  status VARCHAR(50) DEFAULT 'running',
  current_step VARCHAR(255),
  steps_completed JSONB,
  steps_remaining JSONB,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

#### 13. **documents** - 문서
```sql
CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content TEXT NOT NULL,
  metadata JSONB,
  embedding vector(1536),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

#### 14. **agent_presence** - 에이전트 존재감
```sql
CREATE TABLE agent_presence (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id VARCHAR(255) NOT NULL,
  agent_name VARCHAR(255) NOT NULL,
  agent_type VARCHAR(100) NOT NULL,
  status VARCHAR(50) DEFAULT 'offline',
  last_heartbeat TIMESTAMPTZ DEFAULT now(),
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

#### 15. **realtime_messages** - 실시간 메시지
```sql
CREATE TABLE realtime_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id VARCHAR(255) NOT NULL,
  type VARCHAR(100) NOT NULL,
  payload JSONB NOT NULL,
  source VARCHAR(255) NOT NULL,
  target VARCHAR(255),
  timestamp TIMESTAMPTZ DEFAULT now(),
  metadata JSONB
);
```

### 🔍 RPC 함수들

#### 1. **search_agent_knowledge** - 에이전트 지식 검색
```sql
CREATE OR REPLACE FUNCTION search_agent_knowledge(
  target_agent_id TEXT,
  query_vector vector,
  knowledge_type_param VARCHAR DEFAULT NULL,
  match_threshold DOUBLE PRECISION DEFAULT 0.7,
  match_count INTEGER DEFAULT 5
) RETURNS TABLE(...)
```

#### 2. **match_documents** - 문서 매칭
```sql
CREATE OR REPLACE FUNCTION match_documents(
  query_embedding vector DEFAULT NULL,
  match_threshold DOUBLE PRECISION DEFAULT 0.7,
  match_count INTEGER DEFAULT 5
) RETURNS TABLE(...)
```

#### 3. **search_similar_documents** - 유사 문서 검색
```sql
CREATE OR REPLACE FUNCTION search_similar_documents(
  query_vector vector,
  match_threshold DOUBLE PRECISION DEFAULT 0.7,
  match_count INTEGER DEFAULT 5
) RETURNS TABLE(...)
```

#### 4. **search_similar_code** - 유사 코드 검색
```sql
CREATE OR REPLACE FUNCTION search_similar_code(
  query_vector vector,
  target_language TEXT DEFAULT NULL,
  match_threshold DOUBLE PRECISION DEFAULT 0.7,
  match_count INTEGER DEFAULT 5
) RETURNS TABLE(...)
```

#### 5. **search_concept_relationships** - 개념 관계 검색
```sql
CREATE OR REPLACE FUNCTION search_concept_relationships(
  concept TEXT,
  relationship_types TEXT[] DEFAULT NULL,
  match_threshold DOUBLE PRECISION DEFAULT 0.7,
  match_count INTEGER DEFAULT 5
) RETURNS TABLE(...)
```

---

## 🌐 Neo4j Knowledge Graph 스키마

### 📋 현재 노드 타입

기존 마이그레이션 파일을 기반으로 한 노드 타입들:

#### 1. **Concept** - 개념
```cypher
CREATE (c:Concept {
  name: STRING,
  description: STRING,
  category: STRING,
  tags: LIST<STRING>,
  created_at: DATETIME,
  updated_at: DATETIME
})
```

#### 2. **Technology** - 기술
```cypher
CREATE (t:Technology {
  name: STRING,
  version: STRING,
  description: STRING,
  category: STRING,
  created_at: DATETIME
})
```

#### 3. **Pattern** - 패턴
```cypher
CREATE (p:Pattern {
  name: STRING,
  description: STRING,
  category: STRING,
  complexity: INTEGER,
  created_at: DATETIME
})
```

#### 4. **Solution** - 솔루션
```cypher
CREATE (s:Solution {
  name: STRING,
  description: STRING,
  problem: STRING,
  approach: STRING,
  created_at: DATETIME
})
```

#### 5. **Document** - 문서
```cypher
CREATE (d:Document {
  title: STRING,
  content: STRING,
  type: STRING,
  url: STRING,
  created_at: DATETIME
})
```

#### 6. **Code** - 코드
```cypher
CREATE (c:Code {
  file_path: STRING,
  function_name: STRING,
  language: STRING,
  content: STRING,
  complexity_score: FLOAT,
  created_at: DATETIME
})
```

#### 7. **Workflow** - 워크플로우
```cypher
CREATE (w:Workflow {
  name: STRING,
  description: STRING,
  steps: LIST<STRING>,
  created_at: DATETIME
})
```

#### 8. **Task** - 작업
```cypher
CREATE (t:Task {
  task_id: STRING,
  title: STRING,
  description: STRING,
  status: STRING,
  created_at: DATETIME
})
```

#### 9. **Agent** - 에이전트
```cypher
CREATE (a:Agent {
  agent_id: STRING,
  name: STRING,
  type: STRING,
  capabilities: LIST<STRING>,
  created_at: DATETIME
})
```

#### 10. **Activity** - 활동
```cypher
CREATE (a:Activity {
  activity_id: STRING,
  type: STRING,
  description: STRING,
  timestamp: DATETIME,
  metadata: MAP
})
```

#### 11. **QualityAssessment** - 품질 평가
```cypher
CREATE (q:QualityAssessment {
  assessment_id: STRING,
  criteria: LIST<STRING>,
  score: FLOAT,
  feedback: STRING,
  created_at: DATETIME
})
```

### 🔗 관계 타입

#### 1. **USES** - 사용 관계
```cypher
(Concept)-[:USES]->(Technology)
(Code)-[:USES]->(Technology)
```

#### 2. **DEPENDS_ON** - 의존 관계
```cypher
(Technology)-[:DEPENDS_ON]->(Technology)
(Pattern)-[:DEPENDS_ON]->(Concept)
```

#### 3. **IMPLEMENTS** - 구현 관계
```cypher
(Code)-[:IMPLEMENTS]->(Pattern)
(Solution)-[:IMPLEMENTS]->(Pattern)
```

#### 4. **RELATED_TO** - 관련 관계
```cypher
(Concept)-[:RELATED_TO]->(Concept)
(Technology)-[:RELATED_TO]->(Technology)
```

#### 5. **PART_OF** - 포함 관계
```cypher
(Code)-[:PART_OF]->(Document)
(Pattern)-[:PART_OF]->(Workflow)
```

#### 6. **CONTAINS** - 포함 관계
```cypher
(Document)-[:CONTAINS]->(Code)
(Workflow)-[:CONTAINS]->(Task)
```

#### 7. **COLLABORATES_WITH** - 협업 관계
```cypher
(Agent)-[:COLLABORATES_WITH]->(Agent)
```

#### 8. **EXPERT_IN** - 전문 분야
```cypher
(Agent)-[:EXPERT_IN]->(Technology)
(Agent)-[:EXPERT_IN]->(Concept)
```

#### 9. **KNOWS_ABOUT** - 지식 관계
```cypher
(Agent)-[:KNOWS_ABOUT]->(Pattern)
(Agent)-[:KNOWS_ABOUT]->(Solution)
```

---

## 📊 스키마 분석 결과

### ✅ 현재 상태
1. **Supabase 연결**: 실제 데이터베이스에 연결되어 있음
2. **pgvector 확장**: 1536차원 벡터 지원
3. **실시간 기능**: Supabase Realtime 활성화
4. **RPC 함수**: 벡터 검색 및 매칭 함수 구현됨

### 🔍 주요 특징
1. **벡터 저장**: 코드, 문서, 개념 관계에 대한 임베딩 저장
2. **에이전트 관리**: 메타데이터, 성능, 존재감 추적
3. **워크플로우**: 정의 및 실행 상태 관리
4. **작업 큐**: 비동기 작업 처리
5. **실시간 메시징**: 에이전트 간 통신

### 📈 데이터 통계
- **총 테이블 수**: 15개
- **벡터 테이블**: 4개 (code_vectors, concept_relationships, agent_knowledge_vectors, vector_documents)
- **RPC 함수**: 5개
- **Neo4j 노드 타입**: 11개
- **Neo4j 관계 타입**: 9개

---

## 🎯 다음 단계

이 분석을 바탕으로 `database-design-and-namespace.md` 가이드라인에 따라 스키마 확장 계획을 수립할 수 있습니다. 