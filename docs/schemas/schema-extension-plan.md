# 데이터베이스 스키마 확장 계획

## 📋 개요

이 문서는 `database-design-and-namespace.md` 가이드라인에 따라 현재 COGO Agent Core 시스템의 데이터베이스 스키마를 확장하는 계획입니다.

- **기준 문서**: `docs/database-design-and-namespace.md`
- **현재 스키마**: `docs/current-schema-analysis.md`
- **목표**: 확장성, 명확성, 추적성 강화

---

## 🎯 확장 목표

### 1. **사용자 대화 관리 강화**
- 현재: 실시간 메시지만 저장
- 목표: 구조화된 대화 세션 및 메시지 관리

### 2. **에이전트 작업 추적 개선**
- 현재: 기본적인 작업 상태만 관리
- 목표: 상세한 작업 단계 및 이력 추적

### 3. **지식 그래프 확장**
- 현재: 기본적인 개념 및 관계만 저장
- 목표: 코드 구조와 변경 이력 연동

---

## 🗄️ Supabase PostgreSQL 스키마 확장

### 📁 1. 사용자 대화 관리 (User Conversation)

#### **새로 추가할 테이블**

##### **`conversation_sessions`** - 대화 세션
```sql
-- 대화 세션 ENUM 타입
CREATE TYPE conversation_status AS ENUM (
  'active',
  'paused', 
  'completed',
  'archived'
);

-- 대화 세션 테이블
CREATE TABLE conversation_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  title TEXT,
  status conversation_status DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_message_at TIMESTAMPTZ,
  metadata JSONB,
  
  -- 인덱스
  CONSTRAINT idx_conversation_sessions_user_id UNIQUE (user_id, created_at)
);

-- 인덱스 생성
CREATE INDEX idx_conversation_sessions_user_id ON conversation_sessions (user_id);
CREATE INDEX idx_conversation_sessions_status ON conversation_sessions (status);
CREATE INDEX idx_conversation_sessions_updated_at ON conversation_sessions (updated_at);
```

##### **`conversation_messages`** - 대화 메시지
```sql
-- 메시지 역할 ENUM 타입
CREATE TYPE message_role AS ENUM (
  'user',
  'assistant',
  'system',
  'agent'
);

-- 대화 메시지 테이블
CREATE TABLE conversation_messages (
  id BIGSERIAL PRIMARY KEY,
  session_id UUID NOT NULL REFERENCES conversation_sessions(id) ON DELETE CASCADE,
  role message_role NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  token_count INTEGER,
  metadata JSONB,
  
  -- 인덱스
  CONSTRAINT idx_conversation_messages_session_role UNIQUE (session_id, role, created_at)
);

-- 인덱스 생성
CREATE INDEX idx_conversation_messages_session_id ON conversation_messages (session_id);
CREATE INDEX idx_conversation_messages_role ON conversation_messages (role);
CREATE INDEX idx_conversation_messages_created_at ON conversation_messages (created_at);
```

### 📁 2. 에이전트 작업 관리 (Agent Task)

#### **기존 테이블 확장**

##### **`agent_tasks`** - 에이전트 작업 (새로 추가)
```sql
-- 작업 상태 ENUM 타입
CREATE TYPE task_status AS ENUM (
  'pending',
  'running', 
  'completed',
  'failed',
  'cancelled'
);

-- 에이전트 작업 테이블
CREATE TABLE agent_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES conversation_sessions(id) ON DELETE SET NULL,
  title TEXT,
  description TEXT,
  status task_status NOT NULL DEFAULT 'pending',
  final_output JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  metadata JSONB,
  
  -- 인덱스
  CONSTRAINT idx_agent_tasks_session_status UNIQUE (session_id, status, created_at)
);

-- 인덱스 생성
CREATE INDEX idx_agent_tasks_session_id ON agent_tasks (session_id);
CREATE INDEX idx_agent_tasks_status ON agent_tasks (status);
CREATE INDEX idx_agent_tasks_created_at ON agent_tasks (created_at);
```

