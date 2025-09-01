# COGO 소스 생성 시스템 데이터베이스 스키마

## 개요

COGO 소스 생성 시스템은 두 가지 주요 데이터베이스를 사용합니다:
- **Supabase (PostgreSQL)**: 벡터 검색과 구조화된 데이터 저장
- **Neo4j (그래프DB)**: 소스 간 관계와 의존성 모델링

## 1. Supabase (PostgreSQL) 스키마

### 1.1 핵심 테이블 구조

#### 소스 생성 정보 저장 테이블

```sql
-- 소스 생성 정보 저장 테이블
CREATE TABLE IF NOT EXISTS cogo_source_info (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    generation_id VARCHAR(255) UNIQUE NOT NULL,
    prompt_template_id VARCHAR(255) NOT NULL,
    request_data JSONB NOT NULL,
    response_data JSONB NOT NULL,
    generated_source JSONB NOT NULL,
    quality_assessment JSONB NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_cogo_source_info_generation_id ON cogo_source_info(generation_id);
CREATE INDEX IF NOT EXISTS idx_cogo_source_info_template_id ON cogo_source_info(prompt_template_id);
CREATE INDEX IF NOT EXISTS idx_cogo_source_info_created_at ON cogo_source_info(created_at);
CREATE INDEX IF NOT EXISTS idx_cogo_source_info_metadata ON cogo_source_info USING GIN(metadata);
```

#### 프롬프트 템플릿 저장 테이블

```sql
-- 프롬프트 템플릿 저장 테이블
CREATE TABLE IF NOT EXISTS cogo_prompt_templates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    template_id VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(500) NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL,
    template_content TEXT NOT NULL,
    variables JSONB DEFAULT '[]',
    examples JSONB DEFAULT '[]',
    metadata JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    version VARCHAR(50) DEFAULT '1.0.0',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_cogo_prompt_templates_template_id ON cogo_prompt_templates(template_id);
CREATE INDEX IF NOT EXISTS idx_cogo_prompt_templates_category ON cogo_prompt_templates(category);
CREATE INDEX IF NOT EXISTS idx_cogo_prompt_templates_is_active ON cogo_prompt_templates(is_active);
CREATE INDEX IF NOT EXISTS idx_cogo_prompt_templates_metadata ON cogo_prompt_templates USING GIN(metadata);
```

#### 소스 품질 이력 테이블

```sql
-- 소스 품질 이력 테이블
CREATE TABLE IF NOT EXISTS cogo_source_quality_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    source_id UUID REFERENCES cogo_source_info(id) ON DELETE CASCADE,
    assessment_data JSONB NOT NULL,
    assessed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    assessor VARCHAR(255) DEFAULT 'system',
    assessment_version VARCHAR(50) DEFAULT '1.0.0'
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_cogo_source_quality_history_source_id ON cogo_source_quality_history(source_id);
CREATE INDEX IF NOT EXISTS idx_cogo_source_quality_history_assessed_at ON cogo_source_quality_history(assessed_at);
```

### 1.2 벡터 검색용 테이블

#### pgvector 확장 활성화

```sql
-- Enable pgvector extension for vector similarity search
CREATE EXTENSION IF NOT EXISTS vector;
```

#### 소스 코드 벡터 테이블

```sql
-- 소스 코드 벡터 테이블
CREATE TABLE IF NOT EXISTS cogo_source_vectors (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    source_id UUID REFERENCES cogo_source_info(id) ON DELETE CASCADE,
    content_chunk TEXT NOT NULL,
    chunk_type VARCHAR(100) DEFAULT 'code',
    embedding vector(1536),
    embedding_model VARCHAR(100) DEFAULT 'text-embedding-3-small',
    chunk_index INTEGER DEFAULT 0,
    token_count INTEGER DEFAULT 0,
    chunk_metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_cogo_source_vectors_source_id ON cogo_source_vectors(source_id);
CREATE INDEX IF NOT EXISTS idx_cogo_source_vectors_chunk_type ON cogo_source_vectors(chunk_type);
CREATE INDEX IF NOT EXISTS idx_cogo_source_vectors_embedding ON cogo_source_vectors USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
```

#### 프롬프트 템플릿 벡터 테이블

```sql
-- 프롬프트 템플릿 벡터 테이블
CREATE TABLE IF NOT EXISTS cogo_template_vectors (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    template_id UUID REFERENCES cogo_prompt_templates(id) ON DELETE CASCADE,
    template_content TEXT NOT NULL,
    embedding vector(1536),
    embedding_model VARCHAR(100) DEFAULT 'text-embedding-3-small',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_cogo_template_vectors_template_id ON cogo_template_vectors(template_id);
CREATE INDEX IF NOT EXISTS idx_cogo_template_vectors_embedding ON cogo_template_vectors USING ivfflat (embedding vector_cosine_ops) WITH (lists = 50);
```

