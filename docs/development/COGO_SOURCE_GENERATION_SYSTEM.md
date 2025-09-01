# COGO 소스 생성 시스템 문서

## 개요

COGO Agent Core의 소스 생성 시스템은 LLM을 활용하여 다양한 프로그래밍 언어와 프레임워크의 소스 코드를 생성하고, 생성된 소스의 품질을 평가하며, 관련 정보를 체계적으로 저장하는 종합적인 시스템입니다.

## 시스템 아키텍처

### 1. 핵심 구성 요소

- **프롬프트 템플릿 관리**: 다양한 소스 생성 시나리오에 맞는 템플릿 시스템
- **LLM 통합**: OpenAI, Fireworks 등 다양한 LLM과의 연동
- **RAG (Retrieval-Augmented Generation)**: 기존 지식베이스를 활용한 향상된 소스 생성
- **품질 평가**: 생성된 소스의 완성도, 구조, 유효성 평가
- **정보 저장**: 생성된 소스의 메타데이터와 구조 정보 저장

### 2. 데이터 흐름

```
프롬프트 템플릿 → LLM 요청 → 소스 생성 → 품질 평가 → 정보 저장
     ↓              ↓           ↓          ↓          ↓
RAG 컨텍스트 → 향상된 프롬프트 → 소스 코드 → 평가 결과 → 스키마 저장
```

## 스키마 정의

### 1. 프롬프트 템플릿 스키마

```typescript
interface COGOPromptTemplate {
  id: string;
  name: string;
  description: string;
  category: 'code-generation' | 'documentation' | 'testing' | 'configuration';
  template: string;
  variables: PromptVariable[];
  examples: string[];
  metadata: {
    language?: string;
    framework?: string;
    complexity: 'simple' | 'medium' | 'complex';
    estimatedTokens: number;
  };
}
```

### 2. 소스 생성 요청/응답 스키마

```typescript
interface COGOSourceGenerationRequest {
  id: string;
  promptTemplateId: string;
  variables: Record<string, any>;
  context: {
    project: ProjectContext;
    codebase: CodebaseContext;
    userPreferences: UserPreferences;
    knowledgeGraph: KnowledgeGraphContext;
  };
  options: {
    model: string;
    maxTokens: number;
    temperature: number;
    useRAG: boolean;
    qualityThreshold: number;
  };
}

interface COGOSourceGenerationResponse {
  id: string;
  requestId: string;
  generatedSource: GeneratedSource;
  qualityAssessment: SourceQualityAssessment;
  metadata: {
    generationTime: number;
    tokensUsed: number;
    model: string;
    version: string;
  };
}
```

### 3. 생성된 소스 구조 스키마

```typescript
interface GeneratedSource {
  code: {
    content: string;
    language: string;
    framework?: string;
    fileExtension: string;
  };
  structure: {
    components: ComponentStructure[];
    dependencies: DependencyStructure;
    architecture: ArchitectureStructure;
    designPatterns: DesignPattern[];
  };
  documentation: {
    api: APIDocumentation[];
    comments: string[];
    readme: string;
  };
  tests: {
    unit: TestCase[];
    integration: TestCase[];
    e2e: TestCase[];
  };
  configuration: {
    build: Record<string, any>;
    deploy: Record<string, any>;
    environment: Record<string, any>;
  };
  files: GeneratedFile[];
}
```

### 4. 품질 평가 스키마

```typescript
interface SourceQualityAssessment {
  overall: number; // 0-100
  completeness: number;
  structure: number;
  validity: number;
  maintainability: number;
  performance: number;
  security: number;
  issues: QualityIssue[];
  recommendations: QualityRecommendation[];
}
```

## 데이터베이스 스키마

### 1. Supabase (PostgreSQL) 스키마

