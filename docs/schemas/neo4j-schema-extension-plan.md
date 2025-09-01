# Neo4j Knowledge Graph 스키마 확장 계획

## 📋 개요

이 문서는 `database-design-and-namespace.md` 가이드라인에 따라 현재 COGO Agent Core 시스템의 Neo4j Knowledge Graph 스키마를 확장하는 계획입니다.

- **기준 문서**: `docs/database-design-and-namespace.md`
- **현재 스키마**: `docs/neo4j-current-schema-analysis.md`
- **목표**: 확장성, 명확성, 추적성 강화

---

## 🎯 확장 목표

### 1. **대화 및 작업 추적 강화**
- 현재: Agent, Task 노드에 데이터 없음
- 목표: 완전한 대화 세션 및 작업 이력 추적

### 2. **코드 구조 표현 추가**
- 현재: 코드 관련 노드 없음
- 목표: 파일, 함수, 클래스 간의 구조적 관계 표현

### 3. **버전 관리 연동**
- 현재: 버전 관리 노드 없음
- 목표: Git 커밋과 코드 변경 이력 연동

---

## 🌐 Neo4j Knowledge Graph 확장

### 📁 1. 대화 관리 노드 (Conversation Management)

#### **`ConversationSession`** - 대화 세션
```cypher
// 대화 세션 노드 생성
CREATE (cs:ConversationSession {
  session_id: STRING,
  user_id: STRING,
  title: STRING,
  status: STRING,  // 'active', 'paused', 'completed', 'archived'
  created_at: DATETIME,
  updated_at: DATETIME,
  last_message_at: DATETIME,
  metadata: MAP
})

// 인덱스 생성
CREATE INDEX conversation_session_id IF NOT EXISTS FOR (cs:ConversationSession) ON (cs.session_id);
CREATE INDEX conversation_user_id IF NOT EXISTS FOR (cs:ConversationSession) ON (cs.user_id);
CREATE INDEX conversation_status IF NOT EXISTS FOR (cs:ConversationSession) ON (cs.status);
```

#### **`Message`** - 메시지
```cypher
// 메시지 노드 생성
CREATE (m:Message {
  message_id: STRING,
  session_id: STRING,
  role: STRING,  // 'user', 'assistant', 'system', 'agent'
  content: STRING,
  token_count: INTEGER,
  created_at: DATETIME,
  metadata: MAP
})

// 인덱스 생성
CREATE INDEX message_id IF NOT EXISTS FOR (m:Message) ON (m.message_id);
CREATE INDEX message_session_id IF NOT EXISTS FOR (m:Message) ON (m.session_id);
CREATE INDEX message_role IF NOT EXISTS FOR (m:Message) ON (m.role);
```

### 📁 2. 코드 구조 노드 (Code Structure)

#### **`CodeFile`** - 코드 파일
```cypher
// 코드 파일 노드 생성
CREATE (cf:CodeFile {
  file_path: STRING,
  language: STRING,
  summary: STRING,
  complexity_score: FLOAT,
  created_at: DATETIME,
  updated_at: DATETIME,
  metadata: MAP
})

// 인덱스 생성
CREATE INDEX code_file_path IF NOT EXISTS FOR (cf:CodeFile) ON (cf.file_path);
CREATE INDEX code_file_language IF NOT EXISTS FOR (cf:CodeFile) ON (cf.language);
```

#### **`Function`** - 함수
```cypher
// 함수 노드 생성
CREATE (f:Function {
  name: STRING,
  signature: STRING,
  docstring: STRING,
  code_hash: STRING,
  complexity_score: FLOAT,
  created_at: DATETIME,
  metadata: MAP
})

// 인덱스 생성
CREATE INDEX function_name IF NOT EXISTS FOR (f:Function) ON (f.name);
CREATE INDEX function_code_hash IF NOT EXISTS FOR (f:Function) ON (f.code_hash);
```