### 1.3 벡터 검색 함수

#### 소스 코드 유사도 검색 함수

```sql
-- 소스 코드 유사도 검색 함수
CREATE OR REPLACE FUNCTION search_cogo_source_vectors(
    query_embedding vector(1536),
    match_threshold float DEFAULT 0.7,
    match_count int DEFAULT 10
)
RETURNS TABLE (
    id uuid,
    source_id uuid,
    content_chunk text,
    chunk_type varchar,
    similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        csv.id,
        csv.source_id,
        csv.content_chunk,
        csv.chunk_type,
        1 - (csv.embedding <=> query_embedding) as similarity
    FROM cogo_source_vectors csv
    WHERE 1 - (csv.embedding <=> query_embedding) > match_threshold
    ORDER BY csv.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;
```

#### 프롬프트 템플릿 유사도 검색 함수

```sql
-- 프롬프트 템플릿 유사도 검색 함수
CREATE OR REPLACE FUNCTION search_cogo_template_vectors(
    query_embedding vector(1536),
    match_threshold float DEFAULT 0.7,
    match_count int DEFAULT 5
)
RETURNS TABLE (
    id uuid,
    template_id uuid,
    template_content text,
    similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ctv.id,
        ctv.template_id,
        ctv.template_content,
        1 - (ctv.embedding <=> query_embedding) as similarity
    FROM cogo_template_vectors ctv
    WHERE 1 - (ctv.embedding <=> query_embedding) > match_threshold
    ORDER BY ctv.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;
```

### 1.4 트리거 및 뷰

#### 업데이트 시간 자동 갱신 트리거

```sql
-- 업데이트 시간 자동 갱신 함수
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 소스 정보 테이블 트리거
CREATE TRIGGER update_cogo_source_info_updated_at 
    BEFORE UPDATE ON cogo_source_info 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 프롬프트 템플릿 테이블 트리거
CREATE TRIGGER update_cogo_prompt_templates_updated_at 
    BEFORE UPDATE ON cogo_prompt_templates 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

#### 통계 뷰

```sql
-- 소스 생성 통계 뷰
CREATE OR REPLACE VIEW cogo_source_generation_stats AS
SELECT 
    DATE_TRUNC('day', created_at) as generation_date,
    COUNT(*) as total_generations,
    AVG((quality_assessment->>'overall')::float) as avg_quality,
    COUNT(DISTINCT prompt_template_id) as unique_templates_used
