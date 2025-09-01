# COGO 소스 생성 시스템 테스트 가이드

## 개요

COGO 소스 생성 시스템의 테스트는 다양한 시나리오에서 LLM의 소스 생성 능력, RAG 통합, JSON 파싱 품질을 검증하는 종합적인 테스트 스위트입니다.

## 테스트 시스템 아키텍처

### 1. 테스트 구성 요소

```
테스트 시스템
├── 기본 소스 생성 테스트 (SourceGenerationTestSuite)
├── 고급 소스 생성 테스트 (AdvancedSourceGenerationTests)
├── JSON 파싱 엔진 테스트 (AdvancedJSONParsingEngine)
└── RAG 통합 테스트 (RAGSystemTestRunner)
```

### 2. 테스트 카테고리

- **code-generation**: 다양한 언어/프레임워크의 코드 생성
- **rag-integration**: RAG 시스템과의 통합 테스트
- **json-parsing**: JSON 출력 파싱 및 검증
- **complex-scenario**: 복잡한 시나리오 테스트
- **language-specific**: 특정 언어별 테스트
- **framework-specific**: 특정 프레임워크별 테스트

## 기본 소스 생성 테스트

### 1. 실행 방법

```bash
# 기본 소스 생성 테스트 실행
npx ts-node src/tests/rag-system/run-source-generation-tests.ts
```

### 2. 테스트 케이스

#### 코드 생성 테스트

```typescript
{
  id: 'basic-react-component',
  name: 'Basic React Component Generation',
  category: 'code-generation',
  description: 'Generate a simple React component',
  prompt: 'Create a React component for a user profile',
  expectedOutput: {
    type: 'typescript',
    framework: 'react',
    hasJSX: true,
    hasProps: true
  },
  timeout: 30000
}
```

#### RAG 통합 테스트

```typescript
{
  id: 'rag-enhanced-generation',
  name: 'RAG-Enhanced Code Generation',
  category: 'rag-integration',
  description: 'Generate code using RAG context',
  prompt: 'Create a user authentication component',
  useRAG: true,
  expectedSources: 3,
  timeout: 45000
}
```

#### JSON 파싱 테스트

```typescript
{
  id: 'json-response-parsing',
  name: 'JSON Response Parsing',
  category: 'json-parsing',
  description: 'Parse complex JSON responses from LLM',
  prompt: 'Generate a configuration object for a web application',
  expectedOutput: {
    type: 'json',
    isValid: true,
    hasRequiredFields: ['database', 'api', 'security']
  },
  timeout: 30000
}
```

### 3. 테스트 결과 분석

```typescript
interface SourceGenerationTestResult {
  testCase: SourceGenerationTestCase;
  success: boolean;
  output?: any;
  error?: string;
  quality?: {
    completeness: number;
    structure: number;
    validity: number;
  };
  metadata: {
    executionTime: number;
    tokensUsed: number;
    ragSourcesUsed?: number;
  };
}
```

## 고급 소스 생성 테스트

### 1. 실행 방법

```bash
# 모든 고급 테스트 실행
npx ts-node src/tests/rag-system/run-advanced-source-generation-tests.ts --advanced

# 특정 카테고리만 실행
npx ts-node src/tests/rag-system/run-advanced-source-generation-tests.ts --categories code-generation,rag-integration

# 복잡도별 필터링
npx ts-node src/tests/rag-system/run-advanced-source-generation-tests.ts --complexity complex

# 테스트 수 제한
npx ts-node src/tests/rag-system/run-advanced-source-generation-tests.ts --max 10
```

### 2. 명령행 옵션

```bash
--advanced          # 고급 테스트만 실행
--categories        # 특정 카테고리 필터 (comma-separated)
--complexity        # 복잡도 필터 (simple|medium|complex)
--max               # 최대 테스트 수 제한
--output            # 출력 형식 (json|markdown|console)
--verbose           # 상세 로그 출력
```

### 3. 고급 테스트 케이스

#### 언어별 테스트

```typescript
// TypeScript/React 테스트
{
  id: 'typescript-react-advanced',
  name: 'Advanced TypeScript React Component',
  category: 'language-specific',
  language: 'typescript',
  framework: 'react',
  complexity: 'complex',
  prompt: 'Create a complex React component with TypeScript, hooks, and proper error handling',
  expectedOutput: {
    hasTypeScript: true,
    hasHooks: true,
    hasErrorHandling: true,
    hasTests: true
  }
}

// Python/FastAPI 테스트
{
  id: 'python-fastapi-advanced',
  name: 'Advanced Python FastAPI Application',
  category: 'language-specific',
  language: 'python',
  framework: 'fastapi',
  complexity: 'complex',
  prompt: 'Create a FastAPI application with authentication, database models, and API documentation',
  expectedOutput: {
    hasAuthentication: true,
    hasDatabaseModels: true,
    hasAPIDocs: true,
    hasTests: true
  }
}
```