#### **`Class`** - 클래스
```cypher
// 클래스 노드 생성
CREATE (c:Class {
  name: STRING,
  docstring: STRING,
  code_hash: STRING,
  complexity_score: FLOAT,
  created_at: DATETIME,
  metadata: MAP
})

// 인덱스 생성
CREATE INDEX class_name IF NOT EXISTS FOR (c:Class) ON (c.name);
CREATE INDEX class_code_hash IF NOT EXISTS FOR (c:Class) ON (c.code_hash);
```

#### **`Library`** - 라이브러리
```cypher
// 라이브러리 노드 생성
CREATE (l:Library {
  name: STRING,
  version: STRING,
  description: STRING,
  created_at: DATETIME,
  metadata: MAP
})

// 인덱스 생성
CREATE INDEX library_name IF NOT EXISTS FOR (l:Library) ON (l.name);
CREATE INDEX library_version IF NOT EXISTS FOR (l:Library) ON (l.version);
```

### 📁 3. 버전 관리 노드 (Version Management)

#### **`Commit`** - 커밋
```cypher
// 커밋 노드 생성
CREATE (c:Commit {
  hash: STRING,
  message: STRING,
  author: STRING,
  timestamp: DATETIME,
  files_changed: LIST<STRING>,
  metadata: MAP
})

// 인덱스 생성
CREATE INDEX commit_hash IF NOT EXISTS FOR (c:Commit) ON (c.hash);
CREATE INDEX commit_author IF NOT EXISTS FOR (c:Commit) ON (c.author);
CREATE INDEX commit_timestamp IF NOT EXISTS FOR (c:Commit) ON (c.timestamp);
```

### 📁 4. 기존 노드 확장

#### **`Agent` 노드 확장**
```cypher
// 기존 Agent 노드에 속성 추가
MATCH (a:Agent) 
SET a += {
  agent_type: STRING,
  capabilities: LIST<STRING>,
  status: STRING,  // 'online', 'offline', 'busy'
  last_heartbeat: DATETIME,
  performance_metrics: MAP,
  created_at: DATETIME,
  updated_at: DATETIME
}

// 추가 인덱스
CREATE INDEX agent_type IF NOT EXISTS FOR (a:Agent) ON (a.agent_type);
CREATE INDEX agent_status IF NOT EXISTS FOR (a:Agent) ON (a.status);
```

#### **`Task` 노드 확장**
```cypher
// 기존 Task 노드에 속성 추가
MATCH (t:Task)
SET t += {
  task_type: STRING,
  priority: INTEGER,
  status: STRING,  // 'pending', 'running', 'completed', 'failed'
  assigned_agent_type: STRING,
  estimated_duration: INTEGER,
  actual_duration: INTEGER,
  started_at: DATETIME,
  completed_at: DATETIME,
  created_at: DATETIME,
  updated_at: DATETIME
}

// 추가 인덱스
CREATE INDEX task_type IF NOT EXISTS FOR (t:Task) ON (t.task_type);
CREATE INDEX task_status IF NOT EXISTS FOR (t:Task) ON (t.status);
CREATE INDEX task_priority IF NOT EXISTS FOR (t:Task) ON (t.priority);
```

---

## 🔗 관계 타입 확장

### 📁 1. 대화 관련 관계

#### **대화 세션 관계**
```cypher
// 대화 세션이 메시지를 포함
(ConversationSession)-[:CONTAINS]->(Message)

// 메시지가 에이전트 작업을 생성
(Message)-[:GENERATES]->(Task)

// 대화 세션이 에이전트 작업을 포함
(ConversationSession)-[:HAS_TASK]->(Task)

// 에이전트가 대화 세션에 참여
(Agent)-[:PARTICIPATES_IN]->(ConversationSession)
```

### 📁 2. 코드 구조 관계

#### **파일 구조 관계**
```cypher
// 파일이 함수/클래스를 포함
(CodeFile)-[:CONTAINS]->(Function)
(CodeFile)-[:CONTAINS]->(Class)

// 함수가 다른 함수를 호출
(Function)-[:CALLS]->(Function)

// 클래스가 다른 클래스를 상속
(Class)-[:INHERITS_FROM]->(Class)

// 파일이 라이브러리를 임포트
(CodeFile)-[:IMPORTS]->(Library)

// 함수/클래스가 라이브러리를 사용
(Function)-[:USES]->(Library)
(Class)-[:USES]->(Library)
```