FROM cogo_source_info
GROUP BY DATE_TRUNC('day', created_at)
ORDER BY generation_date DESC;
```

## 2. Neo4j (그래프DB) 스키마

### 2.1 노드 타입 정의

```cypher
// 소스 생성 관련 노드 타입 제약 조건
CREATE CONSTRAINT source_generation_id_unique IF NOT EXISTS
FOR (n:SourceGeneration) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT prompt_template_id_unique IF NOT EXISTS
FOR (n:PromptTemplate) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT generated_source_id_unique IF NOT EXISTS
FOR (n:GeneratedSource) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT quality_assessment_id_unique IF NOT EXISTS
FOR (n:QualityAssessment) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT source_file_id_unique IF NOT EXISTS
FOR (n:SourceFile) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT source_function_id_unique IF NOT EXISTS
FOR (n:SourceFunction) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT source_class_id_unique IF NOT EXISTS
FOR (n:SourceClass) REQUIRE n.id IS UNIQUE;
```

### 2.2 노드 생성 예시

#### 소스 생성 요청 노드

```cypher
// 소스 생성 요청 노드
CREATE (sg:SourceGeneration {
  id: 'gen-001',
  promptTemplateId: 'template-001',
  model: 'gpt-4',
  temperature: 0.7,
  maxTokens: 4000,
  useRAG: true,
  generationTime: 2500,
  tokensUsed: 3200,
  status: 'completed',
  createdAt: datetime('2024-01-15T10:32:15Z'),
  metadata: {
    language: 'typescript',
    framework: 'react',
    complexity: 'medium'
  }
});
```

#### 프롬프트 템플릿 노드

```cypher
// 프롬프트 템플릿 노드
CREATE (pt:PromptTemplate {
  id: 'template-001',
  name: 'React Component Generator',
  category: 'code-generation',
  language: 'typescript',
  framework: 'react',
  complexity: 'medium',
  version: '1.0.0',
  isActive: true,
  estimatedTokens: 2000,
  createdAt: datetime('2024-01-10T09:15:30Z'),
  variables: ['componentName', 'props', 'styling', 'stateManagement'],
  examples: ['UserProfile', 'ProductCard', 'NavigationBar']
});
```

#### 생성된 소스 노드

```cypher
// 생성된 소스 노드
CREATE (gs:GeneratedSource {
  id: 'source-001',
  name: 'UserProfile Component',
  language: 'typescript',
  framework: 'react',
  fileExtension: 'tsx',
  linesOfCode: 180,
  cyclomaticComplexity: 4,
  maintainabilityIndex: 85,
  version: '1.0.0',
  createdAt: datetime('2024-01-15T10:32:15Z'),
  metadata: {
    hasTests: true,
    hasDocumentation: true,
    hasComments: true,
    dependencies: ['react', 'typescript', '@types/react']
  }
});
```

#### 품질 평가 노드

```cypher
// 품질 평가 노드
CREATE (qa:QualityAssessment {
  id: 'qa-001',
  overall: 85,
  completeness: 90,
  structure: 88,
  validity: 92,
  maintainability: 82,
  performance: 78,
  security: 85,
  assessedAt: datetime('2024-01-15T10:32:20Z'),
  assessor: 'system',
  assessmentVersion: '1.0.0',
  issues: [
    {type: 'warning', message: 'Consider adding error boundaries'},
    {type: 'info', message: 'Good separation of concerns'}
  ],
  recommendations: [
    'Add unit tests for edge cases',
    'Consider implementing memoization for performance'
  ]
});
```

#### 소스 파일 노드

```cypher
// 소스 파일 노드
CREATE (sf:SourceFile {
  id: 'file-001',
  path: 'src/components/UserProfile.tsx',
  name: 'UserProfile.tsx',
  language: 'typescript',
  size: 4500,
  linesOfCode: 180,
  createdAt: datetime('2024-01-15T10:32:15Z'),
  metadata: {
    hasTests: true,
    testFile: 'src/components/__tests__/UserProfile.test.tsx',
    hasStorybook: true,
    storyFile: 'src/components/UserProfile.stories.tsx'
  }
});
```

#### 소스 함수/클래스 노드

```cypher
// 소스 함수 노드
CREATE (fn:SourceFunction {
  id: 'func-001',
  name: 'UserProfile',
  type: 'component',
  linesOfCode: 180,
  cyclomaticComplexity: 4,
  parameters: ['props'],
  returnType: 'JSX.Element',
  visibility: 'export',
  isAsync: false,
  hasJSDoc: true
});

// 소스 클래스 노드
CREATE (cl:SourceClass {
  id: 'class-001',
  name: 'UserProfileState',
  type: 'interface',
  linesOfCode: 15,
  properties: ['user', 'isLoading', 'error'],
  methods: [],
  visibility: 'export',
  isAbstract: false
});
```

### 2.3 관계 정의

#### 기본 관계

```cypher
// 소스 생성과 프롬프트 템플릿의 관계
MATCH (sg:SourceGeneration {id: 'gen-001'}), (pt:PromptTemplate {id: 'template-001'})
CREATE (sg)-[:USES_TEMPLATE]->(pt);

// 소스 생성과 생성된 소스의 관계
MATCH (sg:SourceGeneration {id: 'gen-001'}), (gs:GeneratedSource {id: 'source-001'})
CREATE (sg)-[:GENERATED]->(gs);

// 생성된 소스와 품질 평가의 관계
MATCH (gs:GeneratedSource {id: 'source-001'}), (qa:QualityAssessment {id: 'qa-001'})
CREATE (gs)-[:HAS_QUALITY]->(qa);

// 생성된 소스와 소스 파일의 관계
MATCH (gs:GeneratedSource {id: 'source-001'}), (sf:SourceFile {id: 'file-001'})
CREATE (gs)-[:CONTAINS_FILE]->(sf);
```

#### 구조적 관계

```cypher
// 소스 파일과 함수/클래스의 관계
MATCH (sf:SourceFile {id: 'file-001'}), (fn:SourceFunction {id: 'func-001'})
CREATE (sf)-[:CONTAINS_FUNCTION]->(fn);

MATCH (sf:SourceFile {id: 'file-001'}), (cl:SourceClass {id: 'class-001'})
CREATE (sf)-[:CONTAINS_CLASS]->(cl);

// 함수와 클래스의 관계
MATCH (fn:SourceFunction {id: 'func-001'}), (cl:SourceClass {id: 'class-001'})
CREATE (fn)-[:USES_TYPE]->(cl);
```

#### 의존성 관계

```cypher
// 소스 간 의존성 관계
MATCH (gs1:GeneratedSource {id: 'source-001'}), (gs2:GeneratedSource {id: 'source-002'})
CREATE (gs1)-[:DEPENDS_ON {type: 'import', strength: 'strong'}]->(gs2);