##### **`task_steps`** - 작업 단계 (새로 추가)
```sql
-- 작업 단계 테이블
CREATE TABLE task_steps (
  id BIGSERIAL PRIMARY KEY,
  task_id UUID NOT NULL REFERENCES agent_tasks(id) ON DELETE CASCADE,
  step_name TEXT,
  step_type TEXT,
  details JSONB,
  status TEXT DEFAULT 'pending',
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- 인덱스
  CONSTRAINT idx_task_steps_task_step UNIQUE (task_id, step_name, created_at)
);

-- 인덱스 생성
CREATE INDEX idx_task_steps_task_id ON task_steps (task_id);
CREATE INDEX idx_task_steps_status ON task_steps (status);
CREATE INDEX idx_task_steps_created_at ON task_steps (created_at);
```

#### **기존 테이블 수정**

##### **`tasks` 테이블 확장**
```sql
-- 기존 tasks 테이블에 새로운 컬럼 추가
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS session_id UUID REFERENCES conversation_sessions(id);
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS parent_task_id UUID REFERENCES tasks(id);
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS assigned_agent_type VARCHAR(100);
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS estimated_duration INTEGER;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS actual_duration INTEGER;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS started_at TIMESTAMPTZ;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;

-- 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_tasks_session_id ON tasks (session_id);
CREATE INDEX IF NOT EXISTS idx_tasks_parent_task_id ON tasks (parent_task_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_agent_type ON tasks (assigned_agent_type);
```

### 📁 3. 벡터 검색 강화

#### **새로운 벡터 테이블**

##### **`conversation_embeddings`** - 대화 임베딩
```sql
-- 대화 임베딩 테이블
CREATE TABLE conversation_embeddings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES conversation_sessions(id) ON DELETE CASCADE,
  message_id BIGINT REFERENCES conversation_messages(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  embedding vector(1536),
  embedding_model VARCHAR(100) DEFAULT 'text-embedding-ada-002',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- 인덱스
  CONSTRAINT idx_conversation_embeddings_session_message UNIQUE (session_id, message_id)
);

-- HNSW 인덱스 생성
CREATE INDEX idx_conversation_embeddings_embedding ON conversation_embeddings 
USING hnsw (embedding vector_cosine_ops);

-- 일반 인덱스
CREATE INDEX idx_conversation_embeddings_session_id ON conversation_embeddings (session_id);
CREATE INDEX idx_conversation_embeddings_message_id ON conversation_embeddings (message_id);
```

##### **`task_embeddings`** - 작업 임베딩
```sql
-- 작업 임베딩 테이블
CREATE TABLE task_embeddings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES agent_tasks(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  embedding vector(1536),
  embedding_model VARCHAR(100) DEFAULT 'text-embedding-ada-002',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- 인덱스
  CONSTRAINT idx_task_embeddings_task UNIQUE (task_id)
);

-- HNSW 인덱스 생성
CREATE INDEX idx_task_embeddings_embedding ON task_embeddings 
USING hnsw (embedding vector_cosine_ops);

-- 일반 인덱스
CREATE INDEX idx_task_embeddings_task_id ON task_embeddings (task_id);
```

### 📁 4. 새로운 RPC 함수

#### **대화 검색 함수**
```sql
-- 대화 내용 검색
CREATE OR REPLACE FUNCTION search_conversation_content(
  query_vector vector,
  session_id UUID DEFAULT NULL,
  match_threshold DOUBLE PRECISION DEFAULT 0.7,
  match_count INTEGER DEFAULT 5
) RETURNS TABLE (
  id UUID,
  session_id UUID,
  message_id BIGINT,
  content TEXT,
  similarity DOUBLE PRECISION,
  created_at TIMESTAMPTZ
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ce.id,
    ce.session_id,
    ce.message_id,
    ce.content,
    1 - (ce.embedding <=> query_vector) as similarity,
    ce.created_at
  FROM conversation_embeddings ce
  WHERE (session_id IS NULL OR ce.session_id = search_conversation_content.session_id)
    AND 1 - (ce.embedding <=> query_vector) > match_threshold
  ORDER BY ce.embedding <=> query_vector
  LIMIT match_count;
END;
$$;
```