### 📁 3. 개념 구현 관계

#### **개념과 코드 연결**
```cypher
// 함수/클래스가 개념을 구현
(Function)-[:IMPLEMENTS]->(CONCEPT)
(Class)-[:IMPLEMENTS]->(CONCEPT)

// 패턴이 코드에 적용됨
(PATTERN)-[:APPLIED_IN]->(CodeFile)
(PATTERN)-[:APPLIED_IN]->(Function)

// 기술이 코드에서 사용됨
(TECHNOLOGY)-[:USED_IN]->(CodeFile)
(TECHNOLOGY)-[:USED_IN]->(Function)
```

### 📁 4. 버전 관리 관계

#### **변경 이력 관계**
```cypher
// 커밋이 파일을 수정
(Commit)-[:MODIFIED]->(CodeFile)

// 커밋이 함수/클래스에 영향을 줌
(Commit)-[:AFFECTS]->(Function)
(Commit)-[:AFFECTS]->(Class)

// 작업이 커밋을 생성
(Task)-[:CREATES_COMMIT]->(Commit)

// 에이전트가 커밋을 생성
(Agent)-[:CREATES_COMMIT]->(Commit)
```

### 📁 5. 작업 추적 관계

#### **작업 흐름 관계**
```cypher
// 에이전트가 작업을 수행
(Agent)-[:EXECUTES]->(Task)

// 작업이 다른 작업에 의존
(Task)-[:DEPENDS_ON]->(Task)

// 작업이 파일을 생성/수정
(Task)-[:GENERATES]->(CodeFile)
(Task)-[:MODIFIES]->(CodeFile)

// 작업이 함수/클래스를 생성/수정
(Task)-[:GENERATES]->(Function)
(Task)-[:MODIFIES]->(Function)
```

### 📁 6. 지식 관계 확장

#### **기존 관계 개선**
```cypher
// 개념 간의 관계를 더 구체적으로 정의
(CONCEPT)-[:RELATED_TO]->(CONCEPT)
(CONCEPT)-[:DEPENDS_ON]->(CONCEPT)
(CONCEPT)-[:SIMILAR_TO]->(CONCEPT)

// 기술 간의 관계
(TECHNOLOGY)-[:INTEGRATES_WITH]->(TECHNOLOGY)
(TECHNOLOGY)-[:DEPENDS_ON]->(TECHNOLOGY)
(TECHNOLOGY)-[:ALTERNATIVE_TO]->(TECHNOLOGY)

// 패턴 간의 관계
(PATTERN)-[:COMPOSES]->(PATTERN)
(PATTERN)-[:ALTERNATIVE_TO]->(PATTERN)
(PATTERN)-[:ENHANCES]->(PATTERN)
```

---

## 🔍 인덱스 및 제약 조건

### 📁 1. 추가 인덱스

#### **관계 인덱스**
```cypher
// 관계 타입별 인덱스
CREATE INDEX contains_relationship IF NOT EXISTS FOR ()-[r:CONTAINS]-() ON (r);
CREATE INDEX calls_relationship IF NOT EXISTS FOR ()-[r:CALLS]-() ON (r);
CREATE INDEX implements_relationship IF NOT EXISTS FOR ()-[r:IMPLEMENTS]-() ON (r);
CREATE INDEX generated_by_relationship IF NOT EXISTS FOR ()-[r:GENERATED_BY]-() ON (r);
CREATE INDEX modified_relationship IF NOT EXISTS FOR ()-[r:MODIFIED]-() ON (r);
CREATE INDEX affects_relationship IF NOT EXISTS FOR ()-[r:AFFECTS]-() ON (r);
```

#### **복합 인덱스**
```cypher
// 성능 최적화를 위한 복합 인덱스
CREATE INDEX conversation_user_status IF NOT EXISTS FOR (cs:ConversationSession) ON (cs.user_id, cs.status);
CREATE INDEX task_agent_status IF NOT EXISTS FOR (t:Task) ON (t.assigned_agent_type, t.status);
CREATE INDEX code_file_lang_path IF NOT EXISTS FOR (cf:CodeFile) ON (cf.language, cf.file_path);
```