#### 프레임워크별 테스트

```typescript
// Vue.js 테스트
{
  id: 'vue-composition-api',
  name: 'Vue 3 Composition API Component',
  category: 'framework-specific',
  framework: 'vue',
  complexity: 'medium',
  prompt: 'Create a Vue 3 component using Composition API with reactive state management',
  expectedOutput: {
    hasCompositionAPI: true,
    hasReactiveState: true,
    hasProps: true,
    hasEmits: true
  }
}

// Angular 테스트
{
  id: 'angular-service-component',
  name: 'Angular Service and Component',
  category: 'framework-specific',
  framework: 'angular',
  complexity: 'medium',
  prompt: 'Create an Angular service and component with dependency injection and HTTP client',
  expectedOutput: {
    hasService: true,
    hasComponent: true,
    hasDependencyInjection: true,
    hasHttpClient: true
  }
}
```

## JSON 파싱 엔진 테스트

### 1. 실행 방법

```bash
# 고급 JSON 파싱 엔진 테스트 실행
npx ts-node src/tests/rag-system/run-advanced-json-parsing-tests.ts
```

### 2. 파싱 엔진 기능

#### 라인별 분석

```typescript
interface LineAnalysis {
  lineNumber: number;
  content: string;
  type: 'object_start' | 'key_value' | 'array_start' | 'array_item' | 'object_end' | 'array_end' | 'malformed';
  issues: string[];
  suggestions: string[];
  braceCount: number;
  bracketCount: number;
  quoteCount: number;
}
```

#### 복구 시도

```typescript
interface RecoveryAttempt {
  method: 'direct' | 'block_extraction' | 'line_reconstruction' | 'partial_parsing' | 'structure_fix';
  success: boolean;
  result?: any;
  error?: string;
  confidence: number;
}
```

### 3. 테스트 케이스

#### 유효한 JSON

```typescript
{
  name: 'Valid Simple JSON',
  content: '{"name": "John", "age": 30}',
  expectedSuccess: true,
  expectedStructure: { name: 'string', age: 'number' }
}
```

#### 잘못된 JSON

```typescript
{
  name: 'Malformed JSON with Trailing Comma',
  content: '{"name": "John", "age": 30,}',
  expectedSuccess: false,
  expectedRecovery: true,
  expectedIssues: ['trailing_comma']
}
```

#### 복잡한 JSON

```typescript
{
  name: 'Complex Nested JSON',
  content: `{
    "user": {
      "name": "John",
      "address": {
        "street": "123 Main St",
        "city": "New York"
      }
    },
    "orders": [
      {"id": 1, "items": ["item1", "item2"]},
      {"id": 2, "items": ["item3"]}
    ]
  }`,
  expectedSuccess: true,
  expectedStructure: {
    user: { name: 'string', address: { street: 'string', city: 'string' } },
    orders: [{ id: 'number', items: ['string'] }]
  }
}
```

## RAG 통합 테스트

### 1. RAG 컨텍스트 검색

```typescript
async searchRAGContext(query: string, expectedSources: number): Promise<any> {
  const results = await this.framework.vectorStore.performVectorSearch(query, expectedSources);
  return results;
}
```

### 2. 향상된 프롬프트 생성

```typescript
createEnhancedPrompt(testCase: SourceGenerationTestCase, ragResults: any): string {
  let enhancedPrompt = testCase.prompt;
  
  if (ragResults && ragResults.length > 0) {
    enhancedPrompt += '\n\nRelevant context:\n';
    ragResults.forEach((result: any, index: number) => {
      enhancedPrompt += `${index + 1}. ${result.content}\n`;
    });
    enhancedPrompt += '\nUse the above context to improve your response.';
  }
  
  return enhancedPrompt;
}
```

### 3. 품질 평가

```typescript
validateOutput(output: any, expectedOutput: any): { isValid: boolean; score: number } {
  let score = 0;
  let totalChecks = 0;
  
  // 타입 검증
  if (expectedOutput.type && output.language === expectedOutput.type) {
    score += 1;
  }
  totalChecks += 1;
  
  // 프레임워크 검증
  if (expectedOutput.framework && output.framework === expectedOutput.framework) {
    score += 1;
  }
  totalChecks += 1;
  
  // 구조 검증
  if (expectedOutput.hasJSX && output.content.includes('JSX')) {
    score += 1;
  }
  totalChecks += 1;
  
  return {
    isValid: score / totalChecks >= 0.7,
    score: score / totalChecks
  };
}
```