#### **작업 검색 함수**
```sql
-- 작업 내용 검색
CREATE OR REPLACE FUNCTION search_task_content(
  query_vector vector,
  task_status TEXT DEFAULT NULL,
  match_threshold DOUBLE PRECISION DEFAULT 0.7,
  match_count INTEGER DEFAULT 5
) RETURNS TABLE (
  id UUID,
  task_id UUID,
  content TEXT,
  similarity DOUBLE PRECISION,
  created_at TIMESTAMPTZ
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT 
    te.id,
    te.task_id,
    te.content,
    1 - (te.embedding <=> query_vector) as similarity,
    te.created_at
  FROM task_embeddings te
  JOIN agent_tasks at ON te.task_id = at.id
  WHERE (task_status IS NULL OR at.status = search_task_content.task_status)
    AND 1 - (te.embedding <=> query_vector) > match_threshold
  ORDER BY te.embedding <=> query_vector
  LIMIT match_count;
END;
$$;
```

---

## 🌐 Neo4j Knowledge Graph 확장

### 📁 1. 새로운 노드 타입

#### **`ConversationSession`** - 대화 세션
```cypher
CREATE (cs:ConversationSession {
  session_id: STRING,
  user_id: STRING,
  title: STRING,
  status: STRING,
  created_at: DATETIME,
  updated_at: DATETIME,
  metadata: MAP
})
```

#### **`Message`** - 메시지
```cypher
CREATE (m:Message {
  message_id: STRING,
  session_id: STRING,
  role: STRING,
  content: STRING,
  token_count: INTEGER,
  created_at: DATETIME,
  metadata: MAP
})
```

#### **`CodeFile`** - 코드 파일
```cypher
CREATE (cf:CodeFile {
  file_path: STRING,
  language: STRING,
  summary: STRING,
  complexity_score: FLOAT,
  created_at: DATETIME,
  updated_at: DATETIME
})
```

#### **`Function`** - 함수
```cypher
CREATE (f:Function {
  name: STRING,
  signature: STRING,
  docstring: STRING,
  code_hash: STRING,
  complexity_score: FLOAT,
  created_at: DATETIME
})
```

#### **`Class`** - 클래스
```cypher
CREATE (c:Class {
  name: STRING,
  docstring: STRING,
  code_hash: STRING,
  complexity_score: FLOAT,
  created_at: DATETIME
})
```

#### **`Library`** - 라이브러리
```cypher
CREATE (l:Library {
  name: STRING,
  version: STRING,
  description: STRING,
  created_at: DATETIME
})
```

#### **`Commit`** - 커밋
```cypher
CREATE (c:Commit {
  hash: STRING,
  message: STRING,
  author: STRING,
  timestamp: DATETIME,
  files_changed: LIST<STRING>
})
```

### 📁 2. 새로운 관계 타입

#### **대화 관련 관계**
```cypher
// 대화 세션이 메시지를 포함
(ConversationSession)-[:CONTAINS]->(Message)

// 메시지가 에이전트 작업을 생성
(Message)-[:GENERATES]->(Task)

// 대화 세션이 에이전트 작업을 포함
(ConversationSession)-[:HAS_TASK]->(Task)
```

#### **코드 구조 관계**
```cypher
// 파일이 함수/클래스를 포함
(CodeFile)-[:CONTAINS]->(Function)
(CodeFile)-[:CONTAINS]->(Class)

// 함수가 다른 함수를 호출
(Function)-[:CALLS]->(Function)

// 파일이 라이브러리를 임포트
(CodeFile)-[:IMPORTS]->(Library)

// 함수/클래스가 라이브러리를 사용
(Function)-[:USES]->(Library)
(Class)-[:USES]->(Library)
```

#### **개념 구현 관계**
```cypher
// 함수/클래스가 개념을 구현
(Function)-[:IMPLEMENTS]->(Concept)
(Class)-[:IMPLEMENTS]->(Concept)

// 코드가 특정 작업에 의해 생성/수정됨
(CodeFile)-[:GENERATED_BY]->(Task)
(Function)-[:GENERATED_BY]->(Task)
```

#### **버전 관리 관계**
```cypher
// 커밋이 파일을 수정
(Commit)-[:MODIFIED]->(CodeFile)

// 커밋이 함수/클래스에 영향을 줌
(Commit)-[:AFFECTS]->(Function)
(Commit)-[:AFFECTS]->(Class)

// 작업이 커밋을 생성
(Task)-[:CREATES_COMMIT]->(Commit)
```