// 함수 호출 관계
MATCH (fn1:SourceFunction {id: 'func-001'}), (fn2:SourceFunction {id: 'func-002'})
CREATE (fn1)-[:CALLS {line: 45, context: 'event handler'}]->(fn2);

// 프롬프트 템플릿 간 관계
MATCH (pt1:PromptTemplate {id: 'template-001'}), (pt2:PromptTemplate {id: 'template-002'})
CREATE (pt1)-[:EXTENDS {version: '2.0.0'}]->(pt2);
```

### 2.4 쿼리 예시

#### 소스 생성 이력 조회

```cypher
// 특정 기간의 소스 생성 이력 조회
MATCH (sg:SourceGeneration)-[:GENERATED]->(gs:GeneratedSource)-[:HAS_QUALITY]->(qa:QualityAssessment)
WHERE sg.createdAt >= datetime('2024-01-01T00:00:00Z')
  AND sg.createdAt <= datetime('2024-01-31T23:59:59Z')
RETURN sg.id, gs.name, qa.overall, sg.generationTime
ORDER BY sg.createdAt DESC
LIMIT 10;
```

#### 품질 기반 소스 검색

```cypher
// 높은 품질의 소스 검색
MATCH (gs:GeneratedSource)-[:HAS_QUALITY]->(qa:QualityAssessment)
WHERE qa.overall >= 80
  AND gs.language = 'typescript'
  AND gs.framework = 'react'
RETURN gs.name, gs.linesOfCode, qa.overall, qa.maintainability
ORDER BY qa.overall DESC;
```

#### 의존성 분석

```cypher
// 소스 의존성 체인 분석
MATCH path = (gs:GeneratedSource)-[:DEPENDS_ON*1..5]->(dependent:GeneratedSource)
WHERE gs.id = 'source-001'
RETURN path
ORDER BY length(path);
```

#### 프롬프트 템플릿 사용 통계

```cypher
// 프롬프트 템플릿별 사용 통계
MATCH (pt:PromptTemplate)<-[:USES_TEMPLATE]-(sg:SourceGeneration)
RETURN pt.name, pt.category, count(sg) as usage_count, avg(sg.generationTime) as avg_generation_time
ORDER BY usage_count DESC;
```

## 3. 스키마 마이그레이션

### 3.1 Supabase 마이그레이션

```sql
-- 마이그레이션 버전 관리 테이블
CREATE TABLE IF NOT EXISTS cogo_schema_migrations (
    id SERIAL PRIMARY KEY,
    version VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 초기 마이그레이션 기록
INSERT INTO cogo_schema_migrations (version, description) VALUES 
('1.0.0', 'Initial schema for COGO source generation system');
```

### 3.2 Neo4j 마이그레이션

```cypher
// 마이그레이션 노드 생성
CREATE (m:Migration {
  version: '1.0.0',
  description: 'Initial schema for COGO source generation system',
  appliedAt: datetime(),
  status: 'completed'
});
```

## 4. 성능 최적화

### 4.1 Supabase 최적화

```sql
-- 파티셔닝 (대용량 데이터용)
CREATE TABLE cogo_source_info_partitioned (
    LIKE cogo_source_info INCLUDING ALL
) PARTITION BY RANGE (created_at);

-- 파티션 생성
CREATE TABLE cogo_source_info_2024_01 PARTITION OF cogo_source_info_partitioned
FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

-- 통계 업데이트
ANALYZE cogo_source_info;
ANALYZE cogo_source_vectors;
```

### 4.2 Neo4j 최적화

```cypher
// 인덱스 생성
CREATE INDEX FOR (n:SourceGeneration) ON (n.createdAt);
CREATE INDEX FOR (n:GeneratedSource) ON (n.language, n.framework);
CREATE INDEX FOR (n:QualityAssessment) ON (n.overall);

// 통계 업데이트
CALL db.awaitIndexes();
```

## 5. 백업 및 복구

### 5.1 Supabase 백업

```sql
-- 백업 뷰 생성
CREATE OR REPLACE VIEW cogo_backup_view AS
SELECT 
    'source_info' as table_name,
    id,
    generation_id,
    created_at,
    to_jsonb(row_to_json(cogo_source_info.*)) as data
FROM cogo_source_info
UNION ALL
SELECT 
    'prompt_templates' as table_name,
    id,
    template_id,
    created_at,
    to_jsonb(row_to_json(cogo_prompt_templates.*)) as data
FROM cogo_prompt_templates;
```

### 5.2 Neo4j 백업

```cypher
// 전체 그래프 백업
CALL apoc.export.json.all(
  'cogo_backup_' + datetime() + '.json',
  {useTypes: true}
);
```

---

**문서 버전**: 1.0  
**최종 업데이트**: 2024-01-15  
**작성자**: COGO AI Team 