#### 소스 정보 저장 테이블

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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 소스 품질 이력 테이블
CREATE TABLE IF NOT EXISTS cogo_source_quality_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    source_id UUID REFERENCES cogo_source_info(id),
    assessment_data JSONB NOT NULL,
    assessed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    assessor VARCHAR(255) DEFAULT 'system'
);
```

#### 벡터 검색용 테이블

```sql
-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- 소스 코드 벡터 테이블
CREATE TABLE IF NOT EXISTS cogo_source_vectors (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    source_id UUID REFERENCES cogo_source_info(id),
    content_chunk TEXT NOT NULL,
    chunk_type VARCHAR(100) DEFAULT 'code',
    embedding vector(1536),
    embedding_model VARCHAR(100) DEFAULT 'text-embedding-3-small',
    chunk_index INTEGER DEFAULT 0,
    token_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 프롬프트 템플릿 벡터 테이블
CREATE TABLE IF NOT EXISTS cogo_template_vectors (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    template_id UUID REFERENCES cogo_prompt_templates(id),
    template_content TEXT NOT NULL,
    embedding vector(1536),
    embedding_model VARCHAR(100) DEFAULT 'text-embedding-3-small',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 2. Neo4j (그래프DB) 스키마

#### 노드 타입 정의

```cypher
// 소스 생성 관련 노드 타입
CREATE CONSTRAINT source_generation_id_unique IF NOT EXISTS
FOR (n:SourceGeneration) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT prompt_template_id_unique IF NOT EXISTS
FOR (n:PromptTemplate) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT generated_source_id_unique IF NOT EXISTS
FOR (n:GeneratedSource) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT quality_assessment_id_unique IF NOT EXISTS
FOR (n:QualityAssessment) REQUIRE n.id IS UNIQUE;
```

#### 노드 생성 예시

```cypher
// 소스 생성 요청 노드
CREATE (sg:SourceGeneration {
  id: 'gen-001',
  promptTemplateId: 'template-001',
  model: 'gpt-4',
  temperature: 0.7,
  maxTokens: 4000,
  useRAG: true,
  createdAt: datetime('2024-01-15T10:32:15Z')
});

// 프롬프트 템플릿 노드
CREATE (pt:PromptTemplate {
  id: 'template-001',
  name: 'React Component Generator',
  category: 'code-generation',
  language: 'typescript',
  framework: 'react',
  complexity: 'medium'
});

// 생성된 소스 노드
CREATE (gs:GeneratedSource {
  id: 'source-001',
  name: 'UserProfile Component',
  language: 'typescript',
  framework: 'react',
  fileExtension: 'tsx',
  linesOfCode: 180
});

// 품질 평가 노드
CREATE (qa:QualityAssessment {
  id: 'qa-001',
  overall: 85,
  completeness: 90,
  structure: 88,
  validity: 92,
  maintainability: 82
});
```

#### 관계 정의

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

// 소스 간 의존성 관계
MATCH (gs1:GeneratedSource {id: 'source-001'}), (gs2:GeneratedSource {id: 'source-002'})
CREATE (gs1)-[:DEPENDS_ON]->(gs2);
```

## 사용 예시

### 1. 기본 소스 생성

```typescript
import { COGOSourceGenerationExamples } from '../examples/COGOSourceGenerationExamples';

// 예제 데이터 가져오기
const request = COGOSourceGenerationExamples.getExampleRequest();
const response = COGOSourceGenerationExamples.getExampleResponse();

console.log('생성된 소스:', response.generatedSource.code.content);
console.log('품질 평가:', response.qualityAssessment.overall);
```

### 2. 프롬프트 템플릿 활용

```typescript
const template = COGOSourceGenerationExamples.getExamplePromptTemplate();
console.log('템플릿 변수:', template.variables);
console.log('예제:', template.examples);
```

### 3. 품질 평가 결과 분석

```typescript
const assessment = response.qualityAssessment;
console.log('전체 품질:', assessment.overall);
console.log('완성도:', assessment.completeness);
console.log('구조:', assessment.structure);
console.log('권장사항:', assessment.recommendations);
```

## 테스트 시스템

### 1. 소스 생성 테스트

```bash
# 기본 소스 생성 테스트 실행
npx ts-node src/tests/rag-system/run-source-generation-tests.ts

# 고급 소스 생성 테스트 실행
npx ts-node src/tests/rag-system/run-advanced-source-generation-tests.ts --categories code-generation --max 5
```

### 2. JSON 파싱 테스트

```bash
# 고급 JSON 파싱 엔진 테스트 실행
npx ts-node src/tests/rag-system/run-advanced-json-parsing-tests.ts
```

### 3. 예제 실행

```bash
# COGO 소스 생성 예제 실행
npx ts-node src/examples/run-cogo-source-generation-examples.ts
```

## 파일 구조

```
src/
├── types/
│   └── COGOSourceGeneration.ts          # 메인 스키마 정의
├── examples/
│   ├── COGOSourceGenerationExamples.ts  # 예제 데이터
│   └── run-cogo-source-generation-examples.ts  # 예제 실행 스크립트
├── tests/rag-system/
│   ├── core/
│   │   ├── SourceGenerationTestSuite.ts
│   │   ├── AdvancedSourceGenerationTests.ts
│   │   └── AdvancedJSONParsingEngine.ts
│   ├── run-source-generation-tests.ts
│   ├── run-advanced-source-generation-tests.ts
│   └── run-advanced-json-parsing-tests.ts
└── services/
    ├── OpenAIClient.ts                  # LLM 통합
    └── ConfigurationManagementService.ts # 설정 관리
```

## 주요 기능

### 1. 다중 언어/프레임워크 지원
- TypeScript/JavaScript (React, Vue, Angular)
- Python (Django, Flask, FastAPI)
- Java (Spring Boot)
- Go, Rust, C++
- 기타 언어 및 프레임워크

### 2. 품질 평가 시스템
- 완성도 평가 (completeness)
- 구조적 품질 (structure)
- 유효성 검증 (validity)
- 유지보수성 (maintainability)
- 성능 및 보안 평가

### 3. RAG 통합
- 기존 지식베이스 활용
- 컨텍스트 기반 소스 생성
- 관련 코드 패턴 참조

### 4. 버전 관리
- 소스 생성 이력 추적
- 품질 평가 이력 관리
- 템플릿 버전 관리

## 향후 개발 계획

1. **실시간 협업**: 다중 사용자 동시 소스 생성 지원
2. **AI 모델 확장**: 더 다양한 LLM 모델 지원
3. **자동 최적화**: 생성된 소스의 자동 최적화 기능
4. **통합 개발 환경**: IDE 플러그인 개발
5. **성능 모니터링**: 실시간 성능 추적 및 분석

## 참고 자료

- [COGO Agent Core 아키텍처](./AGENT_ARCHITECTURE_OVERVIEW.md)
- [RAG 시스템 문서](./RAG_SYSTEM_OVERVIEW.md)
- [테스트 가이드](./TESTING_GUIDE.md)
- [API 문서](./API_DOCUMENTATION.md)

---

**문서 버전**: 1.0  
**최종 업데이트**: 2024-01-15  
**작성자**: COGO AI Team 