### 📁 3. 인덱스 생성

```cypher
// 노드 인덱스
CREATE INDEX conversation_session_id IF NOT EXISTS FOR (cs:ConversationSession) ON (cs.session_id);
CREATE INDEX message_id IF NOT EXISTS FOR (m:Message) ON (m.message_id);
CREATE INDEX code_file_path IF NOT EXISTS FOR (cf:CodeFile) ON (cf.file_path);
CREATE INDEX function_name IF NOT EXISTS FOR (f:Function) ON (f.name);
CREATE INDEX class_name IF NOT EXISTS FOR (c:Class) ON (c.name);
CREATE INDEX library_name IF NOT EXISTS FOR (l:Library) ON (l.name);
CREATE INDEX commit_hash IF NOT EXISTS FOR (c:Commit) ON (c.hash);

// 관계 인덱스
CREATE INDEX contains_relationship IF NOT EXISTS FOR ()-[r:CONTAINS]-() ON (r);
CREATE INDEX calls_relationship IF NOT EXISTS FOR ()-[r:CALLS]-() ON (r);
CREATE INDEX implements_relationship IF NOT EXISTS FOR ()-[r:IMPLEMENTS]-() ON (r);
CREATE INDEX generated_by_relationship IF NOT EXISTS FOR ()-[r:GENERATED_BY]-() ON (r);
```

---

## 🔄 마이그레이션 계획

### 📅 Phase 1: 기본 구조 추가 (1-2일)
1. ENUM 타입 생성
2. `conversation_sessions` 테이블 생성
3. `conversation_messages` 테이블 생성
4. 기본 인덱스 생성

### 📅 Phase 2: 작업 관리 확장 (2-3일)
1. `agent_tasks` 테이블 생성
2. `task_steps` 테이블 생성
3. 기존 `tasks` 테이블 확장
4. 관련 인덱스 생성

### 📅 Phase 3: 벡터 검색 강화 (2-3일)
1. `conversation_embeddings` 테이블 생성
2. `task_embeddings` 테이블 생성
3. HNSW 인덱스 생성
4. 새로운 RPC 함수 생성

### 📅 Phase 4: Neo4j 확장 (3-4일)
1. 새로운 노드 타입 생성
2. 새로운 관계 타입 생성
3. 인덱스 생성
4. 기존 데이터 마이그레이션

### 📅 Phase 5: 통합 및 테스트 (2-3일)
1. API 엔드포인트 업데이트
2. 서비스 레이어 수정
3. 통합 테스트
4. 성능 최적화

---

## 📊 예상 효과

### ✅ 확장성 향상
- 구조화된 대화 관리로 대용량 데이터 처리 가능
- 작업 단계별 추적으로 복잡한 워크플로우 지원
- 벡터 검색으로 빠른 유사성 검색

### ✅ 명확성 향상
- 명확한 네임스페이스 분리
- 일관된 데이터 모델
- 명시적인 관계 정의

### ✅ 추적성 향상
- 대화 → 작업 → 코드 생성의 완전한 추적
- 작업 단계별 상세 로그
- 버전 관리와의 연동

---

## 🚀 구현 우선순위

### 🔥 High Priority
1. `conversation_sessions` 및 `conversation_messages` 테이블
2. `agent_tasks` 및 `task_steps` 테이블
3. 기본 Neo4j 노드 및 관계 확장

### 🔶 Medium Priority
1. 벡터 임베딩 테이블
2. 고급 RPC 함수
3. 성능 최적화

### 🔵 Low Priority
1. 고급 Neo4j 관계
2. 추가 메타데이터 필드
3. 백업 및 복구 기능

---

## 📝 검토 요청사항

이 확장 계획에 대한 검토를 요청드립니다:

1. **테이블 구조**: 제안된 테이블 구조가 적절한가요?
2. **관계 설계**: Neo4j 관계가 올바르게 설계되었나요?
3. **마이그레이션 순서**: 우선순위가 적절한가요?
4. **성능 고려사항**: 인덱스 설계가 충분한가요?
5. **확장성**: 미래 요구사항을 고려했나요?

검토 후 수정사항을 반영하여 실제 마이그레이션 스크립트를 작성하겠습니다. 