## 테스트 결과 및 리포트

### 1. JSON 리포트

```json
{
  "summary": {
    "totalTests": 15,
    "passed": 12,
    "failed": 3,
    "successRate": 80.0,
    "executionTime": 45000
  },
  "results": [
    {
      "testCase": {
        "id": "basic-react-component",
        "name": "Basic React Component Generation"
      },
      "success": true,
      "quality": {
        "completeness": 0.9,
        "structure": 0.85,
        "validity": 0.95
      },
      "metadata": {
        "executionTime": 2500,
        "tokensUsed": 1200
      }
    }
  ]
}
```

### 2. Markdown 리포트

```markdown
# COGO 소스 생성 테스트 리포트

## 요약
- **총 테스트**: 15
- **성공**: 12 (80.0%)
- **실패**: 3 (20.0%)
- **실행 시간**: 45초

## 카테고리별 결과
- **code-generation**: 5/6 (83.3%)
- **rag-integration**: 4/5 (80.0%)
- **json-parsing**: 3/4 (75.0%)

## 상세 결과
### 성공한 테스트
1. ✅ Basic React Component Generation
2. ✅ RAG-Enhanced Code Generation
3. ✅ JSON Response Parsing

### 실패한 테스트
1. ❌ Complex JSON Response Parsing
   - 오류: JSON 파싱 실패
   - 원인: 중첩된 객체 구조 문제
```

## 성능 모니터링

### 1. 실행 시간 추적

```typescript
const startTime = Date.now();
const result = await this.runSingleTest(testCase);
const executionTime = Date.now() - startTime;

result.metadata.executionTime = executionTime;
```

### 2. 토큰 사용량 모니터링

```typescript
const response = await this.openaiClient.generateResponse(request);
const tokensUsed = response.usage?.total_tokens || 0;

result.metadata.tokensUsed = tokensUsed;
```

### 3. 품질 메트릭

```typescript
calculateQuality(result: any): { completeness: number; structure: number; validity: number } {
  return {
    completeness: this.calculateCompleteness(result),
    structure: this.calculateStructure(result),
    validity: this.calculateValidity(result)
  };
}
```

## 테스트 환경 설정

### 1. 환경 변수

```bash
# OpenAI API 설정
OPENAI_API_KEY=your_openai_api_key

# Supabase 설정
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key

# Neo4j 설정
NEO4J_URI=your_neo4j_uri
NEO4J_USERNAME=your_neo4j_username
NEO4J_PASSWORD=your_neo4j_password
```

### 2. 설정 파일

```json
{
  "test": {
    "defaultTimeout": 30000,
    "maxRetries": 3,
    "qualityThreshold": 0.7,
    "enableMockMode": false
  },
  "llm": {
    "defaultModel": "gpt-4",
    "maxTokens": 4000,
    "temperature": 0.7
  },
  "rag": {
    "maxSources": 5,
    "similarityThreshold": 0.7
  }
}
```

## 문제 해결

### 1. 일반적인 문제

#### API 키 오류
```bash
Error: OpenAI API key not configured
```
**해결책**: `config/development.json` 또는 환경 변수에 API 키 설정

#### 타임아웃 오류
```bash
Error: Test execution timeout
```
**해결책**: 테스트 케이스의 `timeout` 값 증가 또는 복잡도 감소

#### JSON 파싱 오류
```bash
Error: JSON parsing failed
```
**해결책**: `AdvancedJSONParsingEngine` 사용하여 복구 시도

### 2. 디버깅 팁

```bash
# 상세 로그로 실행
npx ts-node src/tests/rag-system/run-advanced-source-generation-tests.ts --verbose

# 특정 테스트만 실행
npx ts-node src/tests/rag-system/run-advanced-source-generation-tests.ts --categories json-parsing --max 1

# Mock 모드로 실행 (API 키 없이)
# config/development.json에서 enableMockMode: true 설정
```

## 향후 개선 계획

1. **자동화된 테스트**: CI/CD 파이프라인 통합
2. **성능 벤치마크**: 다양한 모델과 설정 비교
3. **사용자 정의 테스트**: 사용자가 정의한 테스트 케이스 지원
4. **실시간 모니터링**: 테스트 실행 중 실시간 메트릭 수집
5. **A/B 테스트**: 다양한 프롬프트와 모델 비교

---

**문서 버전**: 1.0  
**최종 업데이트**: 2024-01-15  
**작성자**: COGO AI Team 