### 📁 2. 제약 조건

#### **고유성 제약**
```cypher
// 고유 식별자 제약
CREATE CONSTRAINT conversation_session_id_unique IF NOT EXISTS FOR (cs:ConversationSession) REQUIRE cs.session_id IS UNIQUE;
CREATE CONSTRAINT message_id_unique IF NOT EXISTS FOR (m:Message) REQUIRE m.message_id IS UNIQUE;
CREATE CONSTRAINT code_file_path_unique IF NOT EXISTS FOR (cf:CodeFile) REQUIRE cf.file_path IS UNIQUE;
CREATE CONSTRAINT function_hash_unique IF NOT EXISTS FOR (f:Function) REQUIRE f.code_hash IS UNIQUE;
CREATE CONSTRAINT commit_hash_unique IF NOT EXISTS FOR (c:Commit) REQUIRE c.hash IS UNIQUE;
```

---

## 🔄 마이그레이션 계획

### 📅 Phase 1: 기본 노드 추가 (2-3일)
1. `ConversationSession` 노드 및 인덱스 생성
2. `Message` 노드 및 인덱스 생성
3. `CodeFile` 노드 및 인덱스 생성
4. `Function` 노드 및 인덱스 생성
5. `Class` 노드 및 인덱스 생성

### 📅 Phase 2: 관계 타입 추가 (2-3일)
1. 대화 관련 관계 추가
2. 코드 구조 관계 추가
3. 개념 구현 관계 추가
4. 기존 관계 개선

### 📅 Phase 3: 버전 관리 추가 (2-3일)
1. `Commit` 노드 및 인덱스 생성
2. `Library` 노드 및 인덱스 생성
3. 버전 관리 관계 추가
4. 변경 이력 추적 관계 추가

### 📅 Phase 4: 기존 노드 확장 (1-2일)
1. `Agent` 노드 속성 확장
2. `Task` 노드 속성 확장
3. 추가 인덱스 생성
4. 제약 조건 추가

### 📅 Phase 5: 데이터 마이그레이션 (2-3일)
1. 기존 데이터 정리
2. 새로운 구조로 데이터 변환
3. 관계 데이터 생성
4. 통합 테스트

---

## 📊 예상 효과

### ✅ 확장성 향상
- 구조화된 대화 관리로 대용량 데이터 처리 가능
- 코드 구조 표현으로 복잡한 프로젝트 지원
- 버전 관리 연동으로 변경 이력 추적

### ✅ 명확성 향상
- 명확한 노드 타입 분리
- 일관된 관계 정의
- 명시적인 속성 구조

### ✅ 추적성 향상
- 대화 → 작업 → 코드 생성의 완전한 추적
- 버전 관리와의 연동
- 에이전트 활동 추적

---

## 🚀 구현 우선순위

### 🔥 High Priority
1. `ConversationSession` 및 `Message` 노드
2. `CodeFile`, `Function`, `Class` 노드
3. 기본 관계 타입 추가
4. 기존 `Agent`, `Task` 노드 확장

### 🔶 Medium Priority
1. `Commit` 및 `Library` 노드
2. 버전 관리 관계
3. 고급 관계 타입
4. 성능 최적화 인덱스

### 🔵 Low Priority
1. 복합 인덱스
2. 제약 조건
3. 고급 메타데이터
4. 분석 기능

---

## 📝 검토 요청사항

이 확장 계획에 대한 검토를 요청드립니다:

1. **노드 구조**: 제안된 노드 구조가 적절한가요?
2. **관계 설계**: 관계 타입이 올바르게 설계되었나요?
3. **마이그레이션 순서**: 우선순위가 적절한가요?
4. **성능 고려사항**: 인덱스 설계가 충분한가요?
5. **확장성**: 미래 요구사항을 고려했나요?

검토 후 수정사항을 반영하여 실제 마이그레이션 스크립트를 작성하겠습